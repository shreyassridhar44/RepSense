import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/auth/auth_bloc.dart';
import '../../core/theme/app_colors.dart';
import '../../data/models/progress_models.dart';
import '../../shared/widgets/glass_card.dart';
import 'bloc/progress_bloc.dart';
import 'bloc/progress_event.dart';
import 'bloc/progress_state.dart';
import 'widgets/ai_prediction_card.dart';
import 'widgets/consistency_heatmap.dart';
import 'widgets/form_score_chart.dart';
import 'widgets/muscle_balance_radar.dart';
import 'widgets/personal_records_list.dart';
import 'widgets/progress_stats_card.dart';

class ProgressPage extends StatelessWidget {
  const ProgressPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => ProgressBloc(
        authBloc: context.read<AuthBloc>(),
      )..add(const LoadProgress()),
      child: const _ProgressPageContent(),
    );
  }
}

class _ProgressPageContent extends StatelessWidget {
  const _ProgressPageContent();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ProgressBloc, ProgressState>(
      builder: (context, state) {
        return SafeArea(
          child: RefreshIndicator(
            onRefresh: () async {
              context.read<ProgressBloc>().add(const RefreshProgress());
              await Future.delayed(const Duration(seconds: 1));
            },
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
              children: [
                // Header
                Text(
                  'Progress',
                  style: Theme.of(context).textTheme.headlineLarge,
                ),
                const SizedBox(height: 4),
                Text(
                  'Your trends over time.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                ),
                const SizedBox(height: 20),

                // Content based on state
                if (state is ProgressLoading)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(40),
                      child: CircularProgressIndicator(),
                    ),
                  )
                else if (state is ProgressError)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.all(40),
                      child: Column(
                        children: [
                          const Icon(
                            Icons.error_outline,
                            size: 48,
                            color: AppColors.error,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            state.message,
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: AppColors.error),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: () {
                              context.read<ProgressBloc>().add(const LoadProgress());
                            },
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    ),
                  )
                else if (state is ProgressLoaded)
                  _buildLoadedContent(context, state),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildLoadedContent(BuildContext context, ProgressLoaded state) {
    final snapshot = state.snapshot;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Stats Grid
        Row(
          children: [
            Expanded(
              child: ProgressStatsCard(
                label: 'Total Workouts',
                value: '${snapshot.totalWorkouts}',
                icon: Icons.fitness_center,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ProgressStatsCard(
                label: 'Total Reps',
                value: '${snapshot.totalReps}',
                icon: Icons.repeat,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: ProgressStatsCard(
                label: 'Avg Form Score',
                value: '${snapshot.overallAvgFormScore.toStringAsFixed(1)}%',
                icon: Icons.analytics,
                iconColor: _getScoreColor(snapshot.overallAvgFormScore),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ProgressStatsCard(
                label: 'Current Streak',
                value: '${snapshot.currentStreakDays}',
                icon: Icons.local_fire_department,
                iconColor: Colors.orange,
                subtitle: 'days',
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: ProgressStatsCard(
                label: 'Calories Burned',
                value: '${snapshot.totalCalories.toStringAsFixed(0)}',
                icon: Icons.whatshot,
                iconColor: Colors.deepOrange,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ProgressStatsCard(
                label: 'Total Time',
                value: _formatDuration(snapshot.totalDuration),
                icon: Icons.timer,
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),

        // Form Score Trend
        GlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Form Score Trend',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  _buildPeriodSelector(context, state),
                ],
              ),
              const SizedBox(height: 16),
              FormScoreChart(
                trends: state.formTrend,
                period: state.selectedPeriod,
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // AI Prediction
        if (state.aiPrediction != null)
          AiPredictionCard(prediction: state.aiPrediction!)
        else
          GlassCard(
            child: Center(
              child: TextButton.icon(
                onPressed: () {
                  context.read<ProgressBloc>().add(const RequestAiPrediction());
                },
                icon: const Icon(Icons.auto_awesome),
                label: const Text('Get AI Prediction'),
              ),
            ),
          ),
        const SizedBox(height: 24),

        // Personal Records
        Text(
          'Personal Records',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 12),
        PersonalRecordsList(records: state.personalRecords),
        const SizedBox(height: 24),

        // Consistency Heatmap
        GlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Consistency (Last 90 Days)',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 16),
              ConsistencyHeatmap(days: state.consistencyHeatmap),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Muscle Balance
        GlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Muscle Group Balance',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 16),
              MuscleBalanceRadar(points: state.muscleBalance),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPeriodSelector(BuildContext context, ProgressLoaded state) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.backgroundLight,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: TrendPeriod.values.map((period) {
          final isSelected = period == state.selectedPeriod;
          return GestureDetector(
            onTap: () {
              context.read<ProgressBloc>().add(ChangeTrendPeriod(period));
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.electricBlue
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                period.label,
                style: TextStyle(
                  color: isSelected
                      ? AppColors.textPrimary
                      : AppColors.textSecondary,
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Color _getScoreColor(double score) {
    if (score >= 90) return AppColors.success;
    if (score >= 75) return AppColors.electricBlue;
    if (score >= 60) return AppColors.warning;
    return AppColors.error;
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;
    if (hours > 0) {
      return '${hours}h ${minutes}m';
    }
    return '${minutes}m';
  }
}
