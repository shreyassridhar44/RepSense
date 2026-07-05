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

  // Background / Surface
  static const Color background = Color(0xFF0F172A); // Dark Graphite
  static const Color surface = Color(0xFF1E293B);
  static const Color surfaceElevated = Color(0xFF263449);

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
