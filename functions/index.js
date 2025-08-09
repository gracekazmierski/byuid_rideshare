// functions/index.js

// -------------------------------
// Firebase Functions v2 imports
// -------------------------------
const { setGlobalOptions } = require("firebase-functions/v2");
const { onSchedule } = require("firebase-functions/v2/scheduler");
const { onDocumentCreated, onDocumentUpdated } = require("firebase-functions/v2/firestore");
const { onCall, HttpsError } = require("firebase-functions/v2/https");

// -------------------------------
// Admin SDK
// -------------------------------
const admin = require("firebase-admin");

// Initialize Admin once
if (!admin.apps.length) {
  admin.initializeApp();
}
const db = admin.firestore();

// -------------------------------
// Global defaults for v2 functions
// -------------------------------
setGlobalOptions({
  region: "us-central1",
  timeoutSeconds: 60,
  memory: "256MiB",
  // If you enable App Check, you can set enforceAppCheck: true at function-level below.
});

// ---------------------------------------------------------------------------
// Scheduled cleanup: delete old rides (runs 3:00 AM America/Denver daily)
// - Uses chunked batch deletes to stay under Firestore batch limits.
// ---------------------------------------------------------------------------
exports.deleteOldRides = onSchedule(
  {
    schedule: "0 3 * * *",
    timeZone: "America/Denver",
  },
  async () => {
    const now = admin.firestore.Timestamp.now();
    console.log("Running deleteOldRides at:", now.toDate());

    const snap = await db.collection("rides").where("rideDate", "<", now).get();
    if (snap.empty) {
      console.log("No old rides to delete.");
      return;
    }

    const docs = snap.docs;
    // Chunk at <= 450 to leave headroom
    for (let i = 0; i < docs.length; i += 450) {
      const chunk = docs.slice(i, i + 450);
      const batch = db.batch();
      chunk.forEach((doc) => batch.delete(doc.ref));
      await batch.commit();
    }

    console.log(`Deleted ${docs.length} old rides.`);
  }
);

// ---------------------------------------------------------------------------
// Firestore (Created): notify driver when a new ride request is created
// Path: ride_requests/{requestId}
// ---------------------------------------------------------------------------
exports.notifyDriverOnRideRequest = onDocumentCreated(
  { document: "ride_requests/{requestId}" },
  async (event) => {
    const request = event.data?.data();
    if (!request) {
      console.error("Missing ride_requests payload");
      return;
    }

    const {
      driverUid,
      riderUid,
      rideId,
      message = "",
      riderName = "A rider",
    } = request;

    if (!driverUid) {
      console.warn("ride_requests doc missing driverUid");
      return;
    }

    const driverDoc = await db.collection("users").doc(driverUid).get();
    const fcmToken = driverDoc.data()?.fcmToken;
    if (!fcmToken) {
      console.warn(`No FCM token for driver UID: ${driverUid}`);
      return;
    }

    const payload = {
      token: fcmToken,
      notification: {
        title: "New Ride Request",
        body: `${riderName} has requested to join your ride.`,
      },
      data: {
        rideId: String(rideId || ""),
        riderUid: String(riderUid || ""),
        type: "ride_request",
        message: String(message || ""),
      },
    };

    try {
      await admin.messaging().send(payload);
      console.log(`Notification sent to driver ${driverUid}`);
    } catch (error) {
      const code = error?.errorInfo?.code || error?.code || "";
      // Clean up bad tokens
      if (String(code).includes("registration-token-not-registered")) {
        console.warn("Invalid FCM token — removing from Firestore.");
        await db.collection("users").doc(driverUid).update({
          fcmToken: admin.firestore.FieldValue.delete(),
        });
      } else {
        console.error(`Error sending notification to driver ${driverUid}:`, error);
      }
    }
  }
);

// ---------------------------------------------------------------------------
// Firestore (Updated): notify rider when a ride is accepted
// Path: rides/{rideId}
// Triggers only when status changes to 'accepted'
// ---------------------------------------------------------------------------
exports.notifyRiderOnRideAccepted = onDocumentUpdated(
  { document: "rides/{rideId}" },
  async (event) => {
    if (!event.data?.before || !event.data?.after) return;

    const before = event.data.before.data() || {};
    const after = event.data.after.data() || {};

    const prevStatus = before.status;
    const nextStatus = after.status;
    if (prevStatus === nextStatus || nextStatus !== "accepted") return;

    const riderId = after.riderId;
    if (!riderId) {
      console.error("No riderId found on ride.");
      return;
    }

    const riderDoc = await db.collection("users").doc(riderId).get();
    const fcmToken = riderDoc.data()?.fcmToken;
    if (!fcmToken) {
      console.warn(`No FCM token for rider UID: ${riderId}`);
      return;
    }

    const payload = {
      token: fcmToken,
      notification: {
        title: "Ride Accepted",
        body: "A driver has accepted your ride request. 🎉",
      },
      data: {
        rideId: String(event.params.rideId || ""),
        type: "rideAccepted",
      },
    };

    try {
      await admin.messaging().send(payload);
      console.log(`Notification sent to rider ${riderId}`);
    } catch (error) {
      const code = error?.errorInfo?.code || error?.code || "";
      if (String(code).includes("registration-token-not-registered")) {
        console.warn("Invalid FCM token — removing from Firestore.");
        await db.collection("users").doc(riderId).update({
          fcmToken: admin.firestore.FieldValue.delete(),
        });
      } else {
        console.error(`Error sending notification to rider ${riderId}:`, error);
      }
    }
  }
);

// ---------------------------------------------------------------------------
// HTTPS Callable (v2): confirm BYUI verification using secondary ID token
// Called by the app after it signs in with email-link on a secondary Auth
// ---------------------------------------------------------------------------
exports.confirmByuiVerification = onCall(
  {
    region: "us-central1",
    // If you've enabled App Check, uncomment next line:
    // enforceAppCheck: true,
  },
  async (request) => {
    // Auth check for the primary session
    if (!request.auth) {
      throw new HttpsError("unauthenticated", "Sign in first.");
    }

    const primaryUid = request.auth.uid;
    const byuiEmail = String(request.data?.byuiEmail || "").trim().toLowerCase();
    const secondaryIdToken = String(request.data?.secondaryIdToken || "").trim();

    const re = /^[a-zA-Z0-9._%+\-]+@byui\.edu$/;
    if (!re.test(byuiEmail)) {
      throw new HttpsError("invalid-argument", "Email must be @byui.edu");
    }
    if (!secondaryIdToken) {
      throw new HttpsError("invalid-argument", "Missing token");
    }

    // Verify the secondary token (proof of inbox control)
    let decoded;
    try {
      decoded = await admin.auth().verifyIdToken(secondaryIdToken);
    } catch {
      throw new HttpsError("permission-denied", "Invalid secondary token");
    }

    const verifiedEmail = String(decoded.email || "").toLowerCase();
    if (verifiedEmail !== byuiEmail) {
      throw new HttpsError("permission-denied", "Email/token mismatch");
    }

    // Mark verified in Firestore
    await db.collection("users").doc(primaryUid).set(
      {
        byuiEmail,
        byuiEmailVerified: true,
        byuiEmailVerifiedAt: admin.firestore.FieldValue.serverTimestamp(),
      },
      { merge: true }
    );

    // Add/merge custom claims
    const user = await admin.auth().getUser(primaryUid);
    const currentClaims = user.customClaims || {};
    await admin.auth().setCustomUserClaims(primaryUid, {
      ...currentClaims,
      byuiVerified: true,
    });

    // Always return a structured payload
    return { ok: true };
  }
);
