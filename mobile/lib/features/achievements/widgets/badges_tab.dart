import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/achievements.dart';
import '../../../core/providers/providers.dart';
import '../../../core/theme/app_theme.dart';

/// Badges tab showing all available badges
class BadgesTab extends ConsumerWidget {
  final String userId;

  const BadgesTab({super.key, required this.userId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(achievementsNotifierProvider(userId));
    final earnedKeys = state.achievements.map((a) => a.badgeKey).toSet();

    return RefreshIndicator(
      onRefresh: () async {
        await ref.read(achievementsNotifierProvider(userId).notifier).refresh();
      },
      child: GridView.builder(
        padding: const EdgeInsets.all(20),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 0.85,
        ),
        itemCount: AchievementConstants.badges.length,
        itemBuilder: (context, index) {
          final entry = AchievementConstants.badges.entries.elementAt(index);
          final badgeKey = entry.key;
          final isEarned = earnedKeys.contains(badgeKey);

          return _BadgeCard(
            badgeKey: badgeKey,
            isEarned: isEarned,
          );
        },
      ),
    );
  }
}

class _BadgeCard extends StatelessWidget {
  final String badgeKey;
  final bool isEarned;

  const _BadgeCard({
    required this.badgeKey,
    required this.isEarned,
  });

  @override
  Widget build(BuildContext context) {
    final icon = AchievementConstants.getIcon(badgeKey);
    final label = AchievementConstants.getLabel(badgeKey);
    final description = AchievementConstants.getDescription(badgeKey);
    final tier = AchievementConstants.getTier(badgeKey);
    final tierColor = AchievementConstants.getTierColor(tier);

    return Container(
      decoration: BoxDecoration(
        color: isEarned ? AppTheme.surfaceDark : AppTheme.surfaceDark.withOpacity(0.3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isEarned ? tierColor.withOpacity(0.5) : Colors.white.withOpacity(0.1),
          width: 2,
        ),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Badge icon
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: isEarned
                  ? LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [tierColor, tierColor.withOpacity(0.6)],
                    )
                  : null,
              color: isEarned ? null : Colors.white.withOpacity(0.1),
              boxShadow: isEarned
                  ? [
                      BoxShadow(
                        color: tierColor.withOpacity(0.3),
                        blurRadius: 12,
                        spreadRadius: 2,
                      ),
                    ]
                  : null,
            ),
            child: Icon(
              icon,
              color: isEarned ? Colors.white : Colors.white.withOpacity(0.3),
              size: 32,
            ),
          ),
          const SizedBox(height: 12),

          // Badge label
          Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: isEarned ? Colors.white : Colors.white.withOpacity(0.4),
              fontFamily: 'PlusJakartaSans',
            ),
          ),
          const SizedBox(height: 4),

          // Description
          Text(
            description,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: isEarned ? Colors.white.withOpacity(0.6) : Colors.white.withOpacity(0.3),
              fontFamily: 'Manrope',
            ),
          ),

          // Locked indicator
          if (!isEarned) ...[
            const SizedBox(height: 8),
            Icon(
              Icons.lock_outline_rounded,
              size: 16,
              color: Colors.white.withOpacity(0.3),
            ),
          ],
        ],
      ),
    );
  }
}
