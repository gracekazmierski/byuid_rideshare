import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';

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
  // Steps: 0 = name, 1 = contact, 2 = photo, 3 = role
  final _pageController = PageController();
  int _step = 0;

  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _facebookController = TextEditingController();

  final phoneMaskFormatter = MaskTextInputFormatter(
    mask: '###-###-####',
    filter: {"#": RegExp(r'[0-9]')},
    type: MaskAutoCompletionType.lazy,
  );

  UserRole _selectedRole = UserRole.rider;

  final ImagePicker _picker = ImagePicker();
  File? _selectedImageFile;
  Uint8List? _selectedImageBytes;

  // Upload state
  bool _isSaving = false;
  double? _uploadProgress;           // null => indeterminate
  String? _uploadedPhotoUrl;
  bool _uploadingNow = false;
  UploadTask? _currentUploadTask;    // for cancel

  @override
  void dispose() {
    _pageController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    _facebookController.dispose();
    super.dispose();
  }

  // ---------- Header ----------
  Widget _buildHeader() {
    final subtitles = <int, String>{
      0: "Tell us about yourself.",
      1: "How can riders or drivers reach you?",
      2: "Add a profile photo (optional).",
      3: "Choose your role.",
    };

    final showGlobalProgress = _uploadingNow || (_uploadProgress != null && (_uploadProgress ?? 0) < 1);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: double.infinity,
          color: AppColors.byuiBlue,
          padding: EdgeInsets.fromLTRB(
            16.0,
            MediaQuery.of(context).padding.top + 16,
            16.0,
            20.0,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_step > 0 || Navigator.of(context).canPop())
                IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: _onBack,
                ),
              const SizedBox(height: 4),
              const Text(
                'Complete Your Profile',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24.0,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4.0),
              Text(
                subtitles[_step]!,
                style: const TextStyle(color: AppColors.blue100, fontSize: 14.0),
              ),
              const SizedBox(height: 16),
              _buildStepDots(total: 4, current: _step),
            ],
          ),
        ),
        if (showGlobalProgress)
          Container(
            width: double.infinity,
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: LinearProgressIndicator(value: _uploadProgress),
                ),
                const SizedBox(width: 12),
                Text(
                  _uploadProgress == null
                      ? 'Uploading…'
                      : '${((_uploadProgress ?? 0) * 100).toStringAsFixed(0)}%',
                  style: const TextStyle(color: AppColors.textGray600),
                ),
                const SizedBox(width: 8),
                if (_uploadingNow)
                  TextButton(
                    onPressed: _cancelUpload,
                    child: const Text('Cancel'),
                  ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildStepDots({required int total, required int current}) {
    return Row(
      children: List.generate(total, (i) {
        final active = i == current;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          margin: const EdgeInsets.only(right: 8),
          height: 8,
          width: active ? 20 : 8,
          decoration: BoxDecoration(
            color: active ? Colors.white : Colors.white.withOpacity(0.5),
            borderRadius: BorderRadius.circular(99),
          ),
        );
      }),
    );
  }

  // ---------- Navigation ----------
  void _onBack() {
    if (_step > 0) {
      setState(() => _step--);
      _pageController.previousPage(duration: const Duration(milliseconds: 250), curve: Curves.easeOut);
    } else {
      Navigator.of(context).maybePop();
    }
  }

  Future<void> _onNext() async {
    if (!_validateCurrentStep()) return;

    if (_step < 3) {
      setState(() => _step++);
      _pageController.nextPage(duration: const Duration(milliseconds: 250), curve: Curves.easeOut);
      return;
    }
    await _saveProfile();
  }

  bool _validateCurrentStep() {
    final ok = _formKey.currentState?.validate() ?? false;
    if (!ok) {
      ScaffoldMessenger.of(context)
        ..removeCurrentSnackBar()
        ..showSnackBar(const SnackBar(content: Text('Please fix the errors above.')));
    }
    return ok;
  }

  // ---------- Immediate Upload with progress/cancel ----------
  Future<void> _startImmediateUpload(Uint8List bytes) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    // reset UI
    setState(() {
      _uploadProgress = null;    // start as indeterminate (SDK sometimes reports totalBytes=0)
      _uploadingNow = true;
      _uploadedPhotoUrl = null;
    });

    try {
      final task = await UserService().startUploadProfilePictureFromBytes(user.uid, bytes);
      _currentUploadTask = task;

      // progress listener
      final sub = task.snapshotEvents.listen((s) {
        final total = s.totalBytes;
        if (total <= 0) {
          // still negotiating upload; keep indeterminate
          setState(() => _uploadProgress = null);
        } else {
          setState(() => _uploadProgress = s.bytesTransferred / total);
        }
      });

      // await result
      final snap = await task;
      await sub.cancel();

      final url = await snap.ref.getDownloadURL();
      if (!mounted) return;
      setState(() {
        _uploadedPhotoUrl = url;
        _uploadProgress = 1.0;
        _uploadingNow = false;
        _currentUploadTask = null;
      });

      await Future.delayed(const Duration(milliseconds: 200));
    } on FirebaseException catch (e) {
      if (e.code == 'canceled') {
        // user canceled — just clean UI
        if (!mounted) return;
        setState(() {
          _uploadingNow = false;
          _uploadProgress = null;
          _currentUploadTask = null;
        });
      } else {
        if (!mounted) return;
        setState(() {
          _uploadingNow = false;
          _currentUploadTask = null;
        });
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Upload failed: ${e.message}')));
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _uploadingNow = false;
        _currentUploadTask = null;
      });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Upload failed: $e')));
    }
  }

  void _cancelUpload() async {
    try {
      await _currentUploadTask?.cancel();
    } catch (_) {}
    if (!mounted) return;
    setState(() {
      _uploadingNow = false;
      _uploadProgress = null;
      _currentUploadTask = null;
      _uploadedPhotoUrl = null;
    });
  }

  // ---------- Save ----------
  Future<void> _saveProfile() async {
    setState(() => _isSaving = true);

    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('User not logged in.')));
      return;
    }

    // If photo picked but not uploaded yet, finish it now (unless canceled)
    if (_uploadedPhotoUrl == null && (_selectedImageBytes != null || _selectedImageFile != null)) {
      if (_currentUploadTask != null) {
        // still uploading — wait briefly
        try {
          final snap = await _currentUploadTask!;
          _uploadedPhotoUrl = await snap.ref.getDownloadURL();
        } catch (_) {
          // if it fails/canceled we just proceed without photo
        }
      } else if (_selectedImageBytes != null) {
        await _startImmediateUpload(_selectedImageBytes!);
      } else if (_selectedImageFile != null) {
        final bytes = await _selectedImageFile!.readAsBytes();
        await _startImmediateUpload(bytes);
      }
    }

    try {
      final profile = UserProfile(
        uid: currentUser.uid,
        firstName: _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
        phoneNumber: phoneMaskFormatter.getUnmaskedText(),
        facebookUsername: _facebookController.text.trim().isEmpty
            ? null
            : _facebookController.text.trim(),
        isDriver: _selectedRole == UserRole.driver,
        profilePictureUrl: _uploadedPhotoUrl,
      );

      await UserService.saveUserProfile(profile);
      await currentUser.updateDisplayName('${profile.firstName} ${profile.lastName}'.trim());

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profile saved!')));
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const AuthWrapper()),
            (route) => false,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to save profile: $e')));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  // ---------- Build ----------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.gray50,
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
              child: Form(
                key: _formKey,
                child: PageView(
                  controller: _pageController,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    _stepName(),
                    _stepContact(),
                    _stepPhoto(),
                    _stepRole(),
                  ],
                ),
              ),
            ),
          ),
          SafeArea(
            top: false,
            child: Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              color: AppColors.gray50,
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _isSaving ? null : _onBack,
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppColors.gray200),
                        foregroundColor: AppColors.byuiBlue,
                        minimumSize: const Size.fromHeight(48),
                      ),
                      child: const Text('Back'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isSaving ? null : _onNext,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.byuiBlue,
                        foregroundColor: Colors.white,
                        minimumSize: const Size.fromHeight(48),
                      ),
                      child: _isSaving
                          ? const SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(strokeWidth: 3, color: Colors.white),
                      )
                          : Text(_step < 3 ? 'Continue' : 'Finish'),
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

  // ---------- Step Cards ----------
  Widget _card({required String title, required List<Widget> children, String? subtitle}) {
    return Container(
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: AppColors.gray200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(
                  fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textGray600)),
          if (subtitle != null) ...[
            const SizedBox(height: 6),
            Text(subtitle, style: const TextStyle(color: AppColors.textGray500)),
          ],
          const SizedBox(height: 20),
          ...children,
        ],
      ),
    );
  }

  InputDecoration _inputDecoration({required String labelText}) {
    return InputDecoration(
      labelText: labelText,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8.0),
        borderSide: const BorderSide(color: AppColors.gray300),
      ),
      focusedBorder: const OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(8.0)),
        borderSide: BorderSide(color: AppColors.inputFocusBlue, width: 2.0),
      ),
    );
  }

  // Step 0: Name
  Widget _stepName() {
    return SingleChildScrollView(
      child: _card(
        title: 'Your Name',
        subtitle: 'Tell us about yourself',
        children: [
          TextFormField(
            controller: _firstNameController,
            decoration: _inputDecoration(labelText: 'First Name'),
            textInputAction: TextInputAction.next,
            validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter your first name' : null,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _lastNameController,
            decoration: _inputDecoration(labelText: 'Last Name'),
            validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter your last name' : null,
          ),
        ],
      ),
    );
  }

  // Step 1: Contact
  Widget _stepContact() {
    return SingleChildScrollView(
      child: _card(
        title: 'Contact',
        subtitle: 'Phone is required; Facebook is optional',
        children: [
          TextFormField(
            controller: _phoneController,
            inputFormatters: [phoneMaskFormatter],
            keyboardType: TextInputType.phone,
            decoration: _inputDecoration(labelText: 'Phone Number'),
            validator: (v) {
              if (phoneMaskFormatter.getUnmaskedText().length != 10) {
                return 'Enter a valid 10-digit phone number';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _facebookController,
            decoration: _inputDecoration(labelText: 'Facebook Username (optional)'),
          ),
        ],
      ),
    );
  }

  // Step 2: Photo (optional)
  Widget _stepPhoto() {
    final isUploading = _uploadingNow;
    return SingleChildScrollView(
      child: _card(
        title: 'Profile Photo',
        subtitle: 'Add a photo to help others recognize you (optional)',
        children: [
          Center(
            child: Column(
              children: [
                CircleAvatar(
                  radius: 50,
                  backgroundColor: AppColors.blue100,
                  backgroundImage: _selectedImageBytes != null
                      ? MemoryImage(_selectedImageBytes!)
                      : _selectedImageFile != null
                      ? FileImage(_selectedImageFile!) as ImageProvider
                      : null,
                  child: (_selectedImageBytes == null && _selectedImageFile == null)
                      ? const Icon(Icons.person, size: 40, color: Colors.white)
                      : null,
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 12,
                  children: [
                    ElevatedButton.icon(
                      onPressed: _isSaving || isUploading ? null : _pickImage,
                      icon: const Icon(Icons.photo_library),
                      label: const Text('Choose Photo'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.byuiBlue,
                        foregroundColor: Colors.white,
                      ),
                    ),
                    if ((_selectedImageBytes != null || _selectedImageFile != null))
                      OutlinedButton.icon(
                        onPressed: (_isSaving || isUploading)
                            ? _cancelUpload
                            : () {
                          setState(() {
                            _selectedImageBytes = null;
                            _selectedImageFile = null;
                            _uploadedPhotoUrl = null;
                            _uploadProgress = null;
                          });
                        },
                        icon: Icon(isUploading ? Icons.close : Icons.delete_outline),
                        label: Text(isUploading ? 'Cancel upload' : 'Remove'),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: AppColors.gray200),
                          foregroundColor: AppColors.byuiBlue,
                        ),
                      ),
                  ],
                ),
                if (_uploadedPhotoUrl != null) ...[
                  const SizedBox(height: 8),
                  const Text('Photo uploaded ✔', style: TextStyle(color: Colors.green)),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickImage() async {
    final picked = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 70,
    );
    if (picked == null) return;

    if (kIsWeb) {
      final bytes = await picked.readAsBytes();
      setState(() {
        _selectedImageBytes = bytes;
        _selectedImageFile = null;
      });
      await _startImmediateUpload(bytes);
    } else {
      final file = File(picked.path);
      setState(() {
        _selectedImageFile = file;
        _selectedImageBytes = null;
      });
      final bytes = await file.readAsBytes();
      await _startImmediateUpload(bytes);
    }
  }

  // Step 3: Role
  Widget _stepRole() {
    return SingleChildScrollView(
      child: _card(
        title: 'Your Role',
        subtitle: 'Choose how you’ll use RexRide',
        children: [
          ToggleButtons(
            isSelected: [
              _selectedRole == UserRole.rider,
              _selectedRole == UserRole.driver,
            ],
            onPressed: (index) {
              setState(() => _selectedRole = index == 0 ? UserRole.rider : UserRole.driver);
            },
            borderRadius: BorderRadius.circular(8.0),
            selectedColor: Colors.white,
            fillColor: AppColors.byuiBlue,
            color: AppColors.byuiBlue,
            constraints: BoxConstraints(
              minHeight: 48.0,
              minWidth: (MediaQuery.of(context).size.width - 120) / 2,
            ),
            children: const [
              Padding(padding: EdgeInsets.symmetric(horizontal: 16), child: Text('Rider')),
              Padding(padding: EdgeInsets.symmetric(horizontal: 16), child: Text('Driver')),
            ],
          ),
          const SizedBox(height: 12),
          const Text('You can change this later in Edit Profile.', style: TextStyle(color: AppColors.textGray500)),
        ],
      ),
    );
  }
}
