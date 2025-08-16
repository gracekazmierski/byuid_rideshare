// lib/widgets/profile/profile_chip.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:byui_rideshare/theme/app_colors.dart';
import 'package:byui_rideshare/screens/profile/profile_view_screen.dart';

class UserLite {
  final String uid;
  final String name;
  final String? photoUrl;
  final bool byuiVerified;
  const UserLite({
    required this.uid,
    required this.name,
    this.photoUrl,
    required this.byuiVerified,
  });
}

class ProfileChip extends StatelessWidget {
  final String userId;
  final bool showName;          // set false if you want avatar only
  final bool dense;             // smaller sizing for compact lists
  final TextStyle? nameStyle;   // optional override
  final double avatarRadius;    // default adapts to dense
  final VoidCallback? onTap;    // custom action; defaults to open profile
  final double maxNameWidth;    // truncation width in tight layouts

  const ProfileChip({
    super.key,
    required this.userId,
    this.showName = true,
    this.dense = true,
    this.nameStyle,
    double? avatarRadius,
    this.onTap,
    this.maxNameWidth = 140,
  }) : avatarRadius = avatarRadius ?? (dense ? 12 : 18);

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<UserLite>(
      future: _getUserLite(userId),
      builder: (context, snap) {
        final loading = snap.connectionState == ConnectionState.waiting;
        final data = snap.data;

        final name = data?.name ?? (loading ? 'Loading…' : 'Unknown');
        final initials = _initials(name);
        final photoUrl = data?.photoUrl;
        final isByui = data?.byuiVerified ?? false;

        final chip = Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _Avatar(
              photoUrl: photoUrl,
              initials: initials,
              radius: avatarRadius,
              isByuiVerified: isByui,
            ),
            if (showName) const SizedBox(width: 6),
            if (showName)
              ConstrainedBox(
                constraints: BoxConstraints(maxWidth: maxNameWidth),
                child: Text(
                  name,
                  overflow: TextOverflow.ellipsis,
                  softWrap: false,
                  style: nameStyle ??
                      TextStyle(
                        fontSize: dense ? 12 : 14,
                        color: AppColors.textGray500,
                        fontWeight: FontWeight.w500,
                      ),
                ),
              ),
          ],
        );

        return Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap ??
                    () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ProfileViewScreen(userId: userId),
                    ),
                  );
                },
            borderRadius: BorderRadius.circular(999),
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: dense ? 2 : 4,
                vertical: dense ? 2 : 4,
              ),
              child: chip,
            ),
          ),
        );
      },
    );
  }

  static String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+')).where((s) => s.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return (parts.first[0] + parts.last[0]).toUpperCase();
  }
}

class _Avatar extends StatelessWidget {
  final String? photoUrl;
  final String initials;
  final double radius;
  final bool isByuiVerified;

  const _Avatar({
    required this.photoUrl,
    required this.initials,
    required this.radius,
    required this.isByuiVerified,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        CircleAvatar(
          radius: radius,
          backgroundColor: const Color(0xFFE6F1FA), // light blue token circle
          backgroundImage: (photoUrl != null && photoUrl!.isNotEmpty)
              ? NetworkImage(photoUrl!)
              : null,
          child: (photoUrl == null || photoUrl!.isEmpty)
              ? Text(
            initials,
            style: TextStyle(
              fontSize: radius * 0.9,
              fontWeight: FontWeight.bold,
              color: AppColors.byuiBlue,
            ),
          )
              : null,
        ),
        // Small BYUI check overlay
        Positioned(
          bottom: -2,
          right: -2,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
            ),
            padding: const EdgeInsets.all(1.5),
            child: Icon(
              Icons.verified,
              size: radius * 0.9,
              color: isByuiVerified ? AppColors.byuiBlue : AppColors.gray300,
            ),
          ),
        ),
      ],
    );
  }
}

final Map<String, UserLite> _userLiteCache = {};

Future<UserLite> _getUserLite(String uid) async {
  // Cache to avoid repeated reads in lists
  final cached = _userLiteCache[uid];
  if (cached != null) return cached;

  final fs = FirebaseFirestore.instance;
  Map<String, dynamic>? data;

  // Try common collections used in your app
  for (final col in ['users', 'user_profiles']) {
    try {
      final doc = await fs.collection(col).doc(uid).get();
      if (doc.exists) {
        data = doc.data();
        break;
      }
    } catch (_) {/* ignore and try next */}
  }

  String name = 'User';
  String? photoUrl;
  bool byuiVerified = false;

  if (data != null) {
    final fn = (data['firstName'] ?? data['first_name'] ?? '').toString().trim();
    final ln = (data['lastName'] ?? data['last_name'] ?? '').toString().trim();
    final display = (data['displayName'] ?? data['name'] ?? '').toString().trim();
    if (display.isNotEmpty) {
      name = display;
    } else if (fn.isNotEmpty || ln.isNotEmpty) {
      name = [fn, ln].where((s) => s.isNotEmpty).join(' ');
    }

    photoUrl = (data['photoUrl'] ?? data['photo_url'] ?? data['avatarUrl'])?.toString();
    final explicit =
        (data['byuiVerified'] as bool?) ??
            (data['byui_verified'] as bool?) ??
            (data['eduVerified'] as bool?) ??
            (data['edu_verified'] as bool?) ??
            (data['byuiBadge'] as bool?) ??
            false;

    String? byuiEmail = (data['byuiEmail'] ?? data['studentEmail'])?.toString().toLowerCase();
    String? email = (data['email'] as String?)?.toLowerCase();

    bool arrayHasByui = false;
    final emails = (data['emails'] ?? data['email_addresses']);
    if (emails is List) {
      arrayHasByui = emails.whereType<String>().any((e) => e.toLowerCase().endsWith('@byui.edu'));
    }
    final domains = data['verifiedDomains'];
    bool domainHasByui = domains is List && domains.whereType<String>().any((d) => d.toLowerCase() == 'byui.edu');

    byuiVerified = explicit ||
        (byuiEmail?.endsWith('@byui.edu') ?? false) ||
        (email?.endsWith('@byui.edu') ?? false) ||
        arrayHasByui ||
        domainHasByui ||
        (data['byuiVerifiedAt'] is Timestamp);
  }

  final userLite = UserLite(uid: uid, name: name, photoUrl: photoUrl, byuiVerified: byuiVerified);
  _userLiteCache[uid] = userLite;
  return userLite;
}
