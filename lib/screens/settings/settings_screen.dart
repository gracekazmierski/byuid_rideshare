// lib/settings/settings_screen.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:byui_rideshare/theme/app_colors.dart';
import 'package:byui_rideshare/models/ride.dart';
import 'package:byui_rideshare/screens/rides/ride_detail_screen.dart';
import 'package:byui_rideshare/screens/auth/profile_edit_screen.dart';

class SettingsScreen extends StatefulWidget {
  static const routeName = '/settings';

  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _auth = FirebaseAuth.instance;
  final _db = FirebaseFirestore.instance;

  // ---- profile preview for the top card ----
  bool _loadingProfile = true;
  String _displayName = '';
  String _email = '';
  String _phone = '';
  bool _phoneVisible = false;
  String? _photoUrl;

  @override
  void initState() {
    super.initState();
    _loadProfilePreview();
  }

  // ======== THEME HELPERS ========
  Widget _sectionCard({required String title, required List<Widget> children}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppColors.gray200),
        borderRadius: BorderRadius.circular(8.0),
      ),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(
                  fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.byuiBlue)),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  Widget _settingsTile({
    required String label,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: AppColors.gray200),
          borderRadius: BorderRadius.circular(10),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        child: Row(
          children: [
            Icon(icon, color: AppColors.textGray600),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  color: AppColors.textGray800,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.textGray500),
          ],
        ),
      ),
    );
  }

  // ======== PROFILE PREVIEW ========
  Future<void> _loadProfilePreview() async {
    final uid = _auth.currentUser?.uid;
    final user = _auth.currentUser;
    if (uid == null) {
      setState(() => _loadingProfile = false);
      return;
    }

    Map<String, dynamic>? data;
    try {
      final usersDoc = await _db.collection('users').doc(uid).get();
      if (usersDoc.exists) {
        data = usersDoc.data();
      } else {
        final profilesDoc = await _db.collection('user_profiles').doc(uid).get();
        if (profilesDoc.exists) data = profilesDoc.data();
      }
    } catch (_) {}

    setState(() {
      _displayName =
          (data?['displayName'] ?? data?['name'] ?? user?.displayName ?? 'Your name').toString();
      _email = user?.email ?? (data?['email']?.toString() ?? '—');
      _phone = (data?['phone'] ?? data?['phoneNumber'] ?? '').toString();
      _phoneVisible = (data?['phoneVisible'] as bool?) ?? (data?['showPhone'] as bool?) ?? false;
      _photoUrl = (data?['photoUrl'] ?? data?['photo_url'] ?? user?.photoURL)?.toString();
      _loadingProfile = false;
    });
  }

  // ======== UI ========
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.gray50,
      appBar: const _BlueHeader(
        title: 'Settings',
        subtitle: 'Manage your account & support',
        showBack: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ---- My Account card ----
          if (_loadingProfile)
            const Center(
              child: Padding(
                padding: EdgeInsets.only(top: 16.0, bottom: 8),
                child: CircularProgressIndicator(color: AppColors.byuiBlue),
              ),
            )
          else
            _sectionCard(
              title: 'My Account',
              children: [
                Row(
                  children: [
                    _Avatar(photoUrl: _photoUrl, name: _displayName),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(_displayName,
                              style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textGray800)),
                          const SizedBox(height: 2),
                          Text(_email, style: const TextStyle(color: AppColors.textGray600)),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Icon(Icons.phone, size: 18, color: AppColors.byuiBlue),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        (_phone.isEmpty) ? 'Phone: Not provided' : 'Phone: $_phone',
                        style: const TextStyle(color: AppColors.textGray600, fontSize: 14),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: (_phoneVisible ? AppColors.byuiGreen : AppColors.textGray500)
                            .withOpacity(0.08),
                        border: Border.all(
                          color: (_phoneVisible ? AppColors.byuiGreen : AppColors.textGray500)
                              .withOpacity(0.3),
                        ),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        _phoneVisible ? 'Visible' : 'Hidden',
                        style: TextStyle(
                          color: _phoneVisible ? AppColors.byuiGreen : AppColors.textGray500,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 48,
                  child: ElevatedButton(
                    onPressed: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const ProfileEditScreen()),
                      );
                      if (!mounted) return;
                      _loadProfilePreview(); // refresh after returning
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.byuiBlue,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: const Text('Edit My Account',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                  ),
                ),
              ],
            ),

          const SizedBox(height: 16),

          _settingsTile(
            label: 'See Ride History',
            icon: Icons.history_rounded,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const RideHistoryScreen()),
            ),
          ),
          const SizedBox(height: 10),
          _settingsTile(
            label: 'Change Password',
            icon: Icons.lock_outline_rounded,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ChangePasswordScreen()),
            ),
          ),
          const SizedBox(height: 10),
          _settingsTile(
            label: 'Log Out',
            icon: Icons.logout_rounded,
            onTap: _confirmLogout,
          ),
          const SizedBox(height: 10),
          _settingsTile(
            label: 'Get Help',
            icon: Icons.help_outline_rounded,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const HelpScreen()),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmLogout() async {
    final should = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Log Out?'),
        content: const Text('You will be signed out of RexRide.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.byuiBlue,
              foregroundColor: Colors.white,
            ),
            child: const Text('Log Out'),
          ),
        ],
      ),
    );
    if (should == true) {
      await _auth.signOut();
      if (!mounted) return;
      Navigator.of(context).pop(); // return to previous; auth wrapper should react
    }
  }
}

class _BlueHeader extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final String subtitle;
  final bool showBack;

  const _BlueHeader({
    required this.title,
    required this.subtitle,
    this.showBack = true,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight + 40);

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.of(context).padding.top;
    return Container(
      color: AppColors.byuiBlue,
      padding: EdgeInsets.only(top: top),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
        child: Row(
          children: [
            if (showBack) const BackButton(color: Colors.white),
            if (showBack) const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24.0,
                          fontWeight: FontWeight.w600)),
                  const SizedBox(height: 2.0),
                  Text(subtitle,
                      style: const TextStyle(
                          color: AppColors.blue100, fontSize: 14.0)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ========== SMALL REUSABLES ==========

class _Avatar extends StatelessWidget {
  final String? photoUrl;
  final String name;
  const _Avatar({required this.photoUrl, required this.name});

  @override
  Widget build(BuildContext context) {
    String initials = '?';
    final parts = name.trim().split(RegExp(r'\s+')).where((s) => s.isNotEmpty).toList();
    if (parts.isNotEmpty) {
      initials = parts.length == 1
          ? parts.first[0].toUpperCase()
          : (parts.first[0] + parts.last[0]).toUpperCase();
    }

    return CircleAvatar(
      radius: 28,
      backgroundColor: AppColors.gray200,
      backgroundImage: (photoUrl != null && photoUrl!.isNotEmpty) ? NetworkImage(photoUrl!) : null,
      child: (photoUrl == null || photoUrl!.isEmpty)
          ? Text(
        initials,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: AppColors.textGray800,
        ),
      )
          : null,
    );
  }
}

// ========== RIDE HISTORY PAGE ==========

class RideHistoryScreen extends StatefulWidget {
  const RideHistoryScreen({super.key});

  @override
  State<RideHistoryScreen> createState() => _RideHistoryScreenState();
}

class _RideHistoryScreenState extends State<RideHistoryScreen> {
  final _auth = FirebaseAuth.instance;
  final _db = FirebaseFirestore.instance;

  @override
  Widget build(BuildContext context) {
    final uid = _auth.currentUser?.uid;

    return Scaffold(
      backgroundColor: AppColors.gray50,
      appBar: const _BlueHeader(
        title: 'Ride History',
        subtitle: 'Your past rides',
        showBack: true,
      ),
      body: uid == null
          ? const Center(
        child: Text('Please sign in to view your history.',
            style: TextStyle(color: AppColors.textGray600)),
      )
          : FutureBuilder<List<Ride>>(
        future: _fetchRideHistory(uid),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.byuiBlue),
            );
          }
          final rides = snap.data ?? [];
          if (rides.isEmpty) {
            return const Center(
              child: Text('No past rides yet.',
                  style: TextStyle(color: AppColors.textGray600)),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: rides.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, i) {
              final r = rides[i];
              final dateStr =
                  '${DateFormat('EEE, MMM d').format(r.rideDate.toDate())} • ${DateFormat('h:mm a').format(r.rideDate.toDate())}';
              final isDriver = r.driverUid == uid;
              final role = isDriver ? 'Driver' : 'Passenger';
              final roleColor =
              isDriver ? AppColors.byuiGreen : AppColors.textGray500;

              return InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => RideDetailScreen(ride: r)),
                  );
                },
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: AppColors.gray200),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      const Icon(Icons.directions_car, color: AppColors.byuiBlue),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('${r.origin} → ${r.destination}',
                                style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textGray800)),
                            const SizedBox(height: 2),
                            Text(dateStr,
                                style: const TextStyle(color: AppColors.textGray600)),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: roleColor.withOpacity(0.08),
                          border: Border.all(color: roleColor.withOpacity(0.3)),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(role,
                            style: TextStyle(
                                color: roleColor, fontWeight: FontWeight.w600)),
                      ),
                      const SizedBox(width: 6),
                      const Icon(Icons.chevron_right, color: AppColors.textGray500),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Future<List<Ride>> _fetchRideHistory(String uid) async {
    final now = DateTime.now();
    final List<QueryDocumentSnapshot<Map<String, dynamic>>> docs = [];

    Future<void> _collect(String collection) async {
      try {
        final asDriver =
        await _db.collection(collection).where('driverUid', isEqualTo: uid).get();
        docs.addAll(asDriver.docs);
      } catch (_) {}
      try {
        final asDriverAlt =
        await _db.collection(collection).where('driver_id', isEqualTo: uid).get();
        docs.addAll(asDriverAlt.docs);
      } catch (_) {}
      try {
        final asPassenger = await _db
            .collection(collection)
            .where('joinedUserUids', arrayContains: uid)
            .get();
        docs.addAll(asPassenger.docs);
      } catch (_) {}
      try {
        final asPassengerAlt =
        await _db.collection(collection).where('rider_uids', arrayContains: uid).get();
        docs.addAll(asPassengerAlt.docs);
      } catch (_) {}
    }

    await _collect('rides');
    await _collect('ride_offers');

    List<Ride> rides = [];
    for (final doc in docs) {
      final r = _mapDocToRide(doc);
      if (r != null && r.rideDate.toDate().isBefore(now)) {
        rides.add(r);
      }
    }

    final Map<String, Ride> unique = {for (var r in rides) r.id: r};
    final list = unique.values.toList()..sort((a, b) => b.rideDate.compareTo(a.rideDate));
    return list;
  }

  Ride? _mapDocToRide(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    try {
      final d = doc.data();

      Timestamp _toTs(dynamic v) {
        if (v is Timestamp) return v;
        if (v is DateTime) return Timestamp.fromDate(v);
        if (v is String) {
          final p = DateTime.tryParse(v);
          if (p != null) return Timestamp.fromDate(p);
          final n = num.tryParse(v);
          if (n != null) {
            if (n > 100000000000) {
              return Timestamp.fromMillisecondsSinceEpoch(n.toInt());
            } else if (n > 1000000000) {
              return Timestamp.fromMillisecondsSinceEpoch((n * 1000).toInt());
            }
          }
        }
        if (v is num) {
          if (v > 100000000000) {
            return Timestamp.fromMillisecondsSinceEpoch(v.toInt());
          } else if (v > 1000000000) {
            return Timestamp.fromMillisecondsSinceEpoch((v * 1000).toInt());
          }
        }
        return Timestamp.now();
      }

      final origin =
      (d['origin'] ?? d['from_location'] ?? d['from'] ?? 'Unknown').toString();
      final destination =
      (d['destination'] ?? d['to_location'] ?? d['to'] ?? 'Unknown').toString();
      final driverUid = (d['driverUid'] ?? d['driver_id'] ?? '').toString();
      final driverName =
      (d['driverName'] ?? d['driver_name'] ?? 'Unknown Driver').toString();
      final rideDate =
      _toTs(d['rideDate'] ?? d['date'] ?? d['depart_at'] ?? d['timestamp']);
      final postCreationTime =
      _toTs(d['postCreationTime'] ?? d['created_at'] ?? d['createdAt']);
      final availableSeats =
          (d['availableSeats'] as int?) ?? (d['available_seats'] as num?)?.toInt() ?? 0;

      double? fare;
      final f = d['fare'] ?? d['price'] ?? d['cost'];
      if (f is num) fare = f.toDouble();
      if (f is String) fare = double.tryParse(f);

      final isFull = (d['isFull'] as bool?) ?? (availableSeats <= 0);

      List<String> joinedUserUids = [];
      final j = d['joinedUserUids'] ?? d['riderUids'] ?? d['rider_uids'] ?? d['riders'];
      if (j is List) {
        if (j.isNotEmpty && j.first is Map) {
          joinedUserUids = j
              .map((e) => (e['uid'] ?? e['id'] ?? '').toString())
              .where((s) => s.isNotEmpty)
              .toList();
        } else {
          joinedUserUids = j.whereType<String>().toList();
        }
      }

      return Ride(
        id: doc.id,
        origin: origin,
        destination: destination,
        rideDate: rideDate,
        availableSeats: availableSeats,
        fare: fare,
        driverUid: driverUid,
        driverName: driverName,
        postCreationTime: postCreationTime,
        isFull: isFull,
        joinedUserUids: joinedUserUids,
      );
    } catch (_) {
      return null;
    }
  }
}

// ========== CHANGE PASSWORD PAGE ==========

class ChangePasswordScreen extends StatelessWidget {
  const ChangePasswordScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = FirebaseAuth.instance;
    final email = auth.currentUser?.email ?? '—';

    Future<void> _sendPasswordReset() async {
      final e = auth.currentUser?.email;
      if (e == null || e.isEmpty) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('No email on file for this account.')));
        return;
      }
      try {
        await auth.sendPasswordResetEmail(email: e);
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Password reset link sent to $e')));
      } catch (err) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Failed to send reset email: $err')));
      }
    }

    return Scaffold(
      backgroundColor: AppColors.gray50,
      appBar: const _BlueHeader(
        title: 'Change Password',
        subtitle: 'Reset via email link',
        showBack: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: AppColors.gray200),
              borderRadius: BorderRadius.circular(8.0),
            ),
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Reset via Email',
                    style: TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.byuiBlue)),
                const SizedBox(height: 12),
                Text('Account email: $email',
                    style: const TextStyle(color: AppColors.textGray600)),
                const SizedBox(height: 12),
                const Text('We’ll send a password-reset link to your email.',
                    style: TextStyle(color: AppColors.textGray500)),
                const SizedBox(height: 16),
                SizedBox(
                  height: 48,
                  child: ElevatedButton.icon(
                    onPressed: _sendPasswordReset,
                    icon: const Icon(Icons.email_outlined),
                    label: const Text('Send Reset Link'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.byuiBlue,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ========== HELP PAGE ==========

class HelpScreen extends StatefulWidget {
  const HelpScreen({super.key});

  @override
  State<HelpScreen> createState() => _HelpScreenState();
}

class _HelpScreenState extends State<HelpScreen> {
  final _db = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  final _subjectCtrl = TextEditingController();
  final _messageCtrl = TextEditingController();
  bool _sending = false;

  @override
  void dispose() {
    _subjectCtrl.dispose();
    _messageCtrl.dispose();
    super.dispose();
  }

  Future<void> _submitTicket() async {
    final user = _auth.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please sign in to send a help message.')),
      );
      return;
    }

    final uid = user.uid;
    final email = user.email ?? '';
    final subject = _subjectCtrl.text.trim();
    final message = _messageCtrl.text.trim();

    if (subject.isEmpty || message.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Please fill in subject and message.')));
      return;
    }

    setState(() => _sending = true);
    try {
      await _db.collection('support_tickets').add({
        'userId': uid,
        'email': email,
        'subject': subject,
        'message': message,
        'status': 'open',
        'createdAt': FieldValue.serverTimestamp(),
      });
      _subjectCtrl.clear();
      _messageCtrl.clear();
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Thanks! Your message has been sent.')));
    } on FirebaseException catch (e) {
      if (!mounted) return;
      // Surface a clearer message for permission issues
      final msg = e.code == 'permission-denied'
          ? 'Permission denied. Update Firestore rules to allow creating support tickets.'
          : 'Failed to send: ${e.message}';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to send: $e')));
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.gray50,
      appBar: const _BlueHeader(
        title: 'Get Help',
        subtitle: 'Contact RexRide support',
        showBack: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: AppColors.gray200),
              borderRadius: BorderRadius.circular(8.0),
            ),
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Contact Support',
                    style: TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.byuiBlue)),
                const SizedBox(height: 12),
                TextField(
                  controller: _subjectCtrl,
                  decoration: InputDecoration(
                    labelText: 'Subject',
                    labelStyle: const TextStyle(color: AppColors.textGray600),
                    floatingLabelStyle: const TextStyle(color: AppColors.byuiBlue),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8.0),
                      borderSide: const BorderSide(color: AppColors.gray300),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8.0),
                      borderSide: const BorderSide(color: AppColors.gray300),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8.0),
                      borderSide:
                      const BorderSide(color: AppColors.inputFocusBlue, width: 2.0),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _messageCtrl,
                  maxLines: 5,
                  decoration: InputDecoration(
                    labelText: 'How can we help?',
                    labelStyle: const TextStyle(color: AppColors.textGray600),
                    floatingLabelStyle: const TextStyle(color: AppColors.byuiBlue),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8.0),
                      borderSide: const BorderSide(color: AppColors.gray300),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8.0),
                      borderSide: const BorderSide(color: AppColors.gray300),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8.0),
                      borderSide:
                      const BorderSide(color: AppColors.inputFocusBlue, width: 2.0),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 48,
                  child: ElevatedButton(
                    onPressed: _sending ? null : _submitTicket,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.byuiBlue,
                      foregroundColor: Colors.white,
                      shape:
                      RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: _sending
                        ? const SizedBox(
                      height: 22,
                      width: 22,
                      child: CircularProgressIndicator(
                          strokeWidth: 3, color: Colors.white),
                    )
                        : const Text('Send Message',
                        style:
                        TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
