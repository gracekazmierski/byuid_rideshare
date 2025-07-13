// lib/screens/rides/posted_request_detail_screen.dart

import 'package:byui_rideshare/models/posted_request.dart';
import 'package:byui_rideshare/screens/rides/create_ride_screen.dart';
import 'package:byui_rideshare/services/user_service.dart';
import 'package:byui_rideshare/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class PostedRequestDetailScreen extends StatelessWidget {
  final PostedRequest request;

  const PostedRequestDetailScreen({super.key, required this.request});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.gray50,
      appBar: AppBar(
        title: const Text('Request Details'),
        backgroundColor: AppColors.byuiBlue,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          _buildSectionCard(
            child: Column(
              children: [
                _buildDetailTile(
                    icon: Icons.my_location_rounded,
                    title: 'From',
                    subtitle: request.fromLocation,
                    iconColor: AppColors.byuiGreen),
                const Divider(height: 1, indent: 56),
                _buildDetailTile(
                    icon: Icons.flag_rounded,
                    title: 'To',
                    subtitle: request.toLocation,
                    iconColor: AppColors.red500),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _buildSectionCard(
            child: Column(
              children: [
                FutureBuilder<String?>(
                  future: UserService.getUserName(request.requesterUid),
                  builder: (context, snapshot) {
                    return _buildDetailTile(
                        icon: Icons.account_circle_rounded,
                        title: 'Requester',
                        subtitle: snapshot.data ?? 'Loading...');
                  },
                ),
                const Divider(height: 1, indent: 56),
                _buildDetailTile(
                    icon: Icons.date_range,
                    title: 'Desired Date Range',
                    subtitle:
                    '${DateFormat('MMM d, yyyy').format(request.requestDateStart.toDate())} - ${DateFormat('MMM d, yyyy').format(request.requestDateEnd.toDate())}'),
                const Divider(height: 1, indent: 56),
                _buildDetailTile(
                    icon: Icons.group_rounded,
                    title: 'Number of Riders',
                    subtitle:
                    '${request.riders.length} rider${request.riders.length == 1 ? '' : 's'}'),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ElevatedButton.icon(
          icon: const Icon(Icons.directions_car),
          label: const Text('Offer Ride For This Request'),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => CreateRideScreen(
                  initialOrigin: request.fromLocation,
                  initialDestination: request.toLocation,
                ),
              ),
            );
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.byuiBlue,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16.0),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8.0)),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionCard({required Widget child}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: AppColors.gray200),
      ),
      child: child,
    );
  }

  Widget _buildDetailTile(
      {required IconData icon,
        required String title,
        required String subtitle,
        Color? iconColor}) {
    return ListTile(
      leading: Icon(icon, color: iconColor ?? AppColors.textGray500),
      title: Text(title,
          style: const TextStyle(fontSize: 14, color: AppColors.textGray500)),
      subtitle: Text(subtitle,
          style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textGray600)),
    );
  }
}