import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

class RepQualityStrip extends StatelessWidget {
  final List<bool> repQuality;

  const RepQualityStrip({
    super.key,
    required this.repQuality,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.richBlack.withOpacity(0.7),
        borderRadius: BorderRadius.circular(20),
      ),
      child: repQuality.length <= 10
          ? _buildStripContent()
          : SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: _buildStripContent(),
            ),
    );
  }

  Widget _buildStripContent() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (int i = 0; i < repQuality.length; i++) ...[
          TweenAnimationBuilder<double>(
            duration: const Duration(milliseconds: 300),
            tween: Tween(begin: 0.0, end: 1.0),
            builder: (context, value, child) {
              return Transform.scale(
                scale: value,
                child: Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: repQuality[i] ? AppTheme.emerald : Colors.red,
                    boxShadow: [
                      BoxShadow(
                        color: (repQuality[i] ? AppTheme.emerald : Colors.red)
                            .withOpacity(0.5),
                        blurRadius: 8,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      '${i + 1}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
          if (i < repQuality.length - 1) const SizedBox(width: 8),
        ],
      ],
    );
  }
}
