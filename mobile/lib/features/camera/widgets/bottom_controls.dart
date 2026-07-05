import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

class BottomControls extends StatelessWidget {
  final bool showSkeleton;
  final bool isStreaming;
  final VoidCallback onToggleSkeleton;
  final VoidCallback onPauseResume;
  final VoidCallback onFinish;

  const BottomControls({
    super.key,
    required this.showSkeleton,
    required this.isStreaming,
    required this.onToggleSkeleton,
    required this.onPauseResume,
    required this.onFinish,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // Skeleton toggle
          _buildControlButton(
            icon: showSkeleton ? Icons.visibility : Icons.visibility_off,
            label: 'Skeleton',
            onPressed: onToggleSkeleton,
            color: showSkeleton ? AppTheme.electricBlue : AppTheme.platinum,
          ),

          // Pause/Resume button (larger, center)
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isStreaming ? Colors.amber : AppTheme.emerald,
              boxShadow: [
                BoxShadow(
                  color: (isStreaming ? Colors.amber : AppTheme.emerald)
                      .withOpacity(0.5),
                  blurRadius: 20,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: IconButton(
              onPressed: onPauseResume,
              icon: Icon(
                isStreaming ? Icons.pause : Icons.play_arrow,
                size: 36,
              ),
              color: AppTheme.richBlack,
            ),
          ),

          // Finish button
          _buildControlButton(
            icon: Icons.check,
            label: 'Finish',
            onPressed: onFinish,
            color: AppTheme.emerald,
          ),
        ],
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
    required Color color,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppTheme.richBlack.withOpacity(0.7),
            border: Border.all(color: color, width: 2),
          ),
          child: IconButton(
            onPressed: onPressed,
            icon: Icon(icon, color: color),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: TextStyle(
            color: color,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
