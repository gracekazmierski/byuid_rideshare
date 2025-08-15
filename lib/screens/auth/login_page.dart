// lib/screens/auth/login_page.dart

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:byui_rideshare/screens/auth/auth_wrapper.dart';
import 'package:byui_rideshare/screens/auth/create_account_page.dart';
import 'package:byui_rideshare/screens/profile/profile_setup_screen.dart';
import 'package:byui_rideshare/theme/app_colors.dart';
import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  bool _showPassword = false;
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isGoogleSigningIn = false;
  bool _isEmailSigningIn = false;

  @override
  void initState() {
    super.initState();
    // For google_sign_in v7+: initialize once (no-op on web for our flow).
    if (!kIsWeb) {
      GoogleSignIn.instance.initialize().catchError(
            (e) => debugPrint('GoogleSignIn init error: $e'),
      );
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _routeAfterLogin(UserCredential cred) async {
    if (!mounted) return;
    final isNew = cred.additionalUserInfo?.isNewUser ?? false;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => isNew ? const ProfileSetupScreen() : const AuthWrapper()),
          (_) => false,
    );
  }

  Future<void> _signIn() async {
    if (!mounted) return;

    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter both email and password.')),
      );
      return;
    }

    setState(() => _isEmailSigningIn = true);

    try {
      final cred = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      debugPrint('User signed in: ${cred.user?.email}');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sign in successful!')),
      );
      await _routeAfterLogin(cred);
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      final message = switch (e.code) {
        'user-not-found' => 'No user found for that email.',
        'wrong-password' => 'Wrong password provided for that user.',
        'invalid-email' => 'That email address looks invalid.',
        _ => 'Sign in failed: ${e.message}',
      };
      debugPrint('Firebase Auth Error: $message');
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    } catch (e) {
      if (!mounted) return;
      debugPrint('General Error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('An error occurred: $e')),
      );
    } finally {
      if (mounted) setState(() => _isEmailSigningIn = false);
    }
  }

  Future<void> _handleGoogleSignIn() async {
    if (!mounted) return;
    setState(() => _isGoogleSigningIn = true);

    try {
      UserCredential cred;

      if (kIsWeb) {
        // Web: use Firebase popup provider.
        final provider = GoogleAuthProvider()
          ..addScope('email')
          ..setCustomParameters({'prompt': 'select_account'});
        cred = await FirebaseAuth.instance.signInWithPopup(provider);
      } else {
        // Mobile & desktop: google_sign_in v7 flow.
        // Ensure initialized (safe to call again).
        await GoogleSignIn.instance.initialize();

        // Start interactive auth and fetch the ID token.
        final account = await GoogleSignIn.instance.authenticate(scopeHint: const ['email']);
        final gAuth = await account.authentication; // v7: only idToken is provided.
        final oauth = GoogleAuthProvider.credential(idToken: gAuth.idToken);
        cred = await FirebaseAuth.instance.signInWithCredential(oauth);
      }

      await _routeAfterLogin(cred);
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      debugPrint('Google Sign-In Firebase Error: ${e.code} ${e.message}');
      final message = e.message ?? 'An error occurred during Google Sign-In.';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    } catch (e) {
      if (!mounted) return;
      debugPrint('General Google Sign-In Error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('An error occurred during Google Sign-In.')),
      );
    } finally {
      if (mounted) setState(() => _isGoogleSigningIn = false);
    }
  }

  void _navigateToCreateAccount() {
    Navigator.of(context).pushNamed('/create_account');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.gray50,
      body: Column(
        children: [
          // Header
          Container(
            color: AppColors.headerAndPrimaryBlue,
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
            child: SafeArea(
              child: Row(
                children: [
                  SizedBox(
                    height: 32.0,
                    width: 32.0,
                    child: IconButton(
                      padding: EdgeInsets.zero,
                      iconSize: 20.0,
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => Navigator.maybePop(context),
                      splashRadius: 20.0,
                      highlightColor: Colors.white.withOpacity(0.1),
                    ),
                  ),
                  const SizedBox(width: 16.0),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Login',
                        style: TextStyle(fontSize: 20.0, fontWeight: FontWeight.w600, color: Colors.white),
                      ),
                      const SizedBox(height: 4.0),
                      Text('Access your account', style: TextStyle(fontSize: 14.0, color: AppColors.blue100)),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 32.0),
              child: Align(
                alignment: Alignment.topCenter,
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 448.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Login form card
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8.0),
                          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, 2))],
                          border: Border.all(color: AppColors.gray200, width: 1.0),
                        ),
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
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
                            const SizedBox(height: 16.0),
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
                                  icon: Icon(_showPassword ? Icons.visibility_off : Icons.visibility, color: AppColors.textGray500),
                                  onPressed: () => setState(() => _showPassword = !_showPassword),
                                  splashRadius: 20.0,
                                  highlightColor: AppColors.gray700.withOpacity(0.1),
                                ),
                              ),
                            ),
                            const SizedBox(height: 24.0),
                            _isEmailSigningIn
                                ? const Center(child: CircularProgressIndicator())
                                : SizedBox(
                              width: double.infinity,
                              height: 48.0,
                              child: ElevatedButton(
                                onPressed: _signIn,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.headerAndPrimaryBlue,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
                                  textStyle: const TextStyle(fontSize: 16.0, fontWeight: FontWeight.w500),
                                  elevation: 0,
                                ),
                                child: const Text('Sign In'),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24.0),

                      // Alternatives
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _isGoogleSigningIn
                              ? const Center(child: CircularProgressIndicator())
                              : SizedBox(
                            width: double.infinity,
                            height: 48.0,
                            child: OutlinedButton(
                              onPressed: _handleGoogleSignIn,
                              style: OutlinedButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: AppColors.gray700,
                                side: const BorderSide(color: AppColors.gray300, width: 1.0),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
                                textStyle: const TextStyle(fontSize: 16.0, fontWeight: FontWeight.w500),
                              ),
                              child: const Text('Sign In with Google'),
                            ),
                          ),
                          const SizedBox(height: 16.0),
                          Center(
                            child: TextButton(
                              onPressed: _navigateToCreateAccount,
                              style: TextButton.styleFrom(
                                foregroundColor: AppColors.headerAndPrimaryBlue,
                                textStyle: const TextStyle(fontSize: 16.0, fontWeight: FontWeight.w500),
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
