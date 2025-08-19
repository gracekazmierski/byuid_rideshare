// lib/screens/rides/posted_request_detail_screen.dart

import 'package:byui_rideshare/models/posted_request.dart';
import 'package:byui_rideshare/screens/profile/profile_chip.dart';
import 'package:byui_rideshare/screens/rides/fulfill_request_screen.dart';
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
                  subtitle: Text(
                    request.fromLocation,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textGray600,
                    ),
                  ),
                  iconColor: AppColors.byuiGreen,
                ),
                const Divider(height: 1, indent: 56),
                _buildDetailTile(
                  icon: Icons.flag_rounded,
                  title: 'To',
                  subtitle: Text(
                    request.toLocation,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textGray600,
                    ),
                  ),
                  iconColor: AppColors.red500,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _buildSectionCard(
            child: Column(
              children: [
                _buildDetailTile(
                  icon: Icons.account_circle_rounded,
                  title: 'Requester',
                  subtitle: ProfileChip(
                    userId: request.requesterUid,
                    showName: true,
                    dense: true, // larger display for detail screen
                  ),
                ),
                const Divider(height: 1, indent: 56),
                _buildDetailTile(
                  icon: Icons.date_range,
                  title: 'Desired Date',
                  subtitle: Text(
                    DateFormat('EEEE, MMM d, yyyy')
                        .format(request.requestDate.toDate()),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textGray600,
                    ),
                  ),
                ),
                const Divider(height: 1, indent: 56),
                _buildDetailTile(
                  icon: Icons.group_rounded,
                  title: 'Number of Riders',
                  subtitle: Text(
                    '${request.riders.length} rider${request.riders.length == 1 ? '' : 's'}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textGray600,
                    ),
                  ),
                ),
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
                builder: (context) => FulfillRequestScreen(request: request),
              ),
            );
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.byuiBlue,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16.0),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8.0),
            ),
          ),
        ),
      ),
    );
  }

  // Section wrapper
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

  // Generic tile row for details
  Widget _buildDetailTile({
    required IconData icon,
    required String title,
    required Widget subtitle, // now accepts any widget
    Color? iconColor,
  }) {
    return ListTile(
      leading: Icon(icon, color: iconColor ?? AppColors.textGray500),
      title: Text(
        title,
        style: const TextStyle(fontSize: 14, color: AppColors.textGray500),
      ),
      subtitle: subtitle,
    );
  }
}
