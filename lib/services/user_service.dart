import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_profile.dart';

class UserService {
  static final CollectionReference usersCollection =
      FirebaseFirestore.instance.collection('users');

  /// Saves or updates the user profile
  static Future<void> saveUserProfile(UserProfile profile) async {
    try {
      await usersCollection.doc(profile.uid).set(profile.toFirestore());
      print('User profile saved');
    } catch (e) {
      print('Failed to save user profile: $e');
    }
  }

  /// Fetches a user profile by uid
  static Future<UserProfile?> fetchUserProfile(String uid) async {
    try {
      DocumentSnapshot doc = await usersCollection.doc(uid).get();

      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        return UserProfile.fromFirestore(data);
      } else {
        print('No profile found for UID $uid');
        return null;
      }
    } catch (e) {
      print('Failed to fetch user profile: $e');
      return null;
    }
  }
}

void testProfileSave() async {
  UserProfile profile = UserProfile(uid: 'abc123', name: 'Savannah', isDriver: true, phoneNumber: '555');
  await UserService.saveUserProfile(profile);

  UserProfile? fetched = await UserService.fetchUserProfile('abc123');
  print('Name: ${fetched?.name}');
}
