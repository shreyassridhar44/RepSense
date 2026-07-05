import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

class TopStatusBar extends StatelessWidget {
  final String exerciseName;
  final int fps;
  final bool isLightingGood;
  final bool isDistanceGood;
  final VoidCallback onBack;

  const TopStatusBar({
    super.key,
    required this.exerciseName,
    required this.fps,
    required this.isLightingGood,
    required this.isDistanceGood,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Back button
          IconButton(
            onPressed: onBack,
            icon: const Icon(Icons.arrow_back, color: AppTheme.platinum),
            style: IconButton.styleFrom(
              backgroundColor: AppTheme.richBlack.withOpacity(0.7),
            ),
          ),

          // Exercise name pill
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: AppTheme.richBlack.withOpacity(0.7),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              exerciseName,
              style: const TextStyle(
                color: AppTheme.platinum,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          // Status indicators
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppTheme.richBlack.withOpacity(0.7),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // FPS indicator
                if (fps > 0) ...[
                  Icon(
                    Icons.speed,
                    size: 16,
                    color: fps >= 20
                        ? AppTheme.emerald
                        : fps >= 15
                            ? Colors.amber
                            : Colors.red,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '$fps',
                    style: TextStyle(
                      color: fps >= 20
                          ? AppTheme.emerald
                          : fps >= 15
                              ? Colors.amber
                              : Colors.red,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 8),
                ],

                // Lighting indicator
                Icon(
                  isLightingGood ? Icons.wb_sunny : Icons.wb_cloudy,
                  size: 16,
                  color: isLightingGood ? AppTheme.emerald : Colors.amber,
                ),
                const SizedBox(width: 8),

                // Distance indicator
                Icon(
                  isDistanceGood ? Icons.person : Icons.person_off,
                  size: 16,
                  color: isDistanceGood ? AppTheme.emerald : Colors.amber,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
