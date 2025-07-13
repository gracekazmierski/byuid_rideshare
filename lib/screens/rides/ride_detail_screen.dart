import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:byui_rideshare/models/ride.dart';
import 'package:byui_rideshare/models/ride_request.dart';
import 'package:byui_rideshare/services/ride_service.dart';
import 'package:byui_rideshare/services/user_service.dart';
import 'package:byui_rideshare/theme/app_colors.dart';
import 'package:add_2_calendar/add_2_calendar.dart';
import 'package:flutter/foundation.dart' show kIsWeb;


class RideDetailScreen extends StatefulWidget {
  final Ride ride;
  const RideDetailScreen({super.key, required this.ride});

  @override
  State<RideDetailScreen> createState() => _RideDetailScreenState();
}

class _RideDetailScreenState extends State<RideDetailScreen> {
  User? _currentUser;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _currentUser = FirebaseAuth.instance.currentUser;
  }

  // --- ACTION HANDLERS (Unchanged) ---
  void _joinRide(String rideId) async {/*...*/}
  void _acceptRequest(String requestId, String rideId, String riderUid) async {/*...*/}
  void _denyRequest(String requestId) async {/*...*/}
  void _removePassenger(String rideId, String passengerUid) async {/*...*/}
  void _cancelRide(String rideId) async {/*...*/}

  Future<void> _addRideToCalendar(Ride ride) async {
    if (!kIsWeb) {
      final DateTime rideStart = ride.rideDate.toDate();
      final DateTime rideEnd = rideStart.add(const Duration(hours: 3));

      final Event event = Event(
        title: 'Ride from ${ride.origin} to ${ride.destination}',
        description: 'Ride Details with RexRide. Fare: \$${ride.fare?.toStringAsFixed(2)}',
        location: 'Departure from ${ride.origin}',
        startDate: rideStart,
        endDate: rideEnd,
      );
      await Add2Calendar.addEvent2Cal(event);
    } else {
      // If on the web, just show a message for now.
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Add to Calendar is not available on the web version yet.')),
      );
    }
  }

  // --- UI BUILDER WIDGETS ---
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
                  Text('Ride Details', style: TextStyle(color: Colors.white, fontSize: 24.0, fontWeight: FontWeight.w600)),
                  SizedBox(height: 2.0),
                  Text("View ride information", style: TextStyle(color: AppColors.blue100, fontSize: 14.0)),
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
    return StreamBuilder<Ride>(
      stream: RideService.getRideStream(widget.ride.id),
      builder: (context, snapshot) {
        final ride = snapshot.data ?? widget.ride;
        final isLoading = snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData;
        final bool rideIsFull = ride.isFull || ride.availableSeats <= 0;
        final bool hasJoined = _currentUser != null && ride.joinedUserUids.contains(_currentUser!.uid);
        final bool isDriver = _currentUser != null && ride.driverUid == _currentUser!.uid;

        return Scaffold(
          backgroundColor: AppColors.gray50,
          appBar: _buildAppBar(context),
          body: isLoading
              ? const Center(child: CircularProgressIndicator())
              : Stack(
            children: [
              ListView(
                padding: const EdgeInsets.fromLTRB(16, 24, 16, 120), // Increased bottom padding
                children: [
                  _buildRouteCard(ride),
                  const SizedBox(height: 16),
                  _buildDetailsCard(ride),
                  // ✅ The old button that was here has been removed.
                  if (isDriver) ...[
                    const SizedBox(height: 16),
                    _buildDriverAdminCard(ride),
                  ],
                ],
              ),
              // ✅ The new bottom bar now includes the calendar button
              _buildActionAndCalendarBar(ride, isDriver, hasJoined, rideIsFull),
            ],
          ),
        );
      },
    );
  }

  // This new method builds the bottom bar with both buttons
  Widget _buildActionAndCalendarBar(Ride ride, bool isDriver, bool hasJoined, bool rideIsFull) {
    String buttonText;
    VoidCallback? onPressedAction;
    Color buttonColor = AppColors.byuiBlue;

    if (isDriver) {
      buttonText = 'You Are The Driver';
      onPressedAction = null;
    } else if (hasJoined) {
      buttonText = 'You Have Joined This Ride';
      onPressedAction = null;
    } else if (rideIsFull) {
      buttonText = 'Ride Full';
      onPressedAction = null;
    } else {
      buttonText = 'Request to Join Ride';
      onPressedAction = () => _joinRide(ride.id);
    }

    if (onPressedAction == null) {
      buttonColor = Colors.grey;
    }

    return Align(
      alignment: Alignment.bottomCenter,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16.0),
        color: AppColors.gray50.withOpacity(0.95), // Slight transparency
        child: Row(
          children: [
            // Main action button
            Expanded(
              child: ElevatedButton(
                onPressed: _isProcessing ? null : onPressedAction,
                style: ElevatedButton.styleFrom(
                  backgroundColor: buttonColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16.0),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
                ),
                child: _isProcessing
                    ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(strokeWidth: 3, color: Colors.white))
                    : Text(buttonText, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(width: 16),
            // "Add to Calendar" button
            ElevatedButton(
              onPressed: () => _addRideToCalendar(ride),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.byuiBlue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.all(16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
              ),
              child: const Icon(Icons.calendar_month),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRouteCard(Ride ride) {
    return _buildSectionCard(
      child: Column(
        children: [
          _buildDetailTile(icon: Icons.my_location_rounded, title: 'Origin', subtitle: ride.origin, iconColor: AppColors.byuiGreen),
          Padding(
            padding: const EdgeInsets.only(left: 28.0),
            child: Align(
              alignment: Alignment.centerLeft,
              child: SizedBox(
                height: 30,
                child: CustomPaint(painter: DottedLinePainter()),
              ),
            ),
          ),
          _buildDetailTile(icon: Icons.flag_rounded, title: 'Destination', subtitle: ride.destination, iconColor: AppColors.red500),
        ],
      ),
    );
  }

  Widget _buildDetailsCard(Ride ride) {
    return _buildSectionCard(
      child: Column(
        children: [
          FutureBuilder<String?>(
              future: UserService.getUserName(ride.driverUid),
              builder: (context, snapshot) {
                return _buildDetailTile(icon: Icons.account_circle_rounded, title: 'Driver', subtitle: snapshot.data ?? 'Loading...');
              }
          ),
          const Divider(height: 1, indent: 56),
          _buildDetailTile(icon: Icons.calendar_today_rounded, title: 'Date & Time', subtitle: '${DateFormat('EEE, MMM d').format(ride.rideDate.toDate())} at ${DateFormat('h:mm a').format(ride.rideDate.toDate())}'),
          const Divider(height: 1, indent: 56),
          _buildDetailTile(icon: Icons.group_rounded, title: 'Seats Available', subtitle: ride.availableSeats.toString()),
          const Divider(height: 1, indent: 56),
          _buildDetailTile(icon: Icons.attach_money_rounded, title: 'Fare per Person', subtitle: '\$${ride.fare?.toStringAsFixed(2) ?? 'N/A'}'),
        ],
      ),
    );
  }

  Widget _buildDriverAdminCard(Ride ride) {
    return _buildSectionCard(
      child: Column(
        children: [
          StreamBuilder<List<RideRequest>>(
              stream: RideService.fetchRequestsForRide(ride.id),
              builder: (context, snapshot) {
                final requests = snapshot.data ?? [];
                return ExpansionTile(
                  title: const Text('Pending Requests', style: TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text('${requests.length} request(s)'),
                  initiallyExpanded: true,
                  children: [
                    if(snapshot.connectionState == ConnectionState.waiting) const Padding(padding: EdgeInsets.all(8.0), child: CircularProgressIndicator()),
                    if(requests.isEmpty && snapshot.connectionState != ConnectionState.waiting) const ListTile(title: Text('No pending requests.')),
                    ...requests.map((req) => FutureBuilder<String?>(
                        future: UserService.getUserName(req.riderUid),
                        builder: (context, nameSnapshot) {
                          return ListTile(
                            title: Text(nameSnapshot.data ?? 'Loading...'),
                            trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                              IconButton(icon: const Icon(Icons.check_circle, color: AppColors.byuiGreen), onPressed: () => _acceptRequest(req.id, ride.id, req.riderUid)),
                              IconButton(icon: const Icon(Icons.cancel, color: AppColors.red500), onPressed: () => _denyRequest(req.id)),
                            ]),
                          );
                        }
                    )).toList()
                  ],
                );
              }
          ),
          const Divider(height: 1),
          ExpansionTile(
            title: const Text('Current Passengers', style: TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text('${ride.joinedUserUids.length} passenger(s)'),
            children: [
              if(ride.joinedUserUids.isEmpty) const ListTile(title: Text('No passengers have joined.')),
              ...ride.joinedUserUids.map((uid) => FutureBuilder<String?>(
                  future: UserService.getUserName(uid),
                  builder: (context, nameSnapshot) {
                    return ListTile(
                      title: Text(nameSnapshot.data ?? '...'),
                      trailing: IconButton(icon: const Icon(Icons.remove_circle_outline, color: AppColors.red500), onPressed: () => _removePassenger(ride.id, uid)),
                    );
                  }
              )).toList()
            ],
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.delete_forever, color: AppColors.red500),
            title: const Text('Cancel This Ride', style: TextStyle(color: AppColors.red500)),
            onTap: () => _cancelRide(ride.id),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(Ride ride, bool isDriver, bool hasJoined, bool rideIsFull) {
    String buttonText;
    VoidCallback? onPressedAction;
    Color buttonColor = AppColors.byuiBlue;

    if (isDriver) {
      buttonText = 'You Are The Driver';
      onPressedAction = null;
    } else if (hasJoined) {
      buttonText = 'You Have Joined This Ride';
      onPressedAction = null;
    } else if (rideIsFull) {
      buttonText = 'Ride Full';
      onPressedAction = null;
    } else {
      buttonText = 'Request to Join Ride';
      onPressedAction = () => _joinRide(ride.id);
    }

    if (onPressedAction == null) {
      buttonColor = Colors.grey;
    }

    return Align(
      alignment: Alignment.bottomCenter,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16.0),
        color: AppColors.gray50,
        child: ElevatedButton(
          onPressed: _isProcessing ? null : onPressedAction,
          style: ElevatedButton.styleFrom(
            backgroundColor: buttonColor,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16.0),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
          ),
          child: _isProcessing
              ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(strokeWidth: 3, color: Colors.white))
              : Text(buttonText, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        ),
      ),
    );
  }

  Widget _buildSectionCard({required Widget child}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: AppColors.gray200),
      ),
      child: child,
    );
  }

  Widget _buildDetailTile({required IconData icon, required String title, required String subtitle, Color? iconColor}) {
    return ListTile(
      leading: Icon(icon, color: iconColor ?? AppColors.textGray500),
      title: Text(title, style: const TextStyle(fontSize: 14, color: AppColors.textGray500)),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textGray600)),
    );
  }
}

class DottedLinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    var paint = Paint()
      ..color = Colors.grey.shade300
      ..strokeWidth = 2;
    var max = size.height;
    var dashWidth = 5;
    var dashSpace = 5;
    double startY = 0;
    while (startY < max) {
      canvas.drawLine(Offset(0, startY), Offset(0, startY + dashWidth), paint);
      startY += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}