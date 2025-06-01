// lib/screens/rides/ride_confirmation_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:byui_rideshare/models/ride.dart';
import 'package:byui_rideshare/screens/rides/ride_list_screen.dart'; // Import the RideListScreen

class RideConfirmationScreen extends StatelessWidget {
  final Ride ride; // The ride object to display

  const RideConfirmationScreen({super.key, required this.ride});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ride Posted!'),
        automaticallyImplyLeading: false, // Hide back button on confirmation
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Your ride has been successfully posted!',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.green),
            ),
            const SizedBox(height: 20),
            const Text(
              'Trip Details:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 10),
            _buildDetailRow('Origin:', ride.origin),
            _buildDetailRow('Destination:', ride.destination),
            _buildDetailRow('Date:', DateFormat('EEE, MMM d, yyyy').format(ride.rideDate.toDate())),
            _buildDetailRow('Time:', DateFormat('h:mm a').format(ride.rideDate.toDate())),
            _buildDetailRow('Available Seats:', ride.availableSeats.toString()),
            _buildDetailRow('Fare:', '\$${ride.fare?.toStringAsFixed(2) ?? 'N/A'}'),
            _buildDetailRow('Driver:', ride.driverName),
            const SizedBox(height: 30),
            Center(
              child: ElevatedButton.icon(
                onPressed: () {
                  // This navigates back to the RideListScreen and removes
                  // all other routes from the stack below it.
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (context) => const RideListScreen()),
                        (Route<dynamic> route) => false, // This condition removes all routes
                  );
                },
                icon: const Icon(Icons.arrow_back),
                label: const Text(
                  'Return to Ride Board',
                  style: TextStyle(fontSize: 16),
                ),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 15),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120, // Align labels
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