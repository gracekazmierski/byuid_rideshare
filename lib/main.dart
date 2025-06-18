// lib/main.dart
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'services/firebase_options.dart';
import 'package:byui_rideshare/screens/auth/auth_wrapper.dart';
import 'package:byui_rideshare/screens/auth/login_page.dart';
import 'package:byui_rideshare/screens/auth/create_account_page.dart'; // Make sure this is imported!

// need to create a navigation bar type thing or something to put this somewhere
// it allows riders to see the status of the rides they have joined
/* ListTile(
  leading: const Icon(Icons.history),
  title: const Text('My Requests'),
  onTap: () {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const MyRequestsScreen()),
    );
  },
),
 */

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BYU-I Rideshare',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const AuthWrapper(),
      routes: {
        '/login': (context) => const LoginPage(),
        '/create_account': (context) => const CreateAccountPage(),
      },
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});
  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text(
              'Welcome to BYU-I Rideshare!',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 40), // More space for the welcome message

            // Login Button (remains here)
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginPage()),
                );
              },
              child: const Text('Login here'),
            ),
            const SizedBox(height: 16), // Spacing between buttons

            // --- NEW: Create an Account button on the Welcome Page ---
            OutlinedButton( // Using OutlinedButton for visual distinction
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const CreateAccountPage()),
                );
              },
              child: const Text('Create an Account'),
            ),
          ],
        ),
      ),
    );
  }
}