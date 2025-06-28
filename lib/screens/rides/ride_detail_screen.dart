// lib/screens/rides/ride_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:byui_rideshare/models/ride.dart';
import 'package:byui_rideshare/models/ride_request.dart';
import 'package:byui_rideshare/services/ride_service.dart';
import 'package:byui_rideshare/services/user_service.dart';

class RideDetailScreen extends StatefulWidget {
  final Ride ride; // The initial ride object passed from RideListScreen

  const RideDetailScreen({super.key, required this.ride});

  @override
  State<RideDetailScreen> createState() => _RideDetailScreenState();
}

class _RideDetailScreenState extends State<RideDetailScreen> {
  User? _currentUser;
  bool _isJoining = false;

  @override
  void initState() {
    super.initState();
    _currentUser = FirebaseAuth.instance.currentUser;
  }

  void _joinRide() async {
    if (_currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You must be logged in to join a ride.')),
      );
      return;
    }

    setState(() {
      _isJoining = true;
    });

    try {
      await RideService.requestToJoinRide(
        widget.ride.id,
        _currentUser!.uid,
        "", // Optional: include message from a controller here
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ride request sent!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isJoining = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<Ride>(
      stream: RideService.getRideStream(widget.ride.id),
      builder: (context, snapshot) {
        Ride currentRide = widget.ride;

        if (snapshot.connectionState == ConnectionState.waiting) {
          // Show loading spinner
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          print('Error fetching ride stream: ${snapshot.error}');
        } else if (snapshot.hasData) {
          currentRide = snapshot.data!;
        }

        bool rideIsFull = currentRide.isFull || currentRide.availableSeats <= 0;
        bool hasJoined =
            _currentUser != null &&
                currentRide.joinedUserUids.contains(_currentUser!.uid);
        bool isDriver =
            _currentUser != null && currentRide.driverUid == _currentUser!.uid;

        return Scaffold(
          appBar: AppBar(title: const Text('Ride Details')),
          body: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${currentRide.origin} to ${currentRide.destination}',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                _buildDetailRow(
                  'Date:',
                  DateFormat(
                    'EEE, MMM d, yyyy',
                  ).format(currentRide.rideDate.toDate()),
                ),
                _buildDetailRow(
                  'Time:',
                  DateFormat('h:mm a').format(currentRide.rideDate.toDate()),
                ),
                _buildDetailRow(
                  'Available Seats:',
                  currentRide.availableSeats.toString(),
                ),
                _buildDetailRow(
                  'Fare:',
                  '\$${currentRide.fare?.toStringAsFixed(2) ?? 'N/A'}',
                ),
                FutureBuilder<String?>(
                  future: UserService.getUserName(currentRide.driverUid),
                  builder: (context, snapshot) {
                    String name = "Unknown Driver";
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      name = "Loading...";
                    } else if (snapshot.hasData && snapshot.data!.isNotEmpty) {
                      name = snapshot.data!;
                    }

                    return _buildDetailRow('Driver:', name);
                  },
                ),
                _buildDetailRow('Status:', rideIsFull ? 'Full' : 'Available'),

                if (hasJoined)
                  const Padding(
                    padding: EdgeInsets.only(top: 8.0),
                    child: Text(
                      'You have joined this ride.',
                      style: TextStyle(
                        fontStyle: FontStyle.italic,
                        color: Colors.blue,
                      ),
                    ),
                  ),

                if (isDriver) ...[
                  const Padding(
                    padding: EdgeInsets.only(top: 16.0),
                    child: Text(
                      'You are the driver of this ride.',
                      style: TextStyle(
                        fontStyle: FontStyle.italic,
                        color: Colors.purple,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Passengers:',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),

                  const SizedBox(height: 20),
                  const Text(
                    'Join Requests:',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),

                  StreamBuilder<List<RideRequest>>(
                    stream: RideService.fetchRequestsForRide(currentRide.id),
                    builder: (context, requestSnapshot) {
                      if (requestSnapshot.connectionState == ConnectionState.waiting) {
                        return const CircularProgressIndicator();
                      }
                      if (!requestSnapshot.hasData || requestSnapshot.data!.isEmpty) {
                        return const Text('No pending requests.');
                      }

                      final requests = requestSnapshot.data!;

                      return Column(
                        children: requests.map((request) {
                          return FutureBuilder<String?>(
                            future: RideService.getUserNameByUid(request.riderUid),
                            builder: (context, snapshot) {
                              if (snapshot.connectionState == ConnectionState.waiting) {
                                return const ListTile(
                                  title: Text('Rider: Loading...'),
                                );
                              }

                              final riderName = snapshot.data ?? 'Unknown Rider';

                              return ListTile(
                                title: Text('Rider: $riderName'),
                                subtitle: Text(request.message ?? 'No message'),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.check, color: Colors.green),
                                      onPressed: () async {
                                        await RideService.acceptRideRequest(
                                          request.id,
                                          currentRide.id,
                                          request.riderUid,
                                        );
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(content: Text('Request accepted.')),
                                        );
                                      },
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.close, color: Colors.red),
                                      onPressed: () async {
                                        await RideService.denyRideRequest(request.id);
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(content: Text('Request denied.')),
                                        );
                                      },
                                    ),
                                  ],
                                ),
                              );
                            },
                          );


                        }).toList(),
                      );
                    },
                  ),

                  ...currentRide.joinedUserUids.map(
                        (uid) => ListTile(
                      title: Text(uid),
                      trailing: IconButton(
                        icon: const Icon(
                          Icons.remove_circle,
                          color: Colors.red,
                        ),
                        onPressed: () async {
                          await RideService.removePassenger(
                            currentRide.id,
                            uid,
                          );
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Passenger removed.')),
                          );
                        },
                      ),
                    ),
                  ),

                  const SizedBox(height: 10),

                  Center(
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.delete),
                      label: const Text('Cancel Ride'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: () async {
                        await RideService.cancelRide(currentRide.id);
                        if (mounted) {
                          Navigator.of(context).pop();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Ride canceled.')),
                          );
                        }
                      },
                    ),
                  ),
                ],

                const Spacer(),

                Center(
                  child: ElevatedButton(
                    onPressed:
                    (rideIsFull || _isJoining || hasJoined || isDriver)
                        ? null
                        : _joinRide,
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                      (rideIsFull || hasJoined || isDriver)
                          ? Colors.grey
                          : Theme.of(context).primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 40,
                        vertical: 15,
                      ),
                    ),
                    child:
                    _isJoining
                        ? const CircularProgressIndicator(
                      color: Colors.white,
                    )
                        : Text(
                      isDriver
                          ? 'Your Ride'
                          : (hasJoined
                          ? 'Already Joined'
                          : (rideIsFull
                          ? 'Ride Full'
                          : 'Join Ride')),
                      style: const TextStyle(fontSize: 18),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 150,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 16))),
        ],
      ),
    );
  }
}