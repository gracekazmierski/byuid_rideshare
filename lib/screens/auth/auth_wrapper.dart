// lib/screens/auth/auth_wrapper.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:byui_rideshare/screens/rides/ride_list_screen.dart';
import 'package:byui_rideshare/screens/auth/welcome_screen.dart';
import 'package:byui_rideshare/services/save_fcm_token_on_login.dart';

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // Waiting for Firebase to resolve current user
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // Error with the auth stream
        if (snapshot.hasError) {
          return const Scaffold(
            body: Center(
              child: Text(
                'Something went wrong! Please restart the app.',
              ),
            ),
          );
        }

        // User is logged in
        if (snapshot.hasData) {
          final user = snapshot.data;

          // Safety: if user is null for some reason → force logout
          if (user == null) {
            FirebaseAuth.instance.signOut();
            return const WelcomeScreen();
          }

          // Save FCM token
          saveFcmTokenToUser();

          return const RideListScreen();
        }

        // No user logged in → always show Welcome/Login screen
        return const WelcomeScreen();
      },
    );
  }
}
