import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:byui_rideshare/models/ride.dart';
import 'package:byui_rideshare/services/ride_service.dart';

// class CreateRideScreen extends StatefulWidget {
//   const CreateRideScreen({super.key});

class CreateRideScreen extends StatefulWidget{
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

  void _postRide() async {
    if (_formkey.currentState!.validate()) {
      final user = FirebaseAuth.instance.currentUser;
      final ride = Ride(
        origin: _originController.text,
        destination: _destinationController.text,
        availableSeats: int.parse(_availableSeatsController.text),
        fare: double.parse(_fareController.text),
        driverUid: user!.uid,
        driverName: user.displayName ?? 'Unknown Driver',
        rideDate: Timestamp.fromDate(
          DateTime.parse(_rideDateController.text)
        ),
        postCreationTime: Timestamp.now(),
      );

      try {
        await RideService.saveRideListing(ride);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ride posted successfully!')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to post ride: $e')),
        );
      }
    }
  }
  @override
  Widget build(BuildContext context){
    return Scaffold(
      appBar: AppBar(title: Text("Offer a Ride")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formkey,
          child: ListView(
            children: [
              TextFormField(
                controller: _originController,
                decoration: InputDecoration(labelText: 'Origin'),
                validator: (value) => value!.isEmpty ? 'Enter origin' : null,
              ),
              TextFormField(
                controller: _destinationController,
                decoration: InputDecoration(labelText: 'Destination'),
                validator: (value) => value!.isEmpty ? 'Enter Destination' : null,
              ),
              TextFormField(
                controller: _availableSeatsController,
                decoration: InputDecoration(labelText: 'Available Seats'),
                keyboardType: TextInputType.number,
                validator: (value) => value!.isEmpty ? 'Enter number of seats' : null,
              ),
              TextFormField(
                controller: _fareController,
                decoration: InputDecoration(labelText: 'Fare'),
                keyboardType: TextInputType.number,
                validator: (value) => value!.isEmpty ? 'Enter fare' : null,
              ),
              TextFormField(
                controller: _rideDateController,
                decoration: InputDecoration (labelText: 'Date')
              ),
              TextFormField(
                controller: _timeController,
                decoration: InputDecoration(labelText: 'Time'),
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: _postRide,
                child: Text('Post Ride')
              ),
            ]
          )
        ),
      ),
    );
  }
}


