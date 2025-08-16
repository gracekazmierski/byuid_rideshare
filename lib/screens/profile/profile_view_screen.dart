// lib/screens/profile/profile_view_screen.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:byui_rideshare/theme/app_colors.dart';
import 'package:byui_rideshare/models/ride.dart';
import 'package:byui_rideshare/screens/rides/ride_detail_screen.dart';


class ProfileViewArgs {
  final String userId;
  const ProfileViewArgs({required this.userId});
}

class ProfileViewScreen extends StatefulWidget {
  static const String routeName = '/profile-view';

  final String userId;
  const ProfileViewScreen({super.key, required this.userId});

  @override
  State<ProfileViewScreen> createState() => _ProfileViewScreenState();
}

class _ProfileViewScreenState extends State<ProfileViewScreen> {
  final _db = FirebaseFirestore.instance;

  // ---------- PROFILE FETCH ----------
  Future<Map<String, dynamic>?> _fetchUserProfile(String uid) async {
    for (final path in const ['users', 'user_profiles']) {
      try {
        final snap = await _db.collection(path).doc(uid).get();
        if (snap.exists) return snap.data();
      } catch (_) {}
    }
    return null;
  }

  // ---------- BYUI BADGE ----------
  bool _byuiVerifiedFromData(Map<String, dynamic> d) {
    final explicit =
        (d['byuiVerified'] as bool?) ??
            (d['byui_verified'] as bool?) ??
            (d['eduVerified'] as bool?) ??
            (d['edu_verified'] as bool?) ??
            (d['byuiBadge'] as bool?) ??
            false;
    if (explicit) return true;

    final byuiEmail =
    (d['byuiEmail'] ?? d['studentEmail'])?.toString().toLowerCase();
    if (byuiEmail != null && byuiEmail.endsWith('@byui.edu')) return true;

    final email = (d['email'] as String?)?.toLowerCase();
    if (email != null && email.endsWith('@byui.edu')) return true;

    final emails = (d['emails'] ?? d['email_addresses']);
    if (emails is List &&
        emails.whereType<String>().any((e) => e.toLowerCase().endsWith('@byui.edu'))) {
      return true;
    }

    final domains = d['verifiedDomains'];
    if (domains is List &&
        domains.whereType<String>().any((dom) => dom.toLowerCase() == 'byui.edu')) {
      return true;
    }

    if (d['byuiVerifiedAt'] is Timestamp) return true;
    return false;
  }

  // ---------- PROFILE FIELDS ----------
  String _fullName(Map<String, dynamic> d) {
    final fn = (d['firstName'] ?? d['first_name'] ?? '').toString().trim();
    final ln = (d['lastName'] ?? d['last_name'] ?? '').toString().trim();
    final display = (d['displayName'] ?? d['name'] ?? '').toString().trim();
    if (display.isNotEmpty) return display;
    if (fn.isEmpty && ln.isEmpty) return 'Anonymous';
    return [fn, ln].where((s) => s.isNotEmpty).join(' ');
  }

  String? _photoUrl(Map<String, dynamic> d) {
    final url =
    (d['photoUrl'] ?? d['photo_url'] ?? d['avatarUrl'])?.toString();
    return (url == null || url.isEmpty) ? null : url;
  }

  String? _phone(Map<String, dynamic> d) {
    return (d['phone'] ?? d['phoneNumber'] ?? d['phone_number'])
        ?.toString()
        .trim();
  }

  bool _phoneVisible(Map<String, dynamic> d) {
    return (d['phoneVisible'] as bool?) ??
        (d['showPhone'] as bool?) ??
        (d['isPhoneVisible'] as bool?) ??
        false; // default private
  }

  // ---------- DATE HELPERS ----------
  // Robust profile "created at" parsing
  DateTime? _profileCreatedAt(Map<String, dynamic> d) {
    final candidates = [
      d['created_at'],
      d['createdAt'],
      d['joined_at'],
      d['joinedAt'],
      d['accountCreated'],
      d['createdOn'],
      d['created_at_ms'],
      d['createdAtMs'],
      d['createdAtMillis'],
      d['created_at_millis'],
    ];
    for (final v in candidates) {
      final dt = _parseAnyDate(v);
      if (dt != null) return dt;
    }
    return null;
  }

  DateTime? _parseAnyDate(dynamic v) {
    if (v == null) return null;
    if (v is Timestamp) return v.toDate();
    if (v is DateTime) return v;
    if (v is String) {
      final parsed = DateTime.tryParse(v);
      if (parsed != null) return parsed;
      final numVal = num.tryParse(v);
      if (numVal != null) return _fromEpochFlexible(numVal);
    }
    if (v is num) return _fromEpochFlexible(v);
    return null;
  }

  DateTime? _fromEpochFlexible(num value) {
    // ms since epoch (e.g., 1.6e12)
    if (value > 100000000000) {
      return DateTime.fromMillisecondsSinceEpoch(value.toInt());
    }
    // seconds since epoch (e.g., 1.6e9)
    if (value > 1000000000) {
      return DateTime.fromMillisecondsSinceEpoch((value * 1000).toInt());
    }
    return null;
  }

  // Extract a ride's datetime from many possible keys
  static DateTime? _extractRideDate(Map<String, dynamic> d) {
    final candidates = [
      d['rideDate'],
      d['ride_date'],
      d['date'],
      d['depart_at'],
      d['departure'],
      d['departure_time'],
      d['start_time'],
      d['timestamp'],
      d['time'],
      d['created_at'], // last-resort
      d['postCreationTime'], // your Ride model uses this in UI
    ];
    for (final v in candidates) {
      if (v == null) continue;
      if (v is Timestamp) return v.toDate();
      if (v is DateTime) return v;
      if (v is String) {
        final parsed = DateTime.tryParse(v);
        if (parsed != null) return parsed;
        final numVal = num.tryParse(v);
        if (numVal != null) {
          if (numVal > 100000000000) {
            return DateTime.fromMillisecondsSinceEpoch(numVal.toInt());
          } else if (numVal > 1000000000) {
            return DateTime.fromMillisecondsSinceEpoch((numVal * 1000).toInt());
          }
        }
      }
      if (v is num) {
        if (v > 100000000000) {
          return DateTime.fromMillisecondsSinceEpoch(v.toInt());
        } else if (v > 1000000000) {
          return DateTime.fromMillisecondsSinceEpoch((v * 1000).toInt());
        }
      }
    }
    return null;
  }

  // ---------- OFFERED RIDES ----------
  bool _isCanceled(Map<String, dynamic> d) {
    final status = (d['status'] ?? '').toString().toLowerCase();
    final canceledBool =
        (d['isCanceled'] as bool?) ?? (d['isCancelled'] as bool?) ?? false;
    return canceledBool ||
        status == 'canceled' ||
        status == 'cancelled' ||
        status == 'archived';
  }

  bool _isFull(Map<String, dynamic> d) {
    final isFull = (d['isFull'] as bool?) ?? false;
    final seats = (d['availableSeats'] as num?)?.toInt();
    if (isFull) return true;
    if (seats != null && seats <= 0) return true;
    return false;
  }

  Future<List<QueryDocumentSnapshot<Map<String, dynamic>>>>
  _fetchCurrentOfferedRides(String uid) async {
    final collections = ['rides', 'ride_offers'];
    final now = DateTime.now();
    final List<QueryDocumentSnapshot<Map<String, dynamic>>> docs = [];

    for (final col in collections) {
      // driver_id
      try {
        final q = await _db.collection(col).where('driver_id', isEqualTo: uid).get();
        docs.addAll(q.docs);
      } catch (_) {}
      // driverUid
      try {
        final q = await _db.collection(col).where('driverUid', isEqualTo: uid).get();
        docs.addAll(q.docs);
      } catch (_) {}
    }

    final filtered = docs.where((doc) {
      final d = doc.data();
      final dt = _extractRideDate(d);
      if (dt == null) return false;
      if (dt.isBefore(now)) return false;
      if (_isCanceled(d)) return false;
      if (_isFull(d)) return false;
      return true;
    }).toList();

    filtered.sort((a, b) {
      final ad = _extractRideDate(a.data()) ?? DateTime.fromMillisecondsSinceEpoch(0);
      final bd = _extractRideDate(b.data()) ?? DateTime.fromMillisecondsSinceEpoch(0);
      return ad.compareTo(bd); // soonest first
    });

    return filtered;
  }

  Future<void> _openRideDetailFromDoc(
      BuildContext context,
      QueryDocumentSnapshot<Map<String, dynamic>> doc,
      ) async {
    try {
      final ride = _mapDocToRide(doc);
      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => RideDetailScreen(ride: ride)),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not open ride: $e')),
      );
    }
  }

  Ride _mapDocToRide(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data();

    // ---- Strings with fallbacks ----
    final origin = (d['origin'] ?? d['from_location'] ?? d['from'] ?? 'Unknown').toString();
    final destination = (d['destination'] ?? d['to_location'] ?? d['to'] ?? 'Unknown').toString();
    final driverUid = (d['driverUid'] ?? d['driver_id'] ?? '').toString();
    final driverName = (d['driverName'] ?? d['driver_name'] ?? 'Unknown Driver').toString();

    // ---- Timestamps (rideDate & postCreationTime) ----
    Timestamp _toTs(dynamic v) {
      if (v is Timestamp) return v;
      if (v is DateTime) return Timestamp.fromDate(v);
      if (v is String) {
        final p = DateTime.tryParse(v);
        if (p != null) return Timestamp.fromDate(p);
        final n = num.tryParse(v);
        if (n != null) {
          if (n > 100000000000) return Timestamp.fromMillisecondsSinceEpoch(n.toInt());
          if (n > 1000000000) return Timestamp.fromMillisecondsSinceEpoch((n * 1000).toInt());
        }
      }
      if (v is num) {
        if (v > 100000000000) return Timestamp.fromMillisecondsSinceEpoch(v.toInt());
        if (v > 1000000000) return Timestamp.fromMillisecondsSinceEpoch((v * 1000).toInt());
      }
      return Timestamp.now();
    }


    final rideDate = _toTs(d['rideDate'] ?? d['date'] ?? d['depart_at'] ?? d['timestamp']);
    final postCreationTime = _toTs(d['postCreationTime'] ?? d['created_at'] ?? d['createdAt']);

    // ---- Numbers ----
    final availableSeats =
        (d['availableSeats'] as int?) ?? (d['available_seats'] as num?)?.toInt() ?? 0;

    double? fare;
    final f = d['fare'] ?? d['price'] ?? d['cost'];
    if (f is num) fare = f.toDouble();
    if (f is String) fare = double.tryParse(f);

    // ---- Booleans ----
    final isFull = (d['isFull'] as bool?) ?? (availableSeats <= 0);

    // ---- Lists ----
    List<String> joinedUserUids = [];
    final j = d['joinedUserUids'] ?? d['riderUids'] ?? d['rider_uids'] ?? d['riders'];
    if (j is List) {
      if (j.isNotEmpty && j.first is Map) {
        // [{uid: ..., name: ...}]
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
  }

  // ---------- MEMBER SINCE (fallback to earliest activity) ----------
  Future<DateTime?> _deriveMemberSince(String uid, Map<String, dynamic> profile) async {
    // 1) Try profile fields first
    final direct = _profileCreatedAt(profile);
    if (direct != null) return direct;

    // 2) Otherwise, infer from earliest activity across offered rides and ride requests
    final dates = <DateTime>[];

    // Offered rides (driver)
    for (final col in ['rides', 'ride_offers']) {
      // driver_id
      try {
        final q = await _db.collection(col).where('driver_id', isEqualTo: uid).limit(25).get();
        for (final doc in q.docs) {
          final d = doc.data();
          final dt = _extractRideDate(d) ?? _parseAnyDate(d['created_at']) ?? _parseAnyDate(d['postCreationTime']);
          if (dt != null) dates.add(dt);
        }
      } catch (_) {}
      // driverUid
      try {
        final q = await _db.collection(col).where('driverUid', isEqualTo: uid).limit(25).get();
        for (final doc in q.docs) {
          final d = doc.data();
          final dt = _extractRideDate(d) ?? _parseAnyDate(d['created_at']) ?? _parseAnyDate(d['postCreationTime']);
          if (dt != null) dates.add(dt);
        }
      } catch (_) {}
    }

    // Ride requests they created
    try {
      final rq = await _db.collection('ride_requests').where('requester_id', isEqualTo: uid).limit(25).get();
      for (final doc in rq.docs) {
        final d = doc.data();
        final dt = _parseAnyDate(d['request_date']) ??
            _parseAnyDate(d['created_at']) ??
            _parseAnyDate(d['postCreationTime']);
        if (dt != null) dates.add(dt);
      }
    } catch (_) {}

    if (dates.isEmpty) return null;
    dates.sort();
    return dates.first;
  }

  // ---------- UI ----------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.gray50,
      appBar: _buildAppBar(context),
      body: FutureBuilder<Map<String, dynamic>?>(
        future: _fetchUserProfile(widget.userId),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: AppColors.byuiBlue));
          }
          if (!snap.hasData || snap.data == null) {
            return const Center(
              child: Text('User not found', style: TextStyle(color: AppColors.textGray600)),
            );
          }

          final data = snap.data!;
          final name = _fullName(data);
          final photoUrl = _photoUrl(data);
          final isByui = _byuiVerifiedFromData(data);
          final phone = _phone(data);
          final phoneVisible = _phoneVisible(data);
          final bio = (data['bio'] ?? '').toString().trim();

          return ListView(
            padding: const EdgeInsets.all(24.0),
            children: [
              _HeaderCard(
                name: name,
                photoUrl: photoUrl,
                isByuiVerified: isByui,
                phone: phone,
                phoneVisible: phoneVisible,
              ),
              const SizedBox(height: 24),

              if (bio.isNotEmpty)
                _sectionCard(
                  title: 'About',
                  children: [
                    Text(bio, style: const TextStyle(fontSize: 14, color: AppColors.textGray600)),
                  ],
                ),

              if (bio.isNotEmpty) const SizedBox(height: 24),

              _sectionCard(
                title: 'Profile',
                children: [
                  _MetaRow(
                    icon: Icons.verified_user,
                    label: 'BYUI Verification',
                    value: isByui ? 'Verified' : 'Not verified',
                    valueColor: isByui ? AppColors.byuiBlue : AppColors.textGray600,
                  ),
                  const SizedBox(height: 12),
                  // Member Since with robust fallback
                  FutureBuilder<DateTime?>(
                    future: _deriveMemberSince(widget.userId, data),
                    builder: (context, msSnap) {
                      final dt = msSnap.data;
                      final val = (dt != null)
                          ? DateFormat('MMMM yyyy').format(dt)
                          : '—';
                      return _MetaRow(
                        icon: Icons.calendar_month,
                        label: 'Member Since',
                        value: val,
                      );
                    },
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Offered Rides (current/future)
              _sectionCard(
                title: 'Offered Rides',
                children: [
                  FutureBuilder<List<QueryDocumentSnapshot<Map<String, dynamic>>>>(
                    future: _fetchCurrentOfferedRides(widget.userId),
                    builder: (context, rideSnap) {
                      if (rideSnap.connectionState == ConnectionState.waiting) {
                        return const Padding(
                          padding: EdgeInsets.symmetric(vertical: 12.0),
                          child: Center(child: CircularProgressIndicator(color: AppColors.byuiBlue)),
                        );
                      }
                      final rides = rideSnap.data ?? [];
                      if (rides.isEmpty) {
                        return const Text(
                          'No active ride offers at the moment.',
                          style: TextStyle(color: AppColors.textGray600),
                        );
                      }

                      return Column(
                        children: rides.map((doc) {
                          final d = doc.data();
                          final from = (d['from_location'] ?? d['from'] ?? d['origin'] ?? 'Unknown').toString();
                          final to = (d['to_location'] ?? d['to'] ?? d['destination'] ?? 'Unknown').toString();
                          final dt = _extractRideDate(d);
                          final dateStr = (dt != null)
                              ? DateFormat('EEE, MMM d • h:mm a').format(dt)
                              : 'Date TBA';
                          final fare = d['fare'] ?? d['price'] ?? d['cost'];
                          String fareStr = '—';
                          if (fare is num) {
                            fareStr = '\$${fare.toStringAsFixed(2)}';
                          } else if (fare is String && fare.trim().isNotEmpty) {
                            fareStr = fare;
                          }

                          return _RideRow(
                            title: '$from → $to',
                            subtitle: '$dateStr  •  Fare: $fareStr',
                            onTap: () => _openRideDetailFromDoc(context, doc),
                          );
                        }).toList(),
                      );
                    },
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return PreferredSize(
      preferredSize: const Size.fromHeight(kToolbarHeight + 40),
      child: Container(
        color: AppColors.byuiBlue,
        padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top),
        child: const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Row(
            children: [
              BackButton(color: Colors.white),
              SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Profile',
                      style: TextStyle(color: Colors.white, fontSize: 24.0, fontWeight: FontWeight.w600)),
                  SizedBox(height: 2.0),
                  Text("View user details and activity",
                      style: TextStyle(color: AppColors.blue100, fontSize: 14.0)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionCard({required String title, required List<Widget> children}) {
    return Container(
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8.0),
        border: Border.all(color: AppColors.gray200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.byuiBlue)),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }
}

// ---------- Header Card ----------
class _HeaderCard extends StatelessWidget {
  final String name;
  final String? photoUrl;
  final bool isByuiVerified;
  final String? phone;
  final bool phoneVisible;

  const _HeaderCard({
    required this.name,
    required this.photoUrl,
    required this.isByuiVerified,
    required this.phone,
    required this.phoneVisible,
  });

  String get _initials {
    final parts =
    name.trim().split(RegExp(r'\s+')).where((s) => s.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return (parts.first[0] + parts.last[0]).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final phoneText = () {
      if (phone == null || phone!.isEmpty) return 'Not provided';
      if (!phoneVisible) return 'Hidden';
      return phone!;
    }();

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20.0, horizontal: 20.0),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppColors.gray200),
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: Row(
        children: [
          Stack(
            children: [
              CircleAvatar(
                radius: 32,
                backgroundColor: AppColors.gray200,
                backgroundImage: (photoUrl != null && photoUrl!.isNotEmpty)
                    ? NetworkImage(photoUrl!)
                    : null,
                child: (photoUrl == null || photoUrl!.isEmpty)
                    ? Text(_initials,
                    style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textGray800))
                    : null,
              ),
              Positioned(
                bottom: -2,
                right: -2,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  padding: const EdgeInsets.all(2),
                  child: Icon(
                    Icons.verified,
                    size: 18,
                    color: isByuiVerified
                        ? AppColors.byuiBlue
                        : AppColors.gray300,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name,
                    style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textGray800)),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(Icons.verified,
                        size: 18,
                        color:
                        isByuiVerified ? AppColors.byuiBlue : AppColors.gray300),
                    const SizedBox(width: 6),
                    Text(
                      isByuiVerified ? 'BYUI Verified' : 'Not Verified',
                      style: TextStyle(
                        color: isByuiVerified
                            ? AppColors.byuiBlue
                            : AppColors.textGray600,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.phone, size: 18, color: AppColors.byuiBlue),
                    const SizedBox(width: 6),
                    Text(
                      phoneText,
                      style: const TextStyle(
                          color: AppColors.textGray600, fontSize: 13),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ---------- Misc row widgets ----------
class _RideRow extends StatelessWidget {
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  const _RideRow({required this.title, required this.subtitle, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.gray50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.gray200),
      ),
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        leading:
        const Icon(Icons.directions_car, color: AppColors.byuiBlue),
        title: Text(title,
            style: const TextStyle(
                fontWeight: FontWeight.w600, color: AppColors.textGray800)),
        subtitle: Text(subtitle,
            style: const TextStyle(color: AppColors.textGray600)),
        trailing: const Icon(Icons.chevron_right,
            color: AppColors.textGray500),
        onTap: onTap,
      ),
    );
  }
}

class _MetaRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;

  const _MetaRow({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: AppColors.byuiBlue),
        const SizedBox(width: 10),
        Expanded(
          child: Text(label,
              style: const TextStyle(color: AppColors.textGray600)),
        ),
        Text(
          value,
          style: TextStyle(
            color: valueColor ?? AppColors.textGray800,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
