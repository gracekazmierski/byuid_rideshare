// lib/services/ride_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/ride.dart';
// import 'package:byui_rideshare/screens/rides/driver_requests_screen.dart';
import 'package:byui_rideshare/models/ride_request.dart';


class RideService {
  static final CollectionReference ridesCollection =
    FirebaseFirestore.instance.collection('rides');
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // save rides to firestore
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

  // driver can delete rides
  static Future<void> cancelRide(String rideId) async {
    final rideRef = FirebaseFirestore.instance.collection('rides').doc(rideId);
    await rideRef.delete();
  }

  // driver can remove passengers
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
  static Stream<List<Ride>> fetchRideListings({String? searchQuery}) {
    return ridesCollection
        .orderBy('rideDate', descending: false) // Order by date, earliest first
        .snapshots() // Get a stream of query snapshots (real-time updates)
        .map((snapshot) {
          // Convert each document snapshot into a Ride object and collect them into a List<Ride>
          List<Ride> rides = snapshot.docs
              .map((doc) => Ride.fromFirestore(doc as DocumentSnapshot<Map<String, dynamic>>))
              .toList();

          // If a search query is provided, filter the list of rides
          //The query is matched against the "origin" and "destination"
          if (searchQuery != null && searchQuery.isNotEmpty) {
            final lowerQuery = searchQuery.toLowerCase();
            rides = rides.where((ride) =>
              ride.origin.toLowerCase().contains(lowerQuery) ||
              ride.destination.toLowerCase().contains(lowerQuery)).toList(); // Make lowercase so there are no spell search errors.
          }

          return rides;

      // Map each snapshot to a List<Ride>
      // return snapshot.docs
      //     .map((doc) =>
      //     Ride.fromFirestore(doc as DocumentSnapshot<Map<String, dynamic>>))
      //     .toList();
    });
  }

  /// Fetches a stream of ride listings for a specific driver, ordered by rideDate.
  static Stream<List<Ride>> fetchDriverRideListings(String driverUid) {
    return ridesCollection
        .where('driverUid', isEqualTo: driverUid) // Filter by driverUid
        .orderBy('rideDate', descending: false) // Optional: order by date
        .snapshots()
        .map((snapshot) {
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

  // user can request to join ride using the button
  static Future<void> requestToJoinRide(
    String rideId, String riderUid, String message) async {
    try {
      // Get the ride to retrieve its driverUid
      final rideDoc = await _firestore.collection('rides').doc(rideId).get();
      if (!rideDoc.exists) throw Exception("Ride not found");

      final driverUid = rideDoc['driverUid'];

      // Save ride request with driverUid included
      await _firestore.collection('ride_requests').add({
        'rideId': rideId,
        'riderUid': riderUid,
        'driverUid': driverUid, // 🔹 important
        'message': message,
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (error) {
      print('Error sending ride request: $error');
      throw error;
    }
  }

  // shows driver list of requests made from riders
  static Stream<List<RideRequest>> fetchRideRequestsForDriver(String driverUid) {
    return _firestore
        .collection('ride_requests')
        .where('driverUid', isEqualTo: driverUid)
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => RideRequest.fromMap(d.data(), d.id)).toList()); 
  }

  // list of pending requests that need an answer
  static Stream<List<RideRequest>> fetchRequestsForRide(String rideId) {
    return _firestore
        .collection('ride_requests')
        .where('rideId', isEqualTo: rideId)
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .map((snap) =>
            snap.docs.map((doc) => RideRequest.fromMap(doc.data(), doc.id)).toList());
  }

  // ability to accept ride
  static Future<void> acceptRideRequest(
    String requestId, String rideId, String riderUid) async {
    final rideRef = _firestore.collection('rides').doc(rideId);
    final requestRef = _firestore.collection('ride_requests').doc(requestId);

    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(rideRef);
      if (!snapshot.exists) throw Exception('Ride not found.');

      final data = snapshot.data()!;
      final currentJoined = List<String>.from(data['joinedUserUids'] ?? []);
      final availableSeats = data['availableSeats'] ?? 0;
      final driverUid = data['driverUid'];

      if (availableSeats <= 0) throw Exception('No available seats.');
      if (currentJoined.contains(riderUid)) throw Exception('Already joined.');

      final updatedJoined = [...currentJoined, riderUid];
      final updatedSeats = availableSeats - 1;

      // ✨ update exactly what the Firestore rules expect
      transaction.update(rideRef, {
        'joinedUserUids': updatedJoined,
        'availableSeats': updatedSeats,
        'driverUid': driverUid, // 🔐 include this so Firestore knows it didn't change
      });

      transaction.delete(requestRef);
    });

    // Notify the rider
    await _firestore.collection('notifications').add({
      'userId': riderUid,
      'message': 'Your request to join ride $rideId was accepted.',
      'timestamp': FieldValue.serverTimestamp(),
      'read': false,
    });
  }

  //ability to deny ride
  static Future<void> denyRideRequest(String requestId) async {
    await _firestore.collection('ride_requests').doc(requestId).delete();
  }

  // get requests rider has made so far
  static Stream<List<RideRequest>> fetchRequestsByRider(String riderUid) {
    return _firestore
        .collection('ride_requests')
        .where('riderUid', isEqualTo: riderUid)
        .snapshots()
        .map((snap) => snap.docs.map((d) => RideRequest.fromMap(d.data(), d.id)).toList());
  }
  
  /// Fetches a list of joined rides based on the userID
  static Stream<List<Ride>> fetchJoinedRideListings(String? passengerUid) {
    return FirebaseFirestore.instance
        .collection('rides')
        .where('joinedUserUids', arrayContains: passengerUid)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => Ride.fromFirestore(doc)).toList();
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