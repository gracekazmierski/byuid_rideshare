// lib/screens/rides/my_rides_screen.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:byui_rideshare/models/ride.dart';
import 'package:byui_rideshare/services/ride_service.dart';
import 'package:byui_rideshare/screens/rides/ride_detail_screen.dart';
import 'package:byui_rideshare/screens/rides/create_ride_screen.dart'; // For empty state button
import 'package:byui_rideshare/theme/app_colors.dart'; // Use AppColors
import 'package:intl/intl.dart'; // For date formatting in the ride card
import 'package:byui_rideshare/services/user_service.dart'; // For driver name in ride card

class MyRidesScreen extends StatelessWidget {
  const MyRidesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('My Rides')),
        body: const Center(child: Text('Please log in to see your rides.')),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.gray50,
      body: Column(
        children: [
          // Header
          Container(
            width: double.infinity,
            color: AppColors.byuiBlue,
            padding: const EdgeInsets.fromLTRB(16.0, 60.0, 16.0, 24.0),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () => Navigator.of(context).pop(),
                ),
                const SizedBox(width: 8),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('My Posted Rides', style: TextStyle(color: Colors.white, fontSize: 24.0, fontWeight: FontWeight.w600)),
                    SizedBox(height: 4.0),
                    Text("Manage the rides you're driving", style: TextStyle(color: AppColors.blue100, fontSize: 14.0)),
                  ],
                ),
              ],
            ),
          ),
          // Body
          Expanded(
            child: StreamBuilder<List<Ride>>(
              stream: RideService.fetchDriverRideListings(currentUser.uid),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  // Use the new, improved empty state widget
                  return _buildEmptyState(context);
                }

                final rides = snapshot.data!;

                return ListView.builder(
                  padding: const EdgeInsets.all(16.0),
                  itemCount: rides.length,
                  itemBuilder: (context, index) {
                    final ride = rides[index];
                    // Reuse the consistent ride card widget
                    return _buildRideCard(context, ride);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // A new, more engaging widget for when the user has no posted rides.
  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // FIX 1: Replaced the invalid icon with a valid one.
            const Icon(Icons.directions_car, size: 80, color: AppColors.textGray500),
            const SizedBox(height: 20),
            const Text(
              'No Rides Posted Yet',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.textGray600),
            ),
            const SizedBox(height: 8),
            const Text(
              "Ready to hit the road? Offer a ride to start sharing your journey.",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: AppColors.textGray500),
            ),
            const SizedBox(height: 24),

            // FIX 2: Removed 'const' from ElevatedButton because onPressed is not constant.
            ElevatedButton.icon(
              icon: const Icon(Icons.add),
              label: const Text('Offer a Ride'),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const CreateRideScreen()),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.byuiBlue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
              ),
            )
          ],
        ),
      ),
    );
  }

  // Copied directly from ride_list_screen.dart for visual consistency.
  Widget _buildRideCard(BuildContext context, Ride ride) {
    final bool isRideFull = ride.isFull || ride.availableSeats <= 0;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => RideDetailScreen(ride: ride),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Container(
                      width: 8, height: 8,
                      decoration: BoxDecoration(color: AppColors.byuiGreen, borderRadius: BorderRadius.circular(4)),
                      margin: const EdgeInsets.only(right: 8),
                    ),
                    Text(ride.origin, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.gray700)),
                  ]),
                  const SizedBox(height: 4),
                  Row(children: [
                    Container(
                      width: 8, height: 8,
                      decoration: BoxDecoration(color: AppColors.red500, borderRadius: BorderRadius.circular(4)),
                      margin: const EdgeInsets.only(right: 8),
                    ),
                    Text(ride.destination, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.gray700)),
                  ]),
                ],
              ),
              const SizedBox(height: 12),
              Row(children: [
                const Icon(Icons.calendar_today, size: 16, color: AppColors.textGray500),
                const SizedBox(width: 8),
                Text('${DateFormat('MMM d hh:mm a').format(ride.rideDate.toDate())}', style: const TextStyle(fontSize: 14, color: AppColors.textGray500)),
              ]),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(children: [
                    const Icon(Icons.group, size: 16, color: AppColors.byuiBlue),
                    const SizedBox(width: 8),
                    Text('${ride.availableSeats} seat${ride.availableSeats != 1 ? "s" : ""} available', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.byuiBlue)),
                  ]),
                  // Since this screen ONLY shows rides driven by the current user,
                  // we can just show their name directly instead of another database call.
                  Row(children: [
                    const CircleAvatar(radius: 12, backgroundColor: Color(0xFFe6f1fa), child: Icon(Icons.person, size: 14, color: AppColors.byuiBlue)),
                    const SizedBox(width: 4),
                    Text(ride.driverName, style: const TextStyle(fontSize: 12, color: AppColors.textGray500)),
                  ]),
                ],
              ),
              if (isRideFull)
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Align(
                    alignment: Alignment.bottomRight,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(color: AppColors.red500, borderRadius: BorderRadius.circular(4)),
                      child: const Text('FULL', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}