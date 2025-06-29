// lib/screens/rides/ride_list_screen.dart
import 'package:byui_rideshare/screens/auth/profile_edit_screen.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:byui_rideshare/models/ride.dart';
import 'package:byui_rideshare/services/ride_service.dart';
import 'package:intl/intl.dart';
import 'package:byui_rideshare/screens/rides/create_ride_screen.dart';
import 'package:byui_rideshare/screens/rides/ride_detail_screen.dart';
import 'package:byui_rideshare/screens/rides/my_rides_screen.dart';
import 'package:byui_rideshare/screens/rides/my_joined_rides_screen.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:byui_rideshare/services/user_service.dart';
import 'package:byui_rideshare/theme/app_colors.dart';

enum SortOption { soonest, latest, lowestFare, highestFare }

class RideListScreen extends StatefulWidget {
  const RideListScreen({super.key});

  @override
  State<RideListScreen> createState() => _RideListScreenState();
}

class _RideListScreenState extends State<RideListScreen> {
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

  void _showFilterSheet() {
    bool tempShowFull = _showFullRides;
    SortOption tempSort = _selectedSort;
    DateTime? tempStartDate = _startDate;
    DateTime? tempEndDate = _endDate;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter sheetSetState) {
            return Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Filters & Sorting',
                      style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 24),
                  CheckboxListTile(
                    title: const Text('Show Full Rides'),
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
                    decoration: const InputDecoration(labelText: 'Sort By'),
                    items: const [
                      DropdownMenuItem(value: SortOption.soonest, child: Text("Soonest First")),
                      DropdownMenuItem(value: SortOption.latest, child: Text("Latest First")),
                      DropdownMenuItem(value: SortOption.lowestFare, child: Text("Lowest Fare")),
                      DropdownMenuItem(value: SortOption.highestFare, child: Text("Highest Fare")),
                    ],
                    onChanged: (val) {
                      sheetSetState(() => tempSort = val ?? SortOption.soonest);
                    },
                  ),
                  const SizedBox(height: 16),
                  const Divider(),
                  ListTile(
                    leading: const Icon(Icons.date_range),
                    title: const Text("Date Range"),
                    subtitle: Text(
                      (tempStartDate == null)
                          ? "Any date"
                          : "${DateFormat('MM/dd/yy').format(tempStartDate!)} - ${DateFormat('MM/dd/yy').format(tempEndDate ?? tempStartDate!)}",
                    ),
                    onTap: () async {
                      final pickedStart = await showDatePicker(context: context, initialDate: DateTime.now(), firstDate: DateTime(2024), lastDate: DateTime(2030));
                      if (pickedStart != null) {
                        final pickedEnd = await showDatePicker(context: context, initialDate: pickedStart, firstDate: pickedStart, lastDate: DateTime(2030));
                        sheetSetState(() {
                          tempStartDate = pickedStart;
                          tempEndDate = pickedEnd;
                        });
                      }
                    },
                    trailing: (tempStartDate != null)
                        ? IconButton(
                      icon: const Icon(Icons.clear),
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
                      style: ElevatedButton.styleFrom(backgroundColor: AppColors.byuiBlue, foregroundColor: Colors.white),
                      child: const Text('Apply Filters'),
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

  PreferredSizeWidget _buildAppBarHeader(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;
    return PreferredSize(
      preferredSize: const Size.fromHeight(kToolbarHeight + 10),
      child: Container(
        color: AppColors.byuiBlue,
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6.0),
        child: SafeArea(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('RexRide', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
                  Text('Find your ride', style: TextStyle(fontSize: 14, color: Colors.white70)),
                ],
              ),
              Row(
                children: [
                  if (currentUser != null)
                    IconButton(
                      icon: const Icon(Icons.account_circle, color: Colors.white, size: 28),
                      tooltip: "Edit Profile",
                      onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const ProfileEditScreen())),
                    ),
                  IconButton(
                    icon: const Icon(Icons.directions_car_filled_outlined, color: Colors.white, size: 28),
                    tooltip: 'My Posted Rides',
                    onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const MyRidesScreen())),
                  ),
                  IconButton(
                    icon: const Icon(Icons.event_seat, color: Colors.white, size: 28),
                    tooltip: "My Joined Rides",
                    onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const MyJoinedRidesScreen())),
                  ),
                  IconButton(
                    icon: const Icon(Icons.logout, color: Colors.white, size: 28),
                    tooltip: 'Logout',
                    onPressed: () async => await FirebaseAuth.instance.signOut(),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
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
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
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
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
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
                  onPressed: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Searching with applied filters...'))),
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

  Widget _buildRideCard(BuildContext context, Ride ride) {
    final bool isRideFull = ride.isFull || ride.availableSeats <= 0;
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6.0),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: InkWell(
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => RideDetailScreen(ride: ride))),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Container(
                      width: 8, height: 8,
                      decoration: BoxDecoration(color: AppColors.byuiGreen, borderRadius: BorderRadius.circular(4)),
                      margin: const EdgeInsets.only(right: 8),
                    ),
                    Text(ride.origin, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.gray700)),
                  ]),
                  const SizedBox(height: 4),
                  Row(children: [
                    Container(
                      width: 8, height: 8,
                      decoration: BoxDecoration(color: AppColors.red500, borderRadius: BorderRadius.circular(4)),
                      margin: const EdgeInsets.only(right: 8),
                    ),
                    Text(ride.destination, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.gray700)),
                  ]),
                ],
              ),
              const SizedBox(height: 12),
              Row(children: [
                const Icon(Icons.calendar_today, size: 16, color: AppColors.textGray500),
                const SizedBox(width: 8),
                Text('${DateFormat('MMM d hh:mm a').format(ride.rideDate.toDate())}', style: const TextStyle(fontSize: 14, color: AppColors.textGray500)),
              ]),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(children: [
                    const Icon(Icons.group, size: 16, color: AppColors.byuiBlue),
                    const SizedBox(width: 8),
                    Text('${ride.availableSeats} seat${ride.availableSeats != 1 ? "s" : ""} available', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.byuiBlue)),
                  ]),
                  FutureBuilder<String?>(
                    future: UserService.getUserName(ride.driverUid),
                    builder: (context, snapshot) {
                      final name = snapshot.data ?? "Unknown Driver";
                      String initials = name.split(' ').map((w) => w.isNotEmpty ? w[0] : '').join().toUpperCase();
                      if (initials.length > 2) initials = initials.substring(0, 2);
                      if (initials.isEmpty) initials = '?';
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Row(children: [
                          CircleAvatar(radius: 12, backgroundColor: Color(0xFFe6f1fa), child: CircularProgressIndicator(strokeWidth: 2)),
                          SizedBox(width: 4),
                          Text("Loading...", style: TextStyle(fontSize: 12, color: AppColors.textGray500)),
                        ]);
                      }
                      return Row(children: [
                        CircleAvatar(
                          radius: 12,
                          backgroundColor: const Color(0xFFe6f1fa),
                          child: Text(initials, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.byuiBlue)),
                        ),
                        const SizedBox(width: 4),
                        Text(name, style: const TextStyle(fontSize: 12, color: AppColors.textGray500)),
                      ]);
                    },
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text('Fare: \$${ride.fare?.toStringAsFixed(2) ?? 'N/A'}', style: const TextStyle(fontSize: 14)),
              Text('Posted: ${DateFormat('MMM d, h:mm a').format(ride.postCreationTime.toDate())}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
              if (isRideFull)
                Align(
                  alignment: Alignment.bottomRight,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(color: AppColors.red500, borderRadius: BorderRadius.circular(4)),
                    child: const Text('FULL', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomNavBar() {
    return BottomAppBar(
      color: Colors.white,
      elevation: 4,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          Expanded(child: InkWell(
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const MyRidesScreen())),
            customBorder: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            child: const Padding(
              padding: EdgeInsets.symmetric(vertical: 6.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  FaIcon(FontAwesomeIcons.car, size: 20, color: AppColors.byuiBlue),
                  SizedBox(height: 4),
                  Text('My Posted Rides', style: TextStyle(fontSize: 10, color: AppColors.byuiBlue)),
                ],
              ),
            ),
          )),
          Expanded(child: InkWell(
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const CreateRideScreen())),
            customBorder: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 6.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    height: 24, width: 24,
                    decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.textGray600, width: 2)),
                    child: const Center(child: Text('+', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textGray600))),
                  ),
                  const SizedBox(height: 4),
                  const Text('Offer a Ride', style: TextStyle(fontSize: 10, color: AppColors.textGray600)),
                ],
              ),
            ),
          )),
          Expanded(child: InkWell(
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const ProfileEditScreen())),
            customBorder: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            child: const Padding(
              padding: EdgeInsets.symmetric(vertical: 6.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.person, size: 24, color: AppColors.textGray600),
                  SizedBox(height: 4),
                  Text('Edit Profile', style: TextStyle(fontSize: 10, color: AppColors.textGray600)),
                ],
              ),
            ),
          )),
          Expanded(child: InkWell(
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const MyJoinedRidesScreen())),
            customBorder: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            child: const Padding(
              padding: EdgeInsets.symmetric(vertical: 6.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.people_alt, size: 24, color: AppColors.textGray600),
                  SizedBox(height: 4),
                  Text('My Joined Rides', style: TextStyle(fontSize: 10, color: AppColors.textGray600)),
                ],
              ),
            ),
          )),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.gray50,
      appBar: _buildAppBarHeader(context),
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
              ),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: Text('No rides available. Be the first to post one!'));
                }
                final rides = snapshot.data!;
                return ListView.builder(
                  padding: const EdgeInsets.all(16.0),
                  itemCount: rides.length,
                  itemBuilder: (context, index) => _buildRideCard(context, rides[index]),
                );
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomNavBar(),
    );
  }
}