// functions/index.js (or index.ts)

// --- CHANGE 1: Import onSchedule from v2 scheduler ---
const { onSchedule } = require("firebase-functions/v2/scheduler");
const admin = require('firebase-admin');

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