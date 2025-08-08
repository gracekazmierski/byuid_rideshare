// functions/index.js

// ---- Firebase Functions v2 imports ----
const { setGlobalOptions } = require("firebase-functions/v2");
const { onSchedule } = require("firebase-functions/v2/scheduler");
const { onDocumentCreated, onDocumentUpdated } = require("firebase-functions/v2/firestore");
const { onCall } = require("firebase-functions/v2/https");

// ---- Admin SDK ----
const admin = require("firebase-admin");

// Initialize Admin
if (!admin.apps.length) {
  admin.initializeApp();
}
const db = admin.firestore();

// (Optional) Set defaults for all functions. You can tweak memory/timeout here.
// Avoid CPU mismatch errors by keeping v2 everywhere.
setGlobalOptions({
  region: "us-central1",
  timeoutSeconds: 60,
  memory: "256MiB",
});

// ---------------------------------------------------------------------------
// Scheduled cleanup: delete old rides (runs 3:00 AM America/Denver daily)
// ---------------------------------------------------------------------------
exports.deleteOldRides = onSchedule(
  {
    schedule: "0 3 * * *",
    timeZone: "America/Denver",
  },
  async () => {
    const now = admin.firestore.Timestamp.now();
    console.log("Running deleteOldRides scheduled function at:", now.toDate());

    const snapshot = await db
      .collection("rides")
      .where("rideDate", "<", now)
      .get();

    if (snapshot.empty) {
      console.log("No old rides to delete found.");
      return;
    }

    const batch = db.batch();
    snapshot.docs.forEach((doc) => {
      const d = doc.data();
      console.log(`Deleting ride: ${doc.id} (Date: ${d.rideDate?.toDate?.() || d.rideDate})`);
      batch.delete(doc.ref);
    });

    await batch.commit();
    console.log(`Successfully deleted ${snapshot.size} old rides.`);
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
      console.error("Missing request data");
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
      console.error(`Error sending notification to driver ${driverUid}:`, error);
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
    const before = event.data.before.data();
    const after = event.data.after.data();

    const prevStatus = before?.status;
    const nextStatus = after?.status;

    if (prevStatus === nextStatus || nextStatus !== "accepted") {
      return;
    }

    const riderId = after?.riderId;
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
      // If token is invalid/expired, clean it up
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
  { cors: true }, // allow cross-origin if you ever call from web
  async (request) => {
    // Primary user must be authenticated when calling
    if (!request.auth) {
      throw new Error(JSON.stringify({ code: "unauthenticated", message: "Sign in first." }));
    }

    const primaryUid = request.auth.uid;
    const byuiEmail = String(request.data?.byuiEmail || "").trim().toLowerCase();
    const secondaryIdToken = String(request.data?.secondaryIdToken || "").trim();

    const re = /^[a-zA-Z0-9._%+\-]+@byui\.edu$/;
    if (!re.test(byuiEmail)) {
      throw new Error(JSON.stringify({ code: "invalid-argument", message: "Email must be @byui.edu" }));
    }
    if (!secondaryIdToken) {
      throw new Error(JSON.stringify({ code: "invalid-argument", message: "Missing token" }));
    }

    // Verify the secondary user's ID token
    let decoded;
    try {
      decoded = await admin.auth().verifyIdToken(secondaryIdToken);
    } catch (e) {
      throw new Error(JSON.stringify({ code: "permission-denied", message: "Invalid secondary token" }));
    }

    const verifiedEmail = (decoded.email || "").toLowerCase();
    if (verifiedEmail !== byuiEmail) {
      throw new Error(JSON.stringify({ code: "permission-denied", message: "Email/token mismatch" }));
    }

    // Mark verified on primary user's doc
    await db.collection("users").doc(primaryUid).set(
      {
        byuiEmail,
        byuiEmailVerified: true,
        byuiEmailVerifiedAt: admin.firestore.FieldValue.serverTimestamp(),
      },
      { merge: true }
    );

    // Merge custom claims with byuiVerified:true
    const user = await admin.auth().getUser(primaryUid);
    const currentClaims = user.customClaims || {};
    await admin.auth().setCustomUserClaims(primaryUid, {
      ...currentClaims,
      byuiVerified: true,
    });

    return { ok: true };
  }
);
