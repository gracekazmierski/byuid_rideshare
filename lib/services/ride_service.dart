// lib/services/ride_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/ride.dart';

class RideService {
  static final CollectionReference ridesCollection =
  FirebaseFirestore.instance.collection('rides');

  static Future<void> saveRideListing(Ride ride) async {
    try {
      await ridesCollection.add(ride.toFirestore());
      print('Ride saved successfully!');
    } catch (e) {
      print('Failed to save ride: $e');
    }
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
          .map((doc) => Ride.fromFirestore(doc as DocumentSnapshot<Map<String, dynamic>>))
          .toList();
    });
  }
}