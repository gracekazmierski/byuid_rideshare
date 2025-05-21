import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/ride.dart';

class RideService {
  static Future<void> saveRideListing(Ride ride) async {
    try {
      await FirebaseFirestore.instance
          .collection('rides')
          .add(ride.toFirestore());

      print('✅ Ride saved successfully!');
    } catch (e) {
      print('❌ Failed to save ride: $e');
    }
  }
}