// lib/screens/rides/ride_list_screen.dart
import 'package:byui_rideshare/screens/auth/profile_edit_screen.dart'; // From main
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:byui_rideshare/models/ride.dart';
import 'package:byui_rideshare/services/ride_service.dart';
import 'package:intl/intl.dart';
import 'package:byui_rideshare/screens/rides/create_ride_screen.dart';
import 'package:byui_rideshare/screens/rides/ride_detail_screen.dart';
import 'package:byui_rideshare/screens/rides/my_rides_screen.dart'; // My Posted Rides
import 'package:byui_rideshare/screens/rides/my_joined_rides_screen.dart';
import 'package:byui_rideshare/screens/profile/profile_setup_screen.dart'; // Assuming this is your edit profile screen - From Grace
import 'package:font_awesome_flutter/font_awesome_flutter.dart'; // For Car icon - From Grace
import 'package:byui_rideshare/services/user_service.dart';

// Define colors based on the React design - From Grace
const Color BYUI_BLUE = Color(0xFF006eb6);
const Color BYUI_BLUE_HOVER = Color(0xFF005a94);
const Color BYUI_GREEN = Color(0xFF2d8f47);
const Color BYUI_RED = Color(0xFFdc3545);
const Color GRAY_50 = Color(0xFFF9FAFB); // Assuming bg-gray-50 from Tailwind
const Color GRAY_500 = Color(0xFF6B7280); // Assuming text-gray-500
const Color GRAY_600 = Color(0xFF4B5563); // Assuming text-gray-600
const Color GRAY_700 = Color(0xFF374151); // Assuming text-gray-700

// State variables from main
bool _showFullRides = true;
SortOption _selectedSort = SortOption.soonest;
DateTime? _startDate;
DateTime? _endDate;
enum SortOption { soonest, latest, lowestFare, highestFare } // From main

class RideListScreen extends StatefulWidget {
  const RideListScreen({super.key});

  @override
  State<RideListScreen> createState() => _RideListScreenState();
}

class _RideListScreenState extends State<RideListScreen> {
  // From Grace
  final TextEditingController _fromSearchController = TextEditingController();
  final TextEditingController _toSearchController = TextEditingController();
  String _fromQuery = '';
  String _toQuery = '';

  // From main - These are now part of the class state
  // bool _showFullRides = true; // Moved to global scope based on main's initial placement, but better as class member
  // SortOption _selectedSort = SortOption.soonest; // Moved to global scope
  // DateTime? _startDate; // Moved to global scope
  // DateTime? _endDate; // Moved to global scope

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

  // --- Widget for the custom AppBar header --- (Merged Grace's design with main's actions)
  PreferredSizeWidget _buildAppBarHeader(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser; // Get current user

    return PreferredSize(
      preferredSize: const Size.fromHeight(kToolbarHeight + 10), // Adjust height as needed
      child: Container(
        color: BYUI_BLUE,
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6.0),
        child: SafeArea(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Text(
                    'BYUI Rideshare',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    'Find your ride',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
              // Actions from 'main' branch integrated here
              Row(
                children: [
                  if (currentUser != null)
                    IconButton(
                      icon: const Icon(Icons.account_circle, color: Colors.white, size: 28), // Consistent sizing
                      tooltip: "Edit Profile",
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const ProfileEditScreen()),
                        );
                      },
                    ),
                  IconButton(
                    icon: const Icon(Icons.directions_car_filled_outlined, color: Colors.white, size: 28), // Consistent sizing
                    tooltip: 'My Posted Rides',
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const MyRidesScreen()),
                      );
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.event_seat, color: Colors.white, size: 28), // Consistent sizing
                    tooltip: "My Joined Rides",
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const MyJoinedRidesScreen()),
                      );
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.logout, color: Colors.white, size: 28), // Consistent sizing
                    tooltip: 'Logout', // Added tooltip for clarity
                    onPressed: () async {
                      await FirebaseAuth.instance.signOut();
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- Widget for the search input section --- (Merged Grace's design with main's filters)
  Widget _buildSearchSection() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16.0),
      margin: const EdgeInsets.only(bottom: 8.0), // Adds shadow-sm effect spacing
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: _fromSearchController, // Using Grace's controller
            decoration: InputDecoration(
              hintText: 'FROM - Enter pickup location',
              prefixIcon: Icon(Icons.location_on, color: BYUI_GREEN),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide.none, // No border lines
              ),
              filled: true,
              fillColor: GRAY_50, // Lighter background for input
              contentPadding: const EdgeInsets.symmetric(vertical: 14.0, horizontal: 10.0),
            ),
          ),
          const SizedBox(height: 12.0),
          TextField(
            controller: _toSearchController, // Using Grace's controller
            decoration: InputDecoration(
              hintText: 'TO - Enter destination',
              prefixIcon: Icon(Icons.location_on, color: BYUI_RED),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: GRAY_50,
              contentPadding: const EdgeInsets.symmetric(vertical: 14.0, horizontal: 10.0),
            ),
          ),
          const SizedBox(height: 16.0),
          // Filtering and Sorting options from 'main' branch
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Checkbox(
                    value: _showFullRides,
                    onChanged: (val) {
                      setState(() {
                        _showFullRides = val!;
                      });
                    },
                  ),
                  const Text('Show Full Rides'),
                ],
              ),
              Row(
                children: [
                  DropdownButton<SortOption>(
                    value: _selectedSort,
                    onChanged: (SortOption? newValue) {
                      if (newValue != null) {
                        setState(() {
                          _selectedSort = newValue;
                        });
                      }
                    },
                    items: const [
                      DropdownMenuItem(
                        value: SortOption.soonest,
                        child: Text("Soonest First"),
                      ),
                      DropdownMenuItem(
                        value: SortOption.latest,
                        child: Text("Latest First"),
                      ),
                      DropdownMenuItem(
                        value: SortOption.lowestFare,
                        child: Text("Lowest Fare"),
                      ),
                      DropdownMenuItem(
                        value: SortOption.highestFare,
                        child: Text("Highest Fare"),
                      ),
                    ],
                  )
                ],
              ),
              TextButton(
                onPressed: () async {
                  final pickedStart = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now(),
                    firstDate: DateTime(2024),
                    lastDate: DateTime(2030),
                  );
                  if (pickedStart != null) {
                    final pickedEnd = await showDatePicker(
                      context: context,
                      initialDate: pickedStart,
                      firstDate: pickedStart,
                      lastDate: DateTime(2030),
                    );
                    setState(() {
                      _startDate = pickedStart;
                      _endDate = pickedEnd;
                    });
                  }
                },
                child: Text(_startDate == null ? "Select Date Range" : "${DateFormat('MM/dd').format(_startDate!)} - ${DateFormat('MM/dd').format(_endDate ?? _startDate!)}"), // Display selected range
              )
            ],
          ),
          const SizedBox(height: 16.0),
          ElevatedButton(
            onPressed: () {
              // The StreamBuilder will automatically react to changes in state variables
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                    content: Text(
                        'Searching for rides from $_fromQuery to $_toQuery with filters...') // Updated message
                    ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: BYUI_BLUE,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14.0),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              elevation: 2,
            ),
            child: const Text(
              'Search Rides',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  // --- Widget for a single Ride Card --- (Grace's version, assume it's preferred)
  Widget _buildRideCard(BuildContext context, Ride ride) {
    final bool isRideFull = ride.isFull || ride.availableSeats <= 0;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6.0),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => RideDetailScreen(ride: ride),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Route
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: BYUI_GREEN,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        margin: const EdgeInsets.only(right: 8),
                      ),
                      Text(
                        ride.origin,
                        style: const TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w500, color: GRAY_700),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: BYUI_RED,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        margin: const EdgeInsets.only(right: 8),
                      ),
                      Text(
                        ride.destination,
                        style: const TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w500, color: GRAY_700),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Date / Time
              Row(
                children: [
                  const Icon(Icons.calendar_today, size: 16, color: GRAY_500),
                  const SizedBox(width: 8),
                  Text(
                    '${DateFormat('MMM d hh:mm a').format(ride.rideDate.toDate())}',
                    style: const TextStyle(fontSize: 14, color: GRAY_500),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Seats & Driver
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(Icons.group, size: 16, color: BYUI_BLUE),
                      const SizedBox(width: 8),
                      Text(
                        '${ride.availableSeats} seat${ride.availableSeats != 1 ? "s" : ""} available',
                        style: TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w500, color: BYUI_BLUE),
                      ),
                    ],
                  ),
                  FutureBuilder<String?>(
                    future: UserService.getUserName(ride.driverUid),
                    builder: (context, snapshot) {
                      final name = snapshot.data ?? "Unknown Driver";

                      // Calculate initials
                      String initials = name
                          .split(' ')
                          .map((word) => word.isNotEmpty ? word[0] : '')
                          .join()
                          .toUpperCase();
                      if (initials.length > 2) initials = initials.substring(0, 2);
                      if (initials.isEmpty) initials = '?';

                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Row(
                          children: [
                            CircleAvatar(
                              radius: 12,
                              backgroundColor: Color(0xFFe6f1fa),
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                            SizedBox(width: 4),
                            Text("Loading...", style: TextStyle(fontSize: 12, color: GRAY_500)),
                          ],
                        );
                      }

                      return Row(
                        children: [
                          CircleAvatar(
                            radius: 12,
                            backgroundColor: const Color(0xFFe6f1fa),
                            child: Text(
                              initials,
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: BYUI_BLUE,
                              ),
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            name,
                            style: const TextStyle(fontSize: 12, color: GRAY_500),
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
              // Retaining fare and posted time as per original Flutter code
              const SizedBox(height: 8),
              Text(
                'Fare: \$${ride.fare?.toStringAsFixed(2) ?? 'N/A'}',
                style: const TextStyle(fontSize: 14),
              ),
              Text(
                'Posted: ${DateFormat('MMM d, h:mm a').format(ride.postCreationTime.toDate())}',
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                ),
              ),
              if (isRideFull)
                Align(
                  alignment: Alignment.bottomRight,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: BYUI_RED,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      'FULL',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  // --- Widget for the custom Bottom Navigation Bar --- (Grace's version)
  Widget _buildBottomNavBar() {
    return BottomAppBar(
      color: Colors.white,
      elevation: 4,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          Expanded(
            child: InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const MyRidesScreen()),
                );
              },
              customBorder: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 6.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    FaIcon(FontAwesomeIcons.car, size: 20, color: BYUI_BLUE),
                    SizedBox(height: 4),
                    Text('My Posted Rides', style: TextStyle(fontSize: 10, color: BYUI_BLUE)),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const CreateRideScreen()),
                );
              },
              customBorder: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 6.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      height: 24,
                      width: 24,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: GRAY_600, width: 2),
                      ),
                      child: const Center(
                        child: Text(
                          '+',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: GRAY_600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text('Offer a Ride', style: TextStyle(fontSize: 10, color: GRAY_600)),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const ProfileEditScreen()),
                );
              },
              customBorder: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 6.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Icon(Icons.person, size: 24, color: GRAY_600),
                    SizedBox(height: 4),
                    Text('Edit Profile', style: TextStyle(fontSize: 10, color: GRAY_600)),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const MyJoinedRidesScreen()),
                );
              },
              customBorder: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 6.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Icon(Icons.people_alt, size: 24, color: GRAY_600),
                    SizedBox(height: 4),
                    Text('My Joined Rides', style: TextStyle(fontSize: 10, color: GRAY_600)),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: GRAY_50,
      appBar: _buildAppBarHeader(context),
      body: Column(
        children: [
          _buildSearchSection(),
          Expanded(
            child: StreamBuilder<List<Ride>>(
              // Updated to use both search queries and filters/sort options
              stream: RideService.fetchRideListings(
                fromLocation: _fromQuery, // Now correctly using 'from'
                toLocation: _toQuery, // Now correctly using 'to'
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
                  return const Center(
                    child: Text('No rides available. Be the first to post one!'),
                  );
                }

                final rides = snapshot.data!;

                return ListView.builder(
                  padding: const EdgeInsets.all(16.0),
                  itemCount: rides.length,
                  itemBuilder: (context, index) {
                    final ride = rides[index];
                    return _buildRideCard(context, ride);
                  },
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