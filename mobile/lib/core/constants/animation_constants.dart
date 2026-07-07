import 'package:flutter/animation.dart';

/// Standard animation durations and curves for app-wide consistency
class AnimDuration {
  AnimDuration._();

  /// Micro duration for press feedback, icon changes
  static const micro = Duration(milliseconds: 100);

  /// Short duration for card presses, chip selections
  static const short = Duration(milliseconds: 200);

  /// Medium duration for page transitions, modals
  static const medium = Duration(milliseconds: 300);

  /// Long duration for chart animations, score reveals
  static const long = Duration(milliseconds: 500);

  /// Extra long duration for onboarding, achievement unlocks
  static const xlong = Duration(milliseconds: 800);
}

/// Standard animation curves for app-wide consistency
class AnimCurve {
  AnimCurve._();

  /// Standard curve for general animations
  static const standard = Curves.easeInOut;

  /// Decelerate curve for things entering the screen
  static const decelerate = Curves.easeOutCubic;

  /// Accelerate curve for things leaving the screen
  static const accelerate = Curves.easeInCubic;

  /// Spring curve for achievement pops, badge reveals
  static const spring = Curves.elasticOut;

  /// Overshoot curve for rep counter pulse
  static const overshoot = Curves.easeOutBack;
}
