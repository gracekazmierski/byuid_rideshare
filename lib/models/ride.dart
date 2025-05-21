import 'package:cloud_firestore/cloud_firestore.dart';
class Ride {
  final String origin;
  final String destination;
  final Timestamp rideDate;
  final int availableSeats;
  final double? fare;
  final String driverUid;
  final String driverName;
  final Timestamp postCreationTime;

  Ride({
    required this.origin,
    required this.destination,
    required this.rideDate,
    required this.availableSeats,
    this.fare,
    required this.driverUid,
    required this.driverName,
    required this.postCreationTime
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
      'postCreationTime': postCreationTime
    };
  }

  factory Ride.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return Ride(
      origin: data['origin'] as String,
      destination: data['destination'] as String,
      rideDate: data['rideDate'] as Timestamp,
      availableSeats: data['availableSeats'] as int,
      fare: data['fare'] as double,
      driverUid: data['driverUid'] as String,
      driverName: data['driverName'] as String,
      postCreationTime: data['postCreationTime'] as Timestamp
    );
  }
}