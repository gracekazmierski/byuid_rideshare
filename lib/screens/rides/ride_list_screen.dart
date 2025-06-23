// lib/screens/rides/ride_list_screen.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:byui_rideshare/models/ride.dart';
import 'package:byui_rideshare/services/ride_service.dart';
import 'package:intl/intl.dart';
import 'package:byui_rideshare/screens/rides/create_ride_screen.dart';
import 'package:byui_rideshare/screens/rides/ride_detail_screen.dart';
import 'package:byui_rideshare/screens/rides/my_rides_screen.dart'; // My Posted Rides
import 'package:byui_rideshare/screens/rides/my_joined_rides_screen.dart';
import 'package:byui_rideshare/screens/profile/profile_setup_screen.dart'; // Assuming this is your edit profile screen
import 'package:font_awesome_flutter/font_awesome_flutter.dart'; // For Car icon

// Define colors based on the React design
const Color BYUI_BLUE = Color(0xFF006eb6);
const Color BYUI_BLUE_HOVER = Color(0xFF005a94);
const Color BYUI_GREEN = Color(0xFF2d8f47);
const Color BYUI_RED = Color(0xFFdc3545);
const Color GRAY_50 = Color(0xFFF9FAFB); // Assuming bg-gray-50 from Tailwind
const Color GRAY_500 = Color(0xFF6B7280); // Assuming text-gray-500
const Color GRAY_600 = Color(0xFF4B5563); // Assuming text-gray-600
const Color GRAY_700 = Color(0xFF374151); // Assuming text-gray-700


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
      // Potentially trigger a search here, or when the search button is pressed.
      // For now, the StreamBuilder will react to changes in these state variables.
    });
  }

  @override
  void dispose() {
    _fromSearchController.dispose();
    _toSearchController.dispose();
    super.dispose();
  }

  // --- Widget for the custom AppBar header ---
  PreferredSizeWidget _buildAppBarHeader(BuildContext context) {
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
              IconButton(
                icon: const Icon(Icons.person, color: Colors.white, size: 28),
                tooltip: 'Profile',
                onPressed: () {
                  // Navigate to profile editing or viewing screen
                  // Assuming ProfileSetupScreen can also be used for editing
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const ProfileSetupScreen()),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- Widget for the search input section ---
  Widget _buildSearchSection() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16.0),
      margin: const EdgeInsets.only(bottom: 8.0), // Adds shadow-sm effect spacing
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: _fromSearchController,
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
            controller: _toSearchController,
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
          ElevatedButton(
            onPressed: () {
              // Trigger search based on _fromQuery and _toQuery
              // The StreamBuilder will automatically react to setState
              // For a more explicit search, you could call a function here
              // that updates the stream or re-fetches data.
              // For now, just a visual feedback that button was pressed.
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Searching for rides from $_fromQuery to $_toQuery...')),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: BYUI_BLUE,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14.0),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              // Simulate hover effect for web by using MouseRegion
              // On mobile, this will just be the default press animation.
              elevation: 2, // Tailwind shadow-sm equivalent
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

  // --- Widget for a single Ride Card ---
  Widget _buildRideCard(BuildContext context, Ride ride) {
    final bool isRideFull = ride.isFull || ride.availableSeats <= 0;

    // Get driver initials for avatar
    String driverInitials = ride.driverName
        .split(' ')
        .map((name) => name.isNotEmpty ? name[0] : '')
        .join()
        .toUpperCase();
    if (driverInitials.length > 2) { // Limit to 2 initials if name is very long
      driverInitials = driverInitials.substring(0, 2);
    }
    if (driverInitials.isEmpty) {
      driverInitials = '?'; // Fallback if initials are empty
    }


    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6.0),
      elevation: 2, // Corresponds to shadow-md hover
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
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: GRAY_700),
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
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: GRAY_700),
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
                    '${DateFormat('MMM d yyyy').format(ride.rideDate.toDate())} at ${DateFormat('h:mm a').format(ride.rideDate.toDate())}',
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
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: BYUI_BLUE),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 12, // Corresponds to h-6 w-6
                        backgroundColor: const Color(0xFFe6f1fa), // Similar to #e6f1fa
                        child: Text(
                          driverInitials,
                          style: TextStyle(
                            fontSize: 10, // Text-xs in Tailwind is approx 0.75rem or 12px, so 10-12 is good for initials
                            fontWeight: FontWeight.bold,
                            color: BYUI_BLUE,
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        ride.driverName,
                        style:
                        const TextStyle(fontSize: 12, color: GRAY_500),
                      ),
                    ],
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
              if (isRideFull) // FULL tag
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

  // --- Widget for the custom Bottom Navigation Bar ---
  Widget _buildBottomNavBar() {
    return BottomAppBar(
      color: Colors.white,
      elevation: 4, // border-t and shadow effect
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
                    FaIcon(FontAwesomeIcons.car, size: 20, color: BYUI_BLUE), // Car icon
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
                      height: 24, // h-5 w-5 equivalent icon space
                      width: 24,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: GRAY_600, width: 2), // border-2 border-current
                      ),
                      child: Center(
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
                  MaterialPageRoute(builder: (context) => const ProfileSetupScreen()), // Assuming this is for editing profile
                );
              },
              customBorder: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 6.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Icon(Icons.person, size: 24, color: GRAY_600), // User icon
                    SizedBox(height: 4),
                    Text('Edit Profile', style: TextStyle(fontSize: 10, color: GRAY_600)),
                  ],
                ),
              ),
            ),
          ),
          // Added a "My Joined Rides" button, as it was in your original code
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
                    Icon(Icons.people_alt, size: 24, color: GRAY_600), // People icon
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
      backgroundColor: GRAY_50, // Corresponds to bg-gray-50
      appBar: _buildAppBarHeader(context),
      body: Column(
        children: [
          _buildSearchSection(),
          Expanded(
            child: StreamBuilder<List<Ride>>(
              // Updated to use both search queries
              stream: RideService.fetchRideListings(
                searchQuery: _fromQuery, // Use _fromQuery for now for simplicity
                // If RideService.fetchRideListings needs `from` and `to` separate parameters:
                // fromLocation: _fromQuery,
                // toLocation: _toQuery,
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
                  padding: const EdgeInsets.all(16.0), // p-4
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