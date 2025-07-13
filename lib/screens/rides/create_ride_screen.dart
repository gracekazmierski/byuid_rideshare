// lib/screens/rides/create_ride_screen.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:byui_rideshare/models/ride.dart';
import 'package:byui_rideshare/models/user_profile.dart';
import 'package:byui_rideshare/services/ride_service.dart';
import 'package:byui_rideshare/services/user_service.dart';
import 'package:intl/intl.dart';
import 'package:byui_rideshare/screens/rides/ride_confirmation_screen.dart';
import 'package:byui_rideshare/theme/app_colors.dart';
import 'package:byui_rideshare/utils/time_input_formatter.dart';
import 'package:flutter/services.dart';

enum AmPm { am, pm }

class CreateRideScreen extends StatefulWidget {
  // MERGED: Combined parameters from both branches to support all cases.
  final Ride? existingRide;
  final String? initialOrigin;
  final String? initialDestination;

  const CreateRideScreen({
    super.key,
    this.existingRide,
    this.initialOrigin,
    this.initialDestination,
  });

  @override
  State<CreateRideScreen> createState() => _CreateRideScreenState();
}

class _CreateRideScreenState extends State<CreateRideScreen> {
  final _formkey = GlobalKey<FormState>();

  final _originController = TextEditingController();
  final _destinationController = TextEditingController();
  final _availableSeatsController = TextEditingController();
  final _fareController = TextEditingController();
  final _rideDateController = TextEditingController();
  final _timeController = TextEditingController();

  final FocusNode _fareFocusNode = FocusNode();

  DateTime? _selectedDate;
  TimeOfDay? _selectedTime; // Added from logan-updated-ui branch
  bool _isLoading = false;
  AmPm? _selectedAmPm;

  // Added to determine if we are editing or creating
  bool get _isEditing => widget.existingRide != null;

  @override
  void initState() {
    super.initState();
    _fareFocusNode.addListener(_formatFareOnLostFocus);

    // MERGED: Prioritize editing logic, then handle pre-filling for new rides.
    if (_isEditing) {
      // Logic from logan-updated-ui branch for editing
      final ride = widget.existingRide!;
      _originController.text = ride.origin;
      _destinationController.text = ride.destination;
      _availableSeatsController.text = ride.availableSeats.toString();
      _fareController.text = ride.fare?.toStringAsFixed(2) ?? '';
      _selectedDate = ride.rideDate.toDate();
      _selectedTime = TimeOfDay.fromDateTime(_selectedDate!);
      _rideDateController.text = DateFormat('EEEE, MMMM d, yyyy').format(_selectedDate!);

      // Set AM/PM from the existing time
      _selectedAmPm = _selectedTime!.hour < 12 ? AmPm.am : AmPm.pm;
      // Format time to 12-hour format for the text field
      _timeController.text = DateFormat('h:mm').format(_selectedDate!);

    } else {
      // Logic from main branch for pre-filling a new ride
      if (widget.initialOrigin != null) {
        _originController.text = widget.initialOrigin!;
      }
      if (widget.initialDestination != null) {
        _destinationController.text = widget.initialDestination!;
      }
    }
  }


  @override
  void dispose() {
    _originController.dispose();
    _destinationController.dispose();
    _availableSeatsController.dispose();
    _fareController.dispose();
    _rideDateController.dispose();
    _timeController.dispose();
    _fareFocusNode.removeListener(_formatFareOnLostFocus);
    _fareFocusNode.dispose();
    super.dispose();
  }

  void _formatFareOnLostFocus() {
    if (!_fareFocusNode.hasFocus) {
      String text = _fareController.text;
      if (text.isNotEmpty) {
        double? parsedFare = double.tryParse(text);
        if (parsedFare != null) {
          _fareController.text = parsedFare.toStringAsFixed(2);
        } else {
          _fareController.clear();
        }
      }
    }
  }

  TimeOfDay? _parseTimeWithAmPm(String timeStr, AmPm? amPm) {
    if (amPm == null) return null;
    try {
      final parts = timeStr.split(':');
      if (parts.length != 2) return null;
      int hour = int.parse(parts[0]);
      final int minute = int.parse(parts[1]);
      if (hour < 1 || hour > 12 || minute < 0 || minute > 59) return null;
      if (amPm == AmPm.am) {
        if (hour == 12) hour = 0; // Midnight case
      } else { // PM
        if (hour != 12) hour += 12; // Afternoon/evening case
      }
      return TimeOfDay(hour: hour, minute: minute);
    } catch (e) {
      return null;
    }
  }

  // Renamed to handle both creating and updating
  void _submitRide() async {
    if (!_formkey.currentState!.validate()) {
      setState(() {}); // Re-build to show validation errors if any
      return;
    }

    setState(() => _isLoading = true);

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('User not logged in.')));
      setState(() => _isLoading = false);
      return;
    }

    final UserProfile? userProfile = await UserService.fetchUserProfile(user.uid);
    if (userProfile == null || !mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not retrieve user profile.')));
      setState(() => _isLoading = false);
      return;
    }

    final TimeOfDay? rideTime = _parseTimeWithAmPm(_timeController.text, _selectedAmPm);
    if (_selectedDate == null || rideTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select a valid date and time.')));
      setState(() => _isLoading = false);
      return;
    }

    DateTime finalRideDateTime = DateTime(_selectedDate!.year, _selectedDate!.month, _selectedDate!.day, rideTime.hour, rideTime.minute);
    final int? availableSeats = int.tryParse(_availableSeatsController.text);
    final double? fare = double.tryParse(_fareController.text);

    final ride = Ride(
      id: _isEditing ? widget.existingRide!.id : '', // Use existing ID if editing
      origin: _originController.text.trim(),
      destination: _destinationController.text.trim(),
      availableSeats: availableSeats!,
      fare: fare,
      driverUid: user.uid,
      driverName: '${userProfile.firstName} ${userProfile.lastName}',
      rideDate: Timestamp.fromDate(finalRideDateTime),
      // Keep original post time if editing, otherwise set new
      postCreationTime: _isEditing ? widget.existingRide!.postCreationTime : Timestamp.now(),
      isFull: _isEditing ? widget.existingRide!.isFull : false,
      joinedUserUids: _isEditing ? widget.existingRide!.joinedUserUids : [],
    );

    try {
      if (_isEditing) {
        await RideService.updateRideListing(ride);
        if (!mounted) return;
        // Pop twice to get back to ride details screen after editing
        Navigator.of(context).pop();
        Navigator.of(context).pop(true); // Pop with a result to indicate success
      } else {
        await RideService.saveRideListing(ride);
        if (!mounted) return;
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => RideConfirmationScreen(ride: ride)));
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to post ride: $e')));
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  InputDecoration _inputDecoration({required String labelText, Widget? suffixIcon}) {
    return InputDecoration(
      labelText: labelText,
      labelStyle: const TextStyle(color: AppColors.textGray600),
      floatingLabelStyle: const TextStyle(color: AppColors.byuiBlue),
      suffixIcon: suffixIcon,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.0), borderSide: const BorderSide(color: AppColors.gray300)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8.0), borderSide: const BorderSide(color: AppColors.inputFocusBlue, width: 2.0)),
    );
  }

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
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(_isEditing ? 'Update Your Ride' : 'Offer a Ride', style: const TextStyle(color: Colors.white, fontSize: 24.0, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 2.0),
                  Text(_isEditing ? "Update the details below" : "Fill out the details below", style: const TextStyle(color: AppColors.blue100, fontSize: 14.0)),
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
    const grayInputTextStyle = TextStyle(color: AppColors.textGray600);

    return Scaffold(
      backgroundColor: AppColors.gray50,
      appBar: _buildAppBar(context),
      body: Form(
        key: _formkey,
        child: ListView(
          padding: const EdgeInsets.all(24.0),
          children: [
            _buildSectionCard(
              title: 'Route Details',
              children: [
                TextFormField(
                  controller: _originController,
                  style: grayInputTextStyle,
                  decoration: _inputDecoration(labelText: 'Origin (e.g., Rexburg, ID)'),
                  validator: (v) => v!.isEmpty ? 'Please enter an origin' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _destinationController,
                  style: grayInputTextStyle,
                  decoration: _inputDecoration(labelText: 'Destination (e.g., Salt Lake City, UT)'),
                  validator: (v) => v!.isEmpty ? 'Please enter a destination' : null,
                ),
              ],
            ),
            const SizedBox(height: 24),
            _buildSectionCard(
              title: 'Ride Specifics',
              children: [
                TextFormField(
                  controller: _availableSeatsController,
                  style: grayInputTextStyle,
                  decoration: _inputDecoration(labelText: 'Available Seats'),
                  keyboardType: TextInputType.number,
                  validator: (v) => (v == null || v.isEmpty || int.tryParse(v) == null) ? 'Enter a valid number' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _fareController,
                  style: grayInputTextStyle,
                  focusNode: _fareFocusNode,
                  decoration: _inputDecoration(labelText: 'Fare per person (\$)'),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  validator: (v) => (v == null || v.isEmpty || double.tryParse(v) == null) ? 'Enter a valid fare' : null,
                ),
              ],
            ),
            const SizedBox(height: 24),
            _buildSectionCard(
              title: 'Schedule',
              children: [
                TextFormField(
                  controller: _rideDateController,
                  style: const TextStyle(color: AppColors.textGray600),
                  decoration: _inputDecoration(
                    labelText: 'Date',
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.calendar_today, color: AppColors.byuiBlue),
                      onPressed: () async {
                        DateTime? picked = await showDatePicker(context: context, initialDate: _selectedDate ?? DateTime.now(), firstDate: DateTime.now(), lastDate: DateTime(2101));
                        if (picked != null) {
                          setState(() {
                            _selectedDate = picked;
                            _rideDateController.text = DateFormat('EEEE, MMMM d, yyyy').format(picked);
                          });
                        }
                      },
                    ),
                  ),
                  readOnly: true,
                  validator: (v) => v!.isEmpty ? 'Please select a date' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _timeController,
                  style: const TextStyle(color: AppColors.textGray600),
                  decoration: _inputDecoration(labelText: 'Time (e.g., 2:40)'),
                  keyboardType: TextInputType.datetime,
                  inputFormatters: [
                    LengthLimitingTextInputFormatter(5),
                    TimeInputFormatter(),
                  ],
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Please enter a time';
                    final parts = v.split(':');
                    if (parts.length != 2) return 'Use HH:MM format';
                    try {
                      final int hour = int.parse(parts[0]);
                      final int minute = int.parse(parts[1]);
                      if (hour < 1 || hour > 12) return 'Hour must be 1-12';
                      if (minute < 0 || minute > 59) return 'Minute must be 0-59';
                    } catch (e) {
                      return 'Invalid numbers';
                    }
                    if (_selectedAmPm == null) return 'Please select AM or PM';
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: SegmentedButton<AmPm>(
                    segments: const <ButtonSegment<AmPm>>[
                      ButtonSegment<AmPm>(value: AmPm.am, label: Text('AM')),
                      ButtonSegment<AmPm>(value: AmPm.pm, label: Text('PM')),
                    ],
                    selected: <AmPm>{if (_selectedAmPm != null) _selectedAmPm!},
                    onSelectionChanged: (Set<AmPm> newSelection) {
                      setState(() {
                        _selectedAmPm = newSelection.isEmpty ? null : newSelection.first;
                      });
                    },
                    emptySelectionAllowed: true,
                    showSelectedIcon: false,
                    style: SegmentedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: AppColors.byuiBlue,
                      selectedBackgroundColor: AppColors.byuiBlue,
                      selectedForegroundColor: Colors.white,
                      minimumSize: const Size.fromHeight(40),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
            SizedBox(
              height: 48.0,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _submitRide,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.byuiBlue,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
                ),
                child: _isLoading
                    ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(strokeWidth: 3, color: Colors.white))
                    : Text(_isEditing ? 'Update Ride' : 'Post Ride', style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionCard({required String title, required List<Widget> children}) {
    return Container(
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8.0),
        border: Border.all(color: AppColors.gray200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.byuiBlue)),
          const SizedBox(height: 20),
          ...children,
        ],
      ),
    );
  }
}