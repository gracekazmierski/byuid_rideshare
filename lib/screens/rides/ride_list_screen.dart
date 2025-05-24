// lib/screens/rides/ride_list_screen.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart'; // For the sign-out button
import 'package:byui_rideshare/services/ride_service.dart'; // To fetch rides
import 'package:byui_rideshare/models/ride.dart'; // To use the Ride model
import 'package:intl/intl.dart'; // Used for date and time formatting

// NOTE: You'll need to add the 'intl' package to your pubspec.yaml
// In your pubspec.yaml, under dependencies:
// dependencies:
//   flutter:
//     sdk: flutter
//   intl: ^0.18.0 # Add this line

class RideListScreen extends StatefulWidget {
  const RideListScreen({super.key});

  @override
  State<RideListScreen> createState() => _RideListScreenState();
}

class _RideListScreenState extends State<RideListScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('BYU-I Rideshare Bulletin Board'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Sign Out',
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              // The AuthWrapper will automatically navigate to the login/welcome screen
              // because the user's authentication state will change to null.
            },
          ),
        ],
      ),
      // StreamBuilder listens to the stream of rides from Firebase
      body: StreamBuilder<List<Ride>>(
        stream: RideService.fetchRideListings(),
        builder: (context, snapshot) {
          // --- Loading State ---
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          // --- Error State ---
          if (snapshot.hasError) {
            print('Error fetching rides: ${snapshot.error}'); // For debugging
            return Center(child: Text('Error: ${snapshot.error}\nPlease try again later.'));
          }
          // --- No Data State ---
          // Check if data is null or empty. This happens if there are no documents in the 'rides' collection.
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.directions_car_filled, size: 60, color: Colors.grey),
                  SizedBox(height: 10),
                  Text(
                    'No rides available yet.',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                  Text('Be the first to offer a ride!', style: TextStyle(color: Colors.grey)),
                ],
              ),
            );
          }

          // --- Data Available State ---
          final rides = snapshot.data!; // The list of Ride objects

          return ListView.builder(
            padding: const EdgeInsets.all(8.0),
            itemCount: rides.length,
            itemBuilder: (context, index) {
              final ride = rides[index];
              // Format Timestamp to readable date and time strings
              final DateFormat dateFormat = DateFormat('MMM d, yyyy');
              final DateFormat timeFormat = DateFormat('h:mm a');
              final DateTime rideDateTime = ride.rideDate.toDate(); // Convert Timestamp to DateTime

              return Card(
                margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
                elevation: 4.0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0)),
                child: InkWell( // Makes the card tappable
                  onTap: () {
                    // TODO: Implement "View Details" navigation (e.g., to a RideDetailsScreen)
                    print('Tapped on ride from ${ride.origin} to ${ride.destination}');
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${ride.origin} to ${ride.destination}',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.deepPurple,
                          ),
                        ),
                        const Divider(height: 16, thickness: 1),
                        Row(
                          children: [
                            const Icon(Icons.calendar_today, size: 16, color: Colors.grey),
                            const SizedBox(width: 5),
                            Text('Date: ${dateFormat.format(rideDateTime)}'),
                            const SizedBox(width: 20),
                            const Icon(Icons.access_time, size: 16, color: Colors.grey),
                            const SizedBox(width: 5),
                            Text('Time: ${timeFormat.format(rideDateTime)}'),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(Icons.event_seat, size: 16, color: Colors.grey),
                            const SizedBox(width: 5),
                            Text('Seats: ${ride.availableSeats}'),
                            const SizedBox(width: 20),
                            const Icon(Icons.attach_money, size: 16, color: Colors.grey),
                            const SizedBox(width: 5),
                            Text('Fare: \$${ride.fare?.toStringAsFixed(2) ?? '0.00'}'),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(Icons.person, size: 16, color: Colors.grey),
                            const SizedBox(width: 5),
                            Text('Driver: ${ride.driverName}'),
                          ],
                        ),
                        const SizedBox(height: 10),
                        // You can add a button for "View Details" if the whole card isn't tappable
                        // Align(
                        //   alignment: Alignment.bottomRight,
                        //   child: ElevatedButton(
                        //     onPressed: () {
                        //       print('View details for ride from ${ride.driverName}');
                        //     },
                        //     child: const Text('View Details'),
                        //   ),
                        // ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
      // Floating Action Button to add new rides (Logan's task)
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          // TODO: Navigate to CreateRideScreen (Logan's task)
          print('Navigate to create ride screen');
          // Example: Navigator.push(context, MaterialPageRoute(builder: (context) => const CreateRideScreen()));
        },
        label: const Text('Offer a Ride'),
        icon: const Icon(Icons.add),
      ),
    );
  }
}