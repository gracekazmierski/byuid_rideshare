// lib/services/save_fcm_token_on_login.dart

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

Future<void> saveFcmTokenToUser() async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) {
    print("[FCM] No authenticated user, skipping token save.");
    return;
  }

  print("[FCM] Current user UID: ${user.uid}");

  try {
    final token = await FirebaseMessaging.instance.getToken();
    if (token == null) {
      print("[FCM] No FCM token retrieved from FirebaseMessaging.");
      return;
    }

    await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .set(
      {'fcmToken': token},
      SetOptions(merge: true),
    );

    print("[FCM] Token successfully saved for user ${user.uid}");
  } on FirebaseException catch (e) {
    print("[FCM] Firestore error while saving token: ${e.code} - ${e.message}");
  } catch (e, stackTrace) {
    print("[FCM] Unexpected error while saving token: $e");
    print(stackTrace);
  }
}
