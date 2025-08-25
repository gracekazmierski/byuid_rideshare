// lib/models/posted_request.dart

import 'package:cloud_firestore/cloud_firestore.dart';

class PostedRequest {
  final String id;
  final String requesterUid;
  final String fromLocation;
  final String toLocation;
  final Timestamp requestDate; // ✅ Replaces start and end dates
  final List<dynamic> riders;
  final String status;

  PostedRequest({
    required this.id,
    required this.requesterUid,
    required this.fromLocation,
    required this.toLocation,
    required this.requestDate, // ✅ Updated constructor
    required this.riders,
    required this.status,
  });

  factory PostedRequest.fromSnapshot(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return PostedRequest(
      id: doc.id,
      requesterUid: data['requester_id'] ?? '',
      fromLocation: data['from_location'] ?? '',
      toLocation: data['to_location'] ?? '',
      // ✅ Updated to read the single 'request_date' field from Firestore
      requestDate: data['request_date'] ?? Timestamp.now(),
      riders: data['riders'] as List<dynamic>? ?? [],
      status: data['status'] ?? 'unknown',
    );
  }
}
