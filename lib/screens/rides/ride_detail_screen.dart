// lib/screens/rides/ride_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:byui_rideshare/models/ride.dart';
import 'package:byui_rideshare/services/ride_service.dart';

class RideDetailScreen extends StatefulWidget {
  final Ride ride; // The initial ride object passed from RideListScreen

  const RideDetailScreen({super.key, required this.ride});

  @override
  State<RideDetailScreen> createState() => _RideDetailScreenState();
}

class _RideDetailScreenState extends State<RideDetailScreen> {
  User? _currentUser;
  bool _isJoining = false; // To manage button state

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

    final String? errorMessage = await RideService.joinRide(widget.ride.id, _currentUser!.uid);

    if (mounted) { // Check if the widget is still in the tree before setState
      setState(() {
        _isJoining = false;
      });

      if (errorMessage == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Seat claimed successfully!')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to join ride: $errorMessage')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Use a StreamBuilder to get real-time updates for this specific ride
    return StreamBuilder<Ride>(
      stream: RideService.getRideStream(widget.ride.id),
      builder: (context, snapshot) {
        Ride currentRide = widget.ride; // Fallback to initial ride if stream not ready

        if (snapshot.connectionState == ConnectionState.waiting) {
          // Can show a loading indicator or initial data
        } else if (snapshot.hasError) {
          // Handle error, e.g., show a message or use initial data
          print('Error fetching ride stream: ${snapshot.error}');
        } else if (snapshot.hasData) {
          currentRide = snapshot.data!; // Use real-time data if available
        }

        bool rideIsFull = currentRide.isFull || currentRide.availableSeats <= 0;
        bool hasJoined = _currentUser != null && currentRide.joinedUserUids.contains(_currentUser!.uid);
        bool isDriver = _currentUser != null && currentRide.driverUid == _currentUser!.uid;

        return Scaffold(
          appBar: AppBar(
            title: const Text('Ride Details'),
          ),
          body: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${currentRide.origin} to ${currentRide.destination}',
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                _buildDetailRow('Date:', DateFormat('EEE, MMM d,yyyy').format(currentRide.rideDate.toDate())),
                _buildDetailRow('Time:', DateFormat('h:mm a').format(currentRide.rideDate.toDate())),
                _buildDetailRow('Available Seats:', currentRide.availableSeats.toString()),
                _buildDetailRow('Fare:', '\$${currentRide.fare?.toStringAsFixed(2) ?? 'N/A'}'),
                _buildDetailRow('Driver:', currentRide.driverName),
                _buildDetailRow('Status:', rideIsFull ? 'Full' : 'Available'),
                if (hasJoined)
                  const Padding(
                    padding: EdgeInsets.only(top: 8.0),
                    child: Text(
                      'You have joined this ride.',
                      style: TextStyle(fontStyle: FontStyle.italic, color: Colors.blue),
                    ),
                  ),
                if (isDriver)
                  const Padding(
                    padding: EdgeInsets.only(top: 8.0),
                    child: Text(
                      'You are the driver of this ride.',
                      style: TextStyle(fontStyle: FontStyle.italic, color: Colors.purple),
                    ),
                  ),
                const Spacer(), // Pushes the button to the bottom
                Center(
                  child: ElevatedButton(
                    onPressed: (rideIsFull || _isJoining || hasJoined || isDriver) ? null : _joinRide,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: (rideIsFull || hasJoined || isDriver) ? Colors.grey : Theme.of(context).primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                    ),
                    child: _isJoining
                        ? const CircularProgressIndicator(color: Colors.white)
                        : Text(
                      isDriver ? 'Your Ride' : (hasJoined ? 'Already Joined' : (rideIsFull ? 'Ride Full' : 'Join Ride')),
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
            width: 150, // Adjust width as needed for alignment
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }
}