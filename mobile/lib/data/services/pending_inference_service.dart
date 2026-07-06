import 'package:hive_flutter/hive_flutter.dart';
import '../../core/utils/app_logger.dart';
import '../repositories/inference_repository.dart';
import '../supabase/supabase_service.dart';

/// Service for managing pending inference jobs (offline mode)
class PendingInferenceService {
  static const String _boxName = 'pending_inference';
  static const int _maxPending = 3;

  static Box<Map>? _box;

  /// Initialize Hive box
  static Future<void> initialize() async {
    try {
      _box = await Hive.openBox<Map>(_boxName);
      AppLogger.info('✅ Pending inference service initialized');
    } catch (e, stack) {
      AppLogger.error('❌ Failed to initialize pending inference service', e, stack);
    }
  }

  /// Save a pending inference job
  Future<void> save(PendingInferenceJob job) async {
    try {
      if (_box == null) {
        AppLogger.warning('⚠️ Pending inference box not initialized');
        return;
      }

      // Get current jobs
      final jobs = await getAll();

      // If at max capacity, remove oldest
      if (jobs.length >= _maxPending) {
        final oldest = jobs.reduce((a, b) => 
          a.createdAt.isBefore(b.createdAt) ? a : b
        );
        await delete(oldest.id);
        AppLogger.info('🗑️ Removed oldest pending inference job');
      }

      // Save job
      await _box!.put(job.id, job.toMap());
      AppLogger.info('💾 Saved pending inference job: ${job.id}');
    } catch (e, stack) {
      AppLogger.error('❌ Failed to save pending inference job', e, stack);
    }
  }

  /// Get all pending jobs
  Future<List<PendingInferenceJob>> getAll() async {
    try {
      if (_box == null) return [];

      final jobs = <PendingInferenceJob>[];
      for (final key in _box!.keys) {
        final map = _box!.get(key) as Map?;
        if (map != null) {
          try {
            jobs.add(PendingInferenceJob.fromMap(Map<String, dynamic>.from(map)));
          } catch (e) {
            AppLogger.warning('⚠️ Failed to parse pending job: $key', e);
          }
        }
      }

      return jobs;
    } catch (e, stack) {
      AppLogger.error('❌ Failed to get pending inference jobs', e, stack);
      return [];
    }
  }

  /// Delete a job
  Future<void> delete(String jobId) async {
    try {
      if (_box == null) return;
      await _box!.delete(jobId);
      AppLogger.info('🗑️ Deleted pending inference job: $jobId');
    } catch (e, stack) {
      AppLogger.error('❌ Failed to delete pending inference job', e, stack);
    }
  }

  /// Process all pending jobs
  Future<void> processAll(InferenceRepository inferenceRepository) async {
    try {
      final jobs = await getAll();
      
      if (jobs.isEmpty) {
        AppLogger.debug('No pending inference jobs to process');
        return;
      }

      AppLogger.info('🔄 Processing ${jobs.length} pending inference jobs');

      for (final job in jobs) {
        try {
          // Run inference
          final result = await inferenceRepository.analyzeAngles(
            exerciseId: job.exerciseId,
            framesAngles: job.angleSequence,
            durationSeconds: job.durationSeconds,
            totalRepsMobile: job.totalRepsMobile,
            repQualityMobile: job.repQualityMobile,
          );

          // Update workout in Supabase
          final supabase = SupabaseService.instance;
          await supabase.client.from('workouts').update({
            'avg_form_score': result.avgScore,
          }).eq('id', job.workoutId);

          // Insert rep analyses
          if (result.reps.isNotEmpty) {
            final repRows = result.reps.map((rep) => {
                  'workout_id': job.workoutId,
                  'rep_index': rep.repIndex,
                  'overall_score': rep.overallScore,
                  'scores': rep.scores.toJson(),
                  'issues': rep.issues.map((i) => i.toJson()).toList(),
                }).toList();

            await supabase.client.from('rep_analyses').insert(repRows);
          }

          // Delete job after successful processing
          await delete(job.id);
          
          AppLogger.info('✅ Processed pending inference job: ${job.id}');

          // TODO: Show local notification
          // await _showNotification(job.exerciseId);
        } catch (e, stack) {
          AppLogger.error('❌ Failed to process pending job: ${job.id}', e, stack);
          // Keep job in queue for retry
        }
      }
    } catch (e, stack) {
      AppLogger.error('❌ Failed to process pending inference jobs', e, stack);
    }
  }

  /// Clear all pending jobs
  Future<void> clearAll() async {
    try {
      if (_box == null) return;
      await _box!.clear();
      AppLogger.info('🗑️ Cleared all pending inference jobs');
    } catch (e, stack) {
      AppLogger.error('❌ Failed to clear pending inference jobs', e, stack);
    }
  }
}

/// Pending inference job model
class PendingInferenceJob {
  final String id;
  final String workoutId;
  final String exerciseId;
  final List<Map<String, double>> angleSequence;
  final int totalRepsMobile;
  final List<bool> repQualityMobile;
  final int durationSeconds;
  final DateTime createdAt;

  const PendingInferenceJob({
    required this.id,
    required this.workoutId,
    required this.exerciseId,
    required this.angleSequence,
    required this.totalRepsMobile,
    required this.repQualityMobile,
    required this.durationSeconds,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'workoutId': workoutId,
      'exerciseId': exerciseId,
      'angleSequence': angleSequence,
      'totalRepsMobile': totalRepsMobile,
      'repQualityMobile': repQualityMobile,
      'durationSeconds': durationSeconds,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory PendingInferenceJob.fromMap(Map<String, dynamic> map) {
    return PendingInferenceJob(
      id: map['id'] as String,
      workoutId: map['workoutId'] as String,
      exerciseId: map['exerciseId'] as String,
      angleSequence: (map['angleSequence'] as List<dynamic>)
          .map((e) => Map<String, double>.from(e as Map))
          .toList(),
      totalRepsMobile: map['totalRepsMobile'] as int,
      repQualityMobile: (map['repQualityMobile'] as List<dynamic>)
          .map((e) => e as bool)
          .toList(),
      durationSeconds: map['durationSeconds'] as int,
      createdAt: DateTime.parse(map['createdAt'] as String),
    );
  }
}
