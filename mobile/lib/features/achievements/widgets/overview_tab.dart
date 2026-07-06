import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/providers.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../data/services/xp_service.dart';

/// Overview tab with stats summary
class OverviewTab extends ConsumerWidget {
  final String userId;

  const OverviewTab({super.key, required this.userId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(achievementsNotifierProvider(userId));

    return RefreshIndicator(
      onRefresh: () async {
        await ref.read(achievementsNotifierProvider(userId).notifier).refresh();
      },
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Level card
          _buildLevelCard(context, state.stats),
          const SizedBox(height: 16),

          // Stats grid
          _buildStatsGrid(context, state),
          const SizedBox(height: 16),

          // Weekly XP progress
          _buildWeeklyXpCard(context, state.stats),
          const SizedBox(height: 16),

          // Recent achievements
          _buildRecentAchievements(context, state),
        ],
      ),
    );
  }

  Widget _buildLevelCard(BuildContext context, dynamic stats) {
    final levelColor = LevelSystem.levelColor(stats.level);

    return GlassCard(
      child: Column(
        children: [
          // Level badge
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [levelColor, levelColor.withOpacity(0.6)],
              ),
              boxShadow: [
                BoxShadow(
                  color: levelColor.withOpacity(0.3),
                  blurRadius: 20,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Center(
              child: Text(
                'L${stats.level}',
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  fontFamily: 'PlusJakartaSans',
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Level title
          Text(
            stats.levelTitle,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: Colors.white,
              fontFamily: 'PlusJakartaSans',
            ),
          ),
          const SizedBox(height: 8),

          // XP progress
          Text(
            '${stats.totalXp} XP',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.white.withOpacity(0.7),
              fontFamily: 'Manrope',
            ),
          ),
          const SizedBox(height: 16),

          // Progress bar
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: stats.progressToNextLevel,
                  minHeight: 12,
                  backgroundColor: Colors.white.withOpacity(0.1),
                  valueColor: AlwaysStoppedAnimation(levelColor),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '${stats.xpToNextLevel} XP to Level ${stats.level + 1}',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: Colors.white.withOpacity(0.6),
                  fontFamily: 'Manrope',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatsGrid(BuildContext context, dynamic state) {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            icon: Icons.emoji_events_rounded,
            label: 'Badges',
            value: '${state.earnedBadgesCount}/${state.totalBadgesCount}',
            color: AppTheme.amber,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            icon: Icons.local_fire_department_rounded,
            label: 'Streak',
            value: '${state.stats.currentStreak}d',
            color: AppTheme.errorRed,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return GlassCard(
      child: Column(
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: Colors.white,
              fontFamily: 'PlusJakartaSans',
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: Colors.white.withOpacity(0.6),
              fontFamily: 'Manrope',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeeklyXpCard(BuildContext context, dynamic stats) {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.calendar_today_rounded, color: AppTheme.electricBlue, size: 20),
              const SizedBox(width: 8),
              const Text(
                'This Week',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                  fontFamily: 'Manrope',
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              const Text(
                'XP Earned:',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.white70,
                  fontFamily: 'Manrope',
                ),
              ),
              const Spacer(),
              Text(
                '${stats.xpThisWeek} XP',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.electricBlue,
                  fontFamily: 'PlusJakartaSans',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRecentAchievements(BuildContext context, dynamic state) {
    if (state.achievements.isEmpty) {
      return const SizedBox.shrink();
    }

    final recent = state.achievements.take(3).toList();

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Recent Achievements',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.white,
              fontFamily: 'Manrope',
            ),
          ),
          const SizedBox(height: 12),
          ...recent.map((achievement) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle, color: AppTheme.emerald, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      achievement.badgeKey.replaceAll('_', ' ').toUpperCase(),
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.white70,
                        fontFamily: 'Manrope',
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }
}
