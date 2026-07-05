import 'package:camera/camera.dart';
import 'package:equatable/equatable.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';

enum CameraStatus {
  permissionDenied,
  permissionPermanentlyDenied,
  initializing,
  ready,
  streaming,
  paused,
  countdown,
  finished,
  error,
}

enum RepPhase {
  down,
  pause,
  up,
  lockout,
}

enum FeedbackSeverity {
  good,
  warning,
  error,
}

class CameraState extends Equatable {
  final CameraStatus status;
  final String? errorMessage;
  final String exerciseId;
  final String exerciseName;

  // Camera hardware
  final CameraController? controller;
  final bool isFrontCamera;

  // Pose detection
  final Pose? currentPose;
  final double poseConfidence;
  final bool isPersonDetected;

  // Rep counting
  final int repCount;
  final RepPhase currentPhase;
  final bool lastRepWasCorrect;
  final List<bool> repQuality;

  // Form feedback
  final String feedbackMessage;
  final FeedbackSeverity feedbackSeverity;
  final double currentAngle;

  // Set configuration
  final int targetReps;
  final int targetSets;
  final int countdownSeconds;

  // Session tracking
  final DateTime? sessionStartTime;
  final List<Map<String, double>> angleSequence;
  final double estimatedCalories;

  // UI flags
  final bool voiceEnabled;
  final bool showSkeleton;
  final bool isLightingGood;
  final bool isDistanceGood;
  final int fps;

  const CameraState({
    this.status = CameraStatus.initializing,
    this.errorMessage,
    this.exerciseId = '',
    this.exerciseName = '',
    this.controller,
    this.isFrontCamera = true,
    this.currentPose,
    this.poseConfidence = 0.0,
    this.isPersonDetected = false,
    this.repCount = 0,
    this.currentPhase = RepPhase.lockout,
    this.lastRepWasCorrect = false,
    this.repQuality = const [],
    this.feedbackMessage = 'Position yourself in frame',
    this.feedbackSeverity = FeedbackSeverity.warning,
    this.currentAngle = 180.0,
    this.targetReps = 0,
    this.targetSets = 1,
    this.countdownSeconds = 3,
    this.sessionStartTime,
    this.angleSequence = const [],
    this.estimatedCalories = 0.0,
    this.voiceEnabled = true,
    this.showSkeleton = true,
    this.isLightingGood = true,
    this.isDistanceGood = true,
    this.fps = 0,
  });

  int get correctReps => repQuality.where((q) => q).length;
  int get incorrectReps => repQuality.where((q) => !q).length;
  
  Duration? get sessionDuration {
    if (sessionStartTime == null) return null;
    return DateTime.now().difference(sessionStartTime!);
  }

  CameraState copyWith({
    CameraStatus? status,
    String? errorMessage,
    String? exerciseId,
    String? exerciseName,
    CameraController? controller,
    bool? isFrontCamera,
    Pose? currentPose,
    double? poseConfidence,
    bool? isPersonDetected,
    int? repCount,
    RepPhase? currentPhase,
    bool? lastRepWasCorrect,
    List<bool>? repQuality,
    String? feedbackMessage,
    FeedbackSeverity? feedbackSeverity,
    double? currentAngle,
    int? targetReps,
    int? targetSets,
    int? countdownSeconds,
    DateTime? sessionStartTime,
    List<Map<String, double>>? angleSequence,
    double? estimatedCalories,
    bool? voiceEnabled,
    bool? showSkeleton,
    bool? isLightingGood,
    bool? isDistanceGood,
    int? fps,
  }) {
    return CameraState(
      status: status ?? this.status,
      errorMessage: errorMessage,
      exerciseId: exerciseId ?? this.exerciseId,
      exerciseName: exerciseName ?? this.exerciseName,
      controller: controller ?? this.controller,
      isFrontCamera: isFrontCamera ?? this.isFrontCamera,
      currentPose: currentPose ?? this.currentPose,
      poseConfidence: poseConfidence ?? this.poseConfidence,
      isPersonDetected: isPersonDetected ?? this.isPersonDetected,
      repCount: repCount ?? this.repCount,
      currentPhase: currentPhase ?? this.currentPhase,
      lastRepWasCorrect: lastRepWasCorrect ?? this.lastRepWasCorrect,
      repQuality: repQuality ?? this.repQuality,
      feedbackMessage: feedbackMessage ?? this.feedbackMessage,
      feedbackSeverity: feedbackSeverity ?? this.feedbackSeverity,
      currentAngle: currentAngle ?? this.currentAngle,
      targetReps: targetReps ?? this.targetReps,
      targetSets: targetSets ?? this.targetSets,
      countdownSeconds: countdownSeconds ?? this.countdownSeconds,
      sessionStartTime: sessionStartTime ?? this.sessionStartTime,
      angleSequence: angleSequence ?? this.angleSequence,
      estimatedCalories: estimatedCalories ?? this.estimatedCalories,
      voiceEnabled: voiceEnabled ?? this.voiceEnabled,
      showSkeleton: showSkeleton ?? this.showSkeleton,
      isLightingGood: isLightingGood ?? this.isLightingGood,
      isDistanceGood: isDistanceGood ?? this.isDistanceGood,
      fps: fps ?? this.fps,
    );
  }

  @override
  List<Object?> get props => [
        status,
        errorMessage,
        exerciseId,
        exerciseName,
        controller,
        isFrontCamera,
        currentPose,
        poseConfidence,
        isPersonDetected,
        repCount,
        currentPhase,
        lastRepWasCorrect,
        repQuality,
        feedbackMessage,
        feedbackSeverity,
        currentAngle,
        targetReps,
        targetSets,
        countdownSeconds,
        sessionStartTime,
        angleSequence,
        estimatedCalories,
        voiceEnabled,
        showSkeleton,
        isLightingGood,
        isDistanceGood,
        fps,
      ];
}
