// functions/index.js

// --- CHANGE 1: Import onSchedule from v2 scheduler ---
const { onSchedule } = require("firebase-functions/v2/scheduler");
const admin = require('firebase-admin');
const functions = require("firebase-functions");

const { onDocumentCreated } = require("firebase-functions/v2/firestore");
const { initializeApp } = require("firebase-admin/app");
const { getFirestore } = require("firebase-admin/firestore");
const { getMessaging } = require("firebase-admin/messaging");

// // Initialize Admin SDK
// initializeApp();
// const db = getFirestore();

// Initialize Firebase Admin SDK if not already initialized
if (!admin.apps.length) {
  admin.initializeApp();
}

const db = admin.firestore();

// Scheduled function to delete old rides
// This function will run every day at 3:00 AM America/Denver time (MDT)
// Adjust the schedule ('0 3 * * *') or timeZone if needed for your preference.
// Current time in Billings, Montana is Thursday, June 19, 2025 at 7:41:00 PM MDT.
// So 3:00 AM MDT would be ideal for a daily cleanup.

// --- CHANGE 2: Use onSchedule directly with an options object ---
exports.deleteOldRides = onSchedule({
    schedule: '0 3 * * *',
    timeZone: 'America/Denver' // Use America/Denver for MDT (Mountain Daylight Time)
}, async (event) => { // context is often named 'event' in v2, but 'context' also works.
    const now = admin.firestore.Timestamp.now(); // Get current server time

    console.log('Running deleteOldRides scheduled function at:', now.toDate());

    // Query for rides where rideDate is in the past
    const oldRidesQuery = db.collection('rides')
                          .where('rideDate', '<', now);

    const snapshot = await oldRidesQuery.get();

    if (snapshot.empty) {
      console.log('No old rides to delete found.');
      return null;
    }

    // Use a batch to delete multiple documents efficiently
    const batch = db.batch();
    snapshot.docs.forEach(doc => {
      console.log(`Deleting ride: ${doc.id} (Date: ${doc.data().rideDate.toDate()})`);
      batch.delete(doc.ref);
    });

    try {
      await batch.commit();
      console.log(`Successfully deleted ${snapshot.size} old rides.`);
      return null;
    } catch (error) {
      console.error('Error deleting old rides:', error);
      // In v2, it's more standard to just rethrow the error for Firebase to catch it
      throw error; // --- CHANGE 3: Simpler error rethrow for v2 ---
    }
});


// Firestore Trigger: Notify driver when new ride request is created
exports.notifyDriverOnRideRequest = onDocumentCreated(
  "ride_requests/{requestId}",
  async (event) => {
    const request = event.data?.data();

    if (!request) {
      console.error("Missing request data");
      return;
    }

    const { driverUid, riderUid, rideId, message = "", riderName = "A rider" } = request;

    const driverDoc = await db.collection("users").doc(driverUid).get();
    const fcmToken = driverDoc.data()?.fcmToken;

    if (!fcmToken) {
      console.warn(`No FCM token for driver UID: ${driverUid}`);
      return;
    }

    const payload = {
      notification: {
        title: "New Ride Request",
        body: `${riderName} has requested to join your ride.`,
      },
      data: {
        rideId,
        riderUid,
        type: "ride_request",
      },
    };

    try {
      await admin.messaging().send({
        token: fcmToken,
        ...payload,
      });
      console.log(`Notification sent to driver ${driverUid}`);
    } catch (error) {
      console.error(`Error sending notification to driver ${driverUid}:`, error);
    }
    console.log(`Notification sent to driver ${driverUid}`);
  }
);

// Firestore Trigger: Notify rider when ride is accepted
exports.notifyRiderOnRideAccepted = functions
  .region("us-central1")
  .runWith({ memory: "256MB", timeoutSeconds: 60 }) // optional tuning
  .firestore.document("rides/{rideId}")
  .onUpdate(async (change, context) => {
    const before = change.before.data();
    const after = change.after.data();

    if (before.status === after.status || after.status !== "accepted") return null;

    const riderId = after.riderId;
    if (!riderId) return console.error("No riderId found on ride.");

    const riderDoc = await db.collection("users").doc(riderId).get();
    const fcmToken = riderDoc.get("fcmToken");

    if (!fcmToken) {
      console.warn(`No FCM token for rider UID: ${riderId}`);
      return null;
    }

    const payload = {
      notification: {
        title: "Ride Accepted",
        body: "A driver has accepted your ride request. 🎉",
      },
      data: {
        rideId: context.params.rideId,
        type: "rideAccepted",
      },
    };

    try {
      const response = await admin.messaging().sendToDevice(fcmToken, payload);
      const result = response.results[0];

      if (result.error?.code === "messaging/registration-token-not-registered") {
        console.warn("Invalid FCM token — removing from Firestore.");
        await db.collection("users").doc(riderId).update({
          fcmToken: admin.firestore.FieldValue.delete(),
        });
      }

      console.log(`Notification sent to rider ${riderId}`);
    } catch (error) {
      console.error(`Error sending notification to rider ${riderId}:`, error);
    }

    return null;
  });