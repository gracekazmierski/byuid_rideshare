import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:byui_rideshare/models/ride.dart';
import 'package:byui_rideshare/services/ride_service.dart';
import 'package:intl/intl.dart';
import 'package:byui_rideshare/screens/rides/create_ride_screen.dart';
import 'package:byui_rideshare/screens/rides/ride_detail_screen.dart'; // Import the new detail screen
import 'package:byui_rideshare/services/ride_service.dart';

class MyJoinedRidesScreen extends StatefulWidget {
  const MyJoinedRidesScreen({super.key});

  @override
  State<MyJoinedRidesScreen> createState() => _MyJoinedRidesScreenState();
}

class _MyJoinedRidesScreenState extends State<MyJoinedRidesScreen> {
  String? uid;

  @override
  void initState() {
    super.initState();
    User? user = FirebaseAuth.instance.currentUser;
    setState(() {
      uid = user?.uid;
    });
  }
  @override
  Widget build(BuildContext context) {
    if (uid == null) {
      // still loading user info
      return const Center(child: CircularProgressIndicator());
    }
    return Scaffold(
      appBar: AppBar(
        title: const Text("My Joined Rides")
      ),
      body: StreamBuilder<List<Ride>>(
        stream: RideService.fetchJoinedRideListings(uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('You have not joined any rides yet, return to the homepage to explore available rides!'));
          }

          final rides = snapshot.data!;

          return ListView.builder(
            padding: const EdgeInsets.all(8.0),
            itemCount: rides.length,
            itemBuilder: (context, index) {
              final ride = rides[index];
              final bool isRideFull = ride.isFull || ride.availableSeats <= 0; // Check if full

              return Card(
                margin: const EdgeInsets.symmetric(vertical: 8.0),
                child: InkWell( // Make the card tappable
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => RideDetailScreen(ride: ride), // Navigate to detail screen
                      ),
                    );
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                '${ride.origin} to ${ride.destination}',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            if (isRideFull) // Display "FULL" tag if applicable
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.red,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Text(
                                  'FULL',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Date: ${DateFormat('EEE, MMM d,yyyy').format(ride.rideDate.toDate())}',
                          style: const TextStyle(fontSize: 14),
                        ),
                        Text(
                          'Time: ${DateFormat('h:mm a').format(ride.rideDate.toDate())}',
                          style: const TextStyle(fontSize: 14),
                        ),
                        Text(
                          'Available Seats: ${ride.availableSeats}',
                          style: const TextStyle(fontSize: 14),
                        ),
                        Text(
                          'Fare: \$${ride.fare?.toStringAsFixed(2) ?? 'N/A'}',
                          style: const TextStyle(fontSize: 14),
                        ),
                        Text(
                          'Driver: ${ride.driverName}',
                          style: const TextStyle(fontSize: 14, fontStyle: FontStyle.italic),
                        ),
                        Text(
                          'Posted: ${DateFormat('MMM d, h:mm a').format(ride.postCreationTime.toDate())}',
                          style: const TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}