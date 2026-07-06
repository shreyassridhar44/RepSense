import 'package:equatable/equatable.dart';
import 'package:intl/intl.dart';

/// Message role in conversation
enum MessageRole {
  user,
  assistant,
  system;

  String toJson() => name;

  static MessageRole fromJson(String json) {
    return MessageRole.values.firstWhere((e) => e.name == json);
  }
}

/// Message status
enum MessageStatus {
  sending,
  sent,
  error;

  String toJson() => name;

  static MessageStatus fromJson(String json) {
    return MessageStatus.values.firstWhere((e) => e.name == json);
  }
}

/// Message type
enum MessageType {
  text,
  image,
  quickReply;

  String toJson() => name;

  static MessageType fromJson(String json) {
    return MessageType.values.firstWhere((e) => e.name == json);
  }
}

/// Chat message model
class ChatMessage extends Equatable {
  final String id;
  final MessageRole role;
  final String content;
  final MessageType type;
  final MessageStatus status;
  final DateTime timestamp;
  final List<String> suggestedFollowups;
  final String? imageBase64;
  final String? errorMessage;
  final bool isAnimating;

  const ChatMessage({
    required this.id,
    required this.role,
    required this.content,
    required this.type,
    required this.status,
    required this.timestamp,
    this.suggestedFollowups = const [],
    this.imageBase64,
    this.errorMessage,
    this.isAnimating = false,
  });

  bool get isUser => role == MessageRole.user;
  bool get isAssistant => role == MessageRole.assistant;
  bool get isError => status == MessageStatus.error;

  ChatMessage copyWith({
    String? id,
    MessageRole? role,
    String? content,
    MessageType? type,
    MessageStatus? status,
    DateTime? timestamp,
    List<String>? suggestedFollowups,
    String? imageBase64,
    String? errorMessage,
    bool? isAnimating,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      role: role ?? this.role,
      content: content ?? this.content,
      type: type ?? this.type,
      status: status ?? this.status,
      timestamp: timestamp ?? this.timestamp,
      suggestedFollowups: suggestedFollowups ?? this.suggestedFollowups,
      imageBase64: imageBase64 ?? this.imageBase64,
      errorMessage: errorMessage ?? this.errorMessage,
      isAnimating: isAnimating ?? this.isAnimating,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'role': role.toJson(),
      'content': content,
      'type': type.toJson(),
      'status': status.toJson(),
      'timestamp': timestamp.toIso8601String(),
      'suggestedFollowups': suggestedFollowups,
      'errorMessage': errorMessage,
      'isAnimating': isAnimating,
      // Note: imageBase64 NOT persisted (too large)
    };
  }

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'] as String,
      role: MessageRole.fromJson(json['role'] as String),
      content: json['content'] as String,
      type: MessageType.fromJson(json['type'] as String),
      status: MessageStatus.fromJson(json['status'] as String),
      timestamp: DateTime.parse(json['timestamp'] as String),
      suggestedFollowups: (json['suggestedFollowups'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      errorMessage: json['errorMessage'] as String?,
      isAnimating: json['isAnimating'] as bool? ?? false,
    );
  }

  @override
  List<Object?> get props => [
        id,
        role,
        content,
        type,
        status,
        timestamp,
        suggestedFollowups,
        imageBase64,
        errorMessage,
        isAnimating,
      ];
}

/// Recent workout context for coach
class RecentWorkoutContext extends Equatable {
  final String exerciseName;
  final DateTime date;
  final double avgFormScore;
  final int totalReps;
  final String? topIssue;

  const RecentWorkoutContext({
    required this.exerciseName,
    required this.date,
    required this.avgFormScore,
    required this.totalReps,
    this.topIssue,
  });

  Map<String, dynamic> toJson() {
    return {
      'exercise_name': exerciseName,
      'date': date.toIso8601String(),
      'avg_form_score': avgFormScore,
      'total_reps': totalReps,
      'top_issue': topIssue,
    };
  }

  @override
  List<Object?> get props => [exerciseName, date, avgFormScore, totalReps, topIssue];
}

/// Coach context built from Supabase data
class CoachContext extends Equatable {
  final String? displayName;
  final String? trainingExperience;
  final List<String> goals;
  final double? heightCm;
  final double? weightKg;
  final int totalWorkouts;
  final int currentStreakDays;
  final double? avgFormScoreLast7Days;
  final String? mostTrainedExercise;
  final String? weakestMuscleGroup;
  final List<String> recentIssues;
  final List<RecentWorkoutContext> recentWorkouts;

  const CoachContext({
    this.displayName,
    this.trainingExperience,
    this.goals = const [],
    this.heightCm,
    this.weightKg,
    this.totalWorkouts = 0,
    this.currentStreakDays = 0,
    this.avgFormScoreLast7Days,
    this.mostTrainedExercise,
    this.weakestMuscleGroup,
    this.recentIssues = const [],
    this.recentWorkouts = const [],
  });

  Map<String, dynamic> toJson() {
    return {
      'display_name': displayName,
      'training_experience': trainingExperience,
      'goals': goals,
      'height_cm': heightCm,
      'weight_kg': weightKg,
      'total_workouts': totalWorkouts,
      'current_streak_days': currentStreakDays,
      'avg_form_score_last_7_days': avgFormScoreLast7Days,
      'most_trained_exercise': mostTrainedExercise,
      'weakest_muscle_group': weakestMuscleGroup,
      'recent_issues': recentIssues,
      'recent_workouts_summary': recentWorkouts.map((w) => w.toJson()).toList(),
    };
  }

  @override
  List<Object?> get props => [
        displayName,
        trainingExperience,
        goals,
        heightCm,
        weightKg,
        totalWorkouts,
        currentStreakDays,
        avgFormScoreLast7Days,
        mostTrainedExercise,
        weakestMuscleGroup,
        recentIssues,
        recentWorkouts,
      ];
}

/// Conversation export model
class ConversationExport extends Equatable {
  final String title;
  final DateTime exportedAt;
  final List<ChatMessage> messages;

  const ConversationExport({
    required this.title,
    required this.exportedAt,
    required this.messages,
  });

  String toPlainText() {
    final buffer = StringBuffer();
    buffer.writeln(title);
    buffer.writeln('Exported: ${DateFormat('MMM d, yyyy h:mm a').format(exportedAt)}');
    buffer.writeln('${'=' * 50}\n');

    for (final message in messages) {
      final time = DateFormat('HH:mm').format(message.timestamp);
      final sender = message.isUser ? 'You' : 'Coach';
      final content = message.type == MessageType.image
          ? '[Image attached]${message.content.isNotEmpty ? ': ${message.content}' : ''}'
          : message.content;

      buffer.writeln('[$time] $sender: $content\n');
    }

    return buffer.toString();
  }

  @override
  List<Object?> get props => [title, exportedAt, messages];
}
