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
  final _fromController = TextEditingController();
  final _toController = TextEditingController();
  final _notesController = TextEditingController();
  final _dateController = TextEditingController();
  DateTime? _selectedDate;
  bool _isLoading = false;

  @override
  void dispose() {
    _fromController.dispose();
    _toController.dispose();
    _notesController.dispose();
    _dateController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2101),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.byuiBlue,
              onPrimary: Colors.white,
              onSurface: AppColors.textGray600,
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(foregroundColor: AppColors.byuiBlue),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
        _dateController.text = DateFormat('EEEE, MMMM d, yyyy').format(picked);
      });
    }
  }

  Future<void> _submitRequest() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
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
        'request_date': Timestamp.fromDate(_selectedDate!),

        // ✅ FIX: Initialize the 'riders' and 'rider_uids' lists with the requester
        'riders': [
          {'uid': user.uid, 'name': user.displayName ?? 'Anonymous'},
        ],
        'rider_uids': [user.uid],

        'status': 'active',
        'created_at': Timestamp.now(),
      });

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ride request posted successfully!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to post request: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  InputDecoration _inputDecoration({
    required String labelText,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      labelText: labelText,
      labelStyle: const TextStyle(color: AppColors.textGray600),
      floatingLabelStyle: const TextStyle(color: AppColors.byuiBlue),
      suffixIcon: suffixIcon,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8.0),
        borderSide: const BorderSide(color: AppColors.gray300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8.0),
        borderSide: const BorderSide(
          color: AppColors.inputFocusBlue,
          width: 2.0,
        ),
      ),
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
                  Text(
                    'Request a Ride',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24.0,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 2.0),
                  Text(
                    "Let drivers know where you need to go",
                    style: TextStyle(color: AppColors.blue100, fontSize: 14.0),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required List<Widget> children,
  }) {
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
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.byuiBlue,
            ),
          ),
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
                  style: grayInputTextStyle,
                  decoration: _inputDecoration(
                    labelText: 'From (e.g., Rexburg, ID)',
                  ),
                  validator:
                      (v) => v!.isEmpty ? 'Please enter an origin' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _toController,
                  style: grayInputTextStyle,
                  decoration: _inputDecoration(
                    labelText: 'To (e.g., Salt Lake City, UT)',
                  ),
                  validator:
                      (v) => v!.isEmpty ? 'Please enter a destination' : null,
                ),
              ],
            ),
            const SizedBox(height: 24),
            _buildSectionCard(
              title: 'Request Details',
              children: [
                TextFormField(
                  controller: _dateController,
                  style: grayInputTextStyle,
                  decoration: _inputDecoration(
                    labelText: 'Date',
                    suffixIcon: IconButton(
                      icon: const Icon(
                        Icons.calendar_today,
                        color: AppColors.byuiBlue,
                      ),
                      onPressed: _selectDate,
                    ),
                  ),
                  readOnly: true,
                  validator: (v) => v!.isEmpty ? 'Please select a date' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _notesController,
                  style: grayInputTextStyle,
                  decoration: _inputDecoration(
                    labelText: 'Notes (e.g., I have one large suitcase)',
                  ),
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
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                ),
                child:
                    _isLoading
                        ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 3,
                            color: Colors.white,
                          ),
                        )
                        : const Text(
                          'Post Ride Request',
                          style: TextStyle(
                            fontWeight: FontWeight.w500,
                            fontSize: 16,
                          ),
                        ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
