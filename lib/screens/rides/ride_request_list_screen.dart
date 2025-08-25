import 'package:byui_rideshare/models/posted_request.dart';
import 'package:byui_rideshare/models/sort_option.dart';
import 'package:byui_rideshare/screens/rides/fulfill_request_screen.dart';
import 'package:byui_rideshare/screens/rides/posted_request_detail_screen.dart';
import 'package:byui_rideshare/services/posted_request_service.dart';
import 'package:byui_rideshare/services/user_service.dart';
import 'package:byui_rideshare/theme/app_colors.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:byui_rideshare/models/request_sort_option.dart';
import 'package:byui_rideshare/screens/rides/join_request_confirmation_screen.dart';

class RideRequestListScreen extends StatefulWidget {
  const RideRequestListScreen({super.key});
  @override
  State<RideRequestListScreen> createState() => _RideRequestListScreenState();
}

class _RideRequestListScreenState extends State<RideRequestListScreen> {
  // ✅ State variables to match the Offers screen UI
  final TextEditingController _fromSearchController = TextEditingController();
  final TextEditingController _toSearchController = TextEditingController();
  String _fromQuery = '';
  String _toQuery = '';
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
      _fromQuery = _fromSearchController.text.trim().toLowerCase();
      _toQuery = _toSearchController.text.trim().toLowerCase();
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
      labelStyle: const TextStyle(color: AppColors.textGray600),
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

  // ✅ Detailed filter sheet from the Offers screen, adapted for Requests
  void _showFilterSheet() {
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
            Future<DateTime?> showThemedDatePicker({
              required DateTime initialDate,
              required DateTime firstDate,
            }) async {
              return await showDatePicker(
                context: context,
                initialDate: initialDate,
                firstDate: firstDate,
                lastDate: DateTime(2030),
                builder:
                    (context, child) => Theme(
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
                    ),
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
                  DropdownButtonFormField<SortOption>(
                    value: tempSort,
                    decoration: _inputDecoration(labelText: 'Sort By'),
                    // Fare options are removed as they don't apply to requests
                    items: const [
                      DropdownMenuItem(
                        value: SortOption.soonest,
                        child: Text("Soonest First"),
                      ),
                      DropdownMenuItem(
                        value: SortOption.latest,
                        child: Text("Latest First"),
                      ),
                    ],
                    onChanged: (val) {
                      sheetSetState(() => tempSort = val ?? SortOption.soonest);
                    },
                  ),
                  const SizedBox(height: 16),
                  const Divider(),
                  ListTile(
                    leading: const Icon(
                      Icons.date_range,
                      color: AppColors.textGray500,
                    ),
                    title: const Text(
                      "Date Range",
                      style: TextStyle(color: AppColors.textGray500),
                    ),
                    subtitle: Text(
                      (tempStartDate == null)
                          ? "Any date"
                          : "${DateFormat('MM/dd/yy').format(tempStartDate!)} - ${DateFormat('MM/dd/yy').format(tempEndDate ?? tempStartDate!)}",
                      style: const TextStyle(
                        color: AppColors.textGray600,
                        fontWeight: FontWeight.bold,
                      ),
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
                    trailing:
                        (tempStartDate != null)
                            ? IconButton(
                              icon: const Icon(
                                Icons.clear,
                                color: AppColors.textGray500,
                              ),
                              onPressed:
                                  () => sheetSetState(() {
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
                      child: const Text(
                        'Apply Filters',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
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

  // ✅ This is your original, detailed search section.
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
              prefixIcon: const Icon(
                Icons.location_on,
                color: AppColors.byuiGreen,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: AppColors.gray50,
              contentPadding: const EdgeInsets.symmetric(
                vertical: 14.0,
                horizontal: 10.0,
              ),
            ),
          ),
          const SizedBox(height: 12.0),
          TextField(
            controller: _toSearchController,
            decoration: InputDecoration(
              hintText: 'TO - Enter destination',
              prefixIcon: const Icon(
                Icons.location_on,
                color: AppColors.red500,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: AppColors.gray50,
              contentPadding: const EdgeInsets.symmetric(
                vertical: 14.0,
                horizontal: 10.0,
              ),
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
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.byuiBlue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14.0),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    elevation: 2,
                  ),
                  child: const Text(
                    'Search',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // In lib/screens/rides/ride_request_list_screen.dart -> _RideRequestListScreenState

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildSearchSection(),
        Expanded(
          child: StreamBuilder<List<PostedRequest>>(
            // ✅ The stream call is now simpler.
            stream: PostedRequestService.fetchRideRequests(),
            builder: (
              BuildContext context,
              AsyncSnapshot<List<PostedRequest>> snapshot,
            ) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                print("Firestore Error: ${snapshot.error}");
                return const Center(child: Text('Error loading requests.'));
              }
              if (!snapshot.hasData ||
                  snapshot.data == null ||
                  snapshot.data!.isEmpty) {
                return const Center(
                  child: Text('No active ride requests found.'),
                );
              }

              var allRequests = snapshot.data!;

              // ✅ All filtering and sorting logic now happens here, inside the app.
              final filteredList =
                  allRequests.where((req) {
                    final fromMatch =
                        _fromQuery.isEmpty ||
                        req.fromLocation.toLowerCase().contains(_fromQuery);
                    final toMatch =
                        _toQuery.isEmpty ||
                        req.toLocation.toLowerCase().contains(_toQuery);

                    final date = req.requestDate.toDate();
                    final startDateMatch =
                        _startDate == null ||
                        !date.isBefore(
                          DateTime(
                            _startDate!.year,
                            _startDate!.month,
                            _startDate!.day,
                          ),
                        );
                    final endDateMatch =
                        _endDate == null ||
                        !date.isAfter(
                          DateTime(
                            _endDate!.year,
                            _endDate!.month,
                            _endDate!.day,
                            23,
                            59,
                            59,
                          ),
                        );

                    return fromMatch &&
                        toMatch &&
                        startDateMatch &&
                        endDateMatch;
                  }).toList();

              // Sorting the filtered list
              filteredList.sort((a, b) {
                switch (_selectedSort) {
                  case SortOption.latest:
                    return b.requestDate.compareTo(a.requestDate);
                  case SortOption.soonest:
                  default:
                    return a.requestDate.compareTo(b.requestDate);
                }
              });

              if (filteredList.isEmpty) {
                return const Center(
                  child: Text('No requests match your filters.'),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.only(top: 8),
                itemCount: filteredList.length,
                itemBuilder: (context, index) {
                  return RideRequestCard(request: filteredList[index]);
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

class RideRequestCard extends StatefulWidget {
  final PostedRequest request;
  const RideRequestCard({super.key, required this.request});

  @override
  State<RideRequestCard> createState() => _RideRequestCardState();
}

class _RideRequestCardState extends State<RideRequestCard> {
  bool _isJoining = false;

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;
    final riderUids =
        (widget.request.riders as List<dynamic>)
            .map((r) => r['uid'] as String)
            .toList();
    final bool hasJoined =
        currentUser != null && riderUids.contains(currentUser.uid);
    final riderCount = widget.request.riders.length;
    final dateString = DateFormat(
      'E, MMM d',
    ).format(widget.request.requestDate.toDate());

    return Card(
      color: Colors.white,
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: InkWell(
        splashFactory: NoSplash.splashFactory,
        highlightColor: Colors.transparent,
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder:
                  (context) =>
                      PostedRequestDetailScreen(request: widget.request),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: AppColors.byuiGreen,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        margin: const EdgeInsets.only(right: 8),
                      ),
                      Text(
                        widget.request.fromLocation,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: AppColors.gray700,
                        ),
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
                          color: AppColors.red500,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        margin: const EdgeInsets.only(right: 8),
                      ),
                      Text(
                        widget.request.toLocation,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: AppColors.gray700,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(
                    Icons.calendar_today,
                    size: 16,
                    color: AppColors.textGray500,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    dateString,
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.textGray500,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.group,
                        size: 16,
                        color: AppColors.byuiBlue,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '$riderCount Rider${riderCount != 1 ? "s" : ""}',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: AppColors.byuiBlue,
                        ),
                      ),
                    ],
                  ),
                  FutureBuilder<String?>(
                    future: UserService.getUserName(
                      widget.request.requesterUid,
                    ),
                    builder: (context, snapshot) {
                      final name = snapshot.data ?? "Loading...";
                      String initials =
                          name
                              .split(' ')
                              .map((w) => w.isNotEmpty ? w[0] : '')
                              .join()
                              .toUpperCase();
                      if (initials.length > 2)
                        initials = initials.substring(0, 2);
                      if (initials.isEmpty) initials = '?';
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
                                color: AppColors.byuiBlue,
                              ),
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            name,
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textGray500,
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
              const Divider(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (hasJoined)
                    const OutlinedButton(onPressed: null, child: Text('Joined'))
                  else if (_isJoining)
                    const Padding(
                      padding: EdgeInsets.all(8.0),
                      child: CircularProgressIndicator(),
                    )
                  else
                    OutlinedButton(
                      onPressed: () async {
                        setState(() => _isJoining = true);
                        try {
                          await PostedRequestService.joinRideRequest(
                            widget.request.id,
                          );
                          if (mounted)
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder:
                                    (context) => JoinRequestConfirmationScreen(
                                      request: widget.request,
                                    ),
                              ),
                            );
                        } catch (e) {
                          if (mounted)
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  "Failed to join: ${e.toString()}",
                                ),
                                backgroundColor: Colors.red,
                              ),
                            );
                        } finally {
                          if (mounted) setState(() => _isJoining = false);
                        }
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.byuiBlue,
                        side: const BorderSide(color: AppColors.byuiBlue),
                      ),
                      child: const Text('Join'),
                    ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder:
                              (context) =>
                                  FulfillRequestScreen(request: widget.request),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.byuiBlue,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Offer Ride'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
