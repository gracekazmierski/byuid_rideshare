import 'package:byui_rideshare/models/posted_request.dart';
import 'package:byui_rideshare/services/posted_request_service.dart';
import 'package:byui_rideshare/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';
import 'package:byui_rideshare/utils/time_input_formatter.dart';
import 'package:byui_rideshare/models/ride.dart';
import 'package:byui_rideshare/screens/rides/ride_confirmation_screen.dart';

enum AmPm { am, pm }

class FulfillRequestScreen extends StatefulWidget {
  final PostedRequest request;
  const FulfillRequestScreen({super.key, required this.request});

  @override
  State<FulfillRequestScreen> createState() => _FulfillRequestScreenState();
}

class _FulfillRequestScreenState extends State<FulfillRequestScreen> {
  final _formKey = GlobalKey<FormState>();
  final _seatsController = TextEditingController();
  final _fareController = TextEditingController();
  final _timeController = TextEditingController();
  final _fareFocusNode = FocusNode();

  DateTime? _selectedDateTime;
  AmPm? _selectedAmPm;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _fareFocusNode.addListener(_formatFareOnLostFocus);
  }

  @override
  void dispose() {
    _seatsController.dispose();
    _fareController.dispose();
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
        if (hour == 12) hour = 0;
      } else {
        if (hour != 12) hour += 12;
      }
      return TimeOfDay(hour: hour, minute: minute);
    } catch (e) {
      return null;
    }
  }

  Future<void> _submitOffer() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final requestDate = widget.request.requestDate.toDate();
    final rideTime = _parseTimeWithAmPm(_timeController.text, _selectedAmPm);

    if (rideTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a valid time and AM/PM.')),
      );
      setState(() => _isLoading = false);
      return;
    }

    final finalDateTime = DateTime(
      requestDate.year,
      requestDate.month,
      requestDate.day,
      rideTime.hour,
      rideTime.minute,
    );

    try {
      final Ride newRide = await PostedRequestService.fulfillRideRequest(
        requestId: widget.request.id,
        exactDateTime: finalDateTime,
        seats: int.parse(_seatsController.text),
        fare: double.parse(_fareController.text),
        origin: widget.request.fromLocation,
        destination: widget.request.toLocation,
        initialRiders: widget.request.riders,
      );

      if (mounted) {
        // ✅ FIX: Removed the 'isEditing' parameter to match your
        // RideConfirmationScreen constructor.
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (context) => RideConfirmationScreen(ride: newRide),
          ),
          (route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to post offer: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
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
                    'Offer Ride',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24.0,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 2.0),
                  Text(
                    "Fulfilling a student's request",
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
                  initialValue: widget.request.fromLocation,
                  readOnly: true,
                  style: grayInputTextStyle,
                  decoration: _inputDecoration(labelText: 'Origin'),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  initialValue: widget.request.toLocation,
                  readOnly: true,
                  style: grayInputTextStyle,
                  decoration: _inputDecoration(labelText: 'Destination'),
                ),
              ],
            ),
            const SizedBox(height: 24),
            _buildSectionCard(
              title: 'Ride Specifics',
              children: [
                TextFormField(
                  controller: _seatsController,
                  style: grayInputTextStyle,
                  decoration: _inputDecoration(labelText: 'Available Seats'),
                  keyboardType: TextInputType.number,
                  validator:
                      (v) =>
                          (v == null || v.isEmpty || int.tryParse(v) == null)
                              ? 'Enter a valid number'
                              : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _fareController,
                  style: grayInputTextStyle,
                  focusNode: _fareFocusNode,
                  decoration: _inputDecoration(
                    labelText: 'Fare per person (\$)',
                  ),
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  validator:
                      (v) =>
                          (v == null || v.isEmpty || double.tryParse(v) == null)
                              ? 'Enter a valid fare'
                              : null,
                ),
              ],
            ),
            const SizedBox(height: 24),
            _buildSectionCard(
              title: 'Schedule',
              children: [
                TextFormField(
                  initialValue: DateFormat(
                    'EEEE, MMMM d, yyyy',
                  ).format(widget.request.requestDate.toDate()),
                  readOnly: true,
                  style: grayInputTextStyle,
                  decoration: _inputDecoration(labelText: 'Date'),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _timeController,
                  style: grayInputTextStyle,
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
                      if (minute < 0 || minute > 59)
                        return 'Minute must be 0-59';
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
                        _selectedAmPm =
                            newSelection.isEmpty ? null : newSelection.first;
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
                      side: const BorderSide(color: AppColors.gray300),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
            SizedBox(
              height: 48.0,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _submitOffer,
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
                          'Post Offer',
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
