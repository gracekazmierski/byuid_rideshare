// lib/screens/auth/login_page.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart'; // For Google Sign-In
import 'package:byui_rideshare/screens/auth/auth_wrapper.dart'; // For navigation after login
import 'package:byui_rideshare/screens/auth/create_account_page.dart'; // To navigate to create account

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // --- Function to handle Email/Password Sign In ---
  Future<void> _signIn() async {
    try {
      UserCredential userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
      print('User signed in: ${userCredential.user!.email}');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sign in successful!')),
      );

      // Navigate to the home page (via AuthWrapper) and clear navigation stack
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const AuthWrapper()),
            (Route<dynamic> route) => false,
      );

    } on FirebaseAuthException catch (e) {
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
      print('General Error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('An error occurred: $e')),
      );
    }
  }

  // --- Function to handle Google Sign In ---
  Future<void> _handleGoogleSignIn() async {
    try {
      // 1. Begin interactive Google Sign In process
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) {
        // User cancelled the sign-in
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Google Sign-In cancelled.')),
        );
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

      print('Signed in with Google: ${userCredential.user?.email}');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Signed in with Google successfully!')),
      );

      // TODO: Check if this is a new user and save profile if needed
      // You might want to fetch the user profile from Firestore here.
      // If no profile exists, navigate to ProfileSetupScreen.
      // For now, we'll assume a successful sign-in means they go to the main screen.

      // Navigate to the home page (via AuthWrapper) and clear navigation stack
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const AuthWrapper()),
            (Route<dynamic> route) => false,
      );

    } on FirebaseAuthException catch (e) {
      print('Firebase Auth Google Error: ${e.message}');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Google Sign-In failed: ${e.message}')),
      );
    } catch (e) {
      print('General Google Sign-In Error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('An error occurred during Google Sign-In: $e')),
      );
    }
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
                decoration: const InputDecoration(
                  labelText: 'Password',
                  border: OutlineInputBorder(),
                ),
                obscureText: true,
              ),
              const SizedBox(height: 24.0),

              // Sign In Button
              ElevatedButton(
                onPressed: _signIn,
                child: const Text('Sign In'),
              ),
              const SizedBox(height: 16.0),

              // Sign In with Google Button
              OutlinedButton(
                onPressed: _handleGoogleSignIn, // Calls the Google Sign-In function
                child: const Text('Sign In with Google'),
              ),
              const SizedBox(height: 24.0),

            ],
          ),
        ),
      ),
    );
  }
}