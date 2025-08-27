// lib/models/ride.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class Ride {
  final String id;
  final String origin;
  final String destination;
  final Timestamp rideDate;
  final Timestamp? returnDate; // ✅ New for round trips
  final int availableSeats;
  final double? fare;
  final String driverUid;
  final String driverName;
  final Timestamp postCreationTime;
  final bool isFull;
  final List<String> joinedUserUids;

  final bool isEvent;
  final String? eventName;
  final String? eventDescription; // ✅ New short description

  Ride({
    required this.id,
    required this.origin,
    required this.destination,
    required this.rideDate,
    this.returnDate,
    required this.availableSeats,
    this.fare,
    required this.driverUid,
    required this.driverName,
    required this.postCreationTime,
    this.isFull = false,
    this.joinedUserUids = const [],
    this.isEvent = false,
    this.eventName,
    this.eventDescription,
  });

  Map<String, dynamic> toFirestore() {
    return {
      'origin': origin,
      'destination': destination,
      'rideDate': rideDate,
      'returnDate': returnDate, // ✅ Save return date
      'availableSeats': availableSeats,
      'fare': fare ?? 0,
      'driverUid': driverUid,
      'driverName': driverName,
      'postCreationTime': postCreationTime,
      'isFull': isFull,
      'joinedUserUids': joinedUserUids,
      'isEvent': isEvent,
      'eventName': eventName,
      'eventDescription': eventDescription, // ✅ Save description
    };
  }

  factory Ride.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return Ride(
      id: doc.id,
      origin: data['origin'] as String,
      destination: data['destination'] as String,
      rideDate: data['rideDate'] as Timestamp,
      returnDate: data['returnDate'] as Timestamp?, // ✅ Load returnDate
      availableSeats: data['availableSeats'] as int,
      fare: (data['fare'] as num?)?.toDouble(),
      driverUid: data['driverUid'] as String,
      driverName: data['driverName'] as String? ?? 'Unknown Driver',
      postCreationTime: data['postCreationTime'] as Timestamp,
      isFull: data['isFull'] as bool? ?? false,
      joinedUserUids: List<String>.from(data['joinedUserUids'] ?? []),
      isEvent: data['isEvent'] ?? false,
      eventName: data['eventName'],
      eventDescription: data['eventDescription'], // ✅ Load description
    );
  }

  Ride copyWith({
    String? id,
    String? origin,
    String? destination,
    Timestamp? rideDate,
    Timestamp? returnDate,
    int? availableSeats,
    double? fare,
    String? driverUid,
    String? driverName,
    Timestamp? postCreationTime,
    bool? isFull,
    List<String>? joinedUserUids,
    bool? isEvent,
    String? eventName,
    String? eventDescription,
  }) {
    return Ride(
      id: id ?? this.id,
      origin: origin ?? this.origin,
      destination: destination ?? this.destination,
      rideDate: rideDate ?? this.rideDate,
      returnDate: returnDate ?? this.returnDate,
      availableSeats: availableSeats ?? this.availableSeats,
      fare: fare ?? this.fare,
      driverUid: driverUid ?? this.driverUid,
      driverName: driverName ?? this.driverName,
      postCreationTime: postCreationTime ?? this.postCreationTime,
      isFull: isFull ?? this.isFull,
      joinedUserUids: joinedUserUids ?? this.joinedUserUids,
      isEvent: isEvent ?? this.isEvent,
      eventName: eventName ?? this.eventName,
      eventDescription: eventDescription ?? this.eventDescription,
    );
  }
}
