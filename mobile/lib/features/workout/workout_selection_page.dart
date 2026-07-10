import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shimmer/shimmer.dart';
import '../../core/theme/app_colors.dart';
import 'widgets/exercise_card.dart';
import 'widgets/filter_chip_row.dart';
import 'workout_notifier.dart';
import 'workout_state.dart';

final workoutProvider = StateNotifierProvider<WorkoutNotifier, WorkoutState>((ref) {
  return WorkoutNotifier();
});

class WorkoutSelectionPage extends ConsumerStatefulWidget {
  final bool embedded;
  const WorkoutSelectionPage({super.key, this.embedded = false});

  @override
  ConsumerState<WorkoutSelectionPage> createState() => _WorkoutSelectionPageState();
}

class _WorkoutSelectionPageState extends ConsumerState<WorkoutSelectionPage> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(workoutProvider.notifier).load());
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(workoutProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Exercises'),
        actions: [
          IconButton(
            icon: const Icon(Icons.sort),
            onPressed: () => _showSortBottomSheet(context),
          ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () => ref.read(workoutProvider.notifier).refresh(),
          color: AppColors.electricBlue,
          child: _buildBody(context, state),
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context, WorkoutState state) {
    switch (state.status) {
      case WorkoutStatus.loading:
        return _buildLoadingSkeleton();
      case WorkoutStatus.error:
        return _buildErrorState(context, state);
      case WorkoutStatus.loaded:
      case WorkoutStatus.searching:
        return _buildLoadedState(context, state);
    }
  }

  Widget _buildLoadingSkeleton() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          // Search bar skeleton
          Shimmer.fromColors(
            baseColor: AppColors.surface,
            highlightColor: AppColors.surfaceElevated,
            child: Container(
              height: 56,
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Filter chips skeleton
          Shimmer.fromColors(
            baseColor: AppColors.surface,
            highlightColor: AppColors.surfaceElevated,
            child: Container(
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Grid skeleton
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 0.82,
            ),
            itemCount: 6,
            itemBuilder: (context, index) {
              return Shimmer.fromColors(
                baseColor: AppColors.surface,
                highlightColor: AppColors.surfaceElevated,
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, WorkoutState state) {
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
              'Couldn\'t load exercises',
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
            ElevatedButton.icon(
              onPressed: () => ref.read(workoutProvider.notifier).load(),
              icon: const Icon(Icons.refresh),
              label: const Text('Try Again'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.electricBlue,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadedState(BuildContext context, WorkoutState state) {
    if (state.allExercises.isEmpty) {
      return _buildEmptyExercisesState(context);
    }

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Search bar
                TextField(
                  controller: _searchController,
                  autofocus: false,
                  onChanged: (value) {
                    ref.read(workoutProvider.notifier).search(value);
                  },
                  decoration: InputDecoration(
                    hintText: 'Search exercises or muscle groups…',
                    prefixIcon: const Icon(Icons.search, color: AppColors.electricBlue),
                    suffixIcon: state.searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              ref.read(workoutProvider.notifier).search('');
                            },
                          )
                        : null,
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // Filter chips
                FilterChipRow(
                  selectedCategory: state.selectedCategory,
                  selectedDifficulty: state.selectedDifficulty,
                  selectedMuscleGroup: state.selectedMuscleGroup,
                  showFavoritesOnly: state.showFavoritesOnly,
                  hasActiveFilters: state.hasActiveFilters,
                  onCategoryChanged: (category) {
                    ref.read(workoutProvider.notifier).setCategory(category);
                  },
                  onDifficultyChanged: (difficulty) {
                    ref.read(workoutProvider.notifier).setDifficulty(difficulty);
                  },
                  onMuscleGroupChanged: (muscleGroup) {
                    ref.read(workoutProvider.notifier).setMuscleGroup(muscleGroup);
                  },
                  onFavoritesToggled: () {
                    ref.read(workoutProvider.notifier).toggleFavoritesFilter();
                  },
                  onClearFilters: () {
                    _searchController.clear();
                    ref.read(workoutProvider.notifier).clearFilters();
                  },
                ),
                
                const SizedBox(height: 24),
                
                // Results count
                Text(
                  state.hasActiveFilters
                      ? '${state.filteredCount} of ${state.totalCount} exercises'
                      : '${state.totalCount} exercises',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
        ),
        
        // Results area
        if (state.filteredExercises.isEmpty)
          SliverFillRemaining(
            child: _buildEmptyResultsState(context, state),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 0.82,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final exercise = state.filteredExercises[index];
                  return ExerciseCard(
                    exercise: exercise,
                    onTap: () {
                      context.push('/exercise/${exercise.id}');
                    },
                    onFavoriteTap: () {
                      ref.read(workoutProvider.notifier).toggleFavorite(exercise.id);
                    },
                  );
                },
                childCount: state.filteredExercises.length,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildEmptyExercisesState(BuildContext context) {
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
              'No exercises available yet',
              style: Theme.of(context).textTheme.headlineMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'Check back soon.',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () => ref.read(workoutProvider.notifier).refresh(),
              icon: const Icon(Icons.refresh),
              label: const Text('Refresh'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.electricBlue,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyResultsState(BuildContext context, WorkoutState state) {
    if (state.showFavoritesOnly && state.filteredExercises.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.favorite_border,
                size: 64,
                color: AppColors.textSecondary,
              ),
              const SizedBox(height: 24),
              Text(
                'No favorites yet',
                style: Theme.of(context).textTheme.headlineMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                'You haven\'t favorited any exercises yet. Tap the ♥ on any exercise to save it here.',
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 64,
              color: AppColors.textSecondary,
            ),
            const SizedBox(height: 24),
            Text(
              'No exercises found',
              style: Theme.of(context).textTheme.headlineMedium,
              textAlign: TextAlign.center,
            ),
            if (state.searchQuery.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                'for "${state.searchQuery}"',
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
            ],
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () {
                _searchController.clear();
                ref.read(workoutProvider.notifier).clearFilters();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.electricBlue,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              ),
              child: const Text('Clear search'),
            ),
          ],
        ),
      ),
    );
  }

  void _showSortBottomSheet(BuildContext context) {
    final currentSort = ref.read(workoutProvider).sortBy;
    
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Sort by',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 20),
                _SortOption(
                  label: 'A-Z',
                  isSelected: currentSort == 'a-z',
                  onTap: () {
                    ref.read(workoutProvider.notifier).setSortBy('a-z');
                    Navigator.pop(context);
                  },
                ),
                _SortOption(
                  label: 'Z-A',
                  isSelected: currentSort == 'z-a',
                  onTap: () {
                    ref.read(workoutProvider.notifier).setSortBy('z-a');
                    Navigator.pop(context);
                  },
                ),
                _SortOption(
                  label: 'Difficulty (Beginner first)',
                  isSelected: currentSort == 'difficulty',
                  onTap: () {
                    ref.read(workoutProvider.notifier).setSortBy('difficulty');
                    Navigator.pop(context);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _SortOption extends StatelessWidget {
  const _SortOption({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(label),
      trailing: isSelected
          ? const Icon(Icons.check, color: AppColors.electricBlue)
          : null,
      onTap: onTap,
    );
  }
}
