// lib/screens/rides/create_ride_screen.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:byui_rideshare/models/ride.dart';
import 'package:byui_rideshare/services/ride_service.dart';
import 'package:intl/intl.dart';
import 'package:byui_rideshare/screens/rides/ride_confirmation_screen.dart'; // Ensure this is imported

class CreateRideScreen extends StatefulWidget {
  const CreateRideScreen({super.key});

  @override
  State<CreateRideScreen> createState() => _CreateRideScreenState();
}

class _CreateRideScreenState extends State<CreateRideScreen> {
  final _formkey = GlobalKey<FormState>();

  final TextEditingController _originController = TextEditingController();
  final TextEditingController _destinationController = TextEditingController();
  final TextEditingController _availableSeatsController = TextEditingController();
  final TextEditingController _fareController = TextEditingController();
  final TextEditingController _rideDateController = TextEditingController();
  final TextEditingController _timeController = TextEditingController();

  final FocusNode _fareFocusNode = FocusNode();

  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;

  @override
  void initState() {
    super.initState();
    _fareFocusNode.addListener(_formatFareOnLostFocus);
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
      final user = FirebaseAuth.instance.currentUser;

      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('User not logged in.')),
        );
        return;
      }

      if (_selectedDate == null || _selectedTime == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select both date and time for the ride.')),
        );
        return;
      }

      DateTime finalRideDateTime = DateTime(
        _selectedDate!.year,
        _selectedDate!.month,
        _selectedDate!.day,
        _selectedTime!.hour,
        _selectedTime!.minute,
      );

      final int? availableSeats = int.tryParse(_availableSeatsController.text);
      final double? fare = double.tryParse(_fareController.text);

      if (availableSeats == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter a valid number for available seats.')),
        );
        return;
      }

      final ride = Ride(
        id: '', // New rides start with an empty ID, it will be set by Firestore
        origin: _originController.text,
        destination: _destinationController.text,
        availableSeats: availableSeats,
        fare: fare,
        driverUid: user.uid,
        driverName: user.displayName ?? 'Unknown Driver',
        rideDate: Timestamp.fromDate(finalRideDateTime),
        postCreationTime: Timestamp.now(),
        isFull: false, // New: Default to not full
        joinedUserUids: [], // New: Default to empty
      );

      try {
        await RideService.saveRideListing(ride); // Save new ride
        // On success, navigate to the confirmation screen
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => RideConfirmationScreen(ride: ride), // Pass the ride object
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to post ride: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Offer a Ride")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formkey,
          child: ListView(
            children: [
              TextFormField(
                controller: _originController,
                decoration: const InputDecoration(labelText: 'Origin'),
                validator: (value) => value!.isEmpty ? 'Enter origin' : null,
              ),
              TextFormField(
                controller: _destinationController,
                decoration: const InputDecoration(labelText: 'Destination'),
                validator: (value) => value!.isEmpty ? 'Enter Destination' : null,
              ),
              TextFormField(
                controller: _availableSeatsController,
                decoration: const InputDecoration(labelText: 'Available Seats'),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Enter number of seats';
                  }
                  if (int.tryParse(value) == null) {
                    return 'Please enter a valid number';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _fareController,
                focusNode: _fareFocusNode,
                decoration: const InputDecoration(labelText: 'Fare'),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Enter fare';
                  }
                  if (double.tryParse(value) == null) {
                    return 'Please enter a valid fare';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _rideDateController,
                decoration: InputDecoration(
                  labelText: 'Date',
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.calendar_today),
                    onPressed: () async {
                      DateTime? tempPickedDate = await showDatePicker(
                        context: context,
                        initialDate: _selectedDate ?? DateTime.now(),
                        firstDate: DateTime.now(),
                        lastDate: DateTime(2101),
                      );
                      if (tempPickedDate != null) {
                        setState(() {
                          _selectedDate = tempPickedDate;
                          _rideDateController.text = DateFormat('yyyy-MM-dd').format(tempPickedDate);
                        });
                      }
                    },
                  ),
                ),
                readOnly: true,
                validator: (value) => value!.isEmpty ? 'Enter date' : null,
              ),
              TextFormField(
                controller: _timeController,
                decoration: InputDecoration(
                  labelText: 'Time',
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.access_time),
                    onPressed: () async {
                      TimeOfDay? tempPickedTime = await showTimePicker(
                        context: context,
                        initialTime: _selectedTime ?? TimeOfDay.now(),
                      );
                      if (tempPickedTime != null) {
                        setState(() {
                          _selectedTime = tempPickedTime;
                          _timeController.text = tempPickedTime.format(context);
                        });
                      }
                    },
                  ),
                ),
                readOnly: true,
                validator: (value) => value!.isEmpty ? 'Enter time' : null,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _postRide,
                child: const Text('Post Ride'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}