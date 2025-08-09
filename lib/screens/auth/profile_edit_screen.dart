// lib/screens/profile/profile_edit_screen.dart
import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

// Firebase
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// UI / utils
import 'package:image_picker/image_picker.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
  // ----------------------------
  // Config for BYUI email-link (Option A)
  static const String _emailLinkContinueUrl =
      'https://byuirideshare.web.app/#/byui-verify'; // <-- hash route
  static const String _androidPackageName = 'com.rexride.app';
  static const String _iOSBundleId = 'com.rexride.app';
  // static const String _dynamicLinkDomain = 'rexride.page.link'; // optional

  // ----------------------------
  // Form Controllers & State
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

  // Firestore watcher for verification flip (optional but helpful)
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _verifyWatch;

  // Phone mask
  final _phoneFormatter = MaskTextInputFormatter(
    mask: '###-###-####',
    filter: {"#": RegExp(r'[0-9]')},
    type: MaskAutoCompletionType.lazy,
  );

  // ----------------------------
  // BYUI Verification state
  String? _byuiEmail;
  bool _byuiVerified = false;
  bool _sendingByuiEmail = false;
  Timer? _resendTimer;
  int _resendRemaining = 0; // seconds left until you can resend
  bool get _canResendByui => !_sendingByuiEmail && _resendRemaining == 0;

  bool _handledArgs = false; // to process Navigator arguments once

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_handledArgs) return;
    _handledArgs = true;

    // If we were redirected back from /byui-verify with success, show it now.
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is Map && args['byuiVerified'] == true) {
      setState(() {
        _byuiVerified = true;
        final emailArg = args['byuiEmail'];
        if (emailArg is String) _byuiEmail = emailArg;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('BYUI email verified.')),
      );
    }
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
    _resendTimer?.cancel();
    _verifyWatch?.cancel();
    super.dispose();
  }

  // ----------------------------
  // Load profile + BYUI flags
  Future<void> _loadUserProfile() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      setState(() => _isLoading = false);
      return;
    }

    final profile = await UserService.fetchUserProfile(uid);
    if (mounted) {
      setState(() {
        _loadedProfile = profile;
        if (profile != null) {
          _firstNameController.text = profile.firstName;
          _lastNameController.text = profile.lastName;
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
        }
      });
    }

    // Load BYUI verification status from Firestore
    try {
      final snap = await FirebaseFirestore.instance.collection('users').doc(uid).get();
      final data = snap.data();
      if (mounted) {
        setState(() {
          _byuiEmail = data?['byuiEmail'] as String?;
          _byuiVerified = (data?['byuiEmailVerified'] == true);
        });
      }
    } catch (_) {}

    if (mounted) setState(() => _isLoading = false);
  }

  // ----------------------------
  // Save profile changes
  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) {
      debugPrint('❌ Form validation failed');
      return;
    }

    setState(() => _isSaving = true);
    debugPrint('⏳ Saving started');

    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      debugPrint('❌ No logged in user');
      setState(() => _isSaving = false);
      return;
    }

    String? profileUrl;
    try {
      if (_selectedImage != null) {
        debugPrint('📷 Uploading File image...');
        profileUrl = await UserService().uploadProfilePicture(currentUser.uid, _selectedImage!);
      } else if (_selectedImageBytes != null) {
        debugPrint('🧠 Uploading memory image...');
        profileUrl =
        await UserService().uploadProfilePictureFromBytes(currentUser.uid, _selectedImageBytes!);
      }

      debugPrint('🧱 Constructing user profile');
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
        vehicleYear:
        _selectedRole == UserRole.driver ? int.tryParse(_vehicleYearController.text.trim()) : null,
        profilePictureUrl: profileUrl ?? _loadedProfile?.profilePictureUrl,
      );

      debugPrint('💾 Saving profile to Firestore...');
      await UserService.saveUserProfile(userProfile);
      debugPrint('✅ Profile saved');

      await currentUser.updateDisplayName('${userProfile.firstName} ${userProfile.lastName}'.trim());

      if (mounted) {
        debugPrint('🔁 Navigating to RideListScreen');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile saved successfully!')),
        );
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const RideListScreen()),
              (route) => false,
        );
      }
    } catch (e) {
      debugPrint('❌ Error in saveChanges: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save profile: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
        debugPrint('✅ Saving flag reset');
      }
    }
  }

  // ----------------------------
  // AppBar
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
                  Text('Edit Profile',
                      style: TextStyle(color: Colors.white, fontSize: 24.0, fontWeight: FontWeight.w600)),
                  SizedBox(height: 2.0),
                  Text("Keep your information up to date",
                      style: TextStyle(color: AppColors.blue100, fontSize: 14.0)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ----------------------------
  // Build
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.gray50,
      appBar: _buildAppBar(context),
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
                          final pickedFile =
                          await _picker.pickImage(source: ImageSource.gallery);
                          if (pickedFile != null) {
                            if (kIsWeb) {
                              final bytes = await pickedFile.readAsBytes();
                              setState(() {
                                _selectedImageBytes = bytes;
                                _selectedImage = null;
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
                              ? FileImage(_selectedImage!) as ImageProvider
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
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.byuiBlue,
                        ).copyWith(
                          overlayColor: WidgetStateProperty.resolveWith(
                                (states) => states.contains(WidgetState.pressed)
                                ? AppColors.blue100.withValues(alpha: 0.2)
                                : null,
                          ),
                        ),
                        onPressed: () async {
                          final pickedFile =
                          await _picker.pickImage(source: ImageSource.gallery);
                          if (pickedFile != null) {
                            if (kIsWeb) {
                              final bytes = await pickedFile.readAsBytes();
                              setState(() {
                                _selectedImageBytes = bytes;
                                _selectedImage = null;
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

                // Personal Info
                _buildSectionCard(
                  title: 'Personal Information',
                  children: [
                    TextFormField(
                      controller: _firstNameController,
                      decoration: _inputDecoration(labelText: 'First Name'),
                      validator: (v) => v!.isEmpty ? 'Enter first name' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _lastNameController,
                      decoration: _inputDecoration(labelText: 'Last Name'),
                      validator: (v) => v!.isEmpty ? 'Enter last name' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _phoneController,
                      decoration: _inputDecoration(labelText: 'Phone Number'),
                      keyboardType: TextInputType.phone,
                      inputFormatters: [_phoneFormatter],
                      validator: (value) {
                        final unmaskedText = value?.replaceAll(RegExp(r'[^0-9]'), '');
                        if (unmaskedText == null || unmaskedText.length != 10) {
                          return 'Enter a valid 10-digit phone number';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _facebookController,
                      decoration:
                      _inputDecoration(labelText: 'Facebook Username'),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // Account Security
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
                        minimumSize: const Size(double.infinity, 48),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // BYUI Verification
                _buildByuiVerificationCard(),

                const SizedBox(height: 24),

                // Role
                _buildSectionCard(
                  title: 'Your Role',
                  children: [
                    ToggleButtons(
                      isSelected: [
                        _selectedRole == UserRole.rider,
                        _selectedRole == UserRole.driver
                      ],
                      onPressed: (index) => setState(() =>
                      _selectedRole =
                      index == 0 ? UserRole.rider : UserRole.driver),
                      borderRadius: BorderRadius.circular(8.0),
                      selectedColor: Colors.white,
                      fillColor: AppColors.byuiBlue,
                      color: AppColors.byuiBlue,
                      constraints: BoxConstraints(
                        minHeight: 48.0,
                        minWidth:
                        (MediaQuery.of(context).size.width - 110) / 2,
                      ),
                      children: const [Text('Rider'), Text('Driver')],
                    ),
                  ],
                ),

                if (_selectedRole == UserRole.driver) ...[
                  const SizedBox(height: 24),
                  _buildSectionCard(
                    title: 'Vehicle Information',
                    children: [
                      TextFormField(
                        controller: _vehicleMakeController,
                        decoration: _inputDecoration(labelText: 'Vehicle Make'),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _vehicleModelController,
                        decoration: _inputDecoration(labelText: 'Vehicle Model'),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _vehicleColorController,
                        decoration: _inputDecoration(labelText: 'Vehicle Color'),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _vehicleYearController,
                        decoration: _inputDecoration(labelText: 'Vehicle Year'),
                        keyboardType: TextInputType.number,
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),

          // Save button
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
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                ),
                child: _isSaving
                    ? const SizedBox(
                  height: 24,
                  width: 24,
                  child: CircularProgressIndicator(
                      strokeWidth: 3, color: Colors.white),
                )
                    : const Text('Save Changes',
                    style: TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ----------------------------
  // BYUI Verification UI
  Widget _buildByuiVerificationCard() {
    return _buildSectionCard(
      title: 'BYUI Verification',
      children: [
        Row(
          children: [
            Icon(
              _byuiVerified ? Icons.verified : Icons.privacy_tip_outlined,
              color: _byuiVerified ? Colors.green : AppColors.byuiBlue,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                _byuiVerified
                    ? 'Verified: ${_byuiEmail ?? ''}'
                    : (_byuiEmail == null || _byuiEmail!.isEmpty)
                    ? 'Verify your BYU–Idaho student email to unlock trust features.'
                    : 'Pending verification: $_byuiEmail',
                style: const TextStyle(color: AppColors.textGray600),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        if (_byuiVerified)
          OutlinedButton(
            onPressed: _promptForByuiEmail,
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(double.infinity, 48),
              side: const BorderSide(color: AppColors.gray200),
              foregroundColor: AppColors.byuiBlue,
            ),
            child: const Text('Change BYUI email'),
          )
        else ...[
          ElevatedButton(
            onPressed: _canResendByui ? _promptForByuiEmail : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.byuiBlue,
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 48),
            ),
            child: _sendingByuiEmail
                ? const SizedBox(
              height: 22,
              width: 22,
              child: CircularProgressIndicator(strokeWidth: 3, color: Colors.white),
            )
                : Text(
              (_byuiEmail == null || _byuiEmail!.isEmpty)
                  ? 'Send verification link'
                  : (_canResendByui
                  ? 'Resend verification link'
                  : 'Resend available in ${_resendRemaining}s'),
            ),
          ),
          const SizedBox(height: 8),

          const Text(
            "Allow up to 2 minutes for delivery. Check spam if not found.",
            style: TextStyle(fontSize: 13, color: AppColors.textGray500, height: 1.3),
          ),
        ],
      ],
    );
  }

  Future<void> _promptForByuiEmail() async {
    final formKey = GlobalKey<FormState>();
    final controller = TextEditingController(text: _byuiEmail ?? '');

    final base = ThemeData.light(useMaterial3: true);
    final themed = base.copyWith(
      dialogTheme: const DialogThemeData(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
        ),
      ),
      textSelectionTheme: const TextSelectionThemeData(
        cursorColor: AppColors.byuiBlue,
        selectionColor: AppColors.blue100,
        selectionHandleColor: AppColors.byuiBlue,
      ),
      colorScheme: base.colorScheme.copyWith(
        primary: AppColors.byuiBlue,
        secondary: AppColors.byuiBlue,
        surface: Colors.white,
        onSurface: AppColors.textGray600,
        onPrimary: Colors.white,
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.byuiBlue,
        ).copyWith(
          overlayColor: WidgetStateProperty.resolveWith(
                (states) =>
            states.contains(WidgetState.pressed) ? AppColors.blue100.withValues(alpha: 0.2) : null,
          ),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.byuiBlue,
          foregroundColor: Colors.white,
        ),
      ),
    );

    final result = await showDialog<String>(
      context: context,
      builder: (context) => Theme(
        data: themed,
        child: AlertDialog(
          title: const Text(
            'Verify BYUI Email',
            style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textGray600),
          ),
          content: Form(
            key: formKey,
            child: TextFormField(
              controller: controller,
              decoration: _inputDecoration(labelText: 'BYUI email (e.g., name@byui.edu)'),
              keyboardType: TextInputType.emailAddress,
              validator: (v) {
                final value = (v ?? '').trim().toLowerCase();
                if (value.isEmpty) return 'Enter your BYUI email';
                final re = RegExp(r'^[a-zA-Z0-9._%+\-]+@byui\.edu$');
                if (!re.hasMatch(value)) return 'Email must end with @byui.edu';
                return null;
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  Navigator.of(context).pop(controller.text.trim());
                }
              },
              child: const Text('Send Link'),
            ),
          ],
        ),
      ),
    );

    if (result != null) {
      await _sendByuiEmailLink(result);
    }
  }

  // Build ActionCodeSettings for email-link sign-in
  ActionCodeSettings _emailLinkSettings() {
    return ActionCodeSettings(
      url: _emailLinkContinueUrl, // IMPORTANT: hash route to /byui-verify
      handleCodeInApp: true,
      androidPackageName: _androidPackageName,
      androidInstallApp: true,
      iOSBundleId: _iOSBundleId,
      // dynamicLinkDomain: _dynamicLinkDomain,
    );
  }

  void _startVerificationWatcher(String uid, String email) {
    _verifyWatch?.cancel();

    int secondsLeft = 600; // 10 min safety window
    _verifyWatch = FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .snapshots()
        .listen((snap) {
      final data = snap.data();
      final verified = data?['byuiEmailVerified'] == true;
      final savedEmail = (data?['byuiEmail'] as String?)?.toLowerCase() ?? '';
      if (verified && savedEmail == email.toLowerCase()) {
        _verifyWatch?.cancel();
        if (!mounted) return;
        setState(() {
          _byuiVerified = true;
          _byuiEmail = savedEmail;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('BYUI email verified.')),
        );
      }
    });

    Timer.periodic(const Duration(seconds: 1), (t) {
      secondsLeft--;
      if (!mounted || secondsLeft <= 0 || _byuiVerified) {
        t.cancel();
        _verifyWatch?.cancel();
      }
    });
  }

  Future<void> _sendByuiEmailLink(String email) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    try {
      setState(() => _sendingByuiEmail = true);

      // Save BYUI email (unverified) so we can show "pending"
      await UserService.updateByuiEmail(uid, email);

      // Store locally for link completion (do NOT put email into the link)
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('byui_pending_email', email);

      // Send the email-link via Firebase Auth (built-in)
      await FirebaseAuth.instance.sendSignInLinkToEmail(
        email: email,
        actionCodeSettings: _emailLinkSettings(),
      );

      if (mounted) {
        setState(() {
          _byuiEmail = email;
          _byuiVerified = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Verification link sent to $email')),
        );
        _resendRemaining = 60;
        _resendTimer?.cancel();
        _startVerificationWatcher(uid, email);
        _resendTimer = Timer.periodic(const Duration(seconds: 1), (t) {
          if (!mounted) {
            t.cancel();
            return;
          }
          setState(() {
            _resendRemaining = _resendRemaining > 0 ? _resendRemaining - 1 : 0;
            if (_resendRemaining == 0) t.cancel();
          });
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to send link: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _sendingByuiEmail = false);
    }
  }

  // Helpers
  InputDecoration _inputDecoration({required String labelText}) {
    return const InputDecoration(
      labelText: null, // overridden below
    ).copyWith(
      labelText: labelText,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8.0),
        borderSide: const BorderSide(color: AppColors.gray200),
      ),
      focusedBorder: const OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(8.0)),
        borderSide: BorderSide(color: AppColors.inputFocusBlue, width: 2.0),
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
          Text(title,
              style: const TextStyle(
                  fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textGray600)),
          const SizedBox(height: 20),
          ...children,
        ],
      ),
    );
  }

  // Change password dialog (in-theme)
  Future<void> _changePassword() async {
    final currentPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        bool obscureCurrent = true;
        bool obscureNew = true;

        final base = ThemeData.light(useMaterial3: true);
        final themed = base.copyWith(
          dialogTheme: const DialogThemeData(
            backgroundColor: Colors.white,
            surfaceTintColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(16)),
            ),
          ),
          textSelectionTheme: const TextSelectionThemeData(
            cursorColor: AppColors.byuiBlue,
            selectionColor: AppColors.blue100,
            selectionHandleColor: AppColors.byuiBlue,
          ),
          colorScheme: base.colorScheme.copyWith(
            primary: AppColors.byuiBlue,
            secondary: AppColors.byuiBlue,
            surface: Colors.white,
            onSurface: AppColors.textGray600,
            onPrimary: Colors.white,
          ),
          textButtonTheme: TextButtonThemeData(
            style: TextButton.styleFrom(
              foregroundColor: AppColors.byuiBlue,
            ).copyWith(
              overlayColor: WidgetStateProperty.resolveWith(
                    (states) => states.contains(WidgetState.pressed)
                    ? AppColors.blue100.withValues(alpha: 0.2)
                    : null,
              ),
            ),
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.byuiBlue,
              foregroundColor: Colors.white,
            ),
          ),
        );

        return StatefulBuilder(
          builder: (context, setState) => Theme(
            data: themed,
            child: AlertDialog(
              title: const Text(
                "Change Password",
                style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textGray600),
              ),
              content: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
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
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text("Cancel"),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (formKey.currentState!.validate()) {
                      Navigator.of(context).pop(true);
                    }
                  },
                  child: const Text("Change"),
                ),
              ],
            ),
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

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Password changed successfully.")),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Failed to change password: ${e.toString()}")),
          );
        }
      }
    }

    currentPasswordController.dispose();
    newPasswordController.dispose();
  }
}
