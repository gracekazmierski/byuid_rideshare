import 'package:byui_rideshare/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:byui_rideshare/models/ride.dart';
import 'package:byui_rideshare/services/ride_service.dart';
import 'package:byui_rideshare/screens/rides/ride_detail_screen.dart';
import 'package:intl/intl.dart';

class RideHistoryScreen extends StatelessWidget {
  final String userId;
  const RideHistoryScreen({required this.userId, super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.gray50,
      appBar: AppBar(title: const Text('Ride History')),
      body: StreamBuilder<List<Ride>>(
        stream: RideService.fetchRideHistory(userId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text("No past rides yet."));
          }

          final rides = snapshot.data!;

          return ListView.builder(
            itemCount: rides.length,
            itemBuilder: (context, index) {
              final ride = rides [index];
              return Card(
                child: ListTile(
                  title: Text('${ride.origin} -> ${ride.destination}'),
                  subtitle: Text(DateFormat('EEEE, MMM d, yyyy').format(ride.rideDate.toDate())),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => RideDetailScreen(ride: ride),
                      ),
                    );
                  },
                ),
              );
            },

          );
        }
      )
    );
  }

}