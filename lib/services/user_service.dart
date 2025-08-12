import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_profile.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'dart:io';
import 'dart:typed_data'; // For Uint8List;
import 'package:flutter/foundation.dart';
import 'package:flutter/foundation.dart';

class UserService {
  static final _db = FirebaseFirestore.instance;
  static final CollectionReference usersCollection =
  FirebaseFirestore.instance.collection('users');

  /// Saves or updates the user profile, including FCM token
  static Future<void> saveUserProfile(UserProfile profile) async {
    try {
      if (!kIsWeb) {
        // ✅ Only do this on non-web platforms
        final fcmToken = await FirebaseMessaging.instance.getToken();
        if (fcmToken != null) {
          print('📡 FCM token retrieved: $fcmToken');
          final data = profile.toFirestore();
          data['fcmToken'] = fcmToken;
          await usersCollection.doc(profile.uid).set(data);
        } else {
          print('⚠️ FCM token was null — skipping token save');
          await usersCollection.doc(profile.uid).set(profile.toFirestore());
        }
      } else {
        // 🌐 Web: Skip FCM logic entirely
        print('🌐 Web platform — skipping FCM logic');
        await usersCollection.doc(profile.uid).set(profile.toFirestore());
      }

      print('✅ User profile saved!');
    } catch (e) {
      print('❌ Failed to save user profile: $e');
    }
  }

  /// Listens for FCM token refresh and updates Firestore
  static void listenForTokenRefresh() {
    FirebaseMessaging.instance.onTokenRefresh.listen((newToken) async {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await usersCollection.doc(user.uid).update({'fcmToken': newToken});
        print('FCM token updated after refresh: $newToken');
      }
    });
  }

  /// Save FCM token independently (if needed)
  static Future<void> saveFcmToken() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      print("User not logged in, cannot save FCM token.");
      return;
    }

    final fcmToken = await FirebaseMessaging.instance.getToken();
    if (fcmToken == null) {
      print("Failed to get FCM token.");
      return;
    }

    print("Saving FCM token: $fcmToken");

    await usersCollection.doc(user.uid).update({
      'fcmToken': fcmToken,
    });
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
      final docRef = usersCollection.doc(userId);
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

  static Future<void> updateByuiEmail(String uid, String email) async {
    await _db.collection('users').doc(uid).set({
      'byuiEmail': email,
      'byuiEmailVerified': false,
    }, SetOptions(merge: true));
  }

  static Future<Map<String, dynamic>?> fetchByuiStatus(String uid) async {
    final snap = await _db.collection('users').doc(uid).get();
    return snap.data();
  }

  Future<String> uploadProfilePictureFromBytes(String uid, Uint8List imageBytes) async {
    try {
      print('⬆️ Uploading memory image to Firebase Storage...');
      final ref = FirebaseStorage.instance.ref().child('profile_pictures/$uid.jpg');

      final uploadTask = ref.putData(
        imageBytes,
        SettableMetadata(contentType: 'image/jpeg'),
      );

      final snapshot = await uploadTask.timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception('Upload timed out');
        },
      );

      final url = await snapshot.ref.getDownloadURL();
      print('✅ Upload complete: $url');
      return url;
    } catch (e) {
      print('❌ Failed to upload profile picture from bytes: $e');
      rethrow;
    }
  }


  Future<String?> uploadProfilePicture(String uid, File imageFile) async {
    try {
      final ref = FirebaseStorage.instance.ref().child('profile_pictures/$uid.jpg');
      await ref.putFile(imageFile);
      return await ref.getDownloadURL();
    } catch (e) {
      print('Failed to upload profile picture: $e');
      return null;
    }
  }


  /// Returns the full name (or first name only) for a given UID
  static Future<String?> getUserName(String uid) async {
    try {
      final profile = await fetchUserProfile(uid);
      if (profile == null) return "Unknown Driver";

      final first = profile.firstName ?? "";
      final last = profile.lastName ?? "";

      if (first.isEmpty && last.isEmpty) return "Unknown Driver";
      return last.isEmpty ? first : "$first $last";
    } catch (e) {
      print('Error getting user name for UID $uid: $e');
      return "Unknown Driver";
    }
  }
}

void testProfileSave() async {
  UserProfile profile = UserProfile(uid: 'abc123', firstName: 'Savannah', lastName: 'test', isDriver: true, phoneNumber: '555');
  await UserService.saveUserProfile(profile);

  UserProfile? fetched = await UserService.fetchUserProfile('abc123');
  print('Name: ${fetched?.firstName} ${fetched?.lastName}');
}

Future<String?> uploadProfilePicture(String uid, File imageFile) async {
  try {
    print('⬆️ Uploading file to Firebase Storage...');
    final ref = FirebaseStorage.instance.ref().child('profile_pictures/$uid.jpg');
    await ref.putFile(imageFile);
    final url = await ref.getDownloadURL();
    print('✅ Upload complete: $url');
    return url;
  } catch (e) {
    print('❌ Failed to upload profile picture: $e');
    return null;
  }
}

Future<String> uploadProfilePictureFromBytes(String uid, Uint8List imageBytes) async {
  try {
    print('⬆️ Uploading memory image to Firebase Storage...');
    final ref = FirebaseStorage.instance.ref().child('profile_pictures/$uid.jpg');
    await ref.putData(imageBytes, SettableMetadata(contentType: 'image/jpeg'));
    final url = await ref.getDownloadURL();
    print('✅ Upload complete: $url');
    return url;
  } catch (e) {
    print('❌ Failed to upload profile picture from bytes: $e');
    rethrow;
  }
}