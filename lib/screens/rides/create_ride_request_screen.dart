// lib/screens/create_ride_request_screen.dart

import 'package:byui_rideshare/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class CreateRideRequestScreen extends StatefulWidget {
  const CreateRideRequestScreen({super.key});

  @override
  State<CreateRideRequestScreen> createState() =>
      _CreateRideRequestScreenState();
}

class _CreateRideRequestScreenState extends State<CreateRideRequestScreen> {
  final _formKey = GlobalKey<FormState>();

  // Form controllers
  final _fromController = TextEditingController();
  final _toController = TextEditingController();
  final _notesController = TextEditingController();
  final _dateRangeController = TextEditingController();

  // State for the date selection
  DateTime? _startDate;
  DateTime? _endDate;
  bool _isLoading = false;

  @override
  void dispose() {
    _fromController.dispose();
    _toController.dispose();
    _notesController.dispose();
    _dateRangeController.dispose();
    super.dispose();
  }

  // --- Date Picker Logic ---
  Future<void> _selectDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      helpText: 'Select a Date or a Range',
      errorFormatText: 'Enter valid dates',
      errorInvalidRangeText: 'End date must be after start date',
    );

    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
        // Format the date(s) to be readable in the text field
        _dateRangeController.text =
        '${DateFormat.yMMMd().format(_startDate!)} - ${DateFormat.yMMMd().format(_endDate ?? _startDate!)}';
      });
    }
  }

  // --- Submit Logic ---
  Future<void> _submitRequest() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      // Handle user not logged in
      setState(() => _isLoading = false);
      return;
    }

    try {
      await FirebaseFirestore.instance.collection('ride_requests').add({
        'requester_id': user.uid,
        'requester_name': user.displayName ?? 'Anonymous',
        'from_location': _fromController.text.trim(),
        'to_location': _toController.text.trim(),
        'notes': _notesController.text.trim(),
        'request_date_start': Timestamp.fromDate(_startDate!),
        'request_date_end': Timestamp.fromDate(_endDate ?? _startDate!),
        'riders': [
          {'uid': user.uid, 'name': user.displayName ?? 'Anonymous'}
        ],
        'status': 'active',
        'created_at': Timestamp.now(),
      });

      if (mounted) {
        Navigator.of(context).pop(); // Go back to the list screen
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ride request posted successfully!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to post request: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // --- Styling Helper Methods (from create_ride_screen) ---

  // --- CHANGE 1: Update the input decoration to style the label correctly ---
  InputDecoration _inputDecoration(
      {required String labelText, Widget? suffixIcon}) {
    return InputDecoration(
      labelText: labelText,
      // Default state (inside the field) is gray
      labelStyle: const TextStyle(color: AppColors.textGray600),
      // Floating state (above the field) is blue
      floatingLabelStyle: const TextStyle(color: AppColors.byuiBlue),
      suffixIcon: suffixIcon,
      border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.0),
          borderSide: const BorderSide(color: AppColors.gray300)),
      focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.0),
          borderSide:
          const BorderSide(color: AppColors.inputFocusBlue, width: 2.0)),
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
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Request a Ride',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 24.0,
                          fontWeight: FontWeight.w600)),
                  SizedBox(height: 2.0),
                  Text("Let drivers know where you need to go",
                      style:
                      TextStyle(color: AppColors.blue100, fontSize: 14.0)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- CHANGE 2: Update the section card to use a blue title ---
  Widget _buildSectionCard(
      {required String title, required List<Widget> children}) {
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
          Text(title,
              style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.byuiBlue)), // Set title color to blue
          const SizedBox(height: 20),
          ...children,
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // --- CHANGE 3: Define a gray text style for the user's typed input ---
    const grayInputTextStyle = TextStyle(color: AppColors.textGray600);

    return Scaffold(
      backgroundColor: AppColors.gray50,
      appBar: _buildAppBar(context),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(24.0),
          children: [
            _buildSectionCard(
              title: 'Route Details',
              children: [
                TextFormField(
                  controller: _fromController,
                  style: grayInputTextStyle, // Use gray for typed text
                  decoration:
                  _inputDecoration(labelText: 'From (e.g., Rexburg, ID)'),
                  validator: (v) =>
                  v!.isEmpty ? 'Please enter an origin' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _toController,
                  style: grayInputTextStyle, // Use gray for typed text
                  decoration: _inputDecoration(
                      labelText: 'To (e.g., Salt Lake City, UT)'),
                  validator: (v) =>
                  v!.isEmpty ? 'Please enter a destination' : null,
                ),
              ],
            ),
            const SizedBox(height: 24),
            _buildSectionCard(
              title: 'Request Details',
              children: [
                TextFormField(
                  controller: _dateRangeController,
                  style: grayInputTextStyle, // Use gray for typed text
                  decoration: _inputDecoration(
                    labelText: 'Date Range',
                    suffixIcon: IconButton(
                      // --- CHANGE 4: Set the calendar icon color to blue ---
                      icon: const Icon(Icons.calendar_today,
                          color: AppColors.byuiBlue),
                      onPressed: _selectDateRange,
                    ),
                  ),
                  readOnly: true,
                  validator: (v) =>
                  v!.isEmpty ? 'Please select a date range' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _notesController,
                  style: grayInputTextStyle, // Use gray for typed text
                  decoration: _inputDecoration(
                      labelText: 'Notes (e.g., I have one large suitcase)'),
                  maxLines: 3,
                ),
              ],
            ),
            const SizedBox(height: 32),
            SizedBox(
              height: 48.0,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _submitRequest,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.byuiBlue,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.0)),
                ),
                child: _isLoading
                    ? const SizedBox(
                    height: 24,
                    width: 24,
                    child: CircularProgressIndicator(
                        strokeWidth: 3, color: Colors.white))
                    : const Text('Post Ride Request',
                    style: TextStyle(
                        fontWeight: FontWeight.w500, fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}