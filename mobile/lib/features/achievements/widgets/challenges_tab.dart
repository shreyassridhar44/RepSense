import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/providers.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/glass_card.dart';
import '../../../data/services/daily_challenge_service.dart';

/// Challenges tab showing daily challenges
class ChallengesTab extends ConsumerWidget {
  final String userId;

  const ChallengesTab({super.key, required this.userId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(achievementsNotifierProvider(userId));

    return RefreshIndicator(
      onRefresh: () async {
        await ref.read(achievementsNotifierProvider(userId).notifier).refreshChallenge();
      },
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Today's challenge
          if (state.hasTodaysChallenge)
            _DailyChallengeCard(challenge: state.todaysChallenge!),

          if (!state.hasTodaysChallenge)
            GlassCard(
              child: Column(
                children: [
                  Icon(
                    Icons.assignment_rounded,
                    size: 48,
                    color: Colors.white.withOpacity(0.3),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No challenge available',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white.withOpacity(0.6),
                      fontFamily: 'Manrope',
                    ),
                  ),
                ],
              ),
            ),

          const SizedBox(height: 24),

          // Stats
          _buildStatsRow(state),

          const SizedBox(height: 24),

          // History header
          const Text(
            'Challenge History',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Colors.white,
              fontFamily: 'PlusJakartaSans',
            ),
          ),
          const SizedBox(height: 16),

          // Challenge history
          if (state.challengeHistory.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Text(
                  'No challenge history yet',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withOpacity(0.5),
                    fontFamily: 'Manrope',
                  ),
                ),
              ),
            ),

          ...state.challengeHistory.map(
            (challenge) => _ChallengeHistoryTile(challenge: challenge),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRow(dynamic state) {
    return Row(
      children: [
        Expanded(
          child: GlassCard(
            child: Column(
              children: [
                const Icon(Icons.check_circle_rounded, color: AppTheme.emerald, size: 32),
                const SizedBox(height: 8),
                Text(
                  '${state.completedChallengesCount}',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    fontFamily: 'PlusJakartaSans',
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Completed',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: Colors.white.withOpacity(0.6),
                    fontFamily: 'Manrope',
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: GlassCard(
            child: Column(
              children: [
                const Icon(Icons.trending_up_rounded, color: AppTheme.electricBlue, size: 32),
                const SizedBox(height: 8),
                Text(
                  '${(state.stats.challengeCompletionRate * 100).toInt()}%',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    fontFamily: 'PlusJakartaSans',
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Success Rate',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: Colors.white.withOpacity(0.6),
                    fontFamily: 'Manrope',
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _DailyChallengeCard extends StatelessWidget {
  final DailyChallenge challenge;

  const _DailyChallengeCard({required this.challenge});

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: AppTheme.primaryGradient,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.assignment_rounded,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      challenge.title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        fontFamily: 'PlusJakartaSans',
                      ),
                    ),
                    Text(
                      challenge.description,
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
              if (challenge.isCompleted)
                const Icon(Icons.check_circle, color: AppTheme.emerald, size: 32),
            ],
          ),
          const SizedBox(height: 16),

          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: challenge.progress,
              minHeight: 12,
              backgroundColor: Colors.white.withOpacity(0.1),
              valueColor: const AlwaysStoppedAnimation(AppTheme.electricBlue),
            ),
          ),
          const SizedBox(height: 8),

          // Progress text
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${challenge.currentValue} / ${challenge.targetValue}',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.white.withOpacity(0.8),
                  fontFamily: 'Manrope',
                ),
              ),
              Row(
                children: [
                  const Icon(Icons.stars_rounded, color: AppTheme.amber, size: 16),
                  const SizedBox(width: 4),
                  Text(
                    '+${challenge.xpReward} XP',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.amber,
                      fontFamily: 'Manrope',
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ChallengeHistoryTile extends StatelessWidget {
  final DailyChallenge challenge;

  const _ChallengeHistoryTile({required this.challenge});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark.withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: challenge.isCompleted
              ? AppTheme.emerald.withOpacity(0.3)
              : Colors.white.withOpacity(0.1),
        ),
      ),
      child: Row(
        children: [
          Icon(
            challenge.isCompleted ? Icons.check_circle : Icons.cancel,
            color: challenge.isCompleted ? AppTheme.emerald : Colors.white.withOpacity(0.3),
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  challenge.title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                    fontFamily: 'Manrope',
                  ),
                ),
                Text(
                  _formatDate(challenge.challengeDate),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Colors.white.withOpacity(0.5),
                    fontFamily: 'Manrope',
                  ),
                ),
              ],
            ),
          ),
          Text(
            '${challenge.currentValue}/${challenge.targetValue}',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.white.withOpacity(0.6),
              fontFamily: 'Manrope',
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date).inDays;

    if (diff == 0) return 'Today';
    if (diff == 1) return 'Yesterday';
    if (diff < 7) return '$diff days ago';

    return '${date.month}/${date.day}';
  }
}
