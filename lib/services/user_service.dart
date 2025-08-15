import 'dart:async';
import 'dart:typed_data';
import 'dart:io' show File;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart' show kIsWeb, debugPrint; // <-- bring in debugPrint
import 'package:image/image.dart' as img;

import '../models/user_profile.dart';

class UserService {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;
  static final CollectionReference usersCollection = _db.collection('users');

  static Future<void> saveUserProfile(UserProfile profile) async {
    final data = profile.toFirestore();
    if (!kIsWeb) {
      final token = await FirebaseMessaging.instance.getToken();
      if (token != null) data['fcmToken'] = token;
    }
    await usersCollection.doc(profile.uid).set(data, SetOptions(merge: true));
  }

  static void listenForTokenRefresh() {
    if (kIsWeb) return;
    FirebaseMessaging.instance.onTokenRefresh.listen((newToken) async {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await usersCollection
            .doc(user.uid)
            .set({'fcmToken': newToken}, SetOptions(merge: true));
      }
    });
  }

  static Future<UserProfile?> fetchUserProfile(String uid) async {
    final snap = await usersCollection.doc(uid).get();
    if (!snap.exists) return null;
    return UserProfile.fromFirestore(snap.data()! as Map<String, dynamic>);
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

  static Future<String?> getUserName(String uid) async {
    final p = await fetchUserProfile(uid);
    if (p == null) return 'Unknown Driver';
    final first = p.firstName ?? '';
    final last = p.lastName ?? '';
    if (first.isEmpty && last.isEmpty) return 'Unknown Driver';
    return last.isEmpty ? first : '$first $last';
  }

  // ---------- Image compression ----------
  Future<Uint8List> _compressImageBytes(Uint8List input) async {
    try {
      final decoded = img.decodeImage(input);
      if (decoded == null) return input;

      // Smaller + lower quality for faster uploads
      const maxSide = 800;
      final w = decoded.width, h = decoded.height;
      img.Image out = decoded;
      if (w > maxSide || h > maxSide) {
        out = img.copyResize(
          decoded,
          width: w >= h ? maxSide : null,
          height: h > w ? maxSide : null,
          interpolation: img.Interpolation.average, // keep your current choice
        );
      }
      final jpg = img.encodeJpg(out, quality: 70);
      return Uint8List.fromList(jpg);
    } catch (_) {
      return input;
    }
  }

  // ---------- High-level (kept for backwards compatibility) ----------
  Future<String> uploadProfilePictureFromBytes(
      String uid,
      Uint8List bytes, {
        void Function(double progress)? onProgress,
      }) async {
    final task = await startUploadProfilePictureFromBytes(uid, bytes);

    StreamSubscription<TaskSnapshot>? sub;
    if (onProgress != null) {
      sub = task.snapshotEvents.listen((s) {
        final total = s.totalBytes;
        if (total <= 0) {
          onProgress(0);
        } else {
          onProgress(s.bytesTransferred / total);
        }
      });
    }

    try {
      final snap = await task;
      onProgress?.call(1.0);
      return await snap.ref.getDownloadURL();
    } finally {
      await sub?.cancel();
    }
  }

  Future<String> uploadProfilePicture(
      String uid,
      File file, {
        void Function(double progress)? onProgress,
      }) async {
    final bytes = await file.readAsBytes();
    return uploadProfilePictureFromBytes(uid, bytes, onProgress: onProgress);
  }

  Future<UploadTask> startUploadProfilePictureFromBytes(
      String uid, Uint8List bytes) async {
    // Skip compression on web to avoid blocking the main thread
    final data = kIsWeb ? bytes : await _compressImageBytes(bytes);

    final ref = FirebaseStorage.instance.ref().child('profile_pictures/$uid.jpg');

    final meta = SettableMetadata(
      contentType: 'image/jpeg',
      cacheControl: 'public,max-age=3600',
    );

    final task = ref.putData(data, meta);

    // Progress logs
    task.snapshotEvents.listen(
          (s) => debugPrint('Storage: ${s.state}  ${s.bytesTransferred}/${s.totalBytes}'),
      onError: (e) => debugPrint('Storage error: $e'),
    );

    // Watchdog: cancel if literally no bytes after 10s
    bool started = false;
    task.snapshotEvents.listen((s) {
      if (s.bytesTransferred > 0) started = true;
    });
    Timer(const Duration(seconds: 10), () {
      if (!started) {
        task.cancel();
        debugPrint('Upload watchdog: no progress after 10s, canceled.');
      }
    });

    return task;
  }
}
