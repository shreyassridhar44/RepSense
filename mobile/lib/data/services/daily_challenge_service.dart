import 'dart:math';
import '../../core/utils/app_logger.dart';
import '../supabase/supabase_service.dart';

/// Daily challenge model
class DailyChallenge {
  final String id;
  final String userId;
  final String challengeKey;
  final DateTime challengeDate;
  final int targetValue;
  final int currentValue;
  final bool isCompleted;
  final int xpReward;
  final DateTime? completedAt;

  const DailyChallenge({
    required this.id,
    required this.userId,
    required this.challengeKey,
    required this.challengeDate,
    required this.targetValue,
    required this.currentValue,
    required this.isCompleted,
    required this.xpReward,
    this.completedAt,
  });

  factory DailyChallenge.fromJson(Map<String, dynamic> json) {
    return DailyChallenge(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      challengeKey: json['challenge_key'] as String,
      challengeDate: DateTime.parse(json['challenge_date'] as String),
      targetValue: json['target_value'] as int,
      currentValue: json['current_value'] as int? ?? 0,
      isCompleted: json['is_completed'] as bool? ?? false,
      xpReward: json['xp_reward'] as int,
      completedAt: json['completed_at'] != null
          ? DateTime.parse(json['completed_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'challenge_key': challengeKey,
      'challenge_date': challengeDate.toIso8601String().split('T')[0],
      'target_value': targetValue,
      'current_value': currentValue,
      'is_completed': isCompleted,
      'xp_reward': xpReward,
      'completed_at': completedAt?.toIso8601String(),
    };
  }

  DailyChallenge copyWith({
    String? id,
    String? userId,
    String? challengeKey,
    DateTime? challengeDate,
    int? targetValue,
    int? currentValue,
    bool? isCompleted,
    int? xpReward,
    DateTime? completedAt,
  }) {
    return DailyChallenge(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      challengeKey: challengeKey ?? this.challengeKey,
      challengeDate: challengeDate ?? this.challengeDate,
      targetValue: targetValue ?? this.targetValue,
      currentValue: currentValue ?? this.currentValue,
      isCompleted: isCompleted ?? this.isCompleted,
      xpReward: xpReward ?? this.xpReward,
      completedAt: completedAt ?? this.completedAt,
    );
  }

  double get progress => targetValue > 0 ? (currentValue / targetValue).clamp(0.0, 1.0) : 0.0;

  String get title => _getChallengeTitle(challengeKey);
  String get description => _getChallengeDescription(challengeKey, targetValue);

  static String _getChallengeTitle(String key) {
    switch (key) {
      case 'complete_reps':
        return 'Rep Challenge';
      case 'perfect_form':
        return 'Form Master';
      case 'workout_duration':
        return 'Time Challenge';
      case 'high_score':
        return 'Score Hunter';
      case 'variety':
        return 'Exercise Variety';
      default:
        return 'Daily Challenge';
    }
  }

  static String _getChallengeDescription(String key, int target) {
    switch (key) {
      case 'complete_reps':
        return 'Complete $target reps today';
      case 'perfect_form':
        return 'Score $target+ on all reps';
      case 'workout_duration':
        return 'Train for $target minutes';
      case 'high_score':
        return 'Achieve average score of $target+';
      case 'variety':
        return 'Try $target different exercises';
      default:
        return 'Complete daily challenge';
    }
  }
}

/// Service for generating and managing daily challenges
class DailyChallengeService {
  final SupabaseService _supabase;

  DailyChallengeService({SupabaseService? supabase})
      : _supabase = supabase ?? SupabaseService.instance;

  /// Get or generate today's challenge
  Future<DailyChallenge?> getTodaysChallenge(String userId) async {
    try {
      final today = DateTime.now().toIso8601String().split('T')[0];

      // Check if challenge already exists
      final existing = await _supabase.client
          .from('daily_challenges')
          .select()
          .eq('user_id', userId)
          .eq('challenge_date', today)
          .maybeSingle();

      if (existing != null) {
        return DailyChallenge.fromJson(existing);
      }

      // Generate new challenge
      return await _generateChallenge(userId);
    } catch (e, stack) {
      AppLogger.error('Failed to get daily challenge', e, stack);
      return null;
    }
  }

  /// Generate a new daily challenge
  Future<DailyChallenge?> _generateChallenge(String userId) async {
    try {
      final random = Random(DateTime.now().day);
      final challenges = [
        {'key': 'complete_reps', 'target': 50 + random.nextInt(51), 'xp': 150}, // 50-100 reps
        {'key': 'perfect_form', 'target': 90 + random.nextInt(11), 'xp': 200}, // 90-100 score
        {'key': 'workout_duration', 'target': 15 + random.nextInt(16), 'xp': 180}, // 15-30 mins
        {'key': 'high_score', 'target': 85 + random.nextInt(11), 'xp': 175}, // 85-95 avg score
        {'key': 'variety', 'target': 2 + random.nextInt(2), 'xp': 160}, // 2-3 exercises
      ];

      final selected = challenges[random.nextInt(challenges.length)];
      final today = DateTime.now().toIso8601String().split('T')[0];

      final result = await _supabase.client
          .from('daily_challenges')
          .insert({
            'user_id': userId,
            'challenge_key': selected['key'],
            'challenge_date': today,
            'target_value': selected['target'],
            'current_value': 0,
            'is_completed': false,
            'xp_reward': selected['xp'],
          })
          .select()
          .single();

      AppLogger.info('✅ Generated daily challenge: ${selected['key']}');
      return DailyChallenge.fromJson(result);
    } catch (e, stack) {
      AppLogger.error('Failed to generate challenge', e, stack);
      return null;
    }
  }

  /// Update challenge progress
  Future<DailyChallenge?> updateProgress({
    required String userId,
    required Map<String, dynamic> workoutData,
  }) async {
    try {
      final challenge = await getTodaysChallenge(userId);
      if (challenge == null || challenge.isCompleted) return challenge;

      int newValue = challenge.currentValue;

      // Calculate progress based on challenge type
      switch (challenge.challengeKey) {
        case 'complete_reps':
          newValue += workoutData['total_reps'] as int? ?? 0;
          break;
        case 'perfect_form':
          final score = workoutData['avg_form_score'] as double? ?? 0.0;
          if (score >= challenge.targetValue) {
            newValue = challenge.targetValue; // Mark as complete
          }
          break;
        case 'workout_duration':
          newValue += (workoutData['duration_seconds'] as int? ?? 0) ~/ 60;
          break;
        case 'high_score':
          final score = workoutData['avg_form_score'] as double? ?? 0.0;
          if (score >= challenge.targetValue) {
            newValue = challenge.targetValue;
          }
          break;
        case 'variety':
          // This requires checking unique exercises today
          // Simplified: increment once per workout
          newValue += 1;
          break;
      }

      final isCompleted = newValue >= challenge.targetValue;

      final updated = await _supabase.client
          .from('daily_challenges')
          .update({
            'current_value': newValue,
            'is_completed': isCompleted,
            'completed_at': isCompleted ? DateTime.now().toIso8601String() : null,
          })
          .eq('id', challenge.id)
          .select()
          .single();

      if (isCompleted) {
        AppLogger.info('🎉 Daily challenge completed!');
      }

      return DailyChallenge.fromJson(updated);
    } catch (e, stack) {
      AppLogger.error('Failed to update challenge progress', e, stack);
      return null;
    }
  }

  /// Get challenge history
  Future<List<DailyChallenge>> getChallengeHistory(String userId, {int limit = 30}) async {
    try {
      final result = await _supabase.client
          .from('daily_challenges')
          .select()
          .eq('user_id', userId)
          .order('challenge_date', ascending: false)
          .limit(limit);

      return (result as List).map((json) => DailyChallenge.fromJson(json)).toList();
    } catch (e, stack) {
      AppLogger.error('Failed to get challenge history', e, stack);
      return [];
    }
  }

  /// Get completion rate (last 7 days)
  Future<double> getCompletionRate(String userId) async {
    try {
      final sevenDaysAgo = DateTime.now().subtract(const Duration(days: 7));
      final challenges = await _supabase.client
          .from('daily_challenges')
          .select()
          .eq('user_id', userId)
          .gte('challenge_date', sevenDaysAgo.toIso8601String().split('T')[0]);

      if (challenges.isEmpty) return 0.0;

      final completed = (challenges as List).where((c) => c['is_completed'] == true).length;
      return completed / challenges.length;
    } catch (e) {
      AppLogger.error('Failed to get completion rate', e);
      return 0.0;
    }
  }
}
