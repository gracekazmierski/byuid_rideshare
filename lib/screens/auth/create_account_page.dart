// lib/screens/auth/create_account_page.dart

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:byui_rideshare/models/user_profile.dart';
import 'package:byui_rideshare/services/user_service.dart';
import 'package:byui_rideshare/screens/profile/profile_setup_screen.dart';
import 'package:byui_rideshare/theme/app_colors.dart';

class CreateAccountPage extends StatefulWidget {
  const CreateAccountPage({super.key});

  @override
  State<CreateAccountPage> createState() => _CreateAccountPageState();
}

class _CreateAccountPageState extends State<CreateAccountPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isDriver = false;
  bool _isLoading = false;
  bool _showPassword = false; // To toggle password visibility

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // --- Function to handle User Sign Up (Your existing logic) ---
  Future<void> _signUp() async {
    if (_isLoading) return; // Prevent multiple submissions
    if (!mounted) return;
    setState(() {
      _isLoading = true;
    });

    try {
      UserCredential userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      User? user = userCredential.user;
      if (user != null) {
        UserProfile profile = UserProfile(
          uid: user.uid,
          name: user.email!.split('@')[0],
          isDriver: _isDriver,
          phoneNumber: '',
        );
        await UserService.saveUserProfile(profile);

        // Sign in the user immediately to establish the auth session
        await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Account created successfully!')),
        );

        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const ProfileSetupScreen()),
              (Route<dynamic> route) => false,
        );
      }
    } on FirebaseAuthException catch (e) {
      String message;
      if (e.code == 'weak-password') {
        message = 'The password provided is too weak.';
      } else if (e.code == 'email-already-in-use') {
        message = 'An account already exists for that email.';
      } else {
        message = e.message ?? 'An unknown authentication error occurred.';
      }
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(message)));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('An error occurred: $e')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.gray50, // 'bg-gray-100'
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header Section
            Container(
              color: AppColors.byuiBlue,
              padding: const EdgeInsets.fromLTRB(16.0, 60.0, 16.0, 24.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back, color: Colors.white),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                      const SizedBox(width: 8),
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Create Account',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 24.0,
                                fontWeight: FontWeight.w600),
                          ),
                          Text(
                            'Join BYUI Rideshare',
                            style:
                            TextStyle(color: AppColors.blue100, fontSize: 14.0),
                          ),
                        ],
                      ),
                    ],
                  ),

                ],
              ),
            ),
            // Form Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
              child: Column(
                children: [
                  // Form Card
                  Container(
                    padding: const EdgeInsets.all(24.0),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8.0),
                      border: Border.all(color: AppColors.gray200),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10.0,
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Email Input
                        TextFormField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          decoration: InputDecoration(
                            hintText: "Email - Enter your email address",
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8.0),
                                borderSide:
                                const BorderSide(color: AppColors.gray300)),
                            focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8.0),
                                borderSide: const BorderSide(
                                    color: AppColors.inputFocusBlue, width: 2.0)),
                          ),
                        ),
                        const SizedBox(height: 16.0),
                        // Password Input
                        TextFormField(
                          controller: _passwordController,
                          obscureText: !_showPassword,
                          decoration: InputDecoration(
                            hintText: "Password - Enter your password",
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8.0),
                                borderSide:
                                const BorderSide(color: AppColors.gray300)),
                            focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8.0),
                                borderSide: const BorderSide(
                                    color: AppColors.inputFocusBlue, width: 2.0)),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _showPassword
                                    ? Icons.visibility_off
                                    : Icons.visibility,
                                color: AppColors.textGray500,
                              ),
                              onPressed: () {
                                setState(() {
                                  _showPassword = !_showPassword;
                                });
                              },
                            ),
                          ),
                        ),
                        const SizedBox(height: 8.0),
                        // Driver Checkbox
                        Row(
                          children: [
                            Checkbox(
                              value: _isDriver,
                              onChanged: (bool? value) {
                                setState(() {
                                  _isDriver = value ?? false;
                                });
                              },
                              activeColor: AppColors.byuiBlue,
                              side: BorderSide(color: AppColors.gray300, width: 2),
                            ),
                            const Text("I am a driver"),
                          ],
                        ),
                        const SizedBox(height: 16.0),
                        // Create Account Button
                        SizedBox(
                          height: 48.0,
                          child: ElevatedButton(
                            onPressed: _signUp,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.byuiBlue,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8.0)),
                            ),
                            child: _isLoading
                                ? const SizedBox(
                              height: 24,
                              width: 24,
                              child: CircularProgressIndicator(
                                  strokeWidth: 3, color: Colors.white),
                            )
                                : const Text('Create Account',
                                style: TextStyle(fontWeight: FontWeight.w500)),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24.0),

                  // "Or" Divider (Optional but good for UX)
                  const Row(
                    children: [
                      Expanded(child: Divider()),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 8.0),
                        child: Text("OR", style: TextStyle(color: AppColors.textGray500)),
                      ),
                      Expanded(child: Divider()),
                    ],
                  ),
                  const SizedBox(height: 24.0),

                  // Sign In with Google Button
                  SizedBox(
                    height: 48.0,
                    child: OutlinedButton.icon(
                      icon: Image.asset('assets/images/google_icon.png', height: 20.0), // Note: Add a google icon to your assets
                      label: const Text('Sign In with Google'),
                      onPressed: () {
                        // TODO: Implement Google Sign-In logic
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.gray700,
                        backgroundColor: Colors.transparent,
                        side: const BorderSide(color: AppColors.gray300),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8.0)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24.0),

                  // "Already have an account?" link
                  RichText(
                    text: TextSpan(
                      style: const TextStyle(
                          color: AppColors.textGray600,
                          fontSize: 14.0,
                          fontFamily: 'Roboto'),
                      children: [
                        const TextSpan(text: 'Already have an account? '),
                        TextSpan(
                          text: 'Sign In',
                          style: const TextStyle(
                              color: AppColors.byuiBlue,
                              fontWeight: FontWeight.w500),
                          recognizer: TapGestureRecognizer()
                            ..onTap = () {
                              Navigator.of(context).pop();
                            },
                        ),
                      ],
                    ),
                  )
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}