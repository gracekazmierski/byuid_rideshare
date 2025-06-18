// lib/screens/rides/ride_list_screen.dart
// import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:byui_rideshare/models/ride.dart';
import 'package:byui_rideshare/services/ride_service.dart';
import 'package:intl/intl.dart';
import 'package:byui_rideshare/screens/rides/create_ride_screen.dart';
import 'package:byui_rideshare/screens/rides/ride_detail_screen.dart'; // Import the new detail screen
import 'package:byui_rideshare/models/notification_item.dart'; // notifications
import 'package:byui_rideshare/services/notification_service.dart'; // notifications

class RideListScreen extends StatefulWidget {
  const RideListScreen({super.key});

  @override
  State<RideListScreen> createState() => _RideListScreenState();
}

class _RideListScreenState extends State<RideListScreen> {
  User? _currentUser;

  @override
  void initState() {
    super.initState();
    _currentUser = FirebaseAuth.instance.currentUser;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('BYU-I Rideshare Bulletin Board'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            StreamBuilder<List<Ride>>(
              stream: RideService.fetchRideListings(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: Text('No rides available. Be the first to post one!'));
                }

                final rides = snapshot.data!;

                return ListView.builder(
                  physics: const NeverScrollableScrollPhysics(), // disable inner scroll
                  shrinkWrap: true, // let it size based on content
                  padding: const EdgeInsets.all(8.0),
                  itemCount: rides.length,
                  itemBuilder: (context, index) {
                    final ride = rides[index];
                    final bool isRideFull = ride.isFull || ride.availableSeats <= 0;

                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 8.0),
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
                                  if (isRideFull)
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
                              Text('Date: ${DateFormat('EEE, MMM d, yyyy').format(ride.rideDate.toDate())}'),
                              Text('Time: ${DateFormat('h:mm a').format(ride.rideDate.toDate())}'),
                              Text('Available Seats: ${ride.availableSeats}'),
                              Text('Fare: \$${ride.fare?.toStringAsFixed(2) ?? 'N/A'}'),
                              Text('Driver: ${ride.driverName}'),
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
            const SizedBox(height: 20),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0),
              child: Text(
                'Notifications:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
            SizedBox(
              height: 200,
              child: StreamBuilder<List<NotificationItem>>(
                stream: NotificationService.fetchNotifications(_currentUser?.uid ?? ''),
                builder: (context, notifSnapshot) {
                  if (notifSnapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  } else if (notifSnapshot.hasError) {
                    return Center(child: Text('Error loading notifications: ${notifSnapshot.error}'));
                  } else if (!notifSnapshot.hasData || notifSnapshot.data!.isEmpty) {
                    return const Center(child: Text('No notifications.'));
                  }

                  final notifications = notifSnapshot.data!;
                  return ListView.builder(
                    itemCount: notifications.length,
                    itemBuilder: (context, index) {
                      final notification = notifications[index];
                      return ListTile(
                        title: Text(notification.title),
                        subtitle: Text(notification.body),
                        trailing: Text(
                          DateFormat('MMM d, h:mm a').format(notification.timestamp.toDate()),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),

      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(context, MaterialPageRoute(builder: (context) => const CreateRideScreen()));
        },
        label: const Text('Offer a Ride'),
        icon: const Icon(Icons.add),
      ),
    );
  }
}