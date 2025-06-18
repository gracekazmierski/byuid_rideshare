import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:byui_rideshare/models/ride_request.dart';
import 'package:byui_rideshare/services/ride_service.dart';

class MyRequestsScreen extends StatelessWidget {
  const MyRequestsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      return const Center(child: Text('You must be logged in to view ride requests.'));
    }

    return Scaffold(
      appBar: AppBar(title: const Text('My Ride Requests')),
      body: StreamBuilder<List<RideRequest>>(
        stream: RideService.fetchRequestsByRider(currentUser.uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No pending ride requests.'));
          }

          final requests = snapshot.data!;

          return ListView.builder(
            itemCount: requests.length,
            itemBuilder: (context, index) {
              final request = requests[index];
              return ListTile(
                title: Text('Ride ID: ${request.rideId}'),
                subtitle: Text(request.message ?? 'No message'),
              );
            },
          );
        },
      ),
    );
  }
}
