// lib/screens/rides/create_ride_screen.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:byui_rideshare/models/ride.dart';
import 'package:byui_rideshare/services/ride_service.dart';
import 'package:byui_rideshare/services/user_service.dart';
import 'package:intl/intl.dart';
import 'package:byui_rideshare/screens/rides/ride_confirmation_screen.dart';
import 'package:byui_rideshare/theme/app_colors.dart';

class CreateRideScreen extends StatefulWidget {
  final Ride? existingRide;

  const CreateRideScreen({super.key, this.existingRide});

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
  TimeOfDay? _selectedTime;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();

    _fareFocusNode.addListener(_formatFareOnLostFocus);

    if (widget.existingRide != null) {
      final ride = widget.existingRide!;
      _originController.text = ride.origin;
      _destinationController.text = ride.destination;
      _availableSeatsController.text = ride.availableSeats.toString();
      _fareController.text = ride.fare?.toStringAsFixed(2) ?? '';
      _selectedDate = ride.rideDate.toDate();
      _selectedTime = TimeOfDay.fromDateTime(_selectedDate!);
      _rideDateController.text = DateFormat('EEEE, MMMM d, yyyy').format(_selectedDate!);
      _timeController.text = _selectedTime!.format(context);
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

  void _postRide() async {
    if (_formkey.currentState!.validate()) {
      setState(() => _isLoading = true);

      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('User not logged in.')));
        setState(() => _isLoading = false);
        return;
      }

      final userProfile = await UserService.fetchUserProfile(user.uid);
      if (userProfile == null || !mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not retrieve user profile.')));
        setState(() => _isLoading = false);
        return;
      }

      if (_selectedDate == null || _selectedTime == null) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select both date and time.')));
        setState(() => _isLoading = false);
        return;
      }

      DateTime finalRideDateTime = DateTime(_selectedDate!.year, _selectedDate!.month, _selectedDate!.day, _selectedTime!.hour, _selectedTime!.minute);
      final int? availableSeats = int.tryParse(_availableSeatsController.text);
      final double? fare = double.tryParse(_fareController.text);

      final ride = Ride(
        id: '',
        origin: _originController.text.trim(),
        destination: _destinationController.text.trim(),
        availableSeats: availableSeats!,
        fare: fare,
        driverUid: user.uid,
        driverName: '${userProfile.firstName} ${userProfile.lastName}',
        rideDate: Timestamp.fromDate(finalRideDateTime),
        postCreationTime: Timestamp.now(),
        isFull: false,
        joinedUserUids: [],
      );

      try {
        await RideService.saveRideListing(ride);
        if (!mounted) return;
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => RideConfirmationScreen(ride: ride)));
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to post ride: $e')));
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    }
  }

  InputDecoration _inputDecoration({required String labelText, Widget? suffixIcon}) {
    return InputDecoration(
      labelText: labelText,
      suffixIcon: suffixIcon,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.0), borderSide: const BorderSide(color: AppColors.gray300)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8.0), borderSide: const BorderSide(color: AppColors.inputFocusBlue, width: 2.0)),
    );
  }

  // --- NEW: AppBar Widget ---
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
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Offer a Ride', style: TextStyle(color: Colors.white, fontSize: 24.0, fontWeight: FontWeight.w600)),
                  SizedBox(height: 2.0),
                  Text("Fill out the details below", style: TextStyle(color: AppColors.blue100, fontSize: 14.0)),
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
    return Scaffold(
      backgroundColor: AppColors.gray50,
      // --- CHANGE: Using the new AppBar method ---
      appBar: _buildAppBar(context),
      // --- CHANGE: The body is now just the Form ---
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
                  decoration: _inputDecoration(labelText: 'Origin (e.g., Rexburg, ID)'),
                  validator: (v) => v!.isEmpty ? 'Please enter an origin' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _destinationController,
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
                  decoration: _inputDecoration(labelText: 'Available Seats'),
                  keyboardType: TextInputType.number,
                  validator: (v) => (v == null || v.isEmpty || int.tryParse(v) == null) ? 'Enter a valid number' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _fareController,
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
                  decoration: _inputDecoration(
                    labelText: 'Date',
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.calendar_today),
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
                  decoration: _inputDecoration(
                    labelText: 'Time',
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.access_time),
                      onPressed: () async {
                        TimeOfDay? picked = await showTimePicker(context: context, initialTime: _selectedTime ?? TimeOfDay.now());
                        if (picked != null) {
                          setState(() {
                            _selectedTime = picked;
                            _timeController.text = picked.format(context);
                          });
                        }
                      },
                    ),
                  ),
                  readOnly: true,
                  validator: (v) => v!.isEmpty ? 'Please select a time' : null,
                ),
              ],
            ),
            const SizedBox(height: 32),
            SizedBox(
              height: 48.0,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _postRide,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.byuiBlue,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
                ),
                child: _isLoading
                    ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(strokeWidth: 3, color: Colors.white))
                    : const Text('Post Ride', style: TextStyle(fontWeight: FontWeight.w500, fontSize: 16)),
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
          Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textGray600)),
          const SizedBox(height: 20),
          ...children,
        ],
      ),
    );
  }
}