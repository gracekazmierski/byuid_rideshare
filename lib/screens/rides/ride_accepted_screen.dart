// lib/screens/rides/ride_accepted_screen.dart

import 'package:flutter/material.dart';

class RideAcceptedScreen extends StatelessWidget {
  final String rideId;

  const RideAcceptedScreen({super.key, required this.rideId});

  // Display a confirmation message
  // Provide a button to return to the main/home
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Ride Accepted')),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Your ride request was accepted!',
              style: TextStyle(fontSize: 18),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).popUntil((route) => route.isFirst);
              },
              child: Text('Go back to home'),
            ),
          ],
        ),
      ),
    );
  }
}
