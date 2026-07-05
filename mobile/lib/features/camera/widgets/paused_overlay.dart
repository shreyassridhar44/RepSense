import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

class PausedOverlay extends StatelessWidget {
  final VoidCallback onResume;

  const PausedOverlay({
    super.key,
    required this.onResume,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppTheme.richBlack.withOpacity(0.8),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.pause_circle_outline,
              size: 80,
              color: Colors.amber,
            ),
            const SizedBox(height: 24),
            const Text(
              'PAUSED',
              style: TextStyle(
                color: AppTheme.platinum,
                fontSize: 32,
                fontWeight: FontWeight.bold,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Take a breath. Resume when ready.',
              style: TextStyle(
                color: AppTheme.platinum,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: onResume,
              icon: const Icon(Icons.play_arrow),
              label: const Text('Resume'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.emerald,
                padding:
                    const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
