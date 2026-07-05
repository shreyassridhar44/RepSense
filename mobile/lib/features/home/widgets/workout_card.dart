import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/glass_card.dart';
import '../models/workout_summary.dart';

class WorkoutCard extends StatelessWidget {
  const WorkoutCard({
    super.key,
    required this.workout,
    this.onTap,
  });

  final WorkoutSummary workout;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final formScoreColor = _getFormScoreColor(workout.avgFormScore);
    final relativeDate = _getRelativeDate(workout.createdAt);
    final duration = _formatDuration(workout.durationSeconds);

    return GlassCard(
      onTap: onTap,
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          // Exercise icon
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.fitness_center,
              color: Colors.white,
              size: 24,
            ),
          ),
          
          const SizedBox(width: 16),
          
          // Exercise details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  workout.exerciseName,
                  style: Theme.of(context).textTheme.titleMedium,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      relativeDate,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '•',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${workout.totalReps} reps',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '•',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      duration,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          const SizedBox(width: 12),
          
          // Form score badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: formScoreColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: formScoreColor.withOpacity(0.3),
              ),
            ),
            child: Text(
              '${workout.avgFormScore.toInt()}%',
              style: TextStyle(
                color: formScoreColor,
                fontWeight: FontWeight.w600,
                fontSize: 13,
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

  String _getRelativeDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final workoutDate = DateTime(date.year, date.month, date.day);

    if (workoutDate == today) {
      return 'Today';
    } else if (workoutDate == yesterday) {
      return 'Yesterday';
    } else {
      final daysDiff = today.difference(workoutDate).inDays;
      if (daysDiff < 7) {
        return '$daysDiff days ago';
      } else {
        return DateFormat('MMM d').format(date);
      }
    }
  }

  String _formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '${minutes}m ${remainingSeconds}s';
  }
}
