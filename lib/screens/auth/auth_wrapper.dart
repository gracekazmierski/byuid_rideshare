// lib/screens/auth/auth_wrapper.dart

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Import Firebase Auth
import 'package:byui_rideshare/screens/rides/ride_list_screen.dart'; // Import the screen for logged-in users
import 'package:byui_rideshare/screens/auth/welcome_screen.dart'; // Import your WelcomeScreen

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Listen to the authentication state changes
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // If the connection is active and data is available (user logged in/out status)
        if (snapshot.connectionState == ConnectionState.active) {
          final user = snapshot.data; // Get the current user (null if logged out)

          if (user == null) {
            // User is logged out, show the WelcomeScreen
            return const WelcomeScreen(); // Directs to your consolidated WelcomeScreen
          } else {
            // User is logged in, show the RideListScreen
            return const RideListScreen();
          }
        }

        // While waiting for the authentication state, show a loading indicator
        return const Scaffold(
          body: Center(
            child: CircularProgressIndicator(),
          ),
        );
      },
    );
  }
}