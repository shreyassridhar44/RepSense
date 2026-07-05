import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_colors.dart';
import '../../shared/widgets/glass_card.dart';
import '../../shared/widgets/gradient_button.dart';
import '../../shared/widgets/score_gauge.dart';
import 'home_notifier.dart';
import 'home_state.dart';
import 'widgets/achievement_card.dart';
import 'widgets/home_skeleton.dart';
import 'widgets/stats_grid.dart';
import 'widgets/workout_card.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  @override
  void initState() {
    super.initState();
    // Load data on first build
    Future.microtask(() => ref.read(homeProvider.notifier).load());
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(homeProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () => ref.read(homeProvider.notifier).refresh(),
          color: AppColors.electricBlue,
          child: _buildBody(context, state),
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context, HomeState state) {
    switch (state.status) {
      case HomeStatus.loading:
        return const HomeSkeleton();
        
      case HomeStatus.error:
        return _buildErrorState(context, state);
        
      case HomeStatus.loaded:
        return _buildLoadedState(context, state);
    }
  }

  Widget _buildErrorState(BuildContext context, HomeState state) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: AppColors.textSecondary,
            ),
            const SizedBox(height: 24),
            Text(
              'Couldn\'t load your data',
              style: Theme.of(context).textTheme.headlineMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              state.errorMessage?.substring(0, 80) ?? 'An error occurred',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 32),
            GradientButton(
              label: 'Try Again',
              onPressed: () => ref.read(homeProvider.notifier).load(),
              icon: Icons.refresh,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadedState(BuildContext context, HomeState state) {
    final now = DateTime.now();
    final greeting = _getGreeting(now.hour);
    final dateString = DateFormat('EEEE, d MMMM').format(now);
    final weeklyWorkouts = state.recentWorkouts
        .where((w) => w.createdAt.isAfter(now.subtract(const Duration(days: 7))))
        .length;

    return CustomScrollView(
      slivers: [
        // Greeting Header
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '$greeting, ${state.displayName}',
                            style: Theme.of(context).textTheme.headlineMedium,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            dateString,
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppColors.electricBlue,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Avatar
                    GestureDetector(
                      onTap: () => context.push('/profile'),
                      child: Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          gradient: AppColors.primaryGradient,
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            state.displayName.isNotEmpty
                                ? state.displayName[0].toUpperCase()
                                : 'U',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 32),
                
                // Start Training Button
                GradientButton(
                  label: 'Start Training',
                  onPressed: () => context.push('/workouts'),
                  icon: Icons.play_arrow_rounded,
                ),
                
                // Workout Suggestion
                if (state.todayWorkoutSuggestion != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: AppColors.electricBlue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppColors.electricBlue.withOpacity(0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.lightbulb_outline,
                          color: AppColors.electricBlue,
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Suggested: ${state.todayWorkoutSuggestion!.exerciseName} — ${state.todayWorkoutSuggestion!.reason}',
                            style: const TextStyle(
                              color: AppColors.electricBlue,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                
                const SizedBox(height: 32),
                
                // Stats Grid
                StatsGrid(
                  streakDays: state.currentStreakDays,
                  calories: state.totalCaloriesToday,
                  consistency: state.weeklyConsistencyPct,
                  weeklyWorkouts: weeklyWorkouts,
                ),
                
                const SizedBox(height: 32),
                
                // Movement Quality Score
                _buildMovementQualitySection(context, state),
                
                const SizedBox(height: 24),
                
                // Weekly Insight
                _buildWeeklyInsightSection(context, state),
                
                const SizedBox(height: 32),
                
                // Recent Workouts
                _buildRecentWorkoutsSection(context, state),
                
                const SizedBox(height: 32),
                
                // Recent Achievements
                if (state.recentAchievements.isNotEmpty)
                  _buildRecentAchievementsSection(context, state),
                
                const SizedBox(height: 24),
                
                // Last Updated
                if (state.lastUpdated != null)
                  Center(
                    child: Text(
                      'Last updated ${DateFormat('h:mm a').format(state.lastUpdated!)}',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMovementQualitySection(BuildContext context, HomeState state) {
    final hasLimitedData = state.recentWorkouts.length < 3;

    if (state.recentWorkouts.isEmpty) {
      return GlassCard(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const Icon(
              Icons.insights,
              size: 48,
              color: AppColors.textSecondary,
            ),
            const SizedBox(height: 16),
            Text(
              'Complete your first workout to see your scores',
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return GlassCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Movement Quality',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Expanded(
                child: ScoreGauge(
                  score: state.movementQualityScore,
                  label: 'Overall',
                  size: 90,
                ),
              ),
              Expanded(
                child: ScoreGauge(
                  score: state.stabilityScore,
                  label: 'Stability',
                  size: 90,
                ),
              ),
              Expanded(
                child: ScoreGauge(
                  score: state.symmetryScore,
                  label: 'Symmetry',
                  size: 90,
                ),
              ),
            ],
          ),
          if (hasLimitedData) ...[
            const SizedBox(height: 12),
            Text(
              'Based on ${state.recentWorkouts.length} session(s) — train more for accurate data',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    ).animate().fadeIn(duration: 400.ms);
  }

  Widget _buildWeeklyInsightSection(BuildContext context, HomeState state) {
    return GlassCard(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.lightbulb,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              state.weeklyInsight,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 500.ms, delay: 200.ms);
  }

  Widget _buildRecentWorkoutsSection(BuildContext context, HomeState state) {
    if (state.recentWorkouts.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Recent Workouts',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          GlassCard(
            padding: const EdgeInsets.all(32),
            child: Column(
              children: [
                const Icon(
                  Icons.fitness_center_outlined,
                  size: 48,
                  color: AppColors.textSecondary,
                ),
                const SizedBox(height: 16),
                Text(
                  'No workouts yet',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  'Start your first session!',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 20),
                GradientButton(
                  label: 'Start Training',
                  onPressed: () => context.push('/workouts'),
                  icon: Icons.play_arrow_rounded,
                  height: 48,
                ),
              ],
            ),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Recent Workouts',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            TextButton(
              onPressed: () {
                // TODO: Navigate to workout history page
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Workout history coming soon')),
                );
              },
              child: const Text('See all →'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        ...state.recentWorkouts.take(3).map((workout) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: WorkoutCard(workout: workout),
          );
        }).toList(),
      ],
    );
  }

  Widget _buildRecentAchievementsSection(BuildContext context, HomeState state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Achievements',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            TextButton(
              onPressed: () {
                // TODO: Navigate to achievements page
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('All achievements coming soon')),
                );
              },
              child: const Text('See all →'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 160,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: state.recentAchievements.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              return AchievementCard(
                achievement: state.recentAchievements[index],
              );
            },
          ),
        ),
        const SizedBox(height: 32),
      ],
    );
  }

  String _getGreeting(int hour) {
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }
}
