// lib/screens/rides/ride_list_screen.dart
import 'package:byui_rideshare/screens/auth/profile_edit_screen.dart';
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
bool _showFullRides = true;
SortOption _selectedSort = SortOption.soonest;
DateTime? _startDate;
DateTime? _endDate;
enum SortOption{ soonest, latest, lowestFare, highestFare }


class RideListScreen extends StatefulWidget {
  const RideListScreen({super.key});

  @override
  State<RideListScreen> createState() => _RideListScreenState();
}

class _RideListScreenState extends State<RideListScreen> {
  final TextEditingController _fromController = TextEditingController();
  final TextEditingController _toController =  TextEditingController();
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
          title: const Text('BYU-I Rideshare Bulletin Board'),
          actions: [
            if (currentUser != null)
              IconButton(
                icon: const Icon(Icons.account_circle),
                tooltip: "Edit Profile",
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const ProfileEditScreen()),
                  );
                }
              ),
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
            IconButton(
              icon: const Icon(Icons.event_seat),
              tooltip: "My Joined Rides",
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const MyJoinedRidesScreen())
                );
            }),
            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: () async {
                await FirebaseAuth.instance.signOut();
              },
              child: const Text(
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
          preferredSize: const Size.fromHeight(100),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _fromController,
                        decoration: InputDecoration(
                          hintText: 'From',
                          prefixIcon: Icon(Icons.location_on),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          filled: true,
                          fillColor: Colors.white,
                        ),
                        onChanged: (_) => setState(() {}), // trigger ride stream update
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                        child: TextField(
                          controller: _toController,
                          decoration: InputDecoration(
                            hintText: 'To',
                            prefixIcon: Icon(Icons.location_on),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                            filled: true,
                            fillColor: Colors.white,
                          ),
                          onChanged: (_) => setState(() {}),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Checkbox(
                              value: _showFullRides,
                              onChanged: (val) {
                                setState(() {
                                  _showFullRides = val!;
                                });
                              },
                            ),
                            const Text('Show Full Rides'),
                          ],
                        ),
                        Row(
                          children: [
                            DropdownButton<SortOption>(
                              value: _selectedSort,
                              onChanged: (SortOption? newValue) {
                                if (newValue != null) {
                                  setState(() {
                                    _selectedSort = newValue;
                                  });
                                }
                              },
                              items: const [
                                DropdownMenuItem(
                                  value: SortOption.soonest,
                                  child: Text("Soonest First"),
                                ),
                                DropdownMenuItem(
                                  value: SortOption.latest,
                                  child: Text("Latest First"),
                                ),
                                DropdownMenuItem(
                                  value: SortOption.lowestFare,
                                  child: Text("Lowest Fare"),
                                ),
                                DropdownMenuItem(
                                  value: SortOption.highestFare,
                                  child: Text("Highest Fare"),
                                ),
                              ],
                            )
                          ],
                        ),
                        TextButton(
                          onPressed: () async {
                            final pickedStart = await showDatePicker(
                              context: context,
                              initialDate: DateTime.now(),
                              firstDate: DateTime(2024),
                              lastDate: DateTime(2030),
                            );
                            if (pickedStart != null) {
                              final pickedEnd = await showDatePicker(
                              context: context,
                              initialDate: pickedStart,
                              firstDate: pickedStart,
                              lastDate: DateTime(2030)
                              );
                              setState(() {
                                _startDate = pickedStart;
                                _endDate = pickedEnd;
                                });
                              }
                            },
                            child: const Text("Selet Date Range"),
                        )
                      ],
                    ),
                  ],
                ),

            ),
          ),
        ),

        body: StreamBuilder<List<Ride>>(
          stream: RideService.fetchRideListings(
            fromLocation: _fromController.text.trim(),
            toLocation: _toController.text.trim(),
            showFullRides: _showFullRides,
            startDate: _startDate,
            endDate: _endDate,
            sortOption: _selectedSort,
          ),
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