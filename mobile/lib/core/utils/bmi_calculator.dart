import 'package:flutter/material.dart';

enum BmiCategory {
  underweight,
  healthy,
  overweight,
  obese;

  String get label {
    switch (this) {
      case BmiCategory.underweight:
        return 'Underweight';
      case BmiCategory.healthy:
        return 'Healthy Weight';
      case BmiCategory.overweight:
        return 'Overweight';
      case BmiCategory.obese:
        return 'Obese';
    }
  }

  Color get color {
    switch (this) {
      case BmiCategory.underweight:
        return const Color(0xFFF59E0B); // Amber
      case BmiCategory.healthy:
        return const Color(0xFF10B981); // Emerald
      case BmiCategory.overweight:
        return const Color(0xFFF59E0B); // Amber
      case BmiCategory.obese:
        return const Color(0xFFEF4444); // Red
    }
  }
}

/// Pure utility class for BMI calculations
class BmiCalculator {
  BmiCalculator._();

  /// Calculate BMI from height (cm) and weight (kg)
  /// Formula: weight(kg) / (height(m))^2
  static double? calculate({required double? heightCm, required double? weightKg}) {
    if (heightCm == null || weightKg == null) return null;
    if (heightCm <= 0 || weightKg <= 0) return null;

    final heightM = heightCm / 100;
    return weightKg / (heightM * heightM);
  }

  /// Get BMI category
  static BmiCategory? getCategory(double? bmi) {
    if (bmi == null) return null;

    if (bmi < 18.5) return BmiCategory.underweight;
    if (bmi < 25.0) return BmiCategory.healthy;
    if (bmi < 30.0) return BmiCategory.overweight;
    return BmiCategory.obese;
  }

  /// Format BMI for display
  static String format(double? bmi) {
    if (bmi == null) return '--';
    return bmi.toStringAsFixed(1);
  }

  static const String disclaimer =
      'BMI is a general indicator only and does not account for muscle mass.';
}
