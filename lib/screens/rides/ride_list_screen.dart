// lib/screens/rides/ride_list_screen.dart

import 'package:byui_rideshare/screens/rides/ride_request_list_screen.dart';
import 'package:byui_rideshare/screens/auth/profile_edit_screen.dart';
import 'package:byui_rideshare/screens/rides/create_ride_request_screen.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:byui_rideshare/models/ride.dart';
import 'package:byui_rideshare/services/ride_service.dart';
import 'package:intl/intl.dart';
import 'package:byui_rideshare/screens/rides/create_ride_screen.dart';
import 'package:byui_rideshare/screens/rides/ride_detail_screen.dart';
import 'package:byui_rideshare/screens/rides/my_rides_screen.dart';
import 'package:byui_rideshare/screens/rides/my_joined_rides_screen.dart';
import 'package:byui_rideshare/services/user_service.dart';
import 'package:byui_rideshare/theme/app_colors.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:byui_rideshare/models/sort_option.dart';

class RideListScreen extends StatefulWidget {
  const RideListScreen({super.key});

  @override
  State<RideListScreen> createState() => _RideListScreenState();
}

class _RideListScreenState extends State<RideListScreen> {
  // This method handles the popup for offering or requesting a ride.
  void _showCreateDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext bc) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Wrap(
              children: <Widget>[
                ListTile(
                  leading: const Icon(Icons.directions_car, color: AppColors.byuiBlue),
                  title: const Text('Offer a Ride'),
                  onTap: () {
                    Navigator.of(context).pop();
                    Navigator.push(context, MaterialPageRoute(builder: (context) => const CreateRideScreen()));
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.hail, color: AppColors.byuiBlue),
                  title: const Text('Request a Ride'),
                  onTap: () {
                    Navigator.of(context).pop();
                    Navigator.push(context, MaterialPageRoute(builder: (context) => const CreateRideRequestScreen()));
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: AppColors.gray50,
        appBar: AppBar(
          automaticallyImplyLeading: false,
          backgroundColor: AppColors.byuiBlue,
          foregroundColor: Colors.white,
          title: const Text('RexRide'),
          actions: [
            IconButton(
              icon: const Icon(Icons.account_circle, size: 28),
              tooltip: "My Profile",
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const ProfileEditScreen())),
            ),
            IconButton(
              icon: const Icon(Icons.logout, size: 28),
              tooltip: 'Logout',
              onPressed: () async => await FirebaseAuth.instance.signOut(),
            ),
          ],
          bottom: const PreferredSize(
            preferredSize: Size.fromHeight(40.0),
            child: TabBar(
              tabs: [
                Tab(text: 'Ride Offers'),
                Tab(text: 'Ride Requests'),
              ],
              indicatorColor: Colors.white,
              indicatorWeight: 3.0,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white70,
            ),
          ),
        ),
        body: const TabBarView(
          children: [
            RideOffersList(),
            RideRequestListScreen(),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () => _showCreateDialog(context),
          backgroundColor: AppColors.byuiBlue,
          shape: const CircleBorder(),
          elevation: 2.0, // A subtle shadow to lift it slightly
          child: const Icon(Icons.add, color: Colors.white),
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
        bottomNavigationBar: BottomAppBar(
          color: Colors.white,
          surfaceTintColor: Colors.transparent,
          shape: const CircularNotchedRectangle(), // Creates the notch for the FAB.
          notchMargin: 8.0,
          elevation: 4.0, // Gives a slight shadow below the bar.
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: <Widget>[
              _buildNavButton(
                  context,
                  icon: Icons.people_alt,
                  label: 'Joined Rides',
                  route: const MyJoinedRidesScreen()
              ),
              // This SizedBox acts as a spacer, pushing the next button to the other side of the notch.
              const SizedBox(width: 48),
              _buildNavButton(
                  context,
                  icon: FontAwesomeIcons.car,
                  label: 'Offered Rides',
                  route: const MyRidesScreen()
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Helper widget for the bottom navigation buttons with labels.
  Widget _buildNavButton(BuildContext context, {required IconData icon, required String label, required Widget? route}) {
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
              FaIcon(icon, color: AppColors.textGray600, size: 20),
              const SizedBox(height: 4),
              Text(label, style: const TextStyle(fontSize: 10, color: AppColors.textGray600)),
            ],
          ),
        ),
      ),
    );
  }
}

class RideOffersList extends StatefulWidget {
  const RideOffersList({super.key});
  @override
  State<RideOffersList> createState() => _RideOffersListState();
}

class _RideOffersListState extends State<RideOffersList> {
  // All your state variables and methods remain unchanged...
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
          borderSide: const BorderSide(color: AppColors.gray300)
      ),
      focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.0),
          borderSide: const BorderSide(color: AppColors.byuiBlue, width: 2.0)
      ),
    );
  }

  void _showFilterSheet() {
    // ... your _showFilterSheet method is unchanged ...
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
              padding: EdgeInsets.fromLTRB(24, 8, 24, MediaQuery
                  .of(context)
                  .viewInsets
                  .bottom + 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(child: Container(width: 40,
                      height: 5,
                      margin: const EdgeInsets.only(bottom: 20),
                      decoration: BoxDecoration(color: AppColors.gray300,
                          borderRadius: BorderRadius.circular(10)))),
                  const Text('Filters & Sorting', style: TextStyle(fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textGray600)),
                  const SizedBox(height: 24),
                  CheckboxListTile(
                    title: const Text('Show Full Rides',
                        style: TextStyle(color: AppColors.textGray600)),
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
                      DropdownMenuItem(value: SortOption.soonest,
                          child: Text("Soonest First")),
                      DropdownMenuItem(value: SortOption.latest,
                          child: Text("Latest First")),
                      DropdownMenuItem(value: SortOption.lowestFare,
                          child: Text("Lowest Fare")),
                      DropdownMenuItem(value: SortOption.highestFare,
                          child: Text("Highest Fare")),
                    ],
                    onChanged: (val) {
                      sheetSetState(() => tempSort = val ?? SortOption.soonest);
                    },
                  ),
                  const SizedBox(height: 16),
                  const Divider(),
                  ListTile(
                    leading: const Icon(
                        Icons.date_range, color: AppColors.textGray500),
                    title: const Text("Date Range",
                        style: TextStyle(color: AppColors.textGray500)),
                    subtitle: Text(
                        (tempStartDate == null) ? "Any date" : "${DateFormat(
                            'MM/dd/yy').format(tempStartDate!)} - ${DateFormat(
                            'MM/dd/yy').format(tempEndDate ?? tempStartDate!)}",
                        style: const TextStyle(color: AppColors.textGray600,
                            fontWeight: FontWeight.bold)),
                    onTap: () async {
                      final pickedStart = await showThemedDatePicker(
                          initialDate: tempStartDate ?? DateTime.now(),
                          firstDate: DateTime.now());
                      if (pickedStart != null) {
                        final pickedEnd = await showThemedDatePicker(
                            initialDate: pickedStart, firstDate: pickedStart);
                        sheetSetState(() {
                          tempStartDate = pickedStart;
                          tempEndDate = pickedEnd;
                        });
                      }
                    },
                    trailing: (tempStartDate != null) ? IconButton(
                        icon: const Icon(
                            Icons.clear, color: AppColors.textGray500),
                        onPressed: () =>
                            sheetSetState(() {
                              tempStartDate = null;
                              tempEndDate = null;
                            })) : null,
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
                          foregroundColor: Colors.white),
                      child: const Text('Apply Filters',
                          style: TextStyle(fontWeight: FontWeight.bold)),
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
          TextField(controller: _fromSearchController,
              decoration: InputDecoration(
                  hintText: 'FROM - Enter pickup location',
                  prefixIcon: const Icon(
                      Icons.location_on, color: AppColors.byuiGreen),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none),
                  filled: true,
                  fillColor: AppColors.gray50,
                  contentPadding: const EdgeInsets.symmetric(
                      vertical: 14.0, horizontal: 10.0))),
          const SizedBox(height: 12.0),
          TextField(controller: _toSearchController,
              decoration: InputDecoration(hintText: 'TO - Enter destination',
                  prefixIcon: const Icon(
                      Icons.location_on, color: AppColors.red500),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none),
                  filled: true,
                  fillColor: AppColors.gray50,
                  contentPadding: const EdgeInsets.symmetric(
                      vertical: 14.0, horizontal: 10.0))),
          const SizedBox(height: 16.0),
          Row(
            children: [
              Expanded(child: OutlinedButton.icon(
                  icon: const Icon(Icons.filter_list),
                  label: const Text('Filters'),
                  onPressed: _showFilterSheet,
                  style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.byuiBlue,
                      side: const BorderSide(color: AppColors.byuiBlue),
                      padding: const EdgeInsets.symmetric(vertical: 14.0),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8))))),
              const SizedBox(width: 12),
              Expanded(child: ElevatedButton(onPressed: () {},
                  style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.byuiBlue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14.0),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                      elevation: 2),
                  child: const Text('Search', style: TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w600)))),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRideCard(BuildContext context, Ride ride) {
    final bool isRideFull = ride.isFull || ride.availableSeats <= 0;
    return Card(
      color: Colors.white,
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: InkWell(
        splashFactory: NoSplash.splashFactory,
        highlightColor: Colors.transparent,
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
                    Container(width: 8, height: 8, decoration: BoxDecoration(color: AppColors.byuiGreen, borderRadius: BorderRadius.circular(4)), margin: const EdgeInsets.only(right: 8)),
                    Text(ride.origin, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.gray700)),
                  ]),
                  const SizedBox(height: 4),
                  Row(children: [
                    Container(width: 8, height: 8, decoration: BoxDecoration(color: AppColors.red500, borderRadius: BorderRadius.circular(4)), margin: const EdgeInsets.only(right: 8)),
                    Text(ride.destination, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.gray700)),
                  ]),
                ],
              ),
              const SizedBox(height: 12),
              Row(children: [
                const Icon(Icons.calendar_today, size: 16, color: AppColors.textGray500),
                const SizedBox(width: 8),
                Text(DateFormat('MMM d hh:mm a').format(ride.rideDate.toDate()), style: const TextStyle(fontSize: 14, color: AppColors.textGray500)),
              ]),
              const SizedBox(height: 12),

              // ✅ THIS IS THE CORRECTED ROW
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // This part is unchanged
                  Row(children: [
                    const Icon(Icons.group, size: 16, color: AppColors.byuiBlue),
                    const SizedBox(width: 8),
                    Text('${ride.availableSeats} seat${ride.availableSeats != 1 ? "s" : ""} available', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.byuiBlue)),
                  ]),

                  // This FutureBuilder now correctly handles layout
                  FutureBuilder<String?>(
                    future: UserService.getUserName(ride.driverUid),
                    builder: (context, snapshot) {
                      final name = snapshot.data ?? "Unknown Driver";
                      String initials = name.split(' ').map((w) => w.isNotEmpty ? w[0] : '').join().toUpperCase();
                      if (initials.length > 2) initials = initials.substring(0, 2);
                      if (initials.isEmpty) initials = '?';

                      return Row(
                        mainAxisSize: MainAxisSize.min, // Important for Flexible to work
                        children: [
                          CircleAvatar(
                            radius: 12,
                            backgroundColor: const Color(0xFFe6f1fa),
                            child: Text(initials, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.byuiBlue)),
                          ),
                          const SizedBox(width: 4),
                          // Flexible now wraps only the Text, allowing it to truncate
                          // without breaking the parent Row's alignment.
                          Flexible(
                            child: Text(
                              name,
                              style: const TextStyle(fontSize: 12, color: AppColors.textGray500),
                              overflow: TextOverflow.ellipsis,
                              softWrap: false,
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text('Fare: \$${ride.fare?.toStringAsFixed(2) ?? 'N/A'}', style: const TextStyle(fontSize: 14)),
              Text('Posted: ${DateFormat('MMM d, h:mm a').format(ride.postCreationTime.toDate())}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
              if (isRideFull)
                Align(alignment: Alignment.bottomRight, child: Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: AppColors.red500, borderRadius: BorderRadius.circular(4)), child: const Text('FULL', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)))),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
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
              // ✅ SAFER CHECK: This prevents the crash by checking for null explicitly.
              if (!snapshot.hasData || snapshot.data == null ||
                  snapshot.data!.isEmpty) {
                return const Center(child: Text('No rides currently offered.'));
              }

              // This is now safe
              final rides = snapshot.data!;

              return ListView.builder(
                padding: const EdgeInsets.only(top: 8),
                itemCount: rides.length,
                itemBuilder: (context, index) =>
                    _buildRideCard(context, rides[index]),
              );
            },
          ),
        ),
      ],
    );
  }
}
