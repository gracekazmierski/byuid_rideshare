// lib/screens/rides/join_request_confirmation_screen.dart

import 'package:byui_rideshare/models/posted_request.dart';
import 'package:byui_rideshare/screens/rides/ride_list_screen.dart';
import 'package:byui_rideshare/theme/app_colors.dart';
import 'package:flutter/material.dart';

class JoinRequestConfirmationScreen extends StatelessWidget {
  final PostedRequest request;

  const JoinRequestConfirmationScreen({super.key, required this.request});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.gray50,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.check_circle_outline_rounded,
                color: AppColors.byuiGreen,
                size: 100,
              ),
              const SizedBox(height: 24),
              const Text(
                'You Have Joined the Request!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textGray800,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                "The driver will be notified of the updated rider count. You can see this in 'My Joined Rides'.",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: AppColors.textGray600),
              ),
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: () {
                    // Navigate back to the main screen and clear all previous routes
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const RideListScreen(),
                      ),
                      (route) => false,
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.byuiBlue,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Back to Ride Board'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
