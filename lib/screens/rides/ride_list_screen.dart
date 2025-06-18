// lib/screens/rides/ride_list_screen.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:byui_rideshare/models/ride.dart';
import 'package:byui_rideshare/services/ride_service.dart';
import 'package:intl/intl.dart';
import 'package:byui_rideshare/screens/rides/create_ride_screen.dart';

import 'package:byui_rideshare/screens/rides/ride_detail_screen.dart';
import 'package:byui_rideshare/screens/rides/my_rides_screen.dart';
import 'package:byui_rideshare/screens/rides/ride_detail_screen.dart'; // Import the new detail screen
import 'package:byui_rideshare/screens/rides/my_joined_rides_screen.dart';


class RideListScreen extends StatefulWidget {
  const RideListScreen({super.key});

  @override
  State<RideListScreen> createState() => _RideListScreenState();
}

class _RideListScreenState extends State<RideListScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    // Listen to changes in the search bar and update the search query state
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.trim();
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose(); // Clean up the controller
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
          title: const Text('BYU-I Rideshare Bulletin Board'),
          actions: [
            if (currentUser != null)
              IconButton(
                icon: const Icon(Icons.directions_car_filled_outlined), // Choose an appropriate icon
                tooltip: 'My Posted Rides',
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const MyRidesScreen()),
                  );
                },
              ),

            TextButton(
              onPressed: () {
                Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => MyJoinedRidesScreen())
                );
              },
              child: Text(
                'My Joined Rides',
                style: TextStyle(
                    fontSize: 20,
                    color: Colors.black
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: () async {
                await FirebaseAuth.instance.signOut();
              },
            ),
          ],
          bottom: PreferredSize(
              preferredSize: const Size.fromHeight(56),
              child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'Search by origin or destination...',
                        prefixIcon: const Icon(Icons.search),
                        suffixIcon: _searchQuery.isNotEmpty
                            ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchController.clear();
                          },
                        )
                            : null,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        filled: true,
                        fillColor: Colors.white,

                      )
                  )
              )
          )
      ),
      body: StreamBuilder<List<Ride>>(
        stream: RideService.fetchRideListings(searchQuery: _searchQuery),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Text('No rides available. Be the first to post one!'),
            );
          }

          final rides = snapshot.data!;

          return ListView.builder(
            padding: const EdgeInsets.all(8.0),
            itemCount: rides.length,
            itemBuilder: (context, index) {
              final ride = rides[index];
              final bool isRideFull =
                  ride.isFull || ride.availableSeats <= 0; // Check if full

              return Card(
                margin: const EdgeInsets.symmetric(vertical: 8.0),
                child: InkWell(
                  // Make the card tappable
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder:
                            (context) => RideDetailScreen(
                          ride: ride,
                        ), // Navigate to detail screen
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
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
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
                          style: const TextStyle(
                            fontSize: 14,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                        Text(
                          'Posted: ${DateFormat('MMM d, h:mm a').format(ride.postCreationTime.toDate())}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
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
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const CreateRideScreen()),
          );
        },
        label: const Text('Offer a Ride'),
        icon: const Icon(Icons.add),
      ),
    );
  }
}