import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../theme/app_colors.dart';
import '../auth/profile_edit_screen.dart';

class ByuiVerifyScreen extends StatefulWidget {
  static const routeName = '/byui-verify';
  const ByuiVerifyScreen({super.key});

  @override
  State<ByuiVerifyScreen> createState() => _ByuiVerifyScreenState();
}

class _ByuiVerifyScreenState extends State<ByuiVerifyScreen> {
  String _status = 'Verifying your BYUI email…';
  bool _done = false;

  @override
  void initState() {
    super.initState();
    // Run after first frame so Scaffold is ready for SnackBars
    WidgetsBinding.instance.addPostFrameCallback((_) => _handle());
  }

  Future<FirebaseAuth> _getSecondaryAuth() async {
    FirebaseApp app;
    try {
      app = Firebase.app('byuiVerify');
    } catch (_) {
      final defaultApp = Firebase.app();
      app = await Firebase.initializeApp(name: 'byuiVerify', options: defaultApp.options);
    }
    return FirebaseAuth.instanceFor(app: app);
  }

  Future<void> _handle() async {
    try {
      final url = Uri.base.toString();

      // Quick sanity check before doing anything
      if (!FirebaseAuth.instance.isSignInWithEmailLink(url)) {
        setState(() => _status = 'This verification link is invalid or has expired.');
        return;
      }

      final prefs = await SharedPreferences.getInstance();
      var email = prefs.getString('byui_pending_email');

      // If we lost the cached email, ask for it (rare but happens with private windows, etc.)
      if (email == null || email.isEmpty) {
        email = await _askForEmail();
        if (email == null) return; // user canceled
      }

      // Use a secondary auth instance so the main session stays intact.
      final secondary = await _getSecondaryAuth();
      final cred = await secondary.signInWithEmailLink(email: email, emailLink: url);

      final secUser = cred.user;
      if (secUser == null) {
        await secondary.signOut();
        setState(() => _status = 'Could not complete verification. Please request a new link.');
        return;
      }

      final verifiedEmail = (secUser.email ?? email).toLowerCase();
      if (!verifiedEmail.endsWith('@byui.edu')) {
        await secondary.signOut();
        setState(() => _status = 'Email must end with @byui.edu.');
        return;
      }

      // Prove inbox control to backend and mark verified.
      final token = await secUser.getIdToken();
      final functions = FirebaseFunctions.instanceFor(region: 'us-central1');
      final callable = functions.httpsCallable('confirmByuiVerification');
      await callable.call({'byuiEmail': verifiedEmail, 'secondaryIdToken': token});

      await secondary.signOut();
      await prefs.remove('byui_pending_email');

      if (!mounted) return;
      setState(() {
        _status = 'Verified! Redirecting…';
        _done = true;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('BYUI email verified! 🎉')),
      );

      // Refresh custom claims on the primary user (if logged in this tab)
      await FirebaseAuth.instance.currentUser?.getIdToken(true);

      // Small pause so the user sees the status update
      await Future.delayed(const Duration(milliseconds: 600));
      if (!mounted) return;
      Navigator.of(context).pushReplacementNamed(ProfileEditScreen.routeName);
    } catch (e) {
      if (!mounted) return;
      setState(() => _status = 'Verification failed: $e');
    }
  }

  Future<String?> _askForEmail() async {
    final formKey = GlobalKey<FormState>();
    final controller = TextEditingController();

    final base = ThemeData.light(useMaterial3: true);
    final themed = base.copyWith(
      dialogTheme: const DialogThemeData(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
        ),
      ),
      colorScheme: base.colorScheme.copyWith(
        primary: AppColors.byuiBlue,
        onPrimary: Colors.white,
        surface: Colors.white,
        onSurface: AppColors.textGray600,
      ),
      textSelectionTheme: const TextSelectionThemeData(
        cursorColor: AppColors.byuiBlue,
        selectionColor: AppColors.blue100,
        selectionHandleColor: AppColors.byuiBlue,
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: AppColors.byuiBlue),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.byuiBlue,
          foregroundColor: Colors.white,
        ),
      ),
    );

    return showDialog<String>(
      context: context,
      builder: (context) => Theme(
        data: themed,
        child: AlertDialog(
          title: const Text(
            'Enter your BYUI email',
            style: TextStyle(color: AppColors.textGray600, fontWeight: FontWeight.bold),
          ),
          content: Form(
            key: formKey,
            child: TextFormField(
              controller: controller,
              decoration: const InputDecoration(
                labelText: 'name@byui.edu',
                border: OutlineInputBorder(),
              ),
              validator: (v) {
                final value = (v ?? '').trim().toLowerCase();
                final re = RegExp(r'^[a-zA-Z0-9._%+\-]+@byui\.edu$');
                if (value.isEmpty) return 'Enter your BYUI email';
                if (!re.hasMatch(value)) return 'Must be @byui.edu';
                return null;
              },
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  Navigator.pop(context, controller.text.trim());
                }
              },
              child: const Text('Continue'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Minimal screen, still in your color system
    return Scaffold(
      backgroundColor: AppColors.gray50,
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 420),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: AppColors.gray200),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (!_done) const Padding(
                padding: EdgeInsets.only(bottom: 16),
                child: CircularProgressIndicator(),
              ),
              Text(
                _status,
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.textGray600),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
