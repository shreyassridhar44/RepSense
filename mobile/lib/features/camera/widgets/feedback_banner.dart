import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../camera_state.dart';

class FeedbackBanner extends StatelessWidget {
  final String message;
  final FeedbackSeverity severity;

  const FeedbackBanner({
    super.key,
    required this.message,
    required this.severity,
  });

  @override
  Widget build(BuildContext context) {
    Color borderColor;
    Color backgroundColor;
    IconData icon;

    switch (severity) {
      case FeedbackSeverity.good:
        borderColor = AppTheme.emerald;
        backgroundColor = AppTheme.emerald.withOpacity(0.15);
        icon = Icons.check_circle_outline;
        break;
      case FeedbackSeverity.warning:
        borderColor = Colors.amber;
        backgroundColor = Colors.amber.withOpacity(0.15);
        icon = Icons.warning_amber_outlined;
        break;
      case FeedbackSeverity.error:
        borderColor = Colors.red;
        backgroundColor = Colors.red.withOpacity(0.15);
        icon = Icons.error_outline;
        break;
    }

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      child: Container(
        key: ValueKey(message),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(12),
          border: Border(
            left: BorderSide(color: borderColor, width: 4),
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: borderColor,
              size: 24,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: TextStyle(
                  color: AppTheme.platinum,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
