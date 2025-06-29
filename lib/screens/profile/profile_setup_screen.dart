// lib/screens/profile/profile_setup_screen.dart
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:byui_rideshare/models/user_profile.dart';
import 'package:byui_rideshare/services/user_service.dart';
import 'package:byui_rideshare/screens/auth/auth_wrapper.dart';
import 'package:byui_rideshare/theme/app_colors.dart';

enum UserRole { rider, driver }

class ProfileSetupScreen extends StatefulWidget {
  static const String routeName = '/profile-setup';
  const ProfileSetupScreen({super.key});

  @override
  State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _facebookController = TextEditingController();
  UserRole _selectedRole = UserRole.rider;

  final _vehicleMakeController = TextEditingController();
  final _vehicleModelController = TextEditingController();
  final _vehicleColorController = TextEditingController();
  final _vehicleYearController = TextEditingController();

  bool _isLoading = false;

  // Formatter is correctly created here
  final phoneMaskFormatter = MaskTextInputFormatter(
      mask: '###-###-####',
      filter: {"#": RegExp(r'[0-9]')}
  );

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _facebookController.dispose();
    _vehicleMakeController.dispose();
    _vehicleModelController.dispose();
    _vehicleColorController.dispose();
    _vehicleYearController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('User not logged in.')));
          setState(() => _isLoading = false);
        }
        return;
      }

      final fullName = _nameController.text.trim();
      final nameParts = fullName.split(' ');
      final firstName = nameParts.isNotEmpty ? nameParts.first : '';
      final lastName = nameParts.length > 1 ? nameParts.sublist(1).join(' ') : '';

      final userProfile = UserProfile(
        uid: currentUser.uid,
        firstName: firstName,
        lastName: lastName,
        // --- IMPROVEMENT 1: Save the unmasked (clean) phone number ---
        phoneNumber: phoneMaskFormatter.getUnmaskedText(),
        facebookUsername: _facebookController.text.trim(),
        isDriver: _selectedRole == UserRole.driver,
        vehicleMake: _selectedRole == UserRole.driver
            ? _vehicleMakeController.text.trim()
            : null,
        vehicleModel: _selectedRole == UserRole.driver
            ? _vehicleModelController.text.trim()
            : null,
        vehicleColor: _selectedRole == UserRole.driver
            ? _vehicleColorController.text.trim()
            : null,
        vehicleYear: _selectedRole == UserRole.driver
            ? int.tryParse(_vehicleYearController.text.trim())
            : null,
      );

      try {
        await UserService.saveUserProfile(userProfile);
        await currentUser.updateDisplayName(fullName);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Profile saved successfully!')));
          Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (_) => const AuthWrapper()));
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Failed to save profile: $e')));
        }
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    }
  }

  InputDecoration _inputDecoration({required String labelText}) {
    return InputDecoration(
      labelText: labelText,
      border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.0),
          borderSide: const BorderSide(color: AppColors.gray300)
      ),
      focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.0),
          borderSide: const BorderSide(color: AppColors.inputFocusBlue, width: 2.0)
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.gray50,
      body: Column(
        children: [
          Container(
            width: double.infinity,
            color: AppColors.byuiBlue,
            padding: const EdgeInsets.fromLTRB(16.0, 60.0, 16.0, 24.0),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Complete Your Profile', style: TextStyle(color: Colors.white, fontSize: 24.0, fontWeight: FontWeight.w600)),
                SizedBox(height: 4.0),
                Text("Let's get you set up.", style: TextStyle(color: AppColors.blue100, fontSize: 14.0)),
              ],
            ),
          ),
          Expanded(
            child: Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(24.0),
                children: [
                  _buildSectionCard(
                    title: 'Personal Information',
                    children: [
                      TextFormField(
                        controller: _nameController,
                        decoration: _inputDecoration(labelText: 'Full Name'),
                        validator: (v) => v!.isEmpty ? 'Please enter your name' : null,
                      ),
                      const SizedBox(height: 16),
                      // --- THIS IS THE FULLY CORRECTED WIDGET ---
                      TextFormField(
                        controller: _phoneController,
                        // 1. Apply the formatter
                        inputFormatters: [phoneMaskFormatter],
                        decoration: _inputDecoration(labelText: 'Phone Number'),
                        keyboardType: TextInputType.phone,
                        // 2. Improve the validation
                        validator: (v) {
                          if (v == null || v.isEmpty) {
                            return 'Please enter your phone number';
                          }
                          if (phoneMaskFormatter.getUnmaskedText().length != 10) {
                            return 'Please enter a valid 10-digit phone number';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _facebookController,
                        decoration: _inputDecoration(labelText: 'Facebook Username'),
                        validator: (v) => v!.isEmpty ? 'Please enter your Facebook username' : null,
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  _buildSectionCard(
                      title: 'Select Your Role',
                      children: [
                        ToggleButtons(
                          isSelected: [_selectedRole == UserRole.rider, _selectedRole == UserRole.driver],
                          onPressed: (index) {
                            setState(() {
                              _selectedRole = index == 0 ? UserRole.rider : UserRole.driver;
                            });
                          },
                          borderRadius: BorderRadius.circular(8.0),
                          selectedColor: Colors.white,
                          fillColor: AppColors.byuiBlue,
                          color: AppColors.byuiBlue,
                          constraints: BoxConstraints(minHeight: 48.0, minWidth: (MediaQuery.of(context).size.width - 120) / 2),
                          children: const [
                            Padding(padding: EdgeInsets.symmetric(horizontal: 16), child: Text('Rider')),
                            Padding(padding: EdgeInsets.symmetric(horizontal: 16), child: Text('Driver')),
                          ],
                        )
                      ]
                  ),
                  if (_selectedRole == UserRole.driver) ...[
                    const SizedBox(height: 24),
                    _buildSectionCard(
                        title: 'Vehicle Information',
                        children: [
                          TextFormField(
                            controller: _vehicleMakeController,
                            decoration: _inputDecoration(labelText: 'Vehicle Make (e.g., Toyota)'),
                            validator: (v) => v!.isEmpty ? 'Please enter vehicle make' : null,
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _vehicleModelController,
                            decoration: _inputDecoration(labelText: 'Vehicle Model (e.g., Camry)'),
                            validator: (v) => v!.isEmpty ? 'Please enter vehicle model' : null,
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _vehicleColorController,
                            decoration: _inputDecoration(labelText: 'Vehicle Color (e.g., Blue)'),
                            validator: (v) => v!.isEmpty ? 'Please enter vehicle color' : null,
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _vehicleYearController,
                            decoration: _inputDecoration(labelText: 'Vehicle Year (e.g., 2022)'),
                            keyboardType: TextInputType.number,
                            validator: (v) {
                              if (v == null || v.isEmpty) return 'Please enter vehicle year';
                              if (int.tryParse(v) == null || v.length != 4) return 'Please enter a valid year';
                              return null;
                            },
                          ),
                        ]
                    ),
                  ],
                  const SizedBox(height: 32),
                  SizedBox(
                    height: 48.0,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _saveProfile,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.byuiBlue,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
                      ),
                      child: _isLoading
                          ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(strokeWidth: 3, color: Colors.white))
                          : const Text('Save Profile', style: TextStyle(fontWeight: FontWeight.w500)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
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