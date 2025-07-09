// lib/screens/rides/fulfill_request_screen.dart

import 'package:byui_rideshare/models/posted_request.dart';
// ✅ Using your actual service file
import 'package:byui_rideshare/services/posted_request_service.dart';
import 'package:byui_rideshare/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class FulfillRequestScreen extends StatefulWidget {
  final PostedRequest request;
  const FulfillRequestScreen({super.key, required this.request});

  @override
  State<FulfillRequestScreen> createState() => _FulfillRequestScreenState();
}

class _FulfillRequestScreenState extends State<FulfillRequestScreen> {
  final _seatsController = TextEditingController();
  final _fareController = TextEditingController();
  DateTime? _selectedDateTime;
  bool _isLoading = false;

  Future<void> _selectDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: widget.request.requestDateStart.toDate(),
      firstDate: widget.request.requestDateStart.toDate(),
      lastDate: widget.request.requestDateEnd.toDate(),
    );
    if (date == null) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(DateTime.now()),
    );
    if (time == null) return;

    setState(() {
      _selectedDateTime = DateTime(date.year, date.month, date.day, time.hour, time.minute);
    });
  }

  Future<void> _submitOffer() async {
    if (_seatsController.text.isEmpty || _fareController.text.isEmpty || _selectedDateTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please fill all fields.')));
      return;
    }
    setState(() => _isLoading = true);

    try {
      // ✅ CORRECTED to use PostedRequestService
      await PostedRequestService.fulfillRideRequest(
        requestId: widget.request.id,
        exactDateTime: _selectedDateTime!,
        seats: int.parse(_seatsController.text),
        fare: double.parse(_fareController.text),
        origin: widget.request.fromLocation,
        destination: widget.request.toLocation,
        initialRiders: widget.request.riders,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Ride offer posted successfully! The request has been removed.'), backgroundColor: Colors.green));
        // Pop twice to go back to the main list screen
        Navigator.of(context).pop();
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to post offer: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Offer Ride For Request'), backgroundColor: AppColors.byuiBlue),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Offering ride for:', style: Theme.of(context).textTheme.titleMedium),
            Text('${widget.request.fromLocation} to ${widget.request.toLocation}', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
            const Divider(height: 32),
            OutlinedButton.icon(
              icon: const Icon(Icons.calendar_today),
              label: Text(_selectedDateTime == null ? 'Select Exact Date & Time' : DateFormat.yMMMd().add_jm().format(_selectedDateTime!)),
              onPressed: _selectDate,
            ),
            const SizedBox(height: 16),
            TextField(controller: _seatsController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Available Seats', border: OutlineInputBorder())),
            const SizedBox(height: 16),
            TextField(controller: _fareController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Fare per Seat (\$)', border: OutlineInputBorder())),
            const SizedBox(height: 32),
            _isLoading
                ? const Center(child: CircularProgressIndicator())
                : SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(onPressed: _submitOffer, child: const Text('Post Offer')),
            ),
          ],
        ),
      ),
    );
  }
}