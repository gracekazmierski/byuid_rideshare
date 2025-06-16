// lib/screens/auth/auth_wrapper.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:byui_rideshare/screens/rides/ride_list_screen.dart'; // Grace's screen
import 'package:byui_rideshare/main.dart'; // To access MyHomePage if desired

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    // StreamBuilder listens to authentication state changes
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // Show a loading indicator while checking auth state
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        // If there's an error with the stream
        if (snapshot.hasError) {
          return const Scaffold(
            body: Center(child: Text('Error checking authentication state.')),
          );
        }

        final User? user = snapshot.data; // The current authenticated user

        if (user != null) {
          return const RideListScreen();
        } else {
          // User is NOT logged in
          // You can decide whether to show the LoginPage directly or your MyHomePage welcome.
          // For simplicity, let's direct to the welcome page which links to login.
          return const MyHomePage(title: 'BYU-I Rideshare');
        }
      },
    );
  }
}
