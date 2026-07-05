import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../shared/widgets/glass_card.dart';
import '../../shared/widgets/gradient_button.dart';
import 'exercise_detail_notifier.dart';
import 'exercise_detail_state.dart';
import 'widgets/exercise_stats_card.dart';
import 'widgets/instructions_card.dart';
import 'widgets/mistakes_card.dart';
import 'widgets/related_exercises_card.dart';
import 'workout_selection_page.dart';

final exerciseDetailProvider = StateNotifierProvider.family<
    ExerciseDetailNotifier, ExerciseDetailState, String>(
  (ref, exerciseId) => ExerciseDetailNotifier(exerciseId),
);

class ExerciseDetailPage extends ConsumerStatefulWidget {
  const ExerciseDetailPage({
    super.key,
    required this.exerciseId,
  });

  final String exerciseId;

  @override
  ConsumerState<ExerciseDetailPage> createState() => _ExerciseDetailPageState();
}

class _ExerciseDetailPageState extends ConsumerState<ExerciseDetailPage> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(exerciseDetailProvider(widget.exerciseId).notifier).load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(exerciseDetailProvider(widget.exerciseId));

    return Scaffold(
      backgroundColor: AppColors.background,
      body: _buildBody(context, state),
    );
  }

  Widget _buildBody(BuildContext context, ExerciseDetailState state) {
    switch (state.status) {
      case ExerciseDetailStatus.loading:
        return _buildLoadingState();
      case ExerciseDetailStatus.error:
        return _buildErrorState(context, state);
      case ExerciseDetailStatus.loaded:
        return _buildLoadedState(context, state);
    }
  }

  Widget _buildLoadingState() {
    return const Center(
      child: CircularProgressIndicator(
        color: AppColors.electricBlue,
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, ExerciseDetailState state) {
    return SafeArea(
      child: Center(
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
                'Exercise not found',
                style: Theme.of(context).textTheme.headlineMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                state.errorMessage ?? 'An error occurred',
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: () => context.pop(),
                icon: const Icon(Icons.arrow_back),
                label: const Text('Go Back'),
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
      ),
    );
  }

  Widget _buildLoadedState(BuildContext context, ExerciseDetailState state) {
    if (state.exercise == null) return _buildErrorState(context, state);

    final exercise = state.exercise!;
    final stats = state.stats;
    
    // Get related exercises from workout provider
    final workoutState = ref.watch(workoutProvider);
    final relatedExercises = workoutState.allExercises
        .where((e) =>
            e.id != exercise.id &&
            e.muscleGroups.any((muscle) => exercise.muscleGroups.contains(muscle)))
        .take(4)
        .toList();

    return Stack(
      children: [
        CustomScrollView(
          slivers: [
            // Hero section with gradient
            SliverToBoxAdapter(
              child: Stack(
                children: [
                  Hero(
                    tag: 'exercise_icon_${exercise.id}',
                    child: Container(
                      width: double.infinity,
                      height: 200,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [AppColors.electricBlue, AppColors.violet],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      child: Center(
                        child: Icon(
                          exercise.icon,
                          color: Colors.white,
                          size: 80,
                        ),
                      ),
                    ),
                  ),
                  
                  // Back button
                  Positioned(
                    top: MediaQuery.of(context).padding.top + 8,
                    left: 8,
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => context.pop(),
                    ),
                  ),
                  
                  // Favorite button
                  Positioned(
                    top: MediaQuery.of(context).padding.top + 8,
                    right: 8,
                    child: IconButton(
                      icon: Icon(
                        exercise.isFavorited
                            ? Icons.favorite
                            : Icons.favorite_border,
                        color: exercise.isFavorited ? AppColors.amber : Colors.white,
                      ),
                      onPressed: () {
                        ref
                            .read(exerciseDetailProvider(widget.exerciseId).notifier)
                            .toggleFavorite();
                      },
                    ),
                  ),
                  
                  // Difficulty and equipment pills
                  Positioned(
                    bottom: 16,
                    left: 16,
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.4),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            exercise.difficulty,
                            style: TextStyle(
                              color: exercise.difficultyColor,
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                        ),
                        if (exercise.equipment != null) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.4),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              exercise.equipment!,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            // Content
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 100),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Exercise name and description
                    Text(
                      exercise.name,
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    
                    if (exercise.description != null) ...[
                      const SizedBox(height: 12),
                      Text(
                        exercise.description!,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                    
                    const SizedBox(height: 24),
                    
                    // Muscles worked
                    _buildMusclesSection(context, exercise),
                    
                    const SizedBox(height: 24),
                    
                    // Your stats
                    if (stats != null) ExerciseStatsCard(stats: stats),
                    
                    const SizedBox(height: 24),
                    
                    // Benefits
                    if (exercise.benefits.isNotEmpty)
                      _buildBenefitsSection(context, exercise),
                    
                    const SizedBox(height: 24),
                    
                    // Instructions
                    InstructionsCard(instructions: exercise.instructions),
                    
                    const SizedBox(height: 24),
                    
                    // Common mistakes
                    MistakesCard(mistakes: exercise.commonMistakes),
                    
                    const SizedBox(height: 24),
                    
                    // Related exercises
                    if (relatedExercises.isNotEmpty)
                      RelatedExercisesCard(relatedExercises: relatedExercises),
                  ],
                ),
              ),
            ),
          ],
        ),
        
        // Start Analysis button (pinned at bottom)
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: Container(
            padding: EdgeInsets.fromLTRB(
              24,
              16,
              24,
              MediaQuery.of(context).padding.bottom + 16,
            ),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  AppColors.background.withOpacity(0),
                  AppColors.background.withOpacity(0.9),
                  AppColors.background,
                ],
              ),
            ),
            child: GradientButton(
              label: 'Start Analysis',
              onPressed: () {
                // TODO: Navigate to camera page in Module 4
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Camera analysis coming in Module 4'),
                  ),
                );
              },
              icon: Icons.play_arrow_rounded,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMusclesSection(BuildContext context, exercise) {
    return GlassCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Muscles Worked',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          
          // Primary muscle
          if (exercise.primaryMuscle != null)
            Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: AppColors.emerald,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '${exercise.primaryMuscle} ',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                Text(
                  '(Primary)',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.emerald,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          
          if (exercise.primaryMuscle != null && exercise.secondaryMuscles.isNotEmpty)
            const SizedBox(height: 12),
          
          // Secondary muscles
          if (exercise.secondaryMuscles.isNotEmpty)
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: exercise.secondaryMuscles.map<Widget>((muscle) {
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.textSecondary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: AppColors.textSecondary.withOpacity(0.3),
                    ),
                  ),
                  child: Text(
                    muscle,
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }

  Widget _buildBenefitsSection(BuildContext context, exercise) {
    return GlassCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Benefits',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          
          ...exercise.benefits.map<Widget>((benefit) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.check_circle,
                    color: AppColors.emerald,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      benefit,
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }
}
