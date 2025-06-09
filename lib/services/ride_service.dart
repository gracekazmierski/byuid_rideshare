// lib/services/ride_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/ride.dart';

class RideService {
  static final CollectionReference ridesCollection =
  FirebaseFirestore.instance.collection('rides');

  static Future<void> saveRideListing(Ride ride) async {
    try {
      // When saving, if the ride has no ID (new ride), add it and set the ID
      // Otherwise, update the existing document.
      if (ride.id.isEmpty) { // Assuming an empty ID means new ride
        DocumentReference docRef = await ridesCollection.add(ride.toFirestore());
        // You might want to update the local ride object's ID here if needed
        print('Ride saved successfully with ID: ${docRef.id}');
      } else {
        await ridesCollection.doc(ride.id).set(ride.toFirestore());
        print('Ride updated successfully with ID: ${ride.id}');
      }
    } catch (e) {
      print('Failed to save ride: $e');
      rethrow; // Re-throw to propagate error for SnackBar
    }
  }

  static Future<void> cancelRide(String rideId) async {
    final rideRef = FirebaseFirestore.instance.collection('rides').doc(rideId);
    await rideRef.delete();
  }

  static Future<void> removePassenger(String rideId, String passengerUid) async {
    DocumentReference rideRef = FirebaseFirestore.instance.collection('rides').doc(rideId);
    await FirebaseFirestore.instance.runTransaction((transaction) async {
      DocumentSnapshot snapshot = await transaction.get(rideRef);
      if (!snapshot.exists) return;

      List joinedUsers = List.from(snapshot['joinedUserUids']);
      int availableSeats = snapshot['availableSeats'];
      bool isFull = snapshot['isFull'];

      joinedUsers.remove(passengerUid);
      availableSeats += 1;
      isFull = false;

      transaction.update(rideRef, {
        'joinedUserUids': joinedUsers,
        'availableSeats': availableSeats,
        'isFull': isFull,
      });
    });
  }

  /// Fetches a stream of ride listings ordered by rideDate.
  /// This provides real-time updates when new rides are added or existing ones change.
  static Stream<List<Ride>> fetchRideListings() {
    return ridesCollection
        .orderBy('rideDate', descending: false) // Order by date, earliest first
        .snapshots() // Get a stream of query snapshots (real-time updates)
        .map((snapshot) {
      // Map each snapshot to a List<Ride>
      return snapshot.docs
          .map((doc) =>
          Ride.fromFirestore(doc as DocumentSnapshot<Map<String, dynamic>>))
          .toList();
    });
  }

  /// Fetches a stream for a single ride by its ID for real-time updates.
  static Stream<Ride> getRideStream(String rideId) {
    return ridesCollection.doc(rideId).snapshots().map((doc) {
      if (doc.exists) {
        return Ride.fromFirestore(doc as DocumentSnapshot<Map<String, dynamic>>);
      } else {
        throw Exception("Ride not found"); // Or return a default/null value
      }
    });
  }

  /// Claims a seat on a ride using a Firestore transaction for atomicity.
  /// Returns null on success, or an error message string.
  static Future<String?> joinRide(String rideId, String userId) async {
    final rideRef = ridesCollection.doc(rideId);

    try {
      await FirebaseFirestore.instance.runTransaction((transaction) async {
        final DocumentSnapshot snapshot = await transaction.get(rideRef);

        if (!snapshot.exists) {
          throw Exception("Ride no longer exists.");
        }

        final Ride ride = Ride.fromFirestore(snapshot as DocumentSnapshot<Map<String, dynamic>>);

        if (ride.isFull || ride.availableSeats <= 0) {
          throw Exception("This ride is already full!");
        }

        if (ride.driverUid == userId) {
          throw Exception("You cannot join your own ride.");
        }

        if (ride.joinedUserUids.contains(userId)) {
          throw Exception("You have already joined this ride.");
        }

        // Decrement available seats
        final int newAvailableSeats = ride.availableSeats - 1;
        final bool newIsFull = newAvailableSeats <= 0;

        // Add user to joined list
        List<String> newJoinedUserUids = List.from(ride.joinedUserUids);
        newJoinedUserUids.add(userId);

        transaction.update(rideRef, {
          'availableSeats': newAvailableSeats,
          'isFull': newIsFull,
          'joinedUserUids': newJoinedUserUids,
        });
      });
      return null; // Success
    } catch (e) {
      return e.toString().replaceFirst('Exception: ', ''); // Return error message
    }
  }
}