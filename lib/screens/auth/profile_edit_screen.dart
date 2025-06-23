// lib/screens/profile/edit_profile_screen.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/user_service.dart';

enum UserRole { rider, driver }

class ProfileEditScreen extends StatefulWidget {
  static const String routeName = '/edit-profile';

  const ProfileEditScreen({super.key});

  @override
  State<ProfileEditScreen> createState() => _ProfileEditScreenState();
}

class _ProfileEditScreenState extends State<ProfileEditScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _facebookController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  UserRole _selectedRole = UserRole.rider;

  final _vehicleMakeController = TextEditingController();
  final _vehicleModelController = TextEditingController();
  final _vehicleColorController = TextEditingController();
  final _vehicleYearController = TextEditingController();

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    _emailController.text = currentUser.email ?? '';
    final userProfile = await UserService.fetchUserProfile(currentUser.uid);
    if (userProfile != null) {
      _nameController.text = userProfile.name;
      _phoneController.text = userProfile.phoneNumber;
      _facebookController.text = userProfile.facebookUsername ?? '';
      _selectedRole = userProfile.isDriver ? UserRole.driver : UserRole.rider;

      if (_selectedRole == UserRole.driver) {
        _vehicleMakeController.text = userProfile.vehicleMake ?? '';
        _vehicleModelController.text = userProfile.vehicleModel ?? '';
        _vehicleColorController.text = userProfile.vehicleColor ?? '';
        _vehicleYearController.text = userProfile.vehicleYear?.toString() ?? '';
      }
    }

    setState(() => _isLoading = false);
  }

  Future<void> _saveChanges() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      await UserService.updateUserProfile(currentUser.uid, {
        'name': _nameController.text.trim(),
        'phoneNumber': _phoneController.text.trim(),
        'facebookUsername': _facebookController.text.trim(),
        'isDriver': _selectedRole == UserRole.driver,
        'vehicleMake': _selectedRole == UserRole.driver ? _vehicleMakeController.text.trim() : null,
        'vehicleModel': _selectedRole == UserRole.driver ? _vehicleModelController.text.trim() : null,
        'vehicleColor': _selectedRole == UserRole.driver ? _vehicleColorController.text.trim() : null,
        'vehicleYear': _selectedRole == UserRole.driver
            ? int.tryParse(_vehicleYearController.text.trim())
            : null,
      });

      if (_emailController.text.trim() != currentUser.email) {
        await UserService.updateUserEmail(_emailController.text.trim());

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Verification email sent to ${_emailController.text.trim()}. Please verify to complete update.'),
          ),
        );
      }

      if (_passwordController.text.trim().isNotEmpty) {
        await UserService.updateUserPassword(_passwordController.text.trim());
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated!')),
      );

      Navigator.of(context).pop();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating profile: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _facebookController.dispose();
    _emailController.dispose();
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
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Name'),
                validator: (value) =>
                value == null || value.isEmpty ? 'Enter your name' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(labelText: 'Phone Number'),
                keyboardType: TextInputType.phone,
                validator: (value) =>
                value == null || value.isEmpty ? 'Enter phone number' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: 'Email'),
                keyboardType: TextInputType.emailAddress,
                validator: (value) =>
                value == null || value.isEmpty ? 'Enter email' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _facebookController,
                decoration: const InputDecoration(labelText: 'Facebook Username'),
                validator: (value) =>
                value == null || value.isEmpty ? 'Enter facebook username' : null,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _passwordController,
                decoration: InputDecoration(
                  labelText: 'New Password (optional)',
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword ? Icons.visibility_off : Icons.visibility,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscurePassword = !_obscurePassword;
                      });
                    },
                  ),
                ),
                obscureText: _obscurePassword,
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