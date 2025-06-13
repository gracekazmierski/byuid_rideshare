import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:byui_rideshare/models/ride.dart';
import 'package:byui_rideshare/services/ride_service.dart';
import 'package:intl/intl.dart';
import 'package:byui_rideshare/screens/rides/create_ride_screen.dart';
import 'package:byui_rideshare/screens/rides/ride_detail_screen.dart'; // Import the new detail screen

class MyJoinedRidesScreen extends StatefulWidget {
  const MyJoinedRidesScreen({super.key});

  @override
  State<MyJoinedRidesScreen> createState() => _MyJoinedRidesScreenState();
}

class _MyJoinedRidesScreenState extends State<MyJoinedRidesScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("My Joined Rides")),
    );
  }
}