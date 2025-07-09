// lib/theme/app_colors.dart

import 'package:flutter/material.dart';

class AppColors {
  // From WelcomeScreen (main BYUI blue, gradient, text grays)
  static const Color byuiBlue = Color(0xFF006EB6); // Your specific BYUI blue
  static const Color backgroundGradientStart = Color(0xFFEFF6FF); // Tailwind blue-50
  static const Color backgroundGradientEnd = Color(0xFFDBEAFE);   // Tailwind blue-100
  static const Color textGray600 = Color(0xFF4B5563);
  static const Color textGray500 = Color(0xFF6B7280);
  static const Color byuiGreen = Color(0xFF2D8F47);
  // --- NEW COLORS FOR LOGIN PAGE ---

  // Background for the login page body (bg-gray-50)
  static const Color gray50 = Color(0xFFF9FAFB);

  // Specific blue used in the header (bg-[#006eb6]) and primary button, focus border/ring
  static const Color headerAndPrimaryBlue = Color(0xFF006EB6); // This is your 'byui-blue' again, can reuse.

  // Text color for the sub-header in the blue header (text-blue-100)
  static const Color blue100 = Color(0xFFDBEAFE);

  // Debug badge red (bg-red-500)
  static const Color red500 = Color(0xFFEF4444);

  // Card border color (border-gray-200)
  static const Color gray200 = Color(0xFFE5E7EB);

  // Input border color (border-gray-300)
  static const Color gray300 = Color(0xFFD1D5DB);

  // Input focus color (focus:border-[#006eb6] focus:ring-[#006eb6])
  static const Color inputFocusBlue = Color(0xFF006EB6); // Same as headerAndPrimaryBlue

  // Password toggle icon/text (text-gray-500) - already have textGray500
  // Hover text for password toggle (hover:text-gray-700)
  static const Color gray700 = Color(0xFF374151);

  // Google button text (text-gray-700) - already have gray700
  // Google button hover background (hover:bg-gray-50) - already have gray50

  static const Color requestAccent = Color(0xFF00838F);

  static const Color textGray800 = Color(0xFF1F2937);

  // Sign In button hover background (hover:bg-[#005a9a])
  static const Color byuiBlueHover = Color(0xFF005A9A); // A slightly darker shade of byuiBlue
}