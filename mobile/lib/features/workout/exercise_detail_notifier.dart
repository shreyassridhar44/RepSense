import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/utils/app_logger.dart';
import '../../data/repositories/exercise_repository.dart';
import '../../data/supabase/supabase_service.dart';
import '../../domain/entities/exercise.dart';
import '../../domain/entities/exercise_personal_stats.dart';
import 'exercise_detail_state.dart';

class ExerciseDetailNotifier extends StateNotifier<ExerciseDetailState> {
  ExerciseDetailNotifier(this.exerciseId) : super(const ExerciseDetailState());

  final String exerciseId;
  final _repository = ExerciseRepository();
  final _service = SupabaseService.instance;

  Future<void> load() async {
    state = state.copyWith(status: ExerciseDetailStatus.loading);
    AppLogger.info('📊 Loading exercise detail: $exerciseId');

    try {
      final user = _service.currentUser;
      if (user == null) {
        throw Exception('No authenticated user');
      }

      // Fetch exercise and personal stats in parallel
      final results = await Future.wait([
        _repository.getExerciseById(exerciseId, user.id),
        _repository.getPersonalStats(user.id, exerciseId),
      ]);

      final exercise = results[0] as Exercise;
      final stats = results[1] as ExercisePersonalStats;

      state = ExerciseDetailState(
        status: ExerciseDetailStatus.loaded,
        exercise: exercise,
        stats: stats,
      );

      AppLogger.info('✅ Exercise detail loaded: ${exercise.name}');
    } catch (e, stack) {
      AppLogger.error('❌ Failed to load exercise detail', e, stack);
      state = state.copyWith(
        status: ExerciseDetailStatus.error,
        errorMessage: e.toString(),
      );
    }
  }

  Future<void> toggleFavorite() async {
    if (state.exercise == null) return;

    final user = _service.currentUser;
    if (user == null) return;

    final wasFavorited = state.exercise!.isFavorited;

    // Optimistic update
    state = state.copyWith(
      exercise: state.exercise!.copyWith(isFavorited: !wasFavorited),
    );

    try {
      if (wasFavorited) {
        await _repository.removeFavorite(user.id, exerciseId);
      } else {
        await _repository.addFavorite(user.id, exerciseId);
      }
      AppLogger.info('✅ Favorite toggled');
    } catch (e, stack) {
      AppLogger.error('❌ Failed to toggle favorite', e, stack);
      // Rollback
      state = state.copyWith(
        exercise: state.exercise!.copyWith(isFavorited: wasFavorited),
        errorMessage: 'Failed to update favorite',
      );
    }
  }
}
