// lib/screens/auth/create_account_page.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:byui_rideshare/models/user_profile.dart';
import 'package:byui_rideshare/services/user_service.dart';
import 'package:byui_rideshare/screens/auth/auth_wrapper.dart'; // For navigation after sign-up
import 'package:byui_rideshare/screens/profile/profile_setup_screen.dart'; // For profile setup after sign-up

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

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // --- Function to handle User Sign Up ---
  Future<void> _signUp() async {
    // --- Set loading state to true ---
    if (!mounted) return; // Check if widget is still in the tree
    setState(() {
      _isLoading = true;
    });

    try {
      UserCredential userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
      print('User signed up: ${userCredential.user!.email}');

      User? user = userCredential.user;
      if (user != null) {
        // Create a UserProfile object with basic info
        UserProfile profile = UserProfile(
          uid: user.uid,
          name: user.email!.split('@')[0], // Use part of email as default name
          isDriver: _isDriver,
          phoneNumber: '', // Will be updated on profile setup screen
        );
        await UserService.saveUserProfile(profile);
        print('UserProfile saved after sign-up');
        await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Account created successfully!')),
        );

        // Navigate to the home page (via AuthWrapper) and clear navigation stack
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const ProfileSetupScreen()),
              (Route<dynamic> route) => false,
        );
      }

    } on FirebaseAuthException catch (e) {
      if (!mounted) return; // Check if widget is still in the tree
      String message;
      if (e.code == 'weak-password') {
        message = 'The password provided is too weak.';
      } else if (e.code == 'email-already-in-use') {
        message = 'The account already exists for that email.';
      } else {
        message = 'Sign up failed: ${e.message}';
      }
      print('Firebase Auth Error: $message');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $message')),
      );
    } catch (e) {
      if (!mounted) return; // Check if widget is still in the tree
      print('General Error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('An error occurred: $e')),
      );
    } finally {
      // --- Set loading state to false ---
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
      appBar: AppBar(
        title: const Text('Create Account'),
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
                decoration: const InputDecoration(
                  labelText: 'Password',
                  border: OutlineInputBorder(),
                ),
                obscureText: true,
              ),
              const SizedBox(height: 24.0),

              // IsDriver checkbox
              Row(
                children: [
                  Checkbox(
                    value: _isDriver,
                    onChanged: (value) {
                      setState(() {
                        _isDriver = value ?? false;
                      });
                    },
                  ),
                  const Text('I am a driver (initial selection)'),
                ],
              ),
              const SizedBox(height: 24.0),

              // Create Account Button
              _isLoading
                ? const Center(child: CircularProgressIndicator())
                : ElevatedButton(
                    onPressed: _signUp,
                    child: const Text('Create Account'),
                  ),
              const SizedBox(height: 16.0),

              // Already have an account? Sign In link
              TextButton(
                onPressed: () {
                  Navigator.pop(context); // Go back to the Login page
                },
                child: const Text('Already have an account? Sign In'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}