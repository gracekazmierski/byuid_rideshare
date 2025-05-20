import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Import Firebase Auth

import '../../models/user_profile.dart';
import '../../services/user_service.dart';


// Keep any other imports

// Your StatefulWidget and State class definitions for LoginPage
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  // Controllers to get text from the input fields
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _isDriver = false;

  // Dispose controllers when the widget is removed
  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // --- Function to handle User Sign Up (Already added) ---
  Future<void> _signUp() async {
    // ... (keep your existing _signUp function code here) ...
    try {
      UserCredential userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
      print('User signed up: ${userCredential.user!.email}');

      User? user = userCredential.user;
      if (user != null) {
        // Create a UserProfile object
        UserProfile profile = UserProfile(
          uid: user.uid,
          name: 'New User',  // You can replace this with a TextField input if you add one
          isDriver: _isDriver,   // Default for now
          phoneNumber: '',   // Optional, fill in if you collect phone number
        );

        // Save the profile to Firestore
        await UserService.saveUserProfile(profile);
        print('UserProfile saved after sign-up');
      }


      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Sign up successful!')),
      );
      // TODO: Navigate after sign up
      Navigator.pushReplacementNamed(context, '/home');

    } on FirebaseAuthException catch (e) {
      if (e.code == 'weak-password') {
        print('Error: The password provided is too weak.');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: The password provided is too weak.')),
        );
      } else if (e.code == 'email-already-in-use') {
        print('Error: The account already exists for that email.');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: The account already exists for that email.')),
        );
      } else {
        print('Firebase Auth Error: ${e.message}');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Sign up failed: ${e.message}')),
        );
      }
    } catch (e) {
      print('General Error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('An error occurred: $e')),
      );
    }
  }
  // --------------------------------------------------------


  // --- Function to handle User Sign In ---
  Future<void> _signIn() async {
    try {
      // Attempt to sign in an existing user with email and password
      UserCredential userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(), // Get email text
        password: _passwordController.text.trim(), // Get password text
      );
      // Sign-in successful!
      print('User signed in: ${userCredential.user!.email}');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Sign in successful!')),
      );
      // TODO: Navigate to home page after successful login
      // Example navigation after success:
      // Navigator.pushReplacementNamed(context, '/home'); // Assuming you have a route named '/home'
      Navigator.pushReplacementNamed(context, '/home');

    } on FirebaseAuthException catch (e) {
      // Handle specific Firebase Auth errors during login
      if (e.code == 'user-not-found') {
        print('Error: No user found for that email.');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: No user found for that email.')),
        );
      } else if (e.code == 'wrong-password') {
        print('Error: Wrong password provided for that user.');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: Wrong password provided for that user.')),
        );
      } else {
        // Handle other Firebase Auth errors
        print('Firebase Auth Error: ${e.message}');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Sign in failed: ${e.message}')),
        );
      }
    } catch (e) {
      // Handle other potential errors
      print('General Error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('An error occurred: $e')),
      );
    }
  }
  // --------------------------------------


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
              // Email Input Field - Link to the controller
              TextField(
                controller: _emailController,
                decoration: InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16.0),

              // Password Input Field - Link to the controller
              TextField(
                controller: _passwordController,
                decoration: InputDecoration(
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
                  const Text('I am a driver'),
                ],
              ),


              // Sign In Button - Call the _signIn function when pressed
              ElevatedButton(
                onPressed: _signIn, // <-- Call the _signIn function here
                child: const Text('Sign In'),
              ),
              const SizedBox(height: 16.0),

              // Google Sign In Button (Placeholder)
              OutlinedButton(
                onPressed: () {
                  // TODO: Implement Google Sign-In logic
                  print('Google Sign In button pressed');
                },
                child: const Text('Sign In with Google'),
              ),

              const SizedBox(height: 24.0),

              // Sign Up Text Button - Calls the _signUp function
              TextButton(
                onPressed: _signUp, // Calls the sign-up function
                child: const Text('Don\'t have an account? Sign Up'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}