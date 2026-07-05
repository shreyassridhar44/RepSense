import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../shared/widgets/glass_card.dart';

class _Exercise {
  final String id;
  final String name;
  final String muscles;
  final String difficulty;
  final IconData icon;
  const _Exercise(this.id, this.name, this.muscles, this.difficulty, this.icon);
}

const _exercises = [
  _Exercise('squat', 'Squat', 'Quads · Glutes', 'Beginner', Icons.accessibility_new_rounded),
  _Exercise('deadlift', 'Deadlift', 'Hamstrings · Back', 'Advanced', Icons.fitness_center_rounded),
  _Exercise('bench_press', 'Bench Press', 'Chest · Triceps', 'Intermediate', Icons.airline_seat_flat_rounded),
  _Exercise('push_up', 'Push-up', 'Chest · Core', 'Beginner', Icons.self_improvement_rounded),
  _Exercise('pull_up', 'Pull-up', 'Back · Biceps', 'Advanced', Icons.upgrade_rounded),
  _Exercise('overhead_press', 'Overhead Press', 'Shoulders', 'Intermediate', Icons.arrow_upward_rounded),
  _Exercise('lunges', 'Lunges', 'Quads · Glutes', 'Beginner', Icons.directions_walk_rounded),
  _Exercise('bicep_curl', 'Bicep Curl', 'Biceps', 'Beginner', Icons.sports_gymnastics_rounded),
];

class WorkoutSelectionPage extends StatelessWidget {
  const WorkoutSelectionPage({super.key, this.embedded = false});
  final bool embedded;

  @override
  Widget build(BuildContext context) {
    final content = SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Choose Exercise', style: Theme.of(context).textTheme.headlineLarge),
            const SizedBox(height: 4),
            Text('Select a movement to begin AI-guided analysis.',
                style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 16),
            TextField(decoration: InputDecoration(
              hintText: 'Search exercises',
              prefixIcon: const Icon(Icons.search_rounded, color: AppColors.textSecondary),
            )),
            const SizedBox(height: 16),
            Expanded(
              child: GridView.builder(
                physics: const BouncingScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 14,
                  crossAxisSpacing: 14,
                  childAspectRatio: 0.85,
                ),
                itemCount: _exercises.length,
                itemBuilder: (context, i) {
                  final e = _exercises[i];
                  return GlassCard(
                    onTap: () => context.push('/exercise/${e.id}'),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            gradient: AppColors.primaryGradient,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(e.icon, color: Colors.white, size: 22),
                        ),
                        const Spacer(),
                        Text(e.name, style: Theme.of(context).textTheme.titleMedium),
                        const SizedBox(height: 4),
                        Text(e.muscles, style: Theme.of(context).textTheme.bodyMedium),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.electricBlue.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(e.difficulty,
                              style: const TextStyle(fontSize: 10, color: AppColors.electricBlue)),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );

    if (embedded) return content;
    return Scaffold(backgroundColor: AppColors.background, body: content);
  }
}
