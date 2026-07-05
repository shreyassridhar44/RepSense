import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/app_logger.dart';
import '../../data/supabase/supabase_service.dart';
import 'widgets/workout_history_tile.dart';

final workoutHistoryProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final service = SupabaseService.instance;
  final user = service.currentUser;
  
  if (user == null) {
    throw Exception('No authenticated user');
  }
  
  AppLogger.info('📊 Fetching workout history');
  return service.getAllWorkoutHistory(user.id);
});

class WorkoutHistoryPage extends ConsumerWidget {
  const WorkoutHistoryPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(workoutHistoryProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Workout History'),
      ),
      body: historyAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.electricBlue),
        ),
        error: (error, stack) => _buildErrorState(context, ref),
        data: (workouts) => _buildHistoryList(context, workouts),
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, WidgetRef ref) {
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
              'Couldn\'t load history',
              style: Theme.of(context).textTheme.headlineMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () {
                final container = ProviderScope.containerOf(context);
                container.invalidate(workoutHistoryProvider);
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Try Again'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.electricBlue,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryList(BuildContext context, List<Map<String, dynamic>> workouts) {
    if (workouts.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.fitness_center_outlined,
                size: 64,
                color: AppColors.textSecondary,
              ),
              const SizedBox(height: 24),
              Text(
                'No workout history yet',
                style: Theme.of(context).textTheme.headlineMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                'Start your first session!',
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    // Group workouts by date category
    final groupedWorkouts = _groupWorkoutsByDate(workouts);

    return RefreshIndicator(
      onRefresh: () async {
        // Trigger a refetch by invalidating the provider
        final container = ProviderScope.containerOf(context);
        container.invalidate(workoutHistoryProvider);
        // Wait for the new data to load
        await container.read(workoutHistoryProvider.future);
      },
      color: AppColors.electricBlue,
      child: ListView.builder(
        padding: const EdgeInsets.all(24),
        itemCount: groupedWorkouts.length,
        itemBuilder: (context, index) {
          final group = groupedWorkouts[index];
          final dateLabel = group['label'] as String;
          final groupWorkouts = group['workouts'] as List<Map<String, dynamic>>;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Date header
              Padding(
                padding: EdgeInsets.only(bottom: 16, top: index == 0 ? 0 : 16),
                child: Text(
                  dateLabel,
                  style: const TextStyle(
                    color: AppColors.electricBlue,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              
              // Workouts in this group
              ...groupWorkouts.map((workout) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: WorkoutHistoryTile(workout: workout),
                );
              }).toList(),
            ],
          );
        },
      ),
    );
  }

  List<Map<String, dynamic>> _groupWorkoutsByDate(List<Map<String, dynamic>> workouts) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final lastWeek = today.subtract(const Duration(days: 7));

    final groups = <String, List<Map<String, dynamic>>>{
      'Today': [],
      'Yesterday': [],
      'This Week': [],
      'Earlier': [],
    };

    for (final workout in workouts) {
      final createdAt = DateTime.parse(workout['created_at'] as String);
      final workoutDate = DateTime(createdAt.year, createdAt.month, createdAt.day);

      if (workoutDate == today) {
        groups['Today']!.add(workout);
      } else if (workoutDate == yesterday) {
        groups['Yesterday']!.add(workout);
      } else if (workoutDate.isAfter(lastWeek)) {
        groups['This Week']!.add(workout);
      } else {
        groups['Earlier']!.add(workout);
      }
    }

    // Convert to list format and remove empty groups
    return groups.entries
        .where((entry) => entry.value.isNotEmpty)
        .map((entry) => {
              'label': entry.key,
              'workouts': entry.value,
            })
        .toList();
  }
}
