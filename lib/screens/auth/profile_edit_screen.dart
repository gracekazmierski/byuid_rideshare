// lib/screens/profile/edit_profile_screen.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import '../../models/user_profile.dart';
import '../../services/user_service.dart';
import 'auth_wrapper.dart';

enum UserRole { rider, driver }

class ProfileEditScreen extends StatefulWidget {
  static const String routeName = '/edit-profile';

  const ProfileEditScreen({super.key});

  @override
  State<ProfileEditScreen> createState() => _ProfileEditScreenState();
}

class _ProfileEditScreenState extends State<ProfileEditScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _facebookController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  UserRole _selectedRole = UserRole.rider;

  final _vehicleMakeController = TextEditingController();
  final _vehicleModelController = TextEditingController();
  final _vehicleColorController = TextEditingController();
  final _vehicleYearController = TextEditingController();

  bool _isLoading = true;

  Future<void> _changePassword() async {
    final currentPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();

    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        bool obscureCurrent = true;
        bool obscureNew = true;

        return StatefulBuilder(
          builder: (context, setState) => AlertDialog(
            title: const Text("Change Password"),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: currentPasswordController,
                  obscureText: obscureCurrent,
                  decoration: InputDecoration(
                    labelText: 'Current Password',
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      icon: Icon(
                        obscureCurrent ? Icons.visibility_off : Icons.visibility,
                      ),
                      onPressed: () {
                        setState(() {
                          obscureCurrent = !obscureCurrent;
                        });
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: newPasswordController,
                  obscureText: obscureNew,
                  decoration: InputDecoration(
                    labelText: 'New Password',
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      icon: Icon(
                        obscureNew ? Icons.visibility_off : Icons.visibility,
                      ),
                      onPressed: () {
                        setState(() {
                          obscureNew = !obscureNew;
                        });
                      },
                    ),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text("Cancel")),
              TextButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: const Text("Change")),
            ],
          ),
        );
      },
    );

    if (result == true) {
      try {
        final user = FirebaseAuth.instance.currentUser;
        final email = user?.email;
        if (user == null || email == null) throw Exception("User not signed in");

        final cred = EmailAuthProvider.credential(
          email: email,
          password: currentPasswordController.text,
        );

        await user.reauthenticateWithCredential(cred);
        await user.updatePassword(newPasswordController.text);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Password changed successfully.")),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to change password: ${e.toString()}")),
        );
      }
    }
  }

  @override
  void initState() {
    super.initState();
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      _loadUserProfile(currentUser.uid);
    }
  }

  // to allow for phone input to have the dashes
  final _phoneFormatter = MaskTextInputFormatter(
    mask: '(###) ###-####',
    filter: { "#": RegExp(r'[0-9]') },
    type: MaskAutoCompletionType.lazy,
  );

  // for _loadProfileData
  String _formatPhoneNumber(String number) {
    final digits = number.replaceAll(RegExp(r'\D'), '');
    if (digits.length == 10) {
      return '(${digits.substring(0, 3)}) ${digits.substring(3, 6)}-${digits.substring(6)}';
    }
    return number; // Return as-is if not 10 digits
  }

  Future<void> _loadUserProfile(String uid) async {
    setState(() {
      _isLoading = true;
    });

    final profile = await UserService.fetchUserProfile(uid);
    if (profile != null) {
      _firstNameController.text = profile.firstName;
      _lastNameController.text = profile.lastName;
      _phoneController.text = _formatPhoneNumber(profile.phoneNumber);
      _facebookController.text = profile.facebookUsername ?? '';

      if (profile.isDriver) {
        _selectedRole = UserRole.driver;
        _vehicleMakeController.text = profile.vehicleMake ?? '';
        _vehicleModelController.text = profile.vehicleModel ?? '';
        _vehicleColorController.text = profile.vehicleColor ?? '';
        _vehicleYearController.text = profile.vehicleYear?.toString() ?? '';
      } else {
        _selectedRole = UserRole.rider;
      }
    }

    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _saveChanges() async {
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
        firstName: _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
        phoneNumber: _phoneFormatter.getUnmaskedText(),
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

        // Update Firebase Auth displayName with the name from the profile setup
        await currentUser.updateDisplayName(
            '${_firstNameController.text.trim()} ${_lastNameController.text.trim()}'
        );


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
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    _facebookController.dispose();
    _passwordController.dispose();
    _vehicleMakeController.dispose();
    _vehicleModelController.dispose();
    _vehicleColorController.dispose();
    _vehicleYearController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Edit Your Profile')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _firstNameController,
                decoration: const InputDecoration(labelText: 'First Name'),
                validator: (value) =>
                    value == null || value.isEmpty ? 'Enter your first name' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _lastNameController,
                decoration: const InputDecoration(labelText: 'Last Name'),
                validator: (value) =>
                    value == null || value.isEmpty ? 'Enter your last name' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(labelText: 'Phone Number'),
                keyboardType: TextInputType.phone,
                inputFormatters: [_phoneFormatter],
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your phone number';
                  }
                  // Check if all digits are entered
                  if (_phoneFormatter.getUnmaskedText().length != 10) {
                    return 'Please enter a valid 10-digit phone number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _facebookController,
                decoration: const InputDecoration(labelText: 'Facebook Username'),
                validator: (value) =>
                value == null || value.isEmpty ? 'Enter facebook username' : null,
              ),
              const SizedBox(height: 24),
              const Text('Select Your Role:', style: TextStyle(fontSize: 16)),
              RadioListTile<UserRole>(
                title: const Text('Rider'),
                value: UserRole.rider,
                groupValue: _selectedRole,
                onChanged: (UserRole? value) =>
                    setState(() => _selectedRole = value!),
              ),
              RadioListTile<UserRole>(
                title: const Text('Driver'),
                value: UserRole.driver,
                groupValue: _selectedRole,
                onChanged: (UserRole? value) =>
                    setState(() => _selectedRole = value!),
              ),
              if (_selectedRole == UserRole.driver) ...[
                const SizedBox(height: 24),
                const Text('Vehicle Info:',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                TextFormField(
                  controller: _vehicleMakeController,
                  decoration: const InputDecoration(labelText: 'Vehicle Make'),
                ),
                TextFormField(
                  controller: _vehicleModelController,
                  decoration: const InputDecoration(labelText: 'Vehicle Model'),
                ),
                TextFormField(
                  controller: _vehicleColorController,
                  decoration: const InputDecoration(labelText: 'Vehicle Color'),
                ),
                TextFormField(
                  controller: _vehicleYearController,
                  decoration: const InputDecoration(labelText: 'Vehicle Year'),
                  keyboardType: TextInputType.number,
                ),
              ],
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _changePassword,
                child: const Text("Change Password"),
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _saveChanges,
                child: const Text('Save Changes'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}