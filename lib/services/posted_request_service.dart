// lib/services/posted_request_service.dart
import 'package:byui_rideshare/models/request_sort_option.dart';
import 'package:byui_rideshare/models/posted_request.dart';
import 'package:byui_rideshare/models/ride.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class PostedRequestService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final CollectionReference _collection = _firestore.collection('ride_requests');
  static final _auth = FirebaseAuth.instance;

  static Stream<List<PostedRequest>> fetchRideRequests({
    String fromLocation = '',
    String toLocation = '',
    RequestSortOption sortOption = RequestSortOption.newest,
  }) {
    DateTime now = DateTime.now();
    DateTime today = DateTime(now.year, now.month, now.day);

    Query query = _collection
        .where('status', isEqualTo: 'active')
        .where('request_date_end', isGreaterThanOrEqualTo: today)
        .orderBy('request_date_end', descending: false);

    if (sortOption == RequestSortOption.newest) {
      query = query.orderBy('created_at', descending: true);
    } else {
      query = query.orderBy('created_at', descending: false);
    }

    return query.snapshots().map((snapshot) {
      var requests = snapshot.docs.map((doc) => PostedRequest.fromSnapshot(doc)).toList();

      if (fromLocation.isNotEmpty) {
        requests = requests.where((req) => req.fromLocation.toLowerCase().contains(fromLocation.toLowerCase())).toList();
      }
      if (toLocation.isNotEmpty) {
        requests = requests.where((req) => req.toLocation.toLowerCase().contains(toLocation.toLowerCase())).toList();
      }
      return requests;
    });
  }
  static Stream<List<PostedRequest>> fetchJoinedRideRequests() {
    final user = _auth.currentUser;
    if (user == null) {
      return Stream.value([]);
    }

    return _collection
        .where('status', isEqualTo: 'active')
        .where('rider_uids', arrayContains: user.uid)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => PostedRequest.fromSnapshot(doc)).toList());
  }

  static Future<void> leaveRideRequest(String requestId) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception("You must be logged in.");

    final requestRef = _collection.doc(requestId);

    // This data must match what's in your 'riders' array map exactly
    final riderToRemove = {
      'uid': user.uid,
      'name': user.displayName ?? 'Anonymous Rider',
    };

    // Use FieldValue.arrayRemove to remove the user from both arrays
    await requestRef.update({
      'riders': FieldValue.arrayRemove([riderToRemove]),
      'rider_uids': FieldValue.arrayRemove([user.uid])
    });
  }

  static Future<void> joinRideRequest(String requestId) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception("You must be logged in to join a request.");

    final requestRef = _collection.doc(requestId);
    final newRider = {
      'uid': user.uid,
      'name': user.displayName ?? 'Anonymous Rider',
    };

    // ✅ Update BOTH arrays at the same time
    await requestRef.update({
      'riders': FieldValue.arrayUnion([newRider]),
      'rider_uids': FieldValue.arrayUnion([user.uid])
    });
  }

  static Future<void> fulfillRideRequest({
    required String requestId,
    required DateTime exactDateTime,
    required int seats,
    required double fare,
    required String origin,
    required String destination,
    required List<dynamic> initialRiders,
  }) async {
    final driver = _auth.currentUser;
    if (driver == null) throw Exception("You must be logged in.");

    final rideOfferRef = _firestore.collection('rides').doc();
    final rideRequestRef = _collection.doc(requestId);

    // This now correctly creates the Ride object based on your model
    final newRide = Ride(
      id: rideOfferRef.id,
      driverUid: driver.uid,
      driverName: driver.displayName ?? 'Unknown Driver',
      origin: origin,
      destination: destination,
      rideDate: Timestamp.fromDate(exactDateTime),
      availableSeats: seats,
      // Your model uses 'joinedUserUids', not 'passengers'
      joinedUserUids: [],
      fare: fare,
      postCreationTime: Timestamp.now(),
      isFull: false,
    );

    WriteBatch batch = _firestore.batch();

    // ✅ FIX: Changed to use your model's toFirestore() method.
    batch.set(rideOfferRef, newRide.toFirestore());
    batch.delete(rideRequestRef);

    await batch.commit();
  }
}