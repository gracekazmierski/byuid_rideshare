// lib/screens/events/create_event_ride_screen.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:byui_rideshare/models/ride.dart';
import 'package:byui_rideshare/models/user_profile.dart';
import 'package:byui_rideshare/services/ride_service.dart';
import 'package:byui_rideshare/services/user_service.dart';
import 'package:intl/intl.dart';
import 'package:byui_rideshare/theme/app_colors.dart';
import 'package:byui_rideshare/utils/time_input_formatter.dart';
import 'package:flutter/services.dart';

enum AmPm { am, pm }

class CreateEventRideScreen extends StatefulWidget {
  const CreateEventRideScreen({super.key});

  @override
  State<CreateEventRideScreen> createState() => _CreateEventRideScreenState();
}

class _CreateEventRideScreenState extends State<CreateEventRideScreen> {
  final _formKey = GlobalKey<FormState>();

  final _eventNameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _originController = TextEditingController();
  final _destinationController = TextEditingController();
  final _availableSeatsController = TextEditingController();
  final _fareController = TextEditingController();
  final _rideDateController = TextEditingController();
  final _timeController = TextEditingController();
  final _returnDateController = TextEditingController();
  final _returnTimeController = TextEditingController();

  final FocusNode _fareFocusNode = FocusNode();

  DateTime? _selectedDate;
  DateTime? _selectedReturnDate;
  AmPm? _selectedAmPm;
  AmPm? _selectedReturnAmPm;
  bool _isLoading = false;

  @override
  void dispose() {
    _eventNameController.dispose();
    _descriptionController.dispose();
    _originController.dispose();
    _destinationController.dispose();
    _availableSeatsController.dispose();
    _fareController.dispose();
    _rideDateController.dispose();
    _timeController.dispose();
    _returnDateController.dispose();
    _returnTimeController.dispose();
    _fareFocusNode.dispose();
    super.dispose();
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
        if (hour == 12) hour = 0; // midnight
      } else {
        if (hour != 12) hour += 12; // convert to 24hr
      }
      return TimeOfDay(hour: hour, minute: minute);
    } catch (_) {
      return null;
    }
  }

  void _postEventRide() async {
    if (!_formKey.currentState!.validate()) {
      setState(() {});
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

    final rideTime = _parseTimeWithAmPm(_timeController.text, _selectedAmPm);
    final returnTime = _parseTimeWithAmPm(_returnTimeController.text, _selectedReturnAmPm);

    if (_selectedDate == null || rideTime == null || _selectedReturnDate == null || returnTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select valid departure & return times.')));
      setState(() => _isLoading = false);
      return;
    }

    final departureDateTime = DateTime(
      _selectedDate!.year,
      _selectedDate!.month,
      _selectedDate!.day,
      rideTime.hour,
      rideTime.minute,
    );

    final returnDateTime = DateTime(
      _selectedReturnDate!.year,
      _selectedReturnDate!.month,
      _selectedReturnDate!.day,
      returnTime.hour,
      returnTime.minute,
    );

    if (returnDateTime.isBefore(departureDateTime)) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Return trip must be after departure.')));
      setState(() => _isLoading = false);
      return;
    }

    final int? availableSeats = int.tryParse(_availableSeatsController.text);
    final double? fare = double.tryParse(_fareController.text);

    final ride = Ride(
      id: '',
      origin: _originController.text.trim(),
      destination: _destinationController.text.trim(),
      availableSeats: availableSeats ?? 1,
      fare: fare,
      driverUid: user.uid,
      driverName: '${userProfile.firstName} ${userProfile.lastName}',
      rideDate: Timestamp.fromDate(departureDateTime),
      returnDate: Timestamp.fromDate(returnDateTime),
      postCreationTime: Timestamp.now(),
      isEvent: true,
      eventName: _eventNameController.text.trim(),
      eventDescription: _descriptionController.text.trim(),
      joinedUserUids: [],
    );

    try {
      await RideService.saveRideListing(ride);
      if (!mounted) return;
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to save event ride: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
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

  @override
  Widget build(BuildContext context) {
    const grayInputTextStyle = TextStyle(color: AppColors.textGray600);

    return Scaffold(
      backgroundColor: AppColors.gray50,
      appBar: AppBar(
        title: const Text("Create Event Ride"),
        backgroundColor: AppColors.byuiBlue,
        foregroundColor: Colors.white,
        toolbarHeight: 72,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(24.0),
          children: [
            _buildSectionCard(
              title: 'Event Info',
              children: [
                TextFormField(
                  controller: _eventNameController,
                  style: grayInputTextStyle,
                  decoration: _inputDecoration(labelText: 'Event Name'),
                  validator: (v) => v!.isEmpty ? 'Enter event name' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _descriptionController,
                  style: grayInputTextStyle,
                  decoration: _inputDecoration(labelText: 'Short Description'),
                  maxLength: 150,
                  validator: (v) => v!.isEmpty ? 'Enter description (<150 chars)' : null,
                ),
              ],
            ),
            const SizedBox(height: 24),
            _buildSectionCard(
              title: 'Route Details',
              children: [
                TextFormField(
                  controller: _originController,
                  style: grayInputTextStyle,
                  decoration: _inputDecoration(labelText: 'Origin'),
                  validator: (v) => v!.isEmpty ? 'Please enter origin' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _destinationController,
                  style: grayInputTextStyle,
                  decoration: _inputDecoration(labelText: 'Destination'),
                  validator: (v) => v!.isEmpty ? 'Please enter destination' : null,
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
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _fareController,
                  style: grayInputTextStyle,
                  focusNode: _fareFocusNode,
                  decoration: _inputDecoration(labelText: 'Fare per person (\$)'),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                ),
              ],
            ),
            const SizedBox(height: 24),
            _buildSectionCard(
              title: 'Schedule (Round Trip)',
              children: [
                // Departure Date
                TextFormField(
                  controller: _rideDateController,
                  style: grayInputTextStyle,
                  decoration: _inputDecoration(
                    labelText: 'Departure Date',
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.calendar_today, color: AppColors.byuiBlue),
                      onPressed: () async {
                        DateTime? picked = await showDatePicker(
                          context: context,
                          initialDate: _selectedDate ?? DateTime.now(),
                          firstDate: DateTime.now(),
                          lastDate: DateTime(2101),
                        );
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
                  validator: (v) => v!.isEmpty ? 'Select a departure date' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _timeController,
                  style: grayInputTextStyle,
                  decoration: _inputDecoration(labelText: 'Departure Time (e.g., 2:40)'),
                  inputFormatters: [LengthLimitingTextInputFormatter(5), TimeInputFormatter()],
                  keyboardType: TextInputType.datetime,
                ),
                const SizedBox(height: 16),
                SegmentedButton<AmPm>(
                  segments: const [
                    ButtonSegment(value: AmPm.am, label: Text('AM')),
                    ButtonSegment(value: AmPm.pm, label: Text('PM')),
                  ],
                  selected: <AmPm>{if (_selectedAmPm != null) _selectedAmPm!},
                  onSelectionChanged: (Set<AmPm> newSel) {
                    setState(() => _selectedAmPm = newSel.isEmpty ? null : newSel.first);
                  },
                  emptySelectionAllowed: true,
                  showSelectedIcon: false,
                ),
                const SizedBox(height: 24),

                // Return Trip
                TextFormField(
                  controller: _returnDateController,
                  style: grayInputTextStyle,
                  decoration: _inputDecoration(
                    labelText: 'Return Date',
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.calendar_today, color: AppColors.byuiBlue),
                      onPressed: () async {
                        DateTime? picked = await showDatePicker(
                          context: context,
                          initialDate: _selectedReturnDate ?? DateTime.now(),
                          firstDate: DateTime.now(),
                          lastDate: DateTime(2101),
                        );
                        if (picked != null) {
                          setState(() {
                            _selectedReturnDate = picked;
                            _returnDateController.text = DateFormat('EEEE, MMMM d, yyyy').format(picked);
                          });
                        }
                      },
                    ),
                  ),
                  readOnly: true,
                  validator: (v) => v!.isEmpty ? 'Select a return date' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _returnTimeController,
                  style: grayInputTextStyle,
                  decoration: _inputDecoration(labelText: 'Return Time (e.g., 6:30)'),
                  inputFormatters: [LengthLimitingTextInputFormatter(5), TimeInputFormatter()],
                  keyboardType: TextInputType.datetime,
                ),
                const SizedBox(height: 16),
                SegmentedButton<AmPm>(
                  segments: const [
                    ButtonSegment(value: AmPm.am, label: Text('AM')),
                    ButtonSegment(value: AmPm.pm, label: Text('PM')),
                  ],
                  selected: <AmPm>{if (_selectedReturnAmPm != null) _selectedReturnAmPm!},
                  onSelectionChanged: (Set<AmPm> newSel) {
                    setState(() => _selectedReturnAmPm = newSel.isEmpty ? null : newSel.first);
                  },
                  emptySelectionAllowed: true,
                  showSelectedIcon: false,
                ),
              ],
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _isLoading ? null : _postEventRide,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.byuiBlue,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
              ),
              child: _isLoading
                  ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(strokeWidth: 3, color: Colors.white))
                  : const Text('Post Event Ride', style: TextStyle(fontWeight: FontWeight.w500, fontSize: 16)),
            ),
          ],
        ),
      ),
    );
  }
}
