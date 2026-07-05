import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/glass_card.dart';

class WorkoutHistoryTile extends StatefulWidget {
  const WorkoutHistoryTile({
    super.key,
    required this.workout,
  });

  final Map<String, dynamic> workout;

  @override
  State<WorkoutHistoryTile> createState() => _WorkoutHistoryTileState();
}

class _WorkoutHistoryTileState extends State<WorkoutHistoryTile> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final exerciseName = _getExerciseName();
    final time = _getTime();
    final totalReps = widget.workout['total_reps'] as int? ?? 0;
    final avgFormScore = (widget.workout['avg_form_score'] as num?)?.toDouble() ?? 0.0;
    final duration = _formatDuration(widget.workout['duration_seconds'] as int? ?? 0);
    final formScoreColor = _getFormScoreColor(avgFormScore);

    return GlassCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          // Main content (always visible)
          InkWell(
            onTap: () {
              setState(() {
                _isExpanded = !_isExpanded;
              });
            },
            borderRadius: BorderRadius.circular(20),
            child: Padding(
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
                  
                  // Details
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                exerciseName,
                                style: Theme.of(context).textTheme.titleMedium,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Text(
                              time,
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Text(
                              '$totalReps reps',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                            const SizedBox(width: 8),
                            Text('•', style: Theme.of(context).textTheme.bodyMedium),
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
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: formScoreColor.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: formScoreColor.withOpacity(0.3),
                      ),
                    ),
                    child: Text(
                      '${avgFormScore.toInt()}%',
                      style: TextStyle(
                        color: formScoreColor,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  
                  const SizedBox(width: 8),
                  
                  // Expand icon
                  Icon(
                    _isExpanded ? Icons.expand_less : Icons.expand_more,
                    color: AppColors.textSecondary,
                  ),
                ],
              ),
            ),
          ),
          
          // Expanded details
          if (_isExpanded)
            Container(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                children: [
                  Divider(
                    color: AppColors.textSecondary.withOpacity(0.2),
                    height: 1,
                  ),
                  const SizedBox(height: 16),
                  
                  // Detailed stats
                  Row(
                    children: [
                      Expanded(
                        child: _DetailItem(
                          label: 'Correct Reps',
                          value: '${widget.workout['correct_reps'] ?? 0}',
                          color: AppColors.emerald,
                        ),
                      ),
                      Expanded(
                        child: _DetailItem(
                          label: 'Incorrect Reps',
                          value: '${widget.workout['incorrect_reps'] ?? 0}',
                          color: AppColors.error,
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 12),
                  
                  Row(
                    children: [
                      Expanded(
                        child: _DetailItem(
                          label: 'Calories',
                          value: widget.workout['calories'] != null
                              ? '${(widget.workout['calories'] as num).toInt()} kcal'
                              : '—',
                          color: AppColors.amber,
                        ),
                      ),
                      Expanded(
                        child: _DetailItem(
                          label: 'Duration',
                          value: duration,
                          color: AppColors.electricBlue,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  String _getExerciseName() {
    if (widget.workout['exercises'] != null) {
      final exercise = widget.workout['exercises'] as Map<String, dynamic>;
      return exercise['name'] as String? ?? 'Unknown Exercise';
    }
    return 'Unknown Exercise';
  }

  String _getTime() {
    final createdAt = DateTime.parse(widget.workout['created_at'] as String);
    return DateFormat('h:mm a').format(createdAt);
  }

  String _formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '${minutes}m ${remainingSeconds}s';
  }

  Color _getFormScoreColor(double score) {
    if (score >= 85) return AppColors.emerald;
    if (score >= 60) return AppColors.amber;
    return AppColors.error;
  }
}

class _DetailItem extends StatelessWidget {
  const _DetailItem({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: color,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}
