import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_profile.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'dart:io';
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
          final data = profile.toFirestore();
          data['fcmToken'] = fcmToken;
          await usersCollection.doc(profile.uid).set(data);
        } else {
          await usersCollection.doc(profile.uid).set(profile.toFirestore());
        }
      } else {
        await usersCollection.doc(profile.uid).set(profile.toFirestore());
      }

    } catch (e) {
    }
  }

  /// Listens for FCM token refresh and updates Firestore
  static void listenForTokenRefresh() {
    FirebaseMessaging.instance.onTokenRefresh.listen((newToken) async {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await usersCollection.doc(user.uid).update({'fcmToken': newToken});
      }
    });
  }

  /// Save FCM token independently (if needed)
  static Future<void> saveFcmToken() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return;
    }

    final fcmToken = await FirebaseMessaging.instance.getToken();
    if (fcmToken == null) {
      return;
    }


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
        return null;
      }
    } catch (e) {
      return null;
    }
  }

  static Future<void> updateUserProfile(String userId, Map<String, dynamic> data) async {
    try {
      final docRef = usersCollection.doc(userId);
      await docRef.set(data, SetOptions(merge: true));
    } catch (e) {
      rethrow;
    }
  }

  static Future<void> updateUserEmail(String newEmail) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await user.verifyBeforeUpdateEmail(newEmail);
      }
    } catch (e) {
      rethrow;
    }
  }

  static Future<void> updateUserPassword(String newPassword) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await user.updatePassword(newPassword);
      }
    } catch (e) {
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
      return url;
    } catch (e) {
      rethrow;
    }
  }


  Future<String?> uploadProfilePicture(String uid, File imageFile) async {
    try {
      final ref = FirebaseStorage.instance.ref().child('profile_pictures/$uid.jpg');
      await ref.putFile(imageFile);
      return await ref.getDownloadURL();
    } catch (e) {
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
      return "Unknown Driver";
    }
  }

  Future<UploadTask> startUploadProfilePictureFromBytes(
      String uid, Uint8List bytes) async {
    final ref = FirebaseStorage.instance
        .ref()
        .child('profile_pictures/$uid.jpg'); // keep path consistent

    final metadata = SettableMetadata(contentType: 'image/jpeg');
    final task = ref.putData(bytes, metadata);
    return task; // your UI awaits this method to obtain the UploadTask
  }
}

void testProfileSave() async {
  UserProfile profile = UserProfile(uid: 'abc123', firstName: 'Savannah', lastName: 'test', isDriver: true, phoneNumber: '555');
  await UserService.saveUserProfile(profile);

  UserProfile? fetched = await UserService.fetchUserProfile('abc123');
}

Future<String?> uploadProfilePicture(String uid, File imageFile) async {
  try {
    final ref = FirebaseStorage.instance.ref().child('profile_pictures/$uid.jpg');
    await ref.putFile(imageFile);
    final url = await ref.getDownloadURL();
    return url;
  } catch (e) {
    return null;
  }
}
