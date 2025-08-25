// lib/screens/rides/ride_confirmation_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:byui_rideshare/models/ride.dart';
import 'package:byui_rideshare/screens/rides/ride_list_screen.dart';
import 'package:byui_rideshare/theme/app_colors.dart'; // Import app colors

class RideConfirmationScreen extends StatelessWidget {
  final Ride ride;

  const RideConfirmationScreen({super.key, required this.ride});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Use the consistent light gray background
      backgroundColor: AppColors.gray50,
      // We remove the AppBar to give a more modal/final confirmation feel
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 500),
            child: Container(
              padding: const EdgeInsets.all(24.0),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16.0),
                border: Border.all(color: AppColors.gray200),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10.0,
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Success Icon
                  Container(
                    width: 72,
                    height: 72,
                    decoration: const BoxDecoration(
                      color: AppColors.byuiGreen, // Use a consistent green
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check_rounded,
                      color: Colors.white,
                      size: 48,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Confirmation Message
                  const Text(
                    'Ride Posted Successfully!',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textGray600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    "Your ride is now visible on the ride board.",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.textGray500,
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 20.0),
                    child: Divider(),
                  ),

                  // Ride Details Section
                  _buildDetailTile(
                    icon: Icons.my_location,
                    title: 'Origin',
                    subtitle: ride.origin,
                    iconColor: AppColors.byuiGreen,
                  ),
                  _buildDetailTile(
                    icon: Icons.flag,
                    title: 'Destination',
                    subtitle: ride.destination,
                    iconColor: AppColors.red500,
                  ),
                  const Divider(height: 24),
                  _buildDetailTile(
                    icon: Icons.calendar_today,
                    title: 'Date & Time',
                    subtitle:
                        '${DateFormat('EEE, MMM d').format(ride.rideDate.toDate())} at ${DateFormat('h:mm a').format(ride.rideDate.toDate())}',
                  ),
                  const Divider(height: 24),
                  _buildDetailTile(
                    icon: Icons.group,
                    title: 'Seats Available',
                    subtitle: ride.availableSeats.toString(),
                  ),
                  _buildDetailTile(
                    icon: Icons.attach_money,
                    title: 'Fare per Person',
                    subtitle: '\$${ride.fare?.toStringAsFixed(2) ?? 'N/A'}',
                  ),
                  const SizedBox(height: 32),

                  // Action Button
                  SizedBox(
                    width: double.infinity,
                    height: 48.0,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.done_all_rounded),
                      label: const Text(
                        'Return to Ride Board',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      onPressed: () {
                        // Navigate back to the RideListScreen and clear all previous routes
                        Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const RideListScreen(),
                          ),
                          (Route<dynamic> route) => false,
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.byuiBlue,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // A new helper widget for creating clean, icon-based detail rows.
  Widget _buildDetailTile({
    required IconData icon,
    required String title,
    required String subtitle,
    Color? iconColor,
  }) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: iconColor ?? AppColors.textGray500),
      title: Text(
        title,
        style: const TextStyle(fontSize: 14, color: AppColors.textGray500),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: AppColors.textGray600,
        ),
      ),
    );
  }
}
