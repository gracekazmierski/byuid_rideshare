// lib/screens/rides/my_rides_screen.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:byui_rideshare/models/ride.dart'; // Assuming you have a Ride model
import 'package:byui_rideshare/services/ride_service.dart';
import 'package:byui_rideshare/screens/rides/ride_detail_screen.dart'; // Import RideDetailScreen

class MyRidesScreen extends StatelessWidget {
  const MyRidesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      // Should not happen if navigation is handled correctly, but good for safety
      return Scaffold(
        appBar: AppBar(title: const Text('My Rides')),
        body: const Center(child: Text('Please log in to see your rides.')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Posted Rides'),
      ),
      body: StreamBuilder<List<Ride>>(
        stream: RideService.fetchDriverRideListings(currentUser.uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('You have not posted any rides yet.'));
          }

          final rides = snapshot.data!;

          return ListView.builder(
            itemCount: rides.length,
            itemBuilder: (context, index) {
              final ride = rides[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  title: Text('${ride.origin} to ${ride.destination}'),
                  subtitle: Text('Seats Available: ${ride.availableSeats}'), // Adjust based on your Ride model
                  isThreeLine: true,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => RideDetailScreen(ride: ride), // Pass the ride object
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}