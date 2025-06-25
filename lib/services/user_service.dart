import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_profile.dart';
import 'package:firebase_auth/firebase_auth.dart';

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

  static Future<void> updateUserProfile(String userId, Map<String, dynamic> data) async {
    try {
      final docRef = FirebaseFirestore.instance.collection('users').doc(userId);
      await docRef.set(data, SetOptions(merge: true));
      print('User profile updated!');
    } catch (e) {
      print('Error updating user profile: $e');
      rethrow;
    }
  }

  static Future<void> updateUserEmail(String newEmail) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await user.verifyBeforeUpdateEmail(newEmail);
        print('Verification email sent to $newEmail. Email will update after verification.');
      }
    } catch (e) {
      print('Error sending email update verification: $e');
      rethrow;
    }
  }

  static Future<void> updateUserPassword(String newPassword) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await user.updatePassword(newPassword);
        print('Password updated successfully');
      }
    } catch (e) {
      print('Error updating password: $e');
      rethrow;
    }
  }
}

void testProfileSave() async {
  UserProfile profile = UserProfile(uid: 'abc123', firstName: 'Savannah', lastName: 'test', isDriver: true, phoneNumber: '555');
  await UserService.saveUserProfile(profile);

  UserProfile? fetched = await UserService.fetchUserProfile('abc123');
  print('Name: ${fetched?.firstName} ${fetched?.lastName}');
}
