// lib/screens/auth/byui_verify_screen.dart
import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_functions/cloud_functions.dart';

import 'package:http/http.dart' as http;
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
  bool _busy = true;

  @override
  void initState() {
    super.initState();
    // Run after first frame so context is available for navigation
    WidgetsBinding.instance.addPostFrameCallback((_) => _handle());
  }

  Map<String, String> _collectParamsFromUrl() {
    final base = Uri.base;
    final params = <String, String>{};

    // Query params (?oobCode=...&mode=signIn...)
    params.addAll(base.queryParameters);

    // Also parse after '#': "#/byui-verify?oobCode=...&mode=..."
    final frag = base.fragment;
    final qIndex = frag.indexOf('?');
    if (qIndex != -1 && qIndex < frag.length - 1) {
      final fragQuery = frag.substring(qIndex + 1);
      try {
        params.addAll(Uri.splitQueryString(fragQuery));
      } catch (_) {}
    }
    return params;
  }

  String? _readApiKey(Map<String, String> params) {
    final fromUrl = params['apiKey'];
    if (fromUrl != null && fromUrl.isNotEmpty) return fromUrl;
    try {
      return Firebase.app().options.apiKey;
    } catch (_) {
      return null;
    }
  }

  Future<String> _restSignInWithEmailLink({
    required String email,
    required String oobCode,
    required String apiKey,
  }) async {
    final url = Uri.parse(
      'https://identitytoolkit.googleapis.com/v1/accounts:signInWithEmailLink?key=$apiKey',
    );
    final resp = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'oobCode': oobCode}),
    );
    if (resp.statusCode != 200) {
      throw Exception('Sign-in failed (${resp.statusCode}): ${resp.body}');
    }
    final body = jsonDecode(resp.body) as Map<String, dynamic>;
    final idToken = body['idToken'] as String?;
    if (idToken == null || idToken.isEmpty) {
      throw Exception('No idToken returned');
    }
    return idToken;
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
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.byuiBlue,
          foregroundColor: Colors.white,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: AppColors.byuiBlue),
      ),
    );

    return showDialog<String>(
      context: context,
      builder:
          (context) => Theme(
            data: themed,
            child: AlertDialog(
              title: const Text(
                'Enter your BYUI email',
                style: TextStyle(
                  color: AppColors.textGray600,
                  fontWeight: FontWeight.bold,
                ),
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
                  keyboardType: TextInputType.emailAddress,
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
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

  Future<void> _handle() async {
    try {
      final params = _collectParamsFromUrl();
      final mode = params['mode'];
      final oobCode = params['oobCode'];
      if (mode != 'signIn' || (oobCode == null || oobCode.isEmpty)) {
        setState(() {
          _busy = false;
          _status = 'This verification link is invalid or has expired.';
        });
        return;
      }

      final apiKey = _readApiKey(params);
      if (apiKey == null || apiKey.isEmpty) {
        setState(() {
          _busy = false;
          _status = 'Missing API key for verification.';
        });
        return;
      }

      final prefs = await SharedPreferences.getInstance();
      var email = prefs.getString('byui_pending_email');

      if (email == null || email.isEmpty) {
        email = await _askForEmail();
        if (email == null || email.isEmpty) {
          setState(() {
            _busy = false;
            _status = 'Verification canceled.';
          });
          return;
        }
      }

      email = email.toLowerCase();
      if (!email.endsWith('@byui.edu')) {
        setState(() {
          _busy = false;
          _status = 'Email must end with @byui.edu.';
        });
        return;
      }

      // Sign-in via REST to obtain a token for the secondary session
      final idToken = await _restSignInWithEmailLink(
        email: email,
        oobCode: oobCode,
        apiKey: apiKey,
      );

      // Notify our backend to mark verified + set custom claims
      final functions = FirebaseFunctions.instanceFor(region: 'us-central1');
      await functions.httpsCallable('confirmByuiVerification').call({
        'byuiEmail': email,
        'secondaryIdToken': idToken,
      });

      await prefs.remove('byui_pending_email');
      await FirebaseAuth.instance.currentUser?.getIdToken(true);

      if (!mounted) return;
      // ✅ Bounce straight back to Profile with a success flag
      Navigator.of(context).pushNamedAndRemoveUntil(
        ProfileEditScreen.routeName,
        (r) => false,
        arguments: {'byuiVerified': true, 'byuiEmail': email},
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _status = 'Verification failed: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Minimal fallback UI; on success we navigate immediately.
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
              if (_busy)
                const Padding(
                  padding: EdgeInsets.only(bottom: 16),
                  child: CircularProgressIndicator(),
                ),
              Text(
                _status,
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.textGray600),
              ),
              if (!_busy)
                Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: ElevatedButton(
                    onPressed:
                        () => Navigator.of(context).pushNamedAndRemoveUntil(
                          ProfileEditScreen.routeName,
                          (r) => false,
                        ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.byuiBlue,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Back to Profile'),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
