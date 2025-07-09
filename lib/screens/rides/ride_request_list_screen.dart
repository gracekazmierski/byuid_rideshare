// lib/screens/rides/ride_request_list_screen.dart
import 'package:byui_rideshare/models/posted_request.dart';
import 'package:byui_rideshare/screens/rides/fulfill_request_screen.dart';
import 'package:byui_rideshare/screens/rides/posted_request_detail_screen.dart';
import 'package:byui_rideshare/services/posted_request_service.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:byui_rideshare/theme/app_colors.dart';
import 'package:intl/intl.dart';
import 'package:byui_rideshare/services/user_service.dart';
import 'package:byui_rideshare/models/request_sort_option.dart';

class RideRequestListScreen extends StatefulWidget {
  const RideRequestListScreen({super.key});
  @override
  State<RideRequestListScreen> createState() => _RideRequestListScreenState();
}

class _RideRequestListScreenState extends State<RideRequestListScreen> {
  final TextEditingController _fromSearchController = TextEditingController();
  final TextEditingController _toSearchController = TextEditingController();
  String _fromQuery = '';
  String _toQuery = '';
  RequestSortOption _selectedSort = RequestSortOption.newest;

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

  void _showRequestFilterSheet() {
    RequestSortOption tempSort = _selectedSort;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter sheetSetState) {
            return Padding(
              padding: EdgeInsets.fromLTRB(24, 8, 24, MediaQuery.of(context).viewInsets.bottom + 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(child: Container(width: 40, height: 5, margin: const EdgeInsets.only(bottom: 20), decoration: BoxDecoration(color: AppColors.gray300, borderRadius: BorderRadius.circular(10)))),
                  const Text('Sort Requests', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.textGray600)),
                  const SizedBox(height: 24),
                  DropdownButtonFormField<RequestSortOption>(
                    value: tempSort,
                    decoration: const InputDecoration(labelText: 'Sort By', border: OutlineInputBorder()),
                    items: const [
                      DropdownMenuItem(value: RequestSortOption.newest, child: Text("Newest First")),
                      DropdownMenuItem(value: RequestSortOption.oldest, child: Text("Oldest First")),
                    ],
                    onChanged: (val) { sheetSetState(() => tempSort = val ?? RequestSortOption.newest); },
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: () { setState(() { _selectedSort = tempSort; }); Navigator.pop(context); },
                      style: ElevatedButton.styleFrom(backgroundColor: AppColors.byuiBlue, foregroundColor: Colors.white),
                      child: const Text('Apply Sort'),
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

  // ✅ Your original search and filter UI is fully restored.
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
                  onPressed: _showRequestFilterSheet,
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
                  onPressed: () {}, // Search button
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

  @override
  Widget build(BuildContext context) {
    Query requestsQuery = FirebaseFirestore.instance.collection('ride_requests')
        .where('status', isEqualTo: 'active')
        .where('request_date_end', isGreaterThanOrEqualTo: DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day))
        .orderBy('request_date_end', descending: false);

    if (_selectedSort == RequestSortOption.newest) {
      requestsQuery = requestsQuery.orderBy('created_at', descending: true);
    } else {
      requestsQuery = requestsQuery.orderBy('created_at', descending: false);
    }

    return Column(
      children: [
        _buildSearchSection(),
        Expanded(
          child: StreamBuilder<List<PostedRequest>>(
            stream: PostedRequestService.fetchRideRequests(
              fromLocation: _fromQuery,
              toLocation: _toQuery,
              sortOption: _selectedSort,
            ),
            builder: (BuildContext context, AsyncSnapshot<List<PostedRequest>> snapshot) {
              if (snapshot.hasError) return const Center(child: Text('Error loading requests.'));
              if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
              if (!snapshot.hasData || snapshot.data!.isEmpty) return const Center(child: Text('No active ride requests found.'));

              final requests = snapshot.data!;

              if (requests.isEmpty) return const Center(child: Text('No requests match your search.'));

              return ListView.builder(
                padding: const EdgeInsets.only(top: 8),
                itemCount: requests.length,
                itemBuilder: (context, index) {
                  return RideRequestCard(request: requests[index]);
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
    final riderCount = widget.request.riders.length;
    final bool isSameDay = widget.request.requestDateStart.toDate().day == widget.request.requestDateEnd.toDate().day;
    final dateString = isSameDay ? DateFormat('MMM d').format(widget.request.requestDateStart.toDate()) : '${DateFormat('MMM d').format(widget.request.requestDateStart.toDate())} - ${DateFormat('MMM d').format(widget.request.requestDateEnd.toDate())}';

    return Card(
      color: Colors.white,
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: InkWell(
        splashFactory: NoSplash.splashFactory,
        highlightColor: Colors.transparent,
        onTap: () {
          Navigator.push(context, MaterialPageRoute(builder: (context) => PostedRequestDetailScreen(request: widget.request)));
        },
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // This layout now perfectly matches your original ride card
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Container(width: 8, height: 8, decoration: BoxDecoration(color: AppColors.byuiGreen, borderRadius: BorderRadius.circular(4)), margin: const EdgeInsets.only(right: 8)),
                    Text(widget.request.fromLocation, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.gray700)),
                  ]),
                  const SizedBox(height: 4),
                  Row(children: [
                    Container(width: 8, height: 8, decoration: BoxDecoration(color: AppColors.red500, borderRadius: BorderRadius.circular(4)), margin: const EdgeInsets.only(right: 8)),
                    Text(widget.request.toLocation, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.gray700)),
                  ]),
                ],
              ),
              const SizedBox(height: 12),
              Row(children: [
                const Icon(Icons.calendar_today, size: 16, color: AppColors.textGray500),
                const SizedBox(width: 8),
                Text(dateString, style: const TextStyle(fontSize: 14, color: AppColors.textGray500)),
              ]),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(children: [
                    const Icon(Icons.group, size: 16, color: AppColors.byuiBlue),
                    const SizedBox(width: 8),
                    Text('$riderCount Rider${riderCount != 1 ? "s" : ""}', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.byuiBlue)),
                  ]),
                  FutureBuilder<String?>(
                    future: UserService.getUserName(widget.request.requesterUid),
                    builder: (context, snapshot) {
                      final name = snapshot.data ?? "Loading...";
                      String initials = name.split(' ').map((w) => w.isNotEmpty ? w[0] : '').join().toUpperCase();
                      if (initials.length > 2) initials = initials.substring(0, 2);
                      if (initials.isEmpty) initials = '?';
                      return Row(children: [
                        CircleAvatar(radius: 12, backgroundColor: const Color(0xFFe6f1fa), child: Text(initials, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.byuiBlue))),
                        const SizedBox(width: 4),
                        Text(name, style: const TextStyle(fontSize: 12, color: AppColors.textGray500)),
                      ]);
                    },
                  ),
                ],
              ),
              const Divider(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  _isJoining
                      ? const Padding(padding: EdgeInsets.all(8.0), child: CircularProgressIndicator())
                      : OutlinedButton(
                      onPressed: () async {
                        setState(() => _isJoining = true);
                        try {
                          await PostedRequestService.joinRideRequest(widget.request.id);
                          if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Successfully joined request!"), backgroundColor: Colors.green,));
                        } catch (e) {
                          if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Failed to join: ${e.toString()}"), backgroundColor: Colors.red,));
                        } finally {
                          if (mounted) setState(() => _isJoining = false);
                        }
                      },
                      // ✅ Style added to make text and border blue
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.byuiBlue,
                        side: const BorderSide(color: AppColors.byuiBlue),
                      ),
                      child: const Text('Join')
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                      onPressed: () {
                        Navigator.push(context, MaterialPageRoute(builder: (context) => FulfillRequestScreen(request: widget.request)));
                      },
                      // ✅ Style updated to make text white
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.byuiBlue,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Offer Ride')
                  ),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }
}