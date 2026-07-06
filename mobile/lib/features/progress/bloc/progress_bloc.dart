import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/auth/auth_bloc.dart';
import '../../../core/exceptions/app_exception.dart';
import '../../../core/utils/app_logger.dart';
import '../../../data/models/progress_models.dart';
import '../../../data/repositories/progress_repository.dart';
import '../services/progress_service.dart';
import 'progress_event.dart';
import 'progress_state.dart';

/// BLoC for managing progress dashboard state
class ProgressBloc extends Bloc<ProgressEvent, ProgressState> {
  final ProgressService _service;
  final ProgressRepository _repository;
  final AuthBloc _authBloc;

  ProgressBloc({
    ProgressService? service,
    ProgressRepository? repository,
    required AuthBloc authBloc,
  })  : _service = service ?? ProgressService(),
        _repository = repository ?? ProgressRepository(),
        _authBloc = authBloc,
        super(const ProgressInitial()) {
    on<LoadProgress>(_onLoadProgress);
    on<RefreshProgress>(_onRefreshProgress);
    on<ChangeTrendPeriod>(_onChangeTrendPeriod);
    on<RequestAiPrediction>(_onRequestAiPrediction);
  }

  Future<void> _onLoadProgress(
    LoadProgress event,
    Emitter<ProgressState> emit,
  ) async {
    try {
      emit(const ProgressLoading());

      final userId = _getUserId();
      if (userId == null) {
        emit(const ProgressError('User not authenticated'));
        return;
      }

      AppLogger.info('📊 Loading progress data for user: $userId');

      // Load all data in parallel
      final results = await Future.wait([
        _service.computeSnapshot(userId),
        _service.getFormScoreTrend(userId, TrendPeriod.month),
        _service.getCalorieTrend(userId, TrendPeriod.month),
        _service.getRepVolumeTrend(userId, TrendPeriod.month),
        _service.getPersonalRecords(userId),
        _service.getConsistencyHeatmap(userId),
        _service.getMuscleBalance(userId),
      ]);

      final snapshot = results[0] as ProgressSnapshot;
      final formTrend = results[1] as List<FormScoreTrend>;
      final calorieTrend = results[2] as List<CalorieTrend>;
      final repVolumeTrend = results[3] as List<RepVolumeTrend>;
      final personalRecords = results[4] as List<PersonalRecord>;
      final consistencyHeatmap = results[5] as List<ConsistencyDay>;
      final muscleBalance = results[6] as List<MuscleBalancePoint>;

      AppLogger.info('✅ Progress data loaded successfully');

      emit(ProgressLoaded(
        snapshot: snapshot,
        formTrend: formTrend,
        calorieTrend: calorieTrend,
        repVolumeTrend: repVolumeTrend,
        personalRecords: personalRecords,
        consistencyHeatmap: consistencyHeatmap,
        muscleBalance: muscleBalance,
      ));
    } on AppException catch (e) {
      AppLogger.error('❌ Failed to load progress', e);
      emit(ProgressError(e.userMessage));
    } catch (e, stack) {
      AppLogger.error('❌ Unexpected error loading progress', e, stack);
      emit(const ProgressError('Failed to load progress data'));
    }
  }

  Future<void> _onRefreshProgress(
    RefreshProgress event,
    Emitter<ProgressState> emit,
  ) async {
    try {
      final userId = _getUserId();
      if (userId == null) {
        emit(const ProgressError('User not authenticated'));
        return;
      }

      AppLogger.info('🔄 Refreshing progress data');

      // Clear cache
      _repository.clearCache();

      // Reload data
      add(const LoadProgress());
    } catch (e, stack) {
      AppLogger.error('❌ Failed to refresh progress', e, stack);
      emit(const ProgressError('Failed to refresh progress data'));
    }
  }

  Future<void> _onChangeTrendPeriod(
    ChangeTrendPeriod event,
    Emitter<ProgressState> emit,
  ) async {
    if (state is! ProgressLoaded) return;

    try {
      final currentState = state as ProgressLoaded;
      final userId = _getUserId();
      if (userId == null) return;

      AppLogger.info('📅 Changing trend period to: ${event.period.label}');

      // Reload trends with new period
      final results = await Future.wait([
        _service.getFormScoreTrend(userId, event.period),
        _service.getCalorieTrend(userId, event.period),
        _service.getRepVolumeTrend(userId, event.period),
      ]);

      final formTrend = results[0] as List<FormScoreTrend>;
      final calorieTrend = results[1] as List<CalorieTrend>;
      final repVolumeTrend = results[2] as List<RepVolumeTrend>;

      emit(currentState.copyWith(
        formTrend: formTrend,
        calorieTrend: calorieTrend,
        repVolumeTrend: repVolumeTrend,
        selectedPeriod: event.period,
      ));
    } catch (e, stack) {
      AppLogger.error('❌ Failed to change trend period', e, stack);
    }
  }

  Future<void> _onRequestAiPrediction(
    RequestAiPrediction event,
    Emitter<ProgressState> emit,
  ) async {
    if (state is! ProgressLoaded) return;

    try {
      final currentState = state as ProgressLoaded;
      final userId = _getUserId();
      if (userId == null) return;

      AppLogger.info('🤖 Requesting AI prediction');

      final prediction = await _service.getAiPrediction(userId);

      emit(currentState.copyWith(aiPrediction: prediction));
    } catch (e, stack) {
      AppLogger.error('❌ Failed to get AI prediction', e, stack);
    }
  }

  String? _getUserId() {
    final authState = _authBloc.state;
    if (authState is AuthAuthenticated) {
      return authState.session.user.id;
    }
    return null;
  }
}
