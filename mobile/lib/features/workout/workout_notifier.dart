import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/utils/app_logger.dart';
import '../../data/repositories/exercise_repository.dart';
import '../../data/supabase/supabase_service.dart';
import '../../domain/entities/exercise.dart';
import 'workout_state.dart';

class WorkoutNotifier extends StateNotifier<WorkoutState> {
  WorkoutNotifier() : super(const WorkoutState());

  final _repository = ExerciseRepository();
  final _service = SupabaseService.instance;
  bool _isLoading = false;
  Timer? _debounceTimer;

  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
  }

  Future<void> load() async {
    if (_isLoading) return;
    _isLoading = true;

    state = state.copyWith(status: WorkoutStatus.loading);
    AppLogger.info('🏋️ Loading exercises...');

    try {
      final user = _service.currentUser;
      if (user == null) {
        throw Exception('No authenticated user');
      }

      final exercises = await _repository.getAllExercises(user.id);

      state = WorkoutState(
        status: WorkoutStatus.loaded,
        allExercises: exercises,
        filteredExercises: exercises,
        sortBy: state.sortBy,
      );

      AppLogger.info('✅ Loaded ${exercises.length} exercises');
    } catch (e, stack) {
      AppLogger.error('❌ Failed to load exercises', e, stack);
      state = state.copyWith(
        status: WorkoutStatus.error,
        errorMessage: e.toString(),
      );
    } finally {
      _isLoading = false;
    }
  }

  Future<void> refresh() async {
    if (_isLoading) return;

    state = state.copyWith(isRefreshing: true);
    AppLogger.info('🔄 Refreshing exercises...');

    try {
      final user = _service.currentUser;
      if (user == null) {
        throw Exception('No authenticated user');
      }

      final exercises = await _repository.getAllExercises(user.id);

      state = state.copyWith(
        status: WorkoutStatus.loaded,
        isRefreshing: false,
        allExercises: exercises,
      );

      // Re-apply filters
      _applyFilters();

      AppLogger.info('✅ Refreshed ${exercises.length} exercises');
    } catch (e, stack) {
      AppLogger.error('❌ Failed to refresh exercises', e, stack);
      state = state.copyWith(
        isRefreshing: false,
        errorMessage: e.toString(),
      );
    }
  }

  void search(String query) {
    // Cancel previous timer
    _debounceTimer?.cancel();

    // Set searching status immediately for UI feedback
    state = state.copyWith(
      status: WorkoutStatus.searching,
      searchQuery: query,
    );

    // Debounce: wait 300ms after user stops typing
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      AppLogger.info('🔍 Searching: "$query"');
      _applyFilters();
      state = state.copyWith(status: WorkoutStatus.loaded);
    });
  }

  void setCategory(String? category) {
    AppLogger.info('🏷️ Setting category filter: $category');
    state = state.copyWith(selectedCategory: category);
    _applyFilters();
  }

  void setDifficulty(String? difficulty) {
    AppLogger.info('📊 Setting difficulty filter: $difficulty');
    state = state.copyWith(selectedDifficulty: difficulty);
    _applyFilters();
  }

  void setMuscleGroup(String? muscleGroup) {
    AppLogger.info('💪 Setting muscle group filter: $muscleGroup');
    state = state.copyWith(selectedMuscleGroup: muscleGroup);
    _applyFilters();
  }

  void toggleFavoritesFilter() {
    final newValue = !state.showFavoritesOnly;
    AppLogger.info('⭐ Toggle favorites filter: $newValue');
    state = state.copyWith(showFavoritesOnly: newValue);
    _applyFilters();
  }

  void setSortBy(String sortBy) {
    AppLogger.info('🔄 Setting sort: $sortBy');
    state = state.copyWith(sortBy: sortBy);
    _applyFilters();
  }

  void clearFilters() {
    AppLogger.info('🧹 Clearing all filters');
    state = state.copyWith(
      searchQuery: '',
      selectedCategory: null,
      selectedDifficulty: null,
      selectedMuscleGroup: null,
      showFavoritesOnly: false,
    );
    _applyFilters();
  }

  Future<void> toggleFavorite(String exerciseId) async {
    final user = _service.currentUser;
    if (user == null) return;

    // Find the exercise
    final exerciseIndex = state.allExercises.indexWhere((e) => e.id == exerciseId);
    if (exerciseIndex == -1) return;

    final exercise = state.allExercises[exerciseIndex];
    final wasFavorited = exercise.isFavorited;

    AppLogger.info('⭐ Toggling favorite for: ${exercise.name}');

    // Optimistic update
    final updatedExercise = exercise.copyWith(isFavorited: !wasFavorited);
    final updatedList = List<Exercise>.from(state.allExercises);
    updatedList[exerciseIndex] = updatedExercise;

    state = state.copyWith(allExercises: updatedList);
    _applyFilters();

    // Call repository
    try {
      if (wasFavorited) {
        await _repository.removeFavorite(user.id, exerciseId);
      } else {
        await _repository.addFavorite(user.id, exerciseId);
      }
      AppLogger.info('✅ Favorite toggled successfully');
    } catch (e, stack) {
      AppLogger.error('❌ Failed to toggle favorite', e, stack);

      // Rollback on error
      final rollbackList = List<Exercise>.from(state.allExercises);
      rollbackList[exerciseIndex] = exercise;
      state = state.copyWith(
        allExercises: rollbackList,
        errorMessage: 'Failed to update favorite',
      );
      _applyFilters();
    }
  }

  void _applyFilters() {
    var filtered = List<Exercise>.from(state.allExercises);

    // Search filter
    if (state.searchQuery.isNotEmpty) {
      final query = state.searchQuery.toLowerCase();
      filtered = filtered.where((exercise) {
        final nameMatch = exercise.name.toLowerCase().contains(query);
        final muscleMatch = exercise.muscleGroups
            .any((muscle) => muscle.toLowerCase().contains(query));
        final primaryMatch = exercise.primaryMuscle?.toLowerCase().contains(query) ?? false;
        return nameMatch || muscleMatch || primaryMatch;
      }).toList();
    }

    // Category filter (equipment-based)
    if (state.selectedCategory != null) {
      final category = state.selectedCategory!.toLowerCase();
      if (category == 'bodyweight') {
        filtered = filtered.where((e) => 
          e.equipment?.toLowerCase() == 'bodyweight'
        ).toList();
      } else if (category == 'machine') {
        filtered = filtered.where((e) => 
          e.equipment?.toLowerCase() == 'machine'
        ).toList();
      } else if (category == 'compound') {
        // Compound exercises typically work multiple muscle groups
        filtered = filtered.where((e) => e.muscleGroups.length >= 2).toList();
      } else if (category == 'isolation') {
        // Isolation exercises typically work one muscle group
        filtered = filtered.where((e) => e.muscleGroups.length == 1).toList();
      }
    }

    // Difficulty filter
    if (state.selectedDifficulty != null) {
      filtered = filtered.where((e) =>
        e.difficulty.toLowerCase() == state.selectedDifficulty!.toLowerCase()
      ).toList();
    }

    // Muscle group filter
    if (state.selectedMuscleGroup != null) {
      filtered = filtered.where((e) =>
        e.muscleGroups.any((muscle) =>
          muscle.toLowerCase() == state.selectedMuscleGroup!.toLowerCase()
        )
      ).toList();
    }

    // Favorites filter
    if (state.showFavoritesOnly) {
      filtered = filtered.where((e) => e.isFavorited).toList();
    }

    // Apply sorting
    _sortExercises(filtered);

    state = state.copyWith(filteredExercises: filtered);
  }

  void _sortExercises(List<Exercise> exercises) {
    switch (state.sortBy) {
      case 'a-z':
        exercises.sort((a, b) => a.name.compareTo(b.name));
        break;
      case 'z-a':
        exercises.sort((a, b) => b.name.compareTo(a.name));
        break;
      case 'difficulty':
        final difficultyOrder = {'beginner': 1, 'intermediate': 2, 'advanced': 3};
        exercises.sort((a, b) {
          final aOrder = difficultyOrder[a.difficulty.toLowerCase()] ?? 2;
          final bOrder = difficultyOrder[b.difficulty.toLowerCase()] ?? 2;
          return aOrder.compareTo(bOrder);
        });
        break;
      case 'most_performed':
      case 'best_score':
        // These require workout data - would be implemented with additional state
        // For now, fall back to A-Z
        exercises.sort((a, b) => a.name.compareTo(b.name));
        break;
    }
  }
}
