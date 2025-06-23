// lib/screens/profile/profile_setup_screen.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart'; // For getting current user UID
import '../../models/user_profile.dart';
import '../../services/user_service.dart';
// Import your main app screen (e.g., MyHomePage or RideListScreen)
// import '../home_screen.dart'; // Replace with your actual home screen import
import '../auth/auth_wrapper.dart'; // Assuming this leads to your main screen or dashboard

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
  UserRole _selectedRole = UserRole.rider; // Default role

  // Driver specific fields
  final _vehicleMakeController = TextEditingController();
  final _vehicleModelController = TextEditingController();
  final _vehicleColorController = TextEditingController();
  final _vehicleYearController = TextEditingController();

  final UserService _userService = UserService();
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _vehicleMakeController.dispose();
    _vehicleModelController.dispose();
    _vehicleColorController.dispose();
    _vehicleYearController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('User not logged in.')),
        );
        setState(() {
          _isLoading = false;
        });
        return;
      }

      final userProfile = UserProfile(
        uid: currentUser.uid,
        name: _nameController.text.trim(),
        phoneNumber: _phoneController.text.trim(),
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

        // --- NEW LINE ADDED HERE ---
        // Update Firebase Auth displayName with the name from the profile setup
        await currentUser.updateDisplayName(_nameController.text.trim());
        print('Firebase Auth Display Name Updated: ${currentUser.displayName}');
        // --- END NEW LINE ---

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile saved successfully!')),
        );
        // Navigate to the main part of the app
        // Replace with your actual navigation logic and route
        // Assuming AuthWrapper correctly directs to the main content
        Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const AuthWrapper()));
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save profile: $e')),
        );
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Complete Your Profile'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: <Widget>[
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Name'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(labelText: 'Phone Number'),
                keyboardType: TextInputType.phone,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your phone number';
                  }
                  // Add more specific phone validation if needed
                  return null;
                },
              ),
              const SizedBox(height: 24),
              const Text('Select Your Role:', style: TextStyle(fontSize: 16)),
              RadioListTile<UserRole>(
                title: const Text('Rider'),
                value: UserRole.rider,
                groupValue: _selectedRole,
                onChanged: (UserRole? value) {
                  setState(() {
                    _selectedRole = value!;
                  });
                },
              ),
              RadioListTile<UserRole>(
                title: const Text('Driver'),
                value: UserRole.driver,
                groupValue: _selectedRole,
                onChanged: (UserRole? value) {
                  setState(() {
                    _selectedRole = value!;
                  });
                },
              ),
              if (_selectedRole == UserRole.driver) ...[
                const SizedBox(height: 24),
                const Text('Vehicle Information:',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                TextFormField(
                  controller: _vehicleMakeController,
                  decoration: const InputDecoration(labelText: 'Vehicle Make (e.g., Toyota)'),
                  validator: (value) {
                    if (_selectedRole == UserRole.driver && (value == null || value.isEmpty)) {
                      return 'Please enter vehicle make';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _vehicleModelController,
                  decoration: const InputDecoration(labelText: 'Vehicle Model (e.g., Camry)'),
                  validator: (value) {
                    if (_selectedRole == UserRole.driver && (value == null || value.isEmpty)) {
                      return 'Please enter vehicle model';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _vehicleColorController,
                  decoration: const InputDecoration(labelText: 'Vehicle Color (e.g., Blue)'),
                  validator: (value) {
                    if (_selectedRole == UserRole.driver && (value == null || value.isEmpty)) {
                      return 'Please enter vehicle color';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _vehicleYearController,
                  decoration: const InputDecoration(labelText: 'Vehicle Year (e.g., 2020)'),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (_selectedRole == UserRole.driver) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter vehicle year';
                      }
                      if (int.tryParse(value) == null || value.length != 4) {
                        return 'Please enter a valid year';
                      }
                    }
                    return null;
                  },
                ),
              ],
              const SizedBox(height: 32),
              _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton(
                onPressed: _saveProfile,
                child: const Text('Save Profile'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}