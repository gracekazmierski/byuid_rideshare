class UserProfile {
  final String uid;
  final String firstName;
  final String lastName;
  final bool isDriver;
  final String phoneNumber;
  final String? facebookUsername;
  final String? vehicleMake;
  final String? vehicleModel;
  final String? vehicleColor;
  final int? vehicleYear;
  final String? profilePictureUrl;

  UserProfile({
    required this.uid,
    required this.firstName,
    required this.lastName,
    required this.isDriver,
    required this.phoneNumber,
    this.facebookUsername,
    this.vehicleMake,
    this.vehicleModel,
    this.vehicleColor,
    this.vehicleYear,
    this.profilePictureUrl,
  });

  Map<String, dynamic> toFirestore() {
    final data = {
      'uid': uid,
      'firstName': firstName,
      'lastName': lastName,
      'isDriver': isDriver,
      'phoneNumber': phoneNumber,
      'vehicleMake': isDriver ? vehicleMake : null,
      'vehicleModel': isDriver ? vehicleModel : null,
      'vehicleColor': isDriver ? vehicleColor : null,
      'vehicleYear': isDriver ? vehicleYear : null,
      'profilePictureUrl': profilePictureUrl,
    };

    // Conditionally add facebookUsername only if it's non-null and non-empty
    if (facebookUsername != null && facebookUsername!.trim().isNotEmpty) {
      data['facebookUsername'] = facebookUsername!.trim();
    }

    return data;
  }

  factory UserProfile.fromFirestore(Map<String, dynamic> data) {
    return UserProfile(
      uid: data['uid'] ?? '',
      firstName: data['firstName'] ?? '',
      lastName: data['lastName'] ?? '',
      isDriver: data['isDriver'] ?? false,
      phoneNumber: data['phoneNumber'] ?? '',
      facebookUsername: data['facebookUsername'],
      vehicleMake: data['vehicleMake'],
      vehicleModel: data['vehicleModel'],
      vehicleColor: data['vehicleColor'],
      vehicleYear: data['vehicleYear'],
      profilePictureUrl: data['profilePictureUrl'],
    );
  }
}
