import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/achievements.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/glass_card.dart';
import '../models/achievement.dart';

class AchievementCard extends StatelessWidget {
  const AchievementCard({
    super.key,
    required this.achievement,
  });

  final Achievement achievement;

  @override
  Widget build(BuildContext context) {
    final icon = AchievementConstants.getIcon(achievement.badgeKey);
    final relativeDate = _getRelativeDate(achievement.unlockedAt);

    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: SizedBox(
        width: 140,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Badge icon
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.electricBlue.withOpacity(0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Icon(
                icon,
                color: Colors.white,
                size: 28,
              ),
            ),
            
            const SizedBox(height: 12),
            
            // Badge name
            Text(
              achievement.label,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            
            const SizedBox(height: 4),
            
            // Unlocked date
            Text(
              'Unlocked $relativeDate',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontSize: 12,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  String _getRelativeDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        return 'just now';
      }
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return DateFormat('MMM d').format(date);
    }
  }
}
