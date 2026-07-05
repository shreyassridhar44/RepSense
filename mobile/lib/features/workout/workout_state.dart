import 'package:equatable/equatable.dart';
import '../../domain/entities/exercise.dart';

enum WorkoutStatus { loading, loaded, error, searching }

class WorkoutState extends Equatable {
  final WorkoutStatus status;
  final String? errorMessage;
  final List<Exercise> allExercises;
  final List<Exercise> filteredExercises;
  final String searchQuery;
  final String? selectedCategory;
  final String? selectedDifficulty;
  final String? selectedMuscleGroup;
  final bool showFavoritesOnly;
  final bool isRefreshing;
  final String sortBy; // 'a-z', 'z-a', 'difficulty', 'most_performed', 'best_score'

  const WorkoutState({
    this.status = WorkoutStatus.loading,
    this.errorMessage,
    this.allExercises = const [],
    this.filteredExercises = const [],
    this.searchQuery = '',
    this.selectedCategory,
    this.selectedDifficulty,
    this.selectedMuscleGroup,
    this.showFavoritesOnly = false,
    this.isRefreshing = false,
    this.sortBy = 'a-z',
  });

  bool get hasActiveFilters =>
      searchQuery.isNotEmpty ||
      selectedCategory != null ||
      selectedDifficulty != null ||
      selectedMuscleGroup != null ||
      showFavoritesOnly;

  int get totalCount => allExercises.length;
  int get filteredCount => filteredExercises.length;

  WorkoutState copyWith({
    WorkoutStatus? status,
    String? errorMessage,
    List<Exercise>? allExercises,
    List<Exercise>? filteredExercises,
    String? searchQuery,
    String? selectedCategory,
    String? selectedDifficulty,
    String? selectedMuscleGroup,
    bool? showFavoritesOnly,
    bool? isRefreshing,
    String? sortBy,
  }) {
    return WorkoutState(
      status: status ?? this.status,
      errorMessage: errorMessage,
      allExercises: allExercises ?? this.allExercises,
      filteredExercises: filteredExercises ?? this.filteredExercises,
      searchQuery: searchQuery ?? this.searchQuery,
      selectedCategory: selectedCategory,
      selectedDifficulty: selectedDifficulty,
      selectedMuscleGroup: selectedMuscleGroup,
      showFavoritesOnly: showFavoritesOnly ?? this.showFavoritesOnly,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      sortBy: sortBy ?? this.sortBy,
    );
  }

  @override
  List<Object?> get props => [
        status,
        errorMessage,
        allExercises,
        filteredExercises,
        searchQuery,
        selectedCategory,
        selectedDifficulty,
        selectedMuscleGroup,
        showFavoritesOnly,
        isRefreshing,
        sortBy,
      ];
}
