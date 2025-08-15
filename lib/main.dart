// lib/main.dart
import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'services/firebase_options.dart';
import 'services/notification_service.dart';

// Screens
import 'screens/auth/auth_wrapper.dart';
import 'screens/auth/login_page.dart';
import 'screens/auth/create_account_page.dart';
import 'screens/rides/ride_list_screen.dart';
import 'screens/auth/byui_verify_screen.dart';
import 'screens/auth/profile_edit_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // -------------------------------
  // Firebase App Check (per platform)
  // -------------------------------
  try {
    if (kIsWeb) {
      // const siteKey = '6LfdYqArAAAAAKvb3MgYHyBI0RDoBQKxkZlTKH3j';
      // await FirebaseAppCheck.instance.activate(
      //   webProvider: ReCaptchaV3Provider(siteKey),
      // );
      await FirebaseAppCheck.instance.setTokenAutoRefreshEnabled(true);
    } else if (Platform.isAndroid) {
      // Use Play Integrity in release, Debug provider in dev
      await FirebaseAppCheck.instance.activate(
        androidProvider: kReleaseMode
            ? AndroidProvider.playIntegrity
            : AndroidProvider.debug,
      );
      await FirebaseAppCheck.instance.setTokenAutoRefreshEnabled(true);
    } else if (Platform.isIOS) {
      // Use App Attest in release, Debug provider in dev
      // (App Attest works only on real devices, not simulators)
      await FirebaseAppCheck.instance.activate(
        appleProvider: kReleaseMode
            ? AppleProvider.appAttest
            : AppleProvider.debug,
      );
      await FirebaseAppCheck.instance.setTokenAutoRefreshEnabled(true);
    } else {
      // Other desktop platforms (dev only)
      await FirebaseAppCheck.instance.activate();
    }
  } catch (e) {
    debugPrint('App Check init failed (continuing): $e');
  }

  // Show the UI right away
  runApp(const MyApp());

  // Post-launch init (don’t block first frame)
  WidgetsBinding.instance.addPostFrameCallback((_) async {
    await _postLaunchInit();
  });
}

Future<void> _postLaunchInit() async {
  try {
    // Local notifications
    await NotificationService.instance
        .initialize()
        .timeout(const Duration(seconds: 5), onTimeout: () => null);

    // Push (skip on web)
    if (!kIsWeb) {
      await FirebaseMessaging.instance.requestPermission();

      final token = await FirebaseMessaging.instance
          .getToken()
          .timeout(const Duration(seconds: 7), onTimeout: () => null);

      if (token != null) {
        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .set({'fcmToken': token}, SetOptions(merge: true));
          debugPrint('FCM token saved to Firestore');
        }
      } else {
        debugPrint('FCM token not available yet.');
      }

      FirebaseMessaging.instance.onTokenRefresh.listen((t) async {
        final u = FirebaseAuth.instance.currentUser;
        if (u != null) {
          await FirebaseFirestore.instance
              .collection('users')
              .doc(u.uid)
              .set({'fcmToken': t}, SetOptions(merge: true));
          debugPrint('FCM token updated after refresh');
        }
      });
    }
  } catch (e) {
    debugPrint('Post-launch init error: $e');
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BYUI Rideshare',
      debugShowCheckedModeBanner: false,

      // Use routes so Flutter Web honors hash URLs on cold start (e.g. #/byui-verify)
      initialRoute: '/',
      routes: {
        '/': (context) => const AuthWrapper(),
        '/login': (context) => const LoginPage(),
        '/create_account': (context) => const CreateAccountPage(),
        '/ride_list': (context) => const RideListScreen(),
        ByuiVerifyScreen.routeName: (context) => const ByuiVerifyScreen(),
        ProfileEditScreen.routeName: (context) => const ProfileEditScreen(),
      },

      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
    );
  }
}
