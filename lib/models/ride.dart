// lib/models/ride.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class Ride {
  final String id; // Add an ID field for document ID
  final String origin;
  final String destination;
  final Timestamp rideDate;
  final int availableSeats;
  final double? fare;
  final String driverUid;
  final String driverName;
  final Timestamp postCreationTime;
  final bool isFull; // New: To indicate if the ride is full
  final List<String> joinedUserUids; // New: To track users who joined

  Ride({
    required this.id, // Must be provided now
    required this.origin,
    required this.destination,
    required this.rideDate,
    required this.availableSeats,
    this.fare,
    required this.driverUid,
    required this.driverName,
    required this.postCreationTime,
    this.isFull = false, // Default to false
    this.joinedUserUids = const [], // Default to empty list
  });

  Map<String, dynamic> toFirestore() {
    return {
      'origin': origin,
      'destination': destination,
      'rideDate': rideDate,
      'availableSeats': availableSeats,
      'fare': fare ?? 0,
      'driverUid': driverUid,
      'driverName': driverName,
      'postCreationTime': postCreationTime,
      'isFull': isFull,
      'joinedUserUids': joinedUserUids,
    };
  }

  factory Ride.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return Ride(
      id: doc.id, // Set the ID from the document snapshot
      origin: data['origin'] as String,
      destination: data['destination'] as String,
      rideDate: data['rideDate'] as Timestamp,
      availableSeats: data['availableSeats'] as int,
      fare: (data['fare'] as num?)?.toDouble(),
      driverUid: data['driverUid'] as String,
      driverName: data['driverName'] as String? ?? 'Unknown Driver',
      postCreationTime: data['postCreationTime'] as Timestamp,
      isFull: data['isFull'] as bool? ?? false, // Handle null case for existing docs
      joinedUserUids: List<String>.from(data['joinedUserUids'] ?? []), // Handle null case
    );
  }

  // Helper method for updating a Ride object (useful in transactions)
  Ride copyWith({
    String? id,
    String? origin,
    String? destination,
    Timestamp? rideDate,
    int? availableSeats,
    double? fare,
    String? driverUid,
    String? driverName,
    Timestamp? postCreationTime,
    bool? isFull,
    List<String>? joinedUserUids,
  }) {
    return Ride(
      id: id ?? this.id,
      origin: origin ?? this.origin,
      destination: destination ?? this.destination,
      rideDate: rideDate ?? this.rideDate,
      availableSeats: availableSeats ?? this.availableSeats,
      fare: fare ?? this.fare,
      driverUid: driverUid ?? this.driverUid,
      driverName: driverName ?? this.driverName,
      postCreationTime: postCreationTime ?? this.postCreationTime,
      isFull: isFull ?? this.isFull,
      joinedUserUids: joinedUserUids ?? this.joinedUserUids,
    );
  }
}