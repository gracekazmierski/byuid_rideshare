// lib/services/save_fcm_token_on_login.dart

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

Future<void> saveFcmTokenToUser() async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return;

  print("Current user UID: ${user?.uid}");

  try {
    final token = await FirebaseMessaging.instance.getToken();
    if (token != null) {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set(
        {'fcmToken': token},
        SetOptions(merge: true), // <- Merge with existing data
      );
      print('FCM token saved to Firestore');
    } else {
      print('No FCM token received');
    }
  } catch (e) {
    print('Failed to save FCM token: $e');
  }
}
