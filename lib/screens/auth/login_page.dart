// lib/screens/auth/login_page.dart

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart'; // For Google Sign-In
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:byui_rideshare/screens/auth/auth_wrapper.dart'; // For navigation after login
import 'package:byui_rideshare/screens/auth/create_account_page.dart'; // To navigate to create account
import 'package:byui_rideshare/screens/profile/profile_setup_screen.dart'; // For profile setup after sign-up
import 'package:byui_rideshare/theme/app_colors.dart'; // Import custom colors

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  // State variables for UI
  bool _showPassword = false;
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  // State variables for loading indicators
  bool _isGoogleSigningIn = false;
  bool _isEmailSigningIn = false;
  bool _isFacebookSigningIn = false;

  // IMPORTANT: Replace this with your actual Google Web Client ID
  final String _googleWebClientId = '527415309529-fhre160snc1rh4fc6c2at39e6n6p6u68.apps.googleusercontent.com'; // <--- PASTE THE CORRECT WEB CLIENT ID HERE

  final firebaseAuth = FirebaseAuth.instance;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // --- Function to handle Email/Password Sign In ---
  Future<void> _signIn() async {
    if (!mounted) return;
    setState(() {
      _isEmailSigningIn = true;
    });

    try {
      UserCredential userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
      print('User signed in: ${userCredential.user!.email}');

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sign in successful!')),
      );

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const AuthWrapper()),
            (Route<dynamic> route) => false,
      );

    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      String message;
      if (e.code == 'user-not-found') {
        message = 'No user found for that email.';
      } else if (e.code == 'wrong-password') {
        message = 'Wrong password provided for that user.';
      } else {
        message = 'Sign in failed: ${e.message}';
      }
      print('Firebase Auth Error: $message');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $message')),
      );
    } catch (e) {
      if (!mounted) return;
      print('General Error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('An error occurred: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isEmailSigningIn = false;
        });
      }
    }
  }

  // --- Function to handle Google Sign In ---
  Future<void> _handleGoogleSignIn() async {
    if (!mounted) return;
    setState(() {
      _isGoogleSigningIn = true;
    });

    try {
      final GoogleSignInAccount? googleUser = await GoogleSignIn(
        clientId: _googleWebClientId,
      ).signIn();

      if (!mounted) return;
      if (googleUser == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Google Sign-In cancelled.')),
        );
        setState(() => _isGoogleSigningIn = false);
        return;
      }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      UserCredential userCredential = await FirebaseAuth.instance.signInWithCredential(credential);
      User? user = userCredential.user;

      if (!mounted) return;
      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Google Sign-In failed. No user found.')),
        );
        setState(() => _isGoogleSigningIn = false);
        return;
      }

      print('Signed in with Google: ${userCredential.user?.email}');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Signed in with Google successfully!')),
      );

      bool isNewUser = userCredential.additionalUserInfo?.isNewUser ?? false;

      if (!mounted) return;

      if (isNewUser) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Welcome! Please complete your profile.')),
        );
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const ProfileSetupScreen()),
              (Route<dynamic> route) => false,
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Signed in with Google successfully!')),
        );
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const AuthWrapper()),
              (Route<dynamic> route) => false,
        );
      }

    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      print('Firebase Auth Google Error: ${e.message}');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Google Sign-In failed: ${e.message}')),
      );
    } catch (e) {
      if (!mounted) return;
      print('General Google Sign-In Error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('An error occurred during Google Sign-In: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isGoogleSigningIn = false;
        });
      }
    }
  }

  // --- Function to handle Facebook Sign In ---
  Future<void> _handleFacebookSignIn() async {
    if (!mounted) return;
    setState(() {
      _isFacebookSigningIn = true;
    });

    try {
      final LoginResult result = await FacebookAuth.instance.login(
        permissions: ['email', 'public_profile'], // Request permissions
      );

      if (result.status == LoginStatus.success) {
        final AccessToken accessToken = result.accessToken!;
        print('Facebook Access Token: ${accessToken.tokenString}');

        // Create a Firebase credential with the Facebook access token
        final OAuthCredential credential = FacebookAuthProvider.credential(accessToken.tokenString);

        // Sign-in to Firebase with the credential
        final UserCredential userCredential = await firebaseAuth.signInWithCredential(credential);
        User? user = userCredential.user;

        if (!mounted) return;
        if (user == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Facebook Sign-In failed. No user found with Firebase.')),
          );
          if (mounted) setState(() => _isFacebookSigningIn = false);
          return;
        }

        print('Signed in with Facebook: ${userCredential.user?.email}');
        _handleSuccessfulSignIn(userCredential); // Use a common handler

      } else if (result.status == LoginStatus.cancelled) {
        print('Facebook login cancelled by user.');
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Facebook Sign-In cancelled.')),
        );
      } else {
        print('Facebook login failed: ${result.message}');
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Facebook Sign-In failed: ${result.message}')),
        );
      }
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      print('Firebase Auth Facebook Error: ${e.message}');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Facebook Sign-In failed: ${e.message}')),
      );
    } catch (e) {
      if (!mounted) return;
      print('General Facebook Sign-In Error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('An error occurred during Facebook Sign-In: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isFacebookSigningIn = false;
        });
      }
    }
  }

  // <--- COMMON SUCCESS HANDLER --->
  void _handleSuccessfulSignIn(UserCredential userCredential) {
    if (!mounted) return;

    final providerId = userCredential.credential?.providerId ?? "email"; // Get provider
    String successMessage = 'Signed in successfully!';
    if (providerId.contains("google")) {
      successMessage = 'Signed in with Google successfully!';
    } else if (providerId.contains("facebook")) {
      successMessage = 'Signed in with Facebook successfully!';
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(successMessage)),
    );

    bool isNewUser = userCredential.additionalUserInfo?.isNewUser ?? false;

    if (isNewUser) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Welcome! Please complete your profile.')),
      );
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const ProfileSetupScreen()),
            (Route<dynamic> route) => false,
      );
    } else {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const AuthWrapper()),
            (Route<dynamic> route) => false,
      );
    }
  }

  // --- Navigation to Create Account Page ---
  void _navigateToCreateAccount() {
    Navigator.of(context).pushNamed('/create_account');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.gray50, // Main background color for the screen
      body: Column( // Use a Column to stack the header and the scrollable content
        children: [
          // Header (bg-[#006eb6] text-white px-4 py-6 relative)
          Container(
            color: AppColors.headerAndPrimaryBlue, // bg-[#006eb6]
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0), // px-4 py-6
            child: SafeArea( // Ensures content is below status bar
              child: Stack( // For positioning the DEBUG badge
                children: [
                  Row(
                    children: [
                      // Back Button (Button variant="ghost" size="icon" className="text-white hover:bg-white/10 p-0 h-8 w-8)
                      SizedBox(
                        height: 32.0, // h-8
                        width: 32.0,  // w-8
                        child: IconButton(
                          padding: EdgeInsets.zero, // p-0
                          iconSize: 20.0, // h-5 w-5 (approx)
                          icon: const Icon(Icons.arrow_back, color: Colors.white), // ArrowLeft equivalent
                          onPressed: () {
                            Navigator.pop(context); // Go back to WelcomeScreen
                          },
                          splashRadius: 20.0, // Smaller splash radius for icon buttons
                          highlightColor: Colors.white.withOpacity(0.1), // hover:bg-white/10
                        ),
                      ),
                      const SizedBox(width: 16.0), // gap-4

                      // Title and Description
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Login', // h1 className="text-xl font-semibold"
                            style: TextStyle(
                              fontSize: 20.0, // text-xl
                              fontWeight: FontWeight.w600, // font-semibold
                              color: Colors.white, // text-white
                            ),
                          ),
                          const SizedBox(height: 4.0),
                          Text(
                            'Access your account', // p className="text-blue-100 text-sm"
                            style: TextStyle(
                              fontSize: 14.0, // text-sm
                              color: AppColors.blue100, // text-blue-100
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          // Content section (px-4 py-8)
          Expanded( // Allows content to take remaining space and scroll
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 32.0), // px-4 py-8
              child: Align( // max-w-md mx-auto
                alignment: Alignment.topCenter, // Align to top center
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 448.0), // max-w-md (approx 448px for 28rem)
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch, // For stretching buttons
                    children: [
                      // Login Form Card (bg-white rounded-lg shadow-sm border border-gray-200 p-6 space-y-4)
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white, // bg-white
                          borderRadius: BorderRadius.circular(8.0), // rounded-lg
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05), // shadow-sm
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                          border: Border.all(color: AppColors.gray200, width: 1.0), // border border-gray-200
                        ),
                        padding: const EdgeInsets.all(24.0), // p-6
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Email Input Field (space-y-4)
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                TextField(
                                  controller: _emailController,
                                  keyboardType: TextInputType.emailAddress,
                                  decoration: InputDecoration(
                                    hintText: 'Email - Enter your email address',
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8.0),
                                      borderSide: BorderSide(color: AppColors.gray300),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8.0),
                                      borderSide: BorderSide(color: AppColors.gray300),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8.0),
                                      borderSide: BorderSide(color: AppColors.inputFocusBlue, width: 2.0),
                                    ),
                                    filled: true,
                                    fillColor: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16.0), // space-y-4

                            // Password Input Field (space-y-4)
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                TextField(
                                  controller: _passwordController,
                                  obscureText: !_showPassword,
                                  decoration: InputDecoration(
                                    hintText: 'Password - Enter your password',
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8.0),
                                      borderSide: BorderSide(color: AppColors.gray300),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8.0),
                                      borderSide: BorderSide(color: AppColors.gray300),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8.0),
                                      borderSide: BorderSide(color: AppColors.inputFocusBlue, width: 2.0),
                                    ),
                                    filled: true,
                                    fillColor: Colors.white,
                                    suffixIcon: IconButton(
                                      icon: Icon(
                                        _showPassword ? Icons.visibility_off : Icons.visibility,
                                        color: AppColors.textGray500,
                                      ),
                                      onPressed: () {
                                        setState(() {
                                          _showPassword = !_showPassword;
                                        });
                                      },
                                      splashRadius: 20.0,
                                      highlightColor: AppColors.gray700.withOpacity(0.1),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 24.0), // space-y-4 (after password input)

                            // Sign In Button (w-full h-12 bg-[#006eb6] hover:bg-[#005a9a] text-white font-medium rounded-lg)
                            _isEmailSigningIn
                                ? const Center(child: CircularProgressIndicator())
                                : SizedBox(
                              width: double.infinity, // w-full
                              height: 48.0, // h-12
                              child: ElevatedButton(
                                onPressed: _signIn,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.headerAndPrimaryBlue,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8.0), // rounded-lg
                                  ),
                                  textStyle: const TextStyle(
                                    fontSize: 16.0,
                                    fontWeight: FontWeight.w500, // font-medium
                                  ),
                                  elevation: 0, // Flat design
                                ),
                                child: const Text('Sign In'),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24.0), // space-y-6 after the login form card

                      // Alternative Sign In (space-y-4)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Sign In with Google Button (w-full h-12 bg-white text-gray-700 border-gray-300 hover:bg-gray-50 font-medium rounded-lg)
                          _isGoogleSigningIn
                              ? const Center(child: CircularProgressIndicator())
                              : SizedBox(
                            width: double.infinity, // w-full
                            height: 48.0, // h-12
                            child: OutlinedButton(
                              onPressed: _handleGoogleSignIn, // Calls the Google Sign-In function
                              style: OutlinedButton.styleFrom(
                                backgroundColor: Colors.white, // bg-white
                                foregroundColor: AppColors.gray700, // text-gray-700
                                side: const BorderSide(color: AppColors.gray300, width: 1.0), // border-gray-300
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8.0), // rounded-lg
                                ),
                                textStyle: const TextStyle(
                                  fontSize: 16.0,
                                  fontWeight: FontWeight.w500, // font-medium
                                ),
                              ),
                              child: const Text('Sign In with Google'),
                            ),
                          ),
                          const SizedBox(height: 16.0), // space-y-4

                          // <--- 5. ADD FACEBOOK SIGN-IN BUTTON --->
                          _isFacebookSigningIn
                              ? const Center(child: CircularProgressIndicator())
                              : SizedBox(
                            width: double.infinity,
                            height: 48.0,
                            child: ElevatedButton.icon( // Using ElevatedButton.icon for consistency or OutlinedButton
                              icon: const Icon(Icons.facebook, color: Colors.white), // Facebook icon
                              label: const Text('Sign In with Facebook'),
                              onPressed: _handleFacebookSignIn,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF1877F2), // Facebook blue
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8.0),
                                ),
                                textStyle: const TextStyle(
                                  fontSize: 16.0,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16.0),

                          // Create Account Button (text-center Button variant="link" className="text-[#006eb6] hover:text-[#005a9a] font-medium")
                          Center(
                            child: TextButton(
                              onPressed: _navigateToCreateAccount,
                              style: TextButton.styleFrom(
                                foregroundColor: AppColors.headerAndPrimaryBlue, // text-[#006eb6]
                                textStyle: const TextStyle(
                                  fontSize: 16.0,
                                  fontWeight: FontWeight.w500, // font-medium
                                ),
                              ),
                              child: const Text('Create Account'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}