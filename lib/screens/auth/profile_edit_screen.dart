// lib/screens/profile/profile_edit_screen.dart
import 'dart:io';
import 'dart:typed_data'; // For Uint8List;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

import '../../models/user_profile.dart';
import '../../services/user_service.dart';
import '../../theme/app_colors.dart';
import '../rides/ride_list_screen.dart';

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
  final _vehicleMakeController = TextEditingController();
  final _vehicleModelController = TextEditingController();
  final _vehicleColorController = TextEditingController();
  final _vehicleYearController = TextEditingController();

  final ImagePicker _picker = ImagePicker();
  File? _selectedImage;

  UserRole _selectedRole = UserRole.rider;
  Uint8List? _selectedImageBytes;
  UserProfile? _loadedProfile;
  bool _isLoading = true;
  bool _isSaving = false;

  final _phoneFormatter = MaskTextInputFormatter(
    mask: '###-###-####',
    filter: {"#": RegExp(r'[0-9]')},
    type: MaskAutoCompletionType.lazy,
  );

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    _facebookController.dispose();
    _vehicleMakeController.dispose();
    _vehicleModelController.dispose();
    _vehicleColorController.dispose();
    _vehicleYearController.dispose();
    super.dispose();
  }

  Future<void> _loadUserProfile() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      setState(() => _isLoading = false);
      return;
    }

    final profile = await UserService.fetchUserProfile(uid);
    if (profile != null && mounted) {
      setState(() {
        _loadedProfile = profile;

        _firstNameController.text = profile.firstName;
        _lastNameController.text = profile.lastName;

        // ✅ FIX: Use the formatter to mask the text when loading it
        _phoneController.text = _phoneFormatter.maskText(profile.phoneNumber);

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
        _isLoading = false;
      });
    } else {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) {
      print('❌ Form validation failed');
      return;
    }

    setState(() => _isSaving = true);
    print('⏳ Saving started');

    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      print('❌ No logged in user');
      setState(() => _isSaving = false);
      return;
    }

    String? profileUrl;
    try {
      if (_selectedImage != null) {
        print('📷 Uploading File image...');
        profileUrl = await UserService().uploadProfilePicture(currentUser.uid, _selectedImage!);
      } else if (_selectedImageBytes != null) {
        print('🧠 Uploading memory image...');
        profileUrl = await UserService().uploadProfilePictureFromBytes(currentUser.uid, _selectedImageBytes!);
      }

      print('🧱 Constructing user profile');
      final userProfile = UserProfile(
        uid: currentUser.uid,
        firstName: _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
        phoneNumber: _phoneController.text.replaceAll(RegExp(r'[^0-9]'), ''),
        facebookUsername: _facebookController.text.trim(),
        isDriver: _selectedRole == UserRole.driver,
        vehicleMake: _selectedRole == UserRole.driver ? _vehicleMakeController.text.trim() : null,
        vehicleModel: _selectedRole == UserRole.driver ? _vehicleModelController.text.trim() : null,
        vehicleColor: _selectedRole == UserRole.driver ? _vehicleColorController.text.trim() : null,
        vehicleYear: _selectedRole == UserRole.driver ? int.tryParse(_vehicleYearController.text.trim()) : null,
        profilePictureUrl: profileUrl ?? _loadedProfile?.profilePictureUrl,
      );

      print('💾 Saving profile to Firestore...');
      await UserService.saveUserProfile(userProfile);
      print('✅ Profile saved');

      await currentUser.updateDisplayName('${userProfile.firstName} ${userProfile.lastName}'.trim());

      if (mounted) {
        print('🔁 Navigating to RideListScreen');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile saved successfully!')),
        );
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const RideListScreen()),
              (route) => false,
        );
      }
    } catch (e) {
      print('❌ Error in saveChanges: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save profile: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
        print('✅ Saving flag reset');
      }
    }
  }


  Future<void> _changePassword() async {
    final currentPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        bool obscureCurrent = true;
        bool obscureNew = true;

        return StatefulBuilder(
          builder: (context, setState) => AlertDialog(
            // Styled shape and title
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.0)),
            title: const Text(
              "Change Password",
              style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textGray600),
            ),
            content: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Styled "Current Password" field
                  TextFormField(
                    controller: currentPasswordController,
                    obscureText: obscureCurrent,
                    decoration: _inputDecoration(labelText: 'Current Password').copyWith(
                      suffixIcon: IconButton(
                        icon: Icon(obscureCurrent ? Icons.visibility_off : Icons.visibility),
                        onPressed: () => setState(() => obscureCurrent = !obscureCurrent),
                      ),
                    ),
                    validator: (v) => v!.isEmpty ? 'Cannot be empty' : null,
                  ),
                  const SizedBox(height: 16),
                  // Styled "New Password" field
                  TextFormField(
                    controller: newPasswordController,
                    obscureText: obscureNew,
                    decoration: _inputDecoration(labelText: 'New Password').copyWith(
                      suffixIcon: IconButton(
                        icon: Icon(obscureNew ? Icons.visibility_off : Icons.visibility),
                        onPressed: () => setState(() => obscureNew = !obscureNew),
                      ),
                    ),
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Cannot be empty';
                      if (v.length < 6) return 'Must be at least 6 characters';
                      return null;
                    },
                  ),
                ],
              ),
            ),
            // Styled action buttons
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text("Cancel", style: TextStyle(color: AppColors.textGray500)),
              ),
              ElevatedButton(
                onPressed: () {
                  if (formKey.currentState!.validate()) {
                    Navigator.of(context).pop(true);
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.byuiBlue,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
                ),
                child: const Text("Change"),
              ),
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

        if(mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Password changed successfully.")),
          );
        }
      } catch (e) {
        if(mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Failed to change password: ${e.toString()}")),
          );
        }
      }
    }

    currentPasswordController.dispose();
    newPasswordController.dispose();
  }

  // --- NEW: AppBar Widget ---
  // This now matches the structure from your other screens
  // In lib/screens/profile/profile_edit_screen.dart

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return PreferredSize(
      preferredSize: const Size.fromHeight(kToolbarHeight + 40),
      child: Container(
        color: AppColors.byuiBlue,
        // The 'const' keyword has been removed from the next line
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
                  Text('Edit Profile', style: TextStyle(color: Colors.white, fontSize: 24.0, fontWeight: FontWeight.w600)),
                  SizedBox(height: 2.0),
                  Text("Keep your information up to date", style: TextStyle(color: AppColors.blue100, fontSize: 14.0)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- UI Build Method ---
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.gray50,
      // --- CHANGE: Using the new AppBar method ---
      appBar: _buildAppBar(context),
      // --- CHANGE: The body no longer contains the header ---
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Stack(
        children: [
          Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 100),
              children: [
                Center(
                  child: Column(
                    children: [
                      GestureDetector(
                        onTap: () async {
                          final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
                          if (pickedFile != null) {
                            if (kIsWeb) {
                              final bytes = await pickedFile.readAsBytes();
                              setState(() {
                                _selectedImageBytes = bytes;
                                _selectedImage = null; // to avoid conflict
                              });
                            } else {
                              setState(() {
                                _selectedImage = File(pickedFile.path);
                                _selectedImageBytes = null;
                              });
                            }
                          }

                        },
                        child: CircleAvatar(
                          radius: 50,
                          backgroundColor: AppColors.blue100,
                          backgroundImage: _selectedImageBytes != null
                              ? MemoryImage(_selectedImageBytes!)
                              : _selectedImage != null
                              ? FileImage(_selectedImage!)
                              : (_loadedProfile?.profilePictureUrl != null &&
                              _loadedProfile!.profilePictureUrl!.isNotEmpty)
                              ? NetworkImage(_loadedProfile!.profilePictureUrl!)
                              : null,
                          child: (_selectedImageBytes == null &&
                              _selectedImage == null &&
                              (_loadedProfile?.profilePictureUrl == null ||
                                  _loadedProfile!.profilePictureUrl!.isEmpty))
                              ? const Icon(Icons.person, size: 40, color: Colors.white)
                              : null,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: () async {
                          final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
                          if (pickedFile != null) {
                            if (kIsWeb) {
                              final bytes = await pickedFile.readAsBytes();
                              setState(() {
                                _selectedImageBytes = bytes;
                                _selectedImage = null; // to avoid conflict
                              });
                            } else {
                              setState(() {
                                _selectedImage = File(pickedFile.path);
                                _selectedImageBytes = null;
                              });
                            }
                          }

                        },
                        child: const Text("Change Profile Image"),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                _buildSectionCard(
                  title: 'Personal Information',
                  children: [
                    TextFormField(controller: _firstNameController, decoration: _inputDecoration(labelText: 'First Name'), validator: (v) => v!.isEmpty ? 'Enter first name' : null),
                    const SizedBox(height: 16),
                    TextFormField(controller: _lastNameController, decoration: _inputDecoration(labelText: 'Last Name'), validator: (v) => v!.isEmpty ? 'Enter last name' : null),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _phoneController,
                      decoration: _inputDecoration(labelText: 'Phone Number'),
                      keyboardType: TextInputType.phone,
                      inputFormatters: [_phoneFormatter],
                      // ✅ FIX: Get the text from the controller directly for validation
                      validator: (value) {
                        final unmaskedText = value?.replaceAll(RegExp(r'[^0-9]'), '');
                        if (unmaskedText == null || unmaskedText.length != 10) {
                          return 'Enter a valid 10-digit phone number';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(controller: _facebookController, decoration: _inputDecoration(labelText: 'Facebook Username')),
                  ],
                ),
                const SizedBox(height: 24),
                _buildSectionCard(
                  title: 'Account Security',
                  children: [
                    OutlinedButton.icon(
                      icon: const Icon(Icons.lock_outline),
                      label: const Text('Change Password'),
                      onPressed: _changePassword,
                      style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.byuiBlue,
                          side: const BorderSide(color: AppColors.gray200),
                          minimumSize: const Size(double.infinity, 48)
                      ),
                    )
                  ],
                ),
                const SizedBox(height: 24),
                _buildSectionCard(
                  title: 'Your Role',
                  children: [
                    ToggleButtons(
                      isSelected: [_selectedRole == UserRole.rider, _selectedRole == UserRole.driver],
                      onPressed: (index) => setState(() => _selectedRole = index == 0 ? UserRole.rider : UserRole.driver),
                      borderRadius: BorderRadius.circular(8.0),
                      selectedColor: Colors.white,
                      fillColor: AppColors.byuiBlue,
                      color: AppColors.byuiBlue,
                      constraints: BoxConstraints(minHeight: 48.0, minWidth: (MediaQuery.of(context).size.width - 110) / 2),
                      children: const [Text('Rider'), Text('Driver')],
                    )
                  ],
                ),
                if (_selectedRole == UserRole.driver) ...[
                  const SizedBox(height: 24),
                  _buildSectionCard(
                    title: 'Vehicle Information',
                    children: [
                      TextFormField(controller: _vehicleMakeController, decoration: _inputDecoration(labelText: 'Vehicle Make')),
                      const SizedBox(height: 16),
                      TextFormField(controller: _vehicleModelController, decoration: _inputDecoration(labelText: 'Vehicle Model')),
                      const SizedBox(height: 16),
                      TextFormField(controller: _vehicleColorController, decoration: _inputDecoration(labelText: 'Vehicle Color')),
                      const SizedBox(height: 16),
                      TextFormField(controller: _vehicleYearController, decoration: _inputDecoration(labelText: 'Vehicle Year'), keyboardType: TextInputType.number),
                    ],
                  ),
                ],
              ],
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16.0),
              color: AppColors.gray50,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _saveChanges,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.byuiBlue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16.0),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
                ),
                child: _isSaving
                    ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(strokeWidth: 3, color: Colors.white))
                    : const Text('Save Changes', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- HELPER WIDGETS ---
  InputDecoration _inputDecoration({required String labelText}) {
    return InputDecoration(
      labelText: labelText,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.0), borderSide: const BorderSide(color: AppColors.gray200)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8.0), borderSide: const BorderSide(color: AppColors.inputFocusBlue, width: 2.0)),
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