// lib/models/ride_request.dart

class RideRequest {
  final String id;
  final String rideId;
  final String riderUid;
  final String driverUid;
  final String message;

  RideRequest({
    required this.id,
    required this.rideId,
    required this.riderUid,
    required this.driverUid,
    required this.message,
  });

  factory RideRequest.fromMap(Map<String, dynamic> data, String id) {
    return RideRequest(
      id: id,
      rideId: data['rideId'] ?? '',
      riderUid: data['riderUid'] ?? '',
      driverUid: data['driverUid'] ?? '',
      message: data['message'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'rideId': rideId,
      'riderUid': riderUid,
      'driverUid': driverUid,
      'message': message,
    };
  }
}
