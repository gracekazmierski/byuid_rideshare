// lib/screens/auth/auth_wrapper.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:byui_rideshare/screens/rides/ride_list_screen.dart';
import 'package:byui_rideshare/screens/auth/welcome_screen.dart'; // Or your login screen

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    // This stream listens for authentication changes (login, logout)
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {

        // State 1: Waiting for Firebase to check for a saved user
        // While it's checking, we show a loading spinner.
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        // State 2: An error occurred with the auth stream
        if (snapshot.hasError) {
          return const Scaffold(
            body: Center(
              child: Text('Something went wrong! Please restart the app.'),
            ),
          );
        }

        // State 3: We have data, meaning the user IS logged in
        if (snapshot.hasData) {
          // If snapshot.data is not null, a user is signed in.
          // Show the main part of your app.
          return const RideListScreen();
        }

        // State 4: We have no data, meaning the user is NOT logged in
        else {
          // If snapshot.data is null, no user is signed in.
          // Show the welcome/login screen.
          return const WelcomeScreen();
        }
      },
    );
  }
}