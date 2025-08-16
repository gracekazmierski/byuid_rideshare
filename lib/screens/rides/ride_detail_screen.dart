import 'package:byui_rideshare/screens/profile/profile_chip.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:byui_rideshare/models/ride.dart';
import 'package:byui_rideshare/models/ride_request.dart';
import 'package:byui_rideshare/services/ride_service.dart';
// import 'package:byui_rideshare/services/user_service.dart'; // not needed with ProfileChip
import 'package:byui_rideshare/screens/chat/ride_chat_screen.dart';
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

  // ===== Actions =====

  void _joinRide(String rideId) async {
    if (_currentUser == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('You must be logged in to join.')));
      return;
    }
    setState(() => _isProcessing = true);
    try {
      await RideService.requestToJoinRide(rideId, _currentUser!.uid, "");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ride request sent!'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  void _acceptRequest(String requestId, String rideId, String riderUid) async {
    setState(() => _isProcessing = true);
    try {
      await RideService.acceptRideRequest(requestId, rideId, riderUid);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Request accepted.'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  void _denyRequest(String requestId) async {
    try {
      await RideService.denyRideRequest(requestId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Request denied.')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _removePassenger(String rideId, String passengerUid) async {
    try {
      await RideService.removePassenger(rideId, passengerUid);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Passenger removed.')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _cancelRide(String rideId) async {
    try {
      await RideService.cancelRide(rideId);
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Ride canceled.')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}'), backgroundColor: Colors.red),
        );
      }
    }
  }

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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Add to Calendar is not available on the web version yet.')),
      );
    }
  }

  // ===== UI =====

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return PreferredSize(
      preferredSize: const Size.fromHeight(kToolbarHeight + 40),
      child: Container(
        color: AppColors.byuiBlue,
        padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top),
        child: const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Row(
            children: [
              BackButton(color: Colors.white),
              SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('Ride Details',
                        style: TextStyle(color: Colors.white, fontSize: 24.0, fontWeight: FontWeight.w600)),
                    SizedBox(height: 2.0),
                    Text("View ride information",
                        style: TextStyle(color: AppColors.blue100, fontSize: 14.0)),
                  ],
                ),
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
              : ListView(
            padding: const EdgeInsets.fromLTRB(16, 24, 16, 24),
            children: [
              _buildRouteCard(ride),
              const SizedBox(height: 16),
              _buildDetailsCard(ride),
              const SizedBox(height: 16),
              _buildPeopleCard(ride),
              if (isDriver) ...[
                const SizedBox(height: 16),
                _buildDriverAdminCard(ride),
              ],
              if (isDriver || hasJoined) ...[
                const SizedBox(height: 16),
                _buildChatButton(ride),
              ],
              const SizedBox(height: 12),
              _buildBottomActions(ride, isDriver, hasJoined, rideIsFull),
            ],
          ),
        );
      },
    );
  }

  // Not sticky: lives at bottom of the list
  Widget _buildChatButton(Ride ride) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => RideChatScreen(rideId: ride.id)),
          );
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.byuiBlue,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16.0),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
        ),
        child: const Text("Open Ride Chat", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
      ),
    );
  }

  // Not sticky: lives at bottom of the list
  Widget _buildBottomActions(Ride ride, bool isDriver, bool hasJoined, bool rideIsFull) {
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

    if (onPressedAction == null) buttonColor = Colors.grey;

    return Row(
      children: [
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
                ? const SizedBox(
                height: 24, width: 24, child: CircularProgressIndicator(strokeWidth: 3, color: Colors.white))
                : Text(buttonText, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ),
        ),
        const SizedBox(width: 12),
        OutlinedButton.icon(
          onPressed: () => _addRideToCalendar(ride),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.byuiBlue,
            side: const BorderSide(color: AppColors.byuiBlue, width: 1.5),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
          ),
          icon: const Icon(Icons.calendar_month),
          label: const Text('Add'),
        ),
      ],
    );
  }

  // ===== Cards =====

  Widget _buildRouteCard(Ride ride) {
    return _buildSectionCard(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _SectionTitle('Route'),
            const SizedBox(height: 8),
            _iconListRow(
              icon: Icons.location_on,
              iconColor: AppColors.byuiGreen,
              label: 'Origin',
              value: ride.origin,
            ),
            const SizedBox(height: 8),
            _iconListRow(
              icon: Icons.location_on,
              iconColor: AppColors.red500,
              label: 'Destination',
              value: ride.destination,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailsCard(Ride ride) {
    return _buildSectionCard(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _SectionTitle('Details'),
            const SizedBox(height: 8),
            _detailRow(
              icon: Icons.calendar_today_rounded,
              title: 'Date & Time',
              value:
              '${DateFormat('EEE, MMM d').format(ride.rideDate.toDate())} • ${DateFormat('h:mm a').format(ride.rideDate.toDate())}',
            ),
            _detailRow(
              icon: Icons.group_rounded,
              title: 'Seats Available',
              value: ride.availableSeats.toString(),
            ),
            _detailRow(
              icon: Icons.attach_money_rounded,
              title: 'Fare per Person',
              value: ride.fare != null ? '\$${ride.fare!.toStringAsFixed(2)}' : 'N/A',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPeopleCard(Ride ride) {
    final bool isDriver = _currentUser?.uid == ride.driverUid;

    return _buildSectionCard(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _SectionTitle('People'),
            const SizedBox(height: 8),
            const Text('Driver', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textGray600)),
            const SizedBox(height: 6),
            ProfileChip(userId: ride.driverUid, dense: false, maxNameWidth: 240),
            if (!isDriver)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: TextButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => RideChatScreen(rideId: ride.id)),
                    );
                  },
                  icon: const Icon(Icons.chat_bubble_outline, size: 18, color: AppColors.byuiBlue),
                  label: const Text('Message driver', style: TextStyle(color: AppColors.byuiBlue)),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.byuiBlue,
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  ),
                ),
              ),
            const SizedBox(height: 12),
            const Text('Passengers', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textGray600)),
            const SizedBox(height: 6),
            if (ride.joinedUserUids.isEmpty)
              const _EmptyHint('No passengers have joined yet.')
            else
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final uid in ride.joinedUserUids)
                    ProfileChip(userId: uid, dense: true, maxNameWidth: 140),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDriverAdminCard(Ride ride) {
    return _buildSectionCard(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _SectionTitle('Driver Tools'),
            const SizedBox(height: 8),

            // ---- Pending Requests (subtitle shows count; content shows empty hint when none) ----
            Theme(
              data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
              child: StreamBuilder<List<RideRequest>>(
                stream: RideService.fetchRequestsForRide(ride.id),
                builder: (context, snapshot) {
                  final requests = snapshot.data ?? [];
                  final countLabel = '${requests.length} request(s)';

                  return ExpansionTile(
                    initiallyExpanded: true,
                    tilePadding: const EdgeInsets.symmetric(horizontal: 8),
                    childrenPadding: const EdgeInsets.only(top: 8, bottom: 4),
                    iconColor: AppColors.byuiBlue,
                    collapsedIconColor: AppColors.byuiBlue,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    collapsedShape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    title: const Text('Pending Requests',
                        style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textGray800)),
                    subtitle: Text(countLabel, style: const TextStyle(color: AppColors.textGray500)),
                    children: [
                      if (snapshot.connectionState == ConnectionState.waiting)
                        const Center(
                          child: Padding(
                            padding: EdgeInsets.all(8.0),
                            child: CircularProgressIndicator(),
                          ),
                        )
                      else if (requests.isEmpty)
                        const _EmptyHint('No pending requests.')
                      else
                        Column(
                          children: requests.map((req) {
                            return Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                              decoration: BoxDecoration(
                                color: AppColors.gray50,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: AppColors.gray200),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: ProfileChip(userId: req.riderUid, dense: true, maxNameWidth: 180),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.check_circle, color: AppColors.byuiGreen),
                                    onPressed: () => _acceptRequest(req.id, ride.id, req.riderUid),
                                    tooltip: 'Accept',
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.cancel, color: AppColors.red500),
                                    onPressed: () => _denyRequest(req.id),
                                    tooltip: 'Deny',
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                    ],
                  );
                },
              ),
            ),

            // ---- Centered light divider between sections ----
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 6),
              child: Divider(
                height: 1,
                thickness: 0.6,
                color: AppColors.gray200,
              ),
            ),

            // ---- Current Passengers ----
            _prettyExpansion(
              title: 'Current Passengers',
              subtitle: '${ride.joinedUserUids.length} passenger(s)',
              initiallyExpanded: false,
              child: ride.joinedUserUids.isEmpty
                  ? const _EmptyHint('No passengers have joined.')
                  : Column(
                children: ride.joinedUserUids.map((uid) {
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                    decoration: BoxDecoration(
                      color: AppColors.gray50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.gray200),
                    ),
                    child: Row(
                      children: [
                        Expanded(child: ProfileChip(userId: uid, dense: true, maxNameWidth: 180)),
                        IconButton(
                          icon: const Icon(Icons.remove_circle_outline, color: AppColors.red500),
                          onPressed: () => _removePassenger(ride.id, uid),
                          tooltip: 'Remove',
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),

            const SizedBox(height: 12),

            // ---- Back to subtle TextButton (reverted) ----
            TextButton.icon(
              onPressed: () => _cancelRide(ride.id),
              icon: const Icon(Icons.delete_forever, color: AppColors.red500),
              label: const Text('Cancel This Ride', style: TextStyle(color: AppColors.red500)),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                alignment: Alignment.centerLeft,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ===== Building blocks =====

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

  Widget _iconListRow({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: iconColor),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontSize: 13, color: AppColors.textGray500)),
              const SizedBox(height: 2),
              Text(value,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textGray600)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _detailRow({required IconData icon, required String title, required String value}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0, top: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.textGray500),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 13, color: AppColors.textGray500)),
                const SizedBox(height: 2),
                Text(value,
                    style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textGray600)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _prettyExpansion({
    required String title,
    String? subtitle,
    required bool initiallyExpanded,
    required Widget child,
  }) {
    return Theme(
      data: Theme.of(context).copyWith(
        dividerColor: Colors.transparent, // remove gray divider line
      ),
      child: ExpansionTile(
        initiallyExpanded: initiallyExpanded,
        tilePadding: const EdgeInsets.symmetric(horizontal: 8),
        childrenPadding: const EdgeInsets.only(top: 8, bottom: 4),
        backgroundColor: Colors.white,
        collapsedBackgroundColor: Colors.white,
        iconColor: AppColors.byuiBlue,
        collapsedIconColor: AppColors.byuiBlue,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        collapsedShape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textGray800)),
        subtitle: subtitle != null
            ? Text(subtitle, style: const TextStyle(color: AppColors.textGray500))
            : null,
        children: [child],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: AppColors.byuiBlue,
        fontSize: 16,
        fontWeight: FontWeight.bold,
      ),
      textAlign: TextAlign.left,
    );
  }
}

// 🔧 Small helper for subtle empty-state text
class _EmptyHint extends StatelessWidget {
  final String text;
  const _EmptyHint(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(
        text,
        style: const TextStyle(color: AppColors.textGray500, fontSize: 13),
      ),
    );
  }
}
