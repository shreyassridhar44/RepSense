import 'package:flutter/material.dart';

/// RepSense brand colors — sourced directly from RepSense-General.pdf
class AppColors {
  AppColors._();

  // Primary
  static const Color electricBlue = Color(0xFF3B82F6);
  // Secondary
  static const Color emerald = Color(0xFF10B981);
  // Accent
  static const Color violet = Color(0xFF8B5CF6);
  // Warning
  static const Color amber = Color(0xFFF59E0B);
  // Error
  static const Color error = Color(0xFFEF4444);
  static const Color errorRed = Color(0xFFEF4444); // Alias for error
  // Success
  static const Color success = Color(0xFF10B981); // Same as emerald
  // Warning
  static const Color warning = Color(0xFFF59E0B); // Same as amber

  // Background / Surface
  static const Color background = Color(0xFF0F172A); // Dark Graphite
  static const Color backgroundDark = Color(0xFF0A0F1E); // Darker variant
  static const Color backgroundLight = Color(0xFF1E293B); // Lighter variant (same as surface)
  static const Color surface = Color(0xFF1E293B);
  static const Color surfaceDark = Color(0xFF151F31); // Darker surface
  static const Color surfaceElevated = Color(0xFF263449);
  
  // Camera/Module 4 colors
  static const Color richBlack = Color(0xFF0F172A); // Same as background
  static const Color charcoal = Color(0xFF1E293B); // Same as surface
  static const Color platinum = Color(0xFFF8FAFC); // Same as textPrimary

  // Text
  static const Color textPrimary = Color(0xFFF8FAFC);
  static const Color textSecondary = Color(0xFF94A3B8);

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [electricBlue, violet],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient successGradient = LinearGradient(
    colors: [emerald, electricBlue],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static LinearGradient glassGradient = LinearGradient(
    colors: [
      Colors.white.withOpacity(0.08),
      Colors.white.withOpacity(0.02),
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
