import 'package:byui_rideshare/services/notification_service.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Keep if you use FirebaseAuth directly in main, otherwise optional
import 'package:byui_rideshare/services/firebase_options.dart';

// --- Project-Specific Imports (for screens) ---
import 'package:byui_rideshare/screens/auth/auth_wrapper.dart'; // Handles auth redirection
import 'package:byui_rideshare/screens/auth/login_page.dart'; // Your actual email/password login form
import 'package:byui_rideshare/screens/rides/ride_list_screen.dart'; // Screen for logged-in users
import 'package:byui_rideshare/screens/auth/create_account_page.dart';


// Ensure Firebase is initialized before running the app
void main() async {
  WidgetsFlutterBinding.ensureInitialized(); // Required for Firebase initialization

  // try {
  //   await Firebase.initializeApp(
  //     options: DefaultFirebaseOptions.currentPlatform,
  //   );

  //   // Initialize push notifications
  //   // await NotificationService.instance.initialize();

  //   runApp(const MyApp());
  // } catch (e, stack) {
  //   // Log if something crashes
  //   debugPrint('Firebase init failed: $e');
  //   debugPrint('$stack');
  // }

  // Initialize Firebase with platform-specific options
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Initialize with Notification click
  await NotificationService.instance.initialize();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BYUI Rideshare',
      theme: ThemeData(
        primarySwatch: Colors.blue, // You can customize your app's main theme colors here
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),

      // The home property points to AuthWrapper, which decides the initial screen
      home: const AuthWrapper(),

      // Define named routes for navigation within your app
      routes: {
        '/login': (context) => const LoginPage(), // Route to your actual login form
        '/create_account': (context) => const CreateAccountPage(),
        '/ride_list': (context) => const RideListScreen(), // Route for logged-in users
      },
    );
  }
}

// The MyHomePage class (your welcome screen UI) has been removed from here.
// It should now reside solely in 'lib/screens/welcome_screen.dart'.