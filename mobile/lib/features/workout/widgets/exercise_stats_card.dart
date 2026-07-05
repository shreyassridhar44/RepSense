import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../domain/entities/exercise_personal_stats.dart';
import '../../../shared/widgets/glass_card.dart';

class ExerciseStatsCard extends StatelessWidget {
  const ExerciseStatsCard({
    super.key,
    required this.stats,
  });

  final ExercisePersonalStats stats;

  @override
  Widget build(BuildContext context) {
    if (!stats.hasData) {
      return GlassCard(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Icon(
              Icons.insights_outlined,
              size: 48,
              color: AppColors.textSecondary,
            ),
            const SizedBox(height: 16),
            Text(
              'You haven\'t performed this exercise yet.',
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Tap Start Analysis to begin.',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    final bestScoreColor = _getFormScoreColor(stats.bestFormScore);
    final lastPerformedText = _getRelativeDate(stats.lastPerformed);

    return GlassCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Your Stats',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 20),
          
          // 2x2 grid of stats
          Row(
            children: [
              Expanded(
                child: _StatItem(
                  label: 'Total Sessions',
                  value: stats.totalSessions.toString(),
                  icon: Icons.calendar_today,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _StatItem(
                  label: 'Total Reps',
                  value: stats.totalReps.toString(),
                  icon: Icons.fitness_center,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 12),
          
          Row(
            children: [
              Expanded(
                child: _StatItemWithColor(
                  label: 'Best Form Score',
                  value: '${stats.bestFormScore.toInt()}%',
                  color: bestScoreColor,
                  icon: Icons.stars,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _StatItem(
                  label: 'Last Performed',
                  value: lastPerformedText,
                  icon: Icons.schedule,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 20),
          
          // Improvement trend
          _buildTrendIndicator(context, stats),
        ],
      ),
    );
  }

  Widget _buildTrendIndicator(BuildContext context, ExercisePersonalStats stats) {
    String icon;
    String text;
    Color color;

    switch (stats.trendDescription) {
      case 'improving':
        icon = '📈';
        text = 'Improving — your form score is trending up';
        color = AppColors.emerald;
        break;
      case 'declining':
        icon = '📉';
        text = 'Needs attention — focus on form next session';
        color = AppColors.amber;
        break;
      default:
        icon = '📊';
        text = 'Keep training to see your trend';
        color = AppColors.textSecondary;
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          Text(icon, style: const TextStyle(fontSize: 20)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: color,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getFormScoreColor(double score) {
    if (score >= 85) return AppColors.emerald;
    if (score >= 60) return AppColors.amber;
    return AppColors.error;
  }

  String _getRelativeDate(DateTime? date) {
    if (date == null) return '—';
    
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final targetDate = DateTime(date.year, date.month, date.day);
    final difference = today.difference(targetDate).inDays;

    if (difference == 0) return 'Today';
    if (difference == 1) return 'Yesterday';
    if (difference < 7) return '$difference days ago';
    return DateFormat('MMM d').format(date);
  }
}

class _StatItem extends StatelessWidget {
  const _StatItem({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated.withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: AppColors.electricBlue),
          const SizedBox(height: 8),
          Text(
            value,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatItemWithColor extends StatelessWidget {
  const _StatItemWithColor({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
  });

  final String label;
  final String value;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(height: 8),
          Text(
            value,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
