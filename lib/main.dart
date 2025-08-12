import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import 'package:byui_rideshare/services/firebase_options.dart';
import 'package:byui_rideshare/services/notification_service.dart';
import 'package:byui_rideshare/services/user_service.dart';

// Screens
import 'package:byui_rideshare/screens/auth/auth_wrapper.dart';
import 'package:byui_rideshare/screens/auth/login_page.dart';
import 'package:byui_rideshare/screens/auth/create_account_page.dart';
import 'package:byui_rideshare/screens/rides/ride_list_screen.dart';
import 'package:byui_rideshare/screens/auth/byui_verify_screen.dart';
import 'package:byui_rideshare/screens/auth/profile_edit_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // FCM permissions + listeners
  await FirebaseMessaging.instance.requestPermission();
  UserService.listenForTokenRefresh();
  await NotificationService.instance.initialize();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BYUI Rideshare',
      debugShowCheckedModeBanner: false,

      // ❗ IMPORTANT: Do NOT set `home:`. Using routes allows Flutter web
      // to honor the hash URL (e.g. #/byui-verify) on cold start.
      initialRoute: '/',

      routes: {
        '/': (context) => const AuthWrapper(),
        '/login': (context) => const LoginPage(),
        '/create_account': (context) => const CreateAccountPage(),
        '/ride_list': (context) => const RideListScreen(),

        // Needed for verification bounce + profile navigation by routeName
        ByuiVerifyScreen.routeName: (context) => const ByuiVerifyScreen(),
        ProfileEditScreen.routeName: (context) => const ProfileEditScreen(),
      },

      theme: ThemeData(
        visualDensity: VisualDensity.adaptivePlatformDensity,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
    );
  }
}
