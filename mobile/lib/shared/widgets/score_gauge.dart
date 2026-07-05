import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/theme/app_colors.dart';

/// Animated radial gauge — used for Form Quality Score, Joint Alignment,
/// Balance, Range of Motion, etc. on the Exercise Summary screen.
class ScoreGauge extends StatelessWidget {
  const ScoreGauge({
    super.key,
    required this.score, // 0-100
    required this.label,
    this.size = 110,
  });

  final double score;
  final String label;
  final double size;

  Color get _color {
    if (score >= 85) return AppColors.emerald;
    if (score >= 60) return AppColors.amber;
    return AppColors.error;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: size,
          height: size,
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: score / 100),
            duration: const Duration(milliseconds: 900),
            curve: Curves.easeOutCubic,
            builder: (context, value, _) {
              return Stack(
                alignment: Alignment.center,
                children: [
                  CircularProgressIndicator(
                    value: 1,
                    strokeWidth: 8,
                    color: Colors.white.withOpacity(0.06),
                  ),
                  CircularProgressIndicator(
                    value: value,
                    strokeWidth: 8,
                    backgroundColor: Colors.transparent,
                    valueColor: AlwaysStoppedAnimation(_color),
                    strokeCap: StrokeCap.round,
                  ),
                  Text(
                    '${(value * 100).round()}',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              );
            },
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
        ),
      ],
    ).animate().fadeIn(duration: 400.ms);
  }
}
