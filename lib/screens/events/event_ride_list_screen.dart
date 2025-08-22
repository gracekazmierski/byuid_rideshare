// lib/screens/events/event_ride_list_screen.dart
import 'package:byui_rideshare/screens/events/create_event_ride_screen.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:byui_rideshare/models/ride.dart';
import 'package:byui_rideshare/models/sort_option.dart';
import 'package:byui_rideshare/services/ride_service.dart';
import 'package:byui_rideshare/screens/events/event_ride_detail_screen.dart';
import 'package:byui_rideshare/screens/rides/create_ride_screen.dart';
import 'package:byui_rideshare/screens/rides/my_rides_screen.dart';
import 'package:byui_rideshare/screens/rides/my_joined_rides_screen.dart';
import 'package:byui_rideshare/screens/profile/profile_chip.dart';
import 'package:byui_rideshare/theme/app_colors.dart';

class EventRideListScreen extends StatefulWidget {
  static const String routeName = '/event-rides';
  const EventRideListScreen({super.key});

  @override
  State<EventRideListScreen> createState() => _EventRideListScreenState();
}

class _EventRideListScreenState extends State<EventRideListScreen> {
  final TextEditingController _fromSearchController = TextEditingController();
  final TextEditingController _toSearchController = TextEditingController();
  String _fromQuery = '';
  String _toQuery = '';
  bool _showFullRides = true;
  SortOption _selectedSort = SortOption.soonest;
  DateTime? _startDate;
  DateTime? _endDate;

  @override
  void initState() {
    super.initState();
    _fromSearchController.addListener(_updateSearchQuery);
    _toSearchController.addListener(_updateSearchQuery);
  }

  void _updateSearchQuery() {
    setState(() {
      _fromQuery = _fromSearchController.text.trim();
      _toQuery = _toSearchController.text.trim();
    });
  }

  @override
  void dispose() {
    _fromSearchController.dispose();
    _toSearchController.dispose();
    super.dispose();
  }

  InputDecoration _inputDecoration({required String labelText}) {
    return InputDecoration(
      labelText: labelText,
      labelStyle: const TextStyle(color: AppColors.textGray500),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8.0),
        borderSide: const BorderSide(color: AppColors.gray300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8.0),
        borderSide: const BorderSide(color: AppColors.byuiBlue, width: 2.0),
      ),
    );
  }

  void _showFilterSheet() {
    bool tempShowFull = _showFullRides;
    SortOption tempSort = _selectedSort;
    DateTime? tempStartDate = _startDate;
    DateTime? tempEndDate = _endDate;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter sheetSetState) {
            Future<DateTime?> showThemedDatePicker(
                {required DateTime initialDate, required DateTime firstDate}) async {
              return await showDatePicker(
                context: context,
                initialDate: initialDate,
                firstDate: firstDate,
                lastDate: DateTime(2030),
                builder: (context, child) {
                  return Theme(
                    data: Theme.of(context).copyWith(
                      colorScheme: const ColorScheme.light(
                        primary: AppColors.byuiBlue,
                        onPrimary: Colors.white,
                        onSurface: AppColors.textGray600,
                      ),
                      textButtonTheme: TextButtonThemeData(
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.byuiBlue,
                        ),
                      ),
                    ),
                    child: child!,
                  );
                },
              );
            }

            return Padding(
              padding: EdgeInsets.fromLTRB(
                24,
                8,
                24,
                MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 5,
                      margin: const EdgeInsets.only(bottom: 20),
                      decoration: BoxDecoration(
                        color: AppColors.gray300,
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  const Text(
                    'Filters & Sorting',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textGray600,
                    ),
                  ),
                  const SizedBox(height: 24),
                  CheckboxListTile(
                    title: const Text(
                      'Show Full Rides',
                      style: TextStyle(color: AppColors.textGray600),
                    ),
                    value: tempShowFull,
                    onChanged: (val) {
                      sheetSetState(() => tempShowFull = val ?? true);
                    },
                    activeColor: AppColors.byuiBlue,
                    contentPadding: EdgeInsets.zero,
                  ),
                  const Divider(),
                  DropdownButtonFormField<SortOption>(
                    value: tempSort,
                    decoration: _inputDecoration(labelText: 'Sort By'),
                    items: const [
                      DropdownMenuItem(value: SortOption.soonest, child: Text("Soonest First")),
                      DropdownMenuItem(value: SortOption.latest, child: Text("Latest First")),
                    ],
                    onChanged: (val) {
                      sheetSetState(() => tempSort = val ?? SortOption.soonest);
                    },
                  ),
                  const SizedBox(height: 16),
                  const Divider(),
                  ListTile(
                    leading: const Icon(Icons.date_range, color: AppColors.textGray500),
                    title: const Text("Date Range", style: TextStyle(color: AppColors.textGray500)),
                    subtitle: Text(
                      (tempStartDate == null)
                          ? "Any date"
                          : "${DateFormat('MM/dd/yy').format(tempStartDate!)} - ${DateFormat('MM/dd/yy').format(tempEndDate ?? tempStartDate!)}",
                      style: const TextStyle(color: AppColors.textGray600, fontWeight: FontWeight.bold),
                    ),
                    onTap: () async {
                      final pickedStart = await showThemedDatePicker(
                        initialDate: tempStartDate ?? DateTime.now(),
                        firstDate: DateTime.now(),
                      );
                      if (pickedStart != null) {
                        final pickedEnd = await showThemedDatePicker(
                          initialDate: pickedStart,
                          firstDate: pickedStart,
                        );
                        sheetSetState(() {
                          tempStartDate = pickedStart;
                          tempEndDate = pickedEnd;
                        });
                      }
                    },
                    trailing: (tempStartDate != null)
                        ? IconButton(
                      icon: const Icon(Icons.clear, color: AppColors.textGray500),
                      onPressed: () => sheetSetState(() {
                        tempStartDate = null;
                        tempEndDate = null;
                      }),
                    )
                        : null,
                    contentPadding: EdgeInsets.zero,
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _showFullRides = tempShowFull;
                          _selectedSort = tempSort;
                          _startDate = tempStartDate;
                          _endDate = tempEndDate;
                        });
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.byuiBlue,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Apply Filters', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildSearchSection() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16.0),
      margin: const EdgeInsets.only(bottom: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: _fromSearchController,
            decoration: InputDecoration(
              hintText: 'FROM - Enter pickup location',
              prefixIcon: const Icon(Icons.location_on, color: AppColors.byuiGreen),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: AppColors.gray50,
              contentPadding: const EdgeInsets.symmetric(vertical: 14.0, horizontal: 10.0),
            ),
          ),
          const SizedBox(height: 12.0),
          TextField(
            controller: _toSearchController,
            decoration: InputDecoration(
              hintText: 'TO - Enter destination',
              prefixIcon: const Icon(Icons.location_on, color: AppColors.red500),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: AppColors.gray50,
              contentPadding: const EdgeInsets.symmetric(vertical: 14.0, horizontal: 10.0),
            ),
          ),
          const SizedBox(height: 16.0),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.filter_list),
                  label: const Text('Filters'),
                  onPressed: _showFilterSheet,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.byuiBlue,
                    side: const BorderSide(color: AppColors.byuiBlue),
                    padding: const EdgeInsets.symmetric(vertical: 14.0),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {}, // search is live already
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.byuiBlue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14.0),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    elevation: 2,
                  ),
                  child: const Text('Search', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRideCard(Ride ride) {
    final bool isRideFull = ride.isFull || ride.availableSeats <= 0;
    final DateTime dep = ride.rideDate.toDate();
    final DateTime? ret = ride.returnDate?.toDate();

    return Card(
      color: Colors.white,
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: InkWell(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => EventRideDetailScreen(ride: ride)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title (unchanged): Event name or fallback
              Text(
                ride.eventName ?? 'Event Ride',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.byuiBlue,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),

              const SizedBox(height: 6),

              // Subtitle: Origin → Destination
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.route, size: 16, color: AppColors.textGray500),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${ride.origin} → ${ride.destination}',
                      style: const TextStyle(fontSize: 14, color: AppColors.textGray600),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 8),

              // Departure
              Row(
                children: [
                  const Icon(Icons.calendar_today, size: 16, color: AppColors.textGray500),
                  const SizedBox(width: 8),
                  Text(
                    'Departure: ${DateFormat('EEE, MMM d').format(dep)} • ${DateFormat('h:mm a').format(dep)}',
                    style: const TextStyle(fontSize: 13, color: AppColors.textGray500),
                  ),
                ],
              ),

              // Return (optional)
              if (ret != null) ...[
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.calendar_today_outlined, size: 16, color: AppColors.textGray500),
                    const SizedBox(width: 8),
                    Text(
                      'Return: ${DateFormat('EEE, MMM d').format(ret)} • ${DateFormat('h:mm a').format(ret)}',
                      style: const TextStyle(fontSize: 13, color: AppColors.textGray500),
                    ),
                  ],
                ),
              ],

              const SizedBox(height: 10),

              // Seats + Driver
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${ride.availableSeats} seats',
                    style: const TextStyle(fontSize: 14, color: AppColors.byuiBlue),
                  ),
                  ProfileChip(
                    userId: ride.driverUid,
                    dense: true,
                    showName: true,
                    maxNameWidth: 120,
                  ),
                ],
              ),

              // FULL badge
              if (isRideFull)
                Align(
                  alignment: Alignment.bottomRight,
                  child: Container(
                    margin: const EdgeInsets.only(top: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.red500,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      'FULL',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                    ),
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
    return Scaffold(
      backgroundColor: AppColors.gray50,
      appBar: AppBar(
        backgroundColor: AppColors.byuiBlue,
        foregroundColor: Colors.white,
        title: const Text('Event Rides'),
        toolbarHeight: 72,
      ),
      body: Column(
        children: [
          _buildSearchSection(),
          Expanded(
            child: StreamBuilder<List<Ride>>(
              stream: RideService.fetchRideListings(
                fromLocation: _fromQuery,
                toLocation: _toQuery,
                showFullRides: _showFullRides,
                startDate: _startDate,
                endDate: _endDate,
                sortOption: _selectedSort,
                isEvent: true, // only event rides
              ),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: Text('No event rides available.'));
                }

                final rides = snapshot.data!;
                return ListView.builder(
                  padding: const EdgeInsets.only(top: 8),
                  itemCount: rides.length,
                  itemBuilder: (_, i) => _buildRideCard(rides[i]),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showModalBottomSheet(
            context: context,
            backgroundColor: Colors.white,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            builder: (context) {
              return SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 24), // was 16
                  child: Wrap(
                    children: <Widget>[
                      ListTile(
                        leading: const Icon(Icons.event, color: AppColors.byuiBlue),
                        title: const Text('Create Event Ride Listing'),
                        onTap: () {
                          Navigator.of(context).pop();
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const CreateEventRideScreen()),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
        backgroundColor: AppColors.byuiBlue,
        shape: const CircleBorder(),
        elevation: 2.0,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,

      // 🔁 Bottom bar now matches ride_list_screen exactly
      bottomNavigationBar: BottomAppBar(
        color: Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: const CircularNotchedRectangle(),
        notchMargin: 8.0,
        elevation: 4.0,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: <Widget>[
            _buildNavButton(
              context,
              icon: Icons.people_alt,
              label: 'Joined Rides',
              route: const MyJoinedRidesScreen(),
            ),
            const SizedBox(width: 48), // spacer for the FAB notch
            _buildNavButton(
              context,
              icon: Icons.directions_car,
              label: 'Offered Rides',
              route: const MyRidesScreen(),
            ),
          ],
        ),
      ),
    );
  }

  // ⬇️ Identical helper to ride_list_screen
  Widget _buildNavButton(BuildContext context, {
    required IconData icon,
    required String label,
    required Widget? route,
  }) {
    return Expanded(
      child: InkWell(
        onTap: () {
          if (route != null) {
            Navigator.push(context, MaterialPageRoute(builder: (context) => route));
          }
        },
        customBorder: const CircleBorder(),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: AppColors.textGray600, size: 20),
              const SizedBox(height: 4),
              Text(label, style: const TextStyle(fontSize: 10, color: AppColors.textGray600)),
            ],
          ),
        ),
      ),
    );
  }
}
