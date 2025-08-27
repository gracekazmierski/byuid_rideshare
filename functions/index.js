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
  // If App Check is enabled, set enforceAppCheck: true per-function below.
});

// ---------------------------------------------------------------------------
// Scheduled cleanup: archive + delete old rides AND ride requests
// Runs daily at 3:00 AM America/Denver
// ---------------------------------------------------------------------------
exports.deleteOldRidesAndRequests = onSchedule(
  {
    schedule: "0 3 * * *",
    timeZone: "America/Denver",
  },
  async () => {
    const now = admin.firestore.Timestamp.now();
    console.log("Running deleteOldRidesAndRequests at:", now.toDate());

    await archiveAndDelete("rides", "rideDate", "completed_rides", now);
    await archiveAndDelete("ride_requests", "requestDate", "completed_requests", now);

    console.log("Cleanup complete for both rides and ride_requests.");
  }
);

// ---------------------------------------------------------------------------
// Helper: archive + delete old docs from a collection
// ---------------------------------------------------------------------------
async function archiveAndDelete(collection, dateField, archiveCollection, cutoff) {
  const snap = await db.collection(collection).where(dateField, "<", cutoff).get();

  if (snap.empty) {
    console.log(`No old docs to delete in ${collection}.`);
    return;
  }

  const docs = snap.docs;
  const chunkSize = 200; // Safe under Firestore batch write limit

  let processed = 0;
  for (let i = 0; i < docs.length; i += chunkSize) {
    const chunk = docs.slice(i, i + chunkSize);
    const batch = db.batch();

    chunk.forEach((doc) => {
      const data = doc.data();
      const archiveRef = db.collection(archiveCollection).doc(doc.id);
      batch.set(archiveRef, data); // archive
      batch.delete(doc.ref);       // delete
    });

    await batch.commit();
    processed += chunk.length;
    console.log(
      `[${collection}] Archived+deleted chunk: ${chunk.length} (total ${processed}/${docs.length})`
    );
  }

  console.log(
    `[${collection}] Completed cleanup. Total archived+deleted: ${docs.length}.`
  );
}


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
    // If App Check is enabled, uncomment:
    // enforceAppCheck: true,
  },
  async (request) => {
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

    await db.collection("users").doc(primaryUid).set(
      {
        byuiEmail,
        byuiEmailVerified: true,
        byuiEmailVerifiedAt: admin.firestore.FieldValue.serverTimestamp(),
      },
      { merge: true }
    );

    const user = await admin.auth().getUser(primaryUid);
    const currentClaims = user.customClaims || {};
    await admin.auth().setCustomUserClaims(primaryUid, {
      ...currentClaims,
      byuiVerified: true,
    });

    return { ok: true };
  }
);
