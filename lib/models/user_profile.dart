
class UserProfile {
  final String uid;
  final String name;
  final bool isDriver;
  final String phoneNumber;
  final String? vehicleMake;
  final String? vehicleModel;
  final String? vehicleColor;
  final int? vehicleYear;

  UserProfile({
    required this.uid,
    required this.name,
    required this.isDriver,
    required this.phoneNumber,
    this.vehicleMake,
    this.vehicleModel,
    this.vehicleColor,
    this.vehicleYear,
  });

    Map<String, dynamic> toFirestore() {
    return {
      'uid': uid,
      'name': name,
      'isDriver': isDriver,
      'phoneNumber': phoneNumber,
      'vehicleMake': isDriver ? vehicleMake : null,
      'vehicleModel': isDriver ? vehicleModel : null,
      'vehicleColor': isDriver ? vehicleColor : null,
      'vehicleYear': isDriver ? vehicleYear : null,
    };
  }

    factory UserProfile.fromFirestore(Map<String, dynamic> data) {
    return UserProfile(
      uid: data['uid'],
      name: data['name'],
      isDriver: data['isDriver'],
      phoneNumber: data['phoneNumber'],
      vehicleMake: data['vehicleMake'],
      vehicleModel: data['vehicleModel'],
      vehicleColor: data['vehicleColor'],
      vehicleYear: data['vehicleYear'],
    );
  }
}