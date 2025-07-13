import 'package:byui_rideshare/models/posted_request.dart';
import 'package:byui_rideshare/services/posted_request_service.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:byui_rideshare/models/ride.dart';
import 'package:byui_rideshare/services/ride_service.dart';
import 'package:byui_rideshare/screens/rides/ride_list_screen.dart';
import 'package:byui_rideshare/screens/rides/ride_detail_screen.dart';
import 'package:byui_rideshare/theme/app_colors.dart';
import 'package:byui_rideshare/services/user_service.dart';
import 'package:intl/intl.dart';
import 'package:add_2_calendar/add_2_calendar.dart';
import 'package:byui_rideshare/screens/rides/create_ride_screen.dart';



class MyJoinedRidesScreen extends StatelessWidget {
  const MyJoinedRidesScreen({super.key});

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return PreferredSize(
      preferredSize: const Size.fromHeight(kToolbarHeight + 40),
      child: Container(
        color: AppColors.byuiBlue,
        padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => Navigator.of(context).pop(),
              ),
              const SizedBox(width: 8),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('My Joined Rides', style: TextStyle(color: Colors.white, fontSize: 24.0, fontWeight: FontWeight.w600)),
                  SizedBox(height: 2.0),
                  Text("View the rides you have joined", style: TextStyle(color: AppColors.blue100, fontSize: 14.0)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      return Scaffold(appBar: _buildAppBar(context), body: const Center(child: Text('Please log in.')));
    }

    final buttonStyle = ElevatedButton.styleFrom(
      backgroundColor: AppColors.byuiBlue,
      foregroundColor: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
    );

    return Scaffold(
      backgroundColor: AppColors.gray50,
      appBar: _buildAppBar(context),
      body: ListView(
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 24, 16, 8),
            child: Text('Joined Rides', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textGray600)),
          ),
          StreamBuilder<List<Ride>>(
            stream: RideService.fetchJoinedRideListings(currentUser.uid),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: Padding(padding: EdgeInsets.all(16.0), child: CircularProgressIndicator()));

              final rides = snapshot.data ?? [];
              return Column(
                children: [
                  if (rides.isEmpty)
                    const Center(child: Padding(padding: EdgeInsets.all(16.0), child: Text('You have not joined any rides.')))
                  else
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      itemCount: rides.length,
                      itemBuilder: (context, index) => _buildRideCard(context, rides[index]),
                    ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // ✨ CHANGED to ElevatedButton.icon
                        ElevatedButton.icon(
                          icon: const Icon(Icons.search),
                          label: const Text('Search for a ride'),
                          style: buttonStyle,
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const RideListScreen()),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
          const Divider(height: 32, indent: 16, endIndent: 16),
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: Text('Pending Requests', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textGray600)),
          ),
          StreamBuilder<List<PostedRequest>>(
            stream: PostedRequestService.fetchJoinedRideRequests(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: Padding(padding: EdgeInsets.all(16.0), child: CircularProgressIndicator()));

              final requests = snapshot.data ?? [];
              return Column(
                children: [
                  if (requests.isEmpty)
                    const Center(child: Padding(padding: EdgeInsets.all(16.0), child: Text('You have not joined any ride requests.')))
                  else
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      itemCount: requests.length,
                      itemBuilder: (context, index) => JoinedRequestCard(request: requests[index]),
                    ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // ✨ CHANGED to ElevatedButton.icon
                        ElevatedButton.icon(
                          icon: const Icon(Icons.search),
                          label: const Text('Search ride requests'),
                          style: buttonStyle,
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const RideListScreen()),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildRideCard(BuildContext context, Ride ride) {
    return Card(
      color: Colors.white,
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: InkWell(
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => RideDetailScreen(ride: ride))),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Container(width: 8, height: 8, decoration: BoxDecoration(color: AppColors.byuiGreen, borderRadius: BorderRadius.circular(4)), margin: const EdgeInsets.only(right: 8)),
                Text(ride.origin, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.gray700)),
              ]),
              const SizedBox(height: 4),
              Row(children: [
                Container(width: 8, height: 8, decoration: BoxDecoration(color: AppColors.red500, borderRadius: BorderRadius.circular(4)), margin: const EdgeInsets.only(right: 8)),
                Text(ride.destination, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.gray700)),
              ]),
              const SizedBox(height: 12),
              Row(children: [
                const Icon(Icons.calendar_today, size: 16,
                    color: AppColors.textGray500),
                const SizedBox(width: 8),
                Text(DateFormat('MMM d hh:mm a').format(ride.rideDate.toDate()), style: const TextStyle(fontSize: 14, color: AppColors.textGray500)),
              ]),
            ],
          ),
        ),
      ),
    );
  }
}

// ✅ NEW, DETAILED, AND FUNCTIONAL WIDGET FOR JOINED REQUESTS
class JoinedRequestCard extends StatefulWidget {
  final PostedRequest request;
  const JoinedRequestCard({super.key, required this.request});

  @override
  State<JoinedRequestCard> createState() => _JoinedRequestCardState();
}

class _JoinedRequestCardState extends State<JoinedRequestCard> {
  bool _isLeaving = false;

  @override
  Widget build(BuildContext context) {
    final dateString = DateFormat('EEEE, MMM d').format(widget.request.requestDate.toDate());

    return Card(
      color: Colors.white,
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                        '${widget.request.fromLocation} to ${widget.request.toLocation}',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)
                    ),
                    const SizedBox(height: 4),
                    Text(dateString, style: const TextStyle(color: AppColors.textGray500)),
                  ],
                ),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('Pending', style: TextStyle(color: AppColors.byuiBlue, fontWeight: FontWeight.w500)),
                    Icon(Icons.hourglass_top_rounded, color: AppColors.byuiBlue, size: 18),
                  ],
                )
              ],
            ),
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Display the name of the original requester
                FutureBuilder<String?>(
                  future: UserService.getUserName(widget.request.requesterUid),
                  builder: (context, snapshot) {
                    return Text(
                        'Requested by ${snapshot.data ?? "..."}',
                        style: const TextStyle(fontSize: 12, color: AppColors.textGray600)
                    );
                  },
                ),
                // The Leave Request button
                _isLeaving
                    ? const CircularProgressIndicator()
                    : TextButton(
                  onPressed: () async {
                    setState(() => _isLeaving = true);
                    try {
                      await PostedRequestService.leaveRideRequest(widget.request.id);
                      if(mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("You left the ride request."), backgroundColor: Colors.green));
                      }
                    } catch (e) {
                      if(mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Failed to leave: $e"), backgroundColor: Colors.red));
                      }
                    } finally {
                      if(mounted) setState(() => _isLeaving = false);
                    }
                  },
                  style: TextButton.styleFrom(foregroundColor: AppColors.red500),
                  child: const Text('Leave'),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}

// Note: The 'main' branch had a dependency on this method, but the 'GraceK' version of the UI doesn't call it.
// It is kept here as part of the 'GraceK' branch's code.
void _addRideToCalendar(Ride ride) {
  final DateTime rideStart = ride.rideDate.toDate();
  final DateTime rideEnd = rideStart.add(const Duration(hours: 1));

  final Event event = Event(
    title: 'Ride from ${ride.origin} to ${ride.destination}',
    description: 'Ride Details: \$${ride.fare?.toStringAsFixed(2) ?? '0'} fare, ${ride.availableSeats} seats',
    location: 'Departure: ${ride.origin}',
    startDate: rideStart,
    endDate: rideEnd,
  );

  Add2Calendar.addEvent2Cal(event);
}