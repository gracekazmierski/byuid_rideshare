// lib/screens/auth/login_page.dart
import  'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart'; // For Google Sign-In
import 'package:byui_rideshare/screens/auth/auth_wrapper.dart'; // For navigation after login
import 'package:byui_rideshare/screens/auth/create_account_page.dart'; // To navigate to create account
import 'package:byui_rideshare/screens/profile/profile_setup_screen.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  bool _obscurePassword = true;
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isGoogleSigningIn = false;
  bool _isEmailSigningIn = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // --- Function to handle Email/Password Sign In ---
  Future<void> _signIn() async {
    if (!mounted) return; // Check if widget is still in the tree
    setState(() {
      _isEmailSigningIn = true; // Set loading state
    });

    try {
      if (!mounted) return; // Check if widget is still in the tree)

      UserCredential userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
      print('User signed in: ${userCredential.user!.email}');

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sign in successful!')),
      );

      // Navigate to the home page (via AuthWrapper) and clear navigation stack
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
      _isGoogleSigningIn = true; // Set loading state
    });

    try {
      // 1. Begin interactive Google Sign In process
      final GoogleSignInAccount? googleUser = await GoogleSignIn(
        clientId: '527415309529-fhre160snc1rh4fc6c2at39e6n6p6u68.apps.googleusercontent.com', // <--- PASTE THE CORRECT WEB CLIENT ID HERE
      ).signIn();

      if (!mounted) return;
      if (googleUser == null) {
        // User cancelled the sign-in
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Google Sign-In cancelled.')),
        );
        setState(() => _isGoogleSigningIn = false); // Reset loading state
        return;
      }

      // 2. Obtain the auth details from the request
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      // 3. Create a new credential with the Google ID token and Access token
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // 4. Sign in to Firebase with the Google credential
      UserCredential userCredential = await FirebaseAuth.instance.signInWithCredential(credential);
      User? user = userCredential.user;

      if (!mounted) return;
      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Google Sign-In failed. No user found.')),
        );
        setState(() => _isGoogleSigningIn = false); // Reset loading state
        return;
      }

      print('Signed in with Google: ${userCredential.user?.email}');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Signed in with Google successfully!')),
      );

      // TODO: Check if this is a new user and save profile if needed
      // You might want to fetch the user profile from Firestore here.
      // If no profile exists, navigate to ProfileSetupScreen.
      // For now, we'll assume a successful sign-in means they go to the main screen.
      bool isNewUser = userCredential.additionalUserInfo?.isNewUser ?? false;

      if (!mounted) return;

      if (isNewUser) {
        //If this is a new user, navigate to profile setup
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Welcome! Please complete your profile.')),
        );
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const ProfileSetupScreen()),
              (Route<dynamic> route) => false,
        );
      } else {
        // If it's an existing user, navigate to the (AuthWrapper)
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Signed in with Google successfully!')),
        );
        // Navigate to the home page (via AuthWrapper) and clear navigation stack
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
          _isGoogleSigningIn = false; // Reset loading state
        });
      }
    }
  }

  void _navigateToCreateAccount() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => const CreateAccountPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Login'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              // Email Input Field
              TextField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16.0),

              // Password Input Field
              TextField(
                controller: _passwordController,
                decoration: InputDecoration(
                  labelText: 'Password',
                  border: const OutlineInputBorder(),
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
              const SizedBox(height: 24.0),

              // Sign In Button
              _isEmailSigningIn
              ? const Center(child: CircularProgressIndicator())
              : ElevatedButton(
                  onPressed: _signIn,
                  child: const Text('Sign In'),
                ),
              const SizedBox(height: 16.0),

              // Sign In with Google Button
              _isGoogleSigningIn
              ? const Center(child: CircularProgressIndicator())
              : OutlinedButton(
                  onPressed: _handleGoogleSignIn, // Calls the Google Sign-In function
                  child: const Text('Sign In with Google'),
                ),
              const SizedBox(height: 24.0),

              // Navigate to Create Account Page
              TextButton(
                onPressed: _navigateToCreateAccount,
                child: const Text('Create Account'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}