import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/providers.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/glass_card.dart';

/// Leaderboard tab showing weekly XP rankings
class LeaderboardTab extends ConsumerWidget {
  final String userId;

  const LeaderboardTab({super.key, required this.userId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(achievementsNotifierProvider(userId));

    return RefreshIndicator(
      onRefresh: () async {
        await ref.read(achievementsNotifierProvider(userId).notifier).refreshLeaderboard();
      },
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Header
          GlassCard(
            child: Column(
              children: [
                const Icon(
                  Icons.leaderboard_rounded,
                  size: 48,
                  color: AppTheme.amber,
                ),
                const SizedBox(height: 12),
                const Text(
                  'Weekly Leaderboard',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    fontFamily: 'PlusJakartaSans',
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Top performers this week',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.white.withOpacity(0.6),
                    fontFamily: 'Manrope',
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Your rank
          if (state.userRank > 0) ...[
            GlassCard(
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      gradient: AppTheme.primaryGradient,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Text(
                        '#${state.userRank}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          fontFamily: 'PlusJakartaSans',
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Your Rank',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                            fontFamily: 'Manrope',
                          ),
                        ),
                        Text(
                          '${state.stats.xpThisWeek} XP this week',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Colors.white.withOpacity(0.6),
                            fontFamily: 'Manrope',
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],

          // Top 3 podium
          if (state.leaderboard.length >= 3) ...[
            _buildPodium(state.leaderboard.take(3).toList()),
            const SizedBox(height: 24),
          ],

          // Rest of leaderboard
          if (state.leaderboard.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Text(
                  'No leaderboard data yet',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withOpacity(0.5),
                    fontFamily: 'Manrope',
                  ),
                ),
              ),
            ),

          if (state.leaderboard.length > 3)
            ...state.leaderboard.skip(3).map(
                  (entry) => _LeaderboardRow(entry: entry),
                ),
        ],
      ),
    );
  }

  Widget _buildPodium(List<dynamic> topThree) {
    if (topThree.length < 3) return const SizedBox.shrink();

    final first = topThree[0];
    final second = topThree[1];
    final third = topThree[2];

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        // 2nd place
        Expanded(child: _buildPodiumPlace(second, 2, 100, AppTheme.electricBlue.withOpacity(0.7))),
        const SizedBox(width: 8),
        // 1st place
        Expanded(child: _buildPodiumPlace(first, 1, 130, AppTheme.amber)),
        const SizedBox(width: 8),
        // 3rd place
        Expanded(child: _buildPodiumPlace(third, 3, 80, const Color(0xFFCD7F32))),
      ],
    );
  }

  Widget _buildPodiumPlace(dynamic entry, int rank, double height, Color color) {
    return Column(
      children: [
        // Crown for 1st
        if (rank == 1)
          const Padding(
            padding: EdgeInsets.only(bottom: 8),
            child: Icon(Icons.workspace_premium_rounded, color: AppTheme.amber, size: 32),
          ),

        // Avatar
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [color, color.withOpacity(0.6)],
            ),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.3),
                blurRadius: 12,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Center(
            child: Text(
              entry.displayName[0].toUpperCase(),
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: Colors.white,
                fontFamily: 'PlusJakartaSans',
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),

        // Name
        Text(
          entry.displayName,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Colors.white,
            fontFamily: 'Manrope',
          ),
        ),

        // XP
        Text(
          '${entry.xpThisWeek} XP',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: Colors.white.withOpacity(0.6),
            fontFamily: 'Manrope',
          ),
        ),
        const SizedBox(height: 8),

        // Podium
        Container(
          height: height,
          decoration: BoxDecoration(
            color: color.withOpacity(0.3),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
            border: Border.all(color: color, width: 2),
          ),
          child: Center(
            child: Text(
              '#$rank',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.w900,
                color: color,
                fontFamily: 'PlusJakartaSans',
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _LeaderboardRow extends StatelessWidget {
  final dynamic entry;

  const _LeaderboardRow({required this.entry});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: entry.isCurrentUser
            ? AppTheme.electricBlue.withOpacity(0.1)
            : AppTheme.surfaceDark.withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: entry.isCurrentUser
              ? AppTheme.electricBlue.withOpacity(0.5)
              : Colors.white.withOpacity(0.1),
        ),
      ),
      child: Row(
        children: [
          // Rank
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                '#${entry.rank}',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  fontFamily: 'PlusJakartaSans',
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Avatar
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: AppTheme.primaryGradient,
            ),
            child: Center(
              child: Text(
                entry.displayName[0].toUpperCase(),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  fontFamily: 'PlusJakartaSans',
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Name
          Expanded(
            child: Text(
              entry.displayName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: entry.isCurrentUser ? AppTheme.electricBlue : Colors.white,
                fontFamily: 'Manrope',
              ),
            ),
          ),

          // XP
          Text(
            '${entry.xpThisWeek} XP',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.white.withOpacity(0.6),
              fontFamily: 'Manrope',
            ),
          ),
        ],
      ),
    );
  }
}
