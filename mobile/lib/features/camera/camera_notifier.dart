import 'dart:async';
import 'package:camera/camera.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../core/utils/app_logger.dart';
import '../../core/utils/image_converter.dart';
import '../../data/repositories/exercise_repository.dart';
import '../../data/supabase/supabase_service.dart';
import 'camera_state.dart';
import 'feedback_engine.dart';
import 'joint_angle_engine.dart';
import 'rep_counter.dart';
import 'voice_service.dart';

/// Camera notifier - the brain of Module 4
class CameraNotifier extends StateNotifier<CameraState> {
  final ExerciseRepository _exerciseRepository;
  
  CameraController? _cameraController;
  PoseDetector? _poseDetector;
  final JointAngleEngine _jointAngleEngine = JointAngleEngine();
  final RepCounter _repCounter = RepCounter();
  final FeedbackEngine _feedbackEngine = FeedbackEngine();
  final VoiceService _voiceService = VoiceService.instance;

  bool _busy = false;
  Timer? _countdownTimer;
  Timer? _fpsTimer;
  int _frameCount = 0;
  List<Map<String, double>> _currentRepAngles = [];
  List<Map<String, double>>? _lastRepAngles;

  CameraNotifier({
    required ExerciseRepository exerciseRepository,
  })  : _exerciseRepository = exerciseRepository,
        super(const CameraState());

  /// Initialize camera and pose detector for an exercise
  Future<void> initialize(String exerciseId) async {
    try {
      AppLogger.info('📸 Initializing camera for exercise: $exerciseId');
      state = state.copyWith(status: CameraStatus.initializing);

      // Check camera permission
      final permissionStatus = await Permission.camera.status;
      if (permissionStatus.isDenied) {
        final granted = await Permission.camera.request();
        if (!granted.isGranted) {
          state = state.copyWith(
            status: CameraStatus.permissionDenied,
            errorMessage: 'Camera permission is required',
          );
          return;
        }
      } else if (permissionStatus.isPermanentlyDenied) {
        state = state.copyWith(
          status: CameraStatus.permissionPermanentlyDenied,
          errorMessage: 'Please grant camera permission in settings',
        );
        return;
      }

      // Load exercise details
      final userId = SupabaseService.instance.currentUser?.id ?? '';
      final exercise = await _exerciseRepository.getExerciseById(exerciseId, userId);
      if (exercise == null) {
        state = state.copyWith(
          status: CameraStatus.error,
          errorMessage: 'Exercise not found',
        );
        return;
      }

      // Get available cameras
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        state = state.copyWith(
          status: CameraStatus.error,
          errorMessage: 'No cameras available',
        );
        return;
      }

      // Initialize front camera by default
      final frontCamera = cameras.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first,
      );

      await _initializeCamera(frontCamera);

      // Initialize pose detector
      _poseDetector = PoseDetector(
        options: PoseDetectorOptions(
          mode: PoseDetectionMode.stream,
          model: PoseDetectionModel.accurate,
        ),
      );

      // Initialize voice service
      await _voiceService.initialize();

      // Initialize rep counter
      _repCounter.initialize(exerciseId);

      // Set target reps based on exercise difficulty
      int defaultTargetReps = 10;
      switch (exercise.difficulty.toLowerCase()) {
        case 'beginner':
          defaultTargetReps = 8;
          break;
        case 'intermediate':
          defaultTargetReps = 12;
          break;
        case 'advanced':
          defaultTargetReps = 15;
          break;
      }

      state = state.copyWith(
        status: CameraStatus.ready,
        exerciseId: exerciseId,
        exerciseName: exercise.name,
        targetReps: defaultTargetReps,
        isFrontCamera: frontCamera.lensDirection == CameraLensDirection.front,
      );

      AppLogger.info('✅ Camera initialized successfully');
    } catch (e, stack) {
      AppLogger.error('❌ Failed to initialize camera', e, stack);
      state = state.copyWith(
        status: CameraStatus.error,
        errorMessage: 'Camera initialization failed: ${e.toString()}',
      );
    }
  }

  /// Initialize camera controller
  Future<void> _initializeCamera(CameraDescription camera) async {
    _cameraController = CameraController(
      camera,
      ResolutionPreset.medium, // Balance between quality and performance
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.yuv420,
    );

    await _cameraController!.initialize();
    state = state.copyWith(controller: _cameraController);
  }

  /// Start countdown before streaming
  Future<void> startCountdown() async {
    if (state.status != CameraStatus.ready) return;

    AppLogger.info('⏱️ Starting countdown');
    state = state.copyWith(status: CameraStatus.countdown);

    int countdown = state.countdownSeconds;
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) async {
      if (countdown > 0) {
        await _voiceService.speak(countdown.toString());
        countdown--;
      } else {
        timer.cancel();
        await _voiceService.speak('Go!');
        await startStreaming();
      }
    });
  }

  /// Start streaming and processing frames
  Future<void> startStreaming() async {
    if (_cameraController == null || _poseDetector == null) return;

    try {
      AppLogger.info('🎥 Starting camera stream');
      
      state = state.copyWith(
        status: CameraStatus.streaming,
        sessionStartTime: DateTime.now(),
      );

      // Start FPS counter
      _startFpsCounter();

      // Start image stream
      _cameraController!.startImageStream(_processFrame);

      AppLogger.info('✅ Camera streaming started');
    } catch (e, stack) {
      AppLogger.error('❌ Failed to start streaming', e, stack);
      state = state.copyWith(
        status: CameraStatus.error,
        errorMessage: 'Failed to start camera stream',
      );
    }
  }

  /// Pause streaming
  Future<void> pauseStreaming() async {
    if (state.status != CameraStatus.streaming) return;

    try {
      AppLogger.info('⏸️ Pausing camera stream');
      await _cameraController?.stopImageStream();
      _fpsTimer?.cancel();
      
      state = state.copyWith(status: CameraStatus.paused);
      AppLogger.info('✅ Camera stream paused');
    } catch (e, stack) {
      AppLogger.error('❌ Failed to pause streaming', e, stack);
    }
  }

  /// Resume streaming
  Future<void> resumeStreaming() async {
    if (state.status != CameraStatus.paused) return;

    try {
      AppLogger.info('▶️ Resuming camera stream');
      
      state = state.copyWith(status: CameraStatus.streaming);
      _startFpsCounter();
      _cameraController?.startImageStream(_processFrame);
      
      AppLogger.info('✅ Camera stream resumed');
    } catch (e, stack) {
      AppLogger.error('❌ Failed to resume streaming', e, stack);
    }
  }

  /// Switch between front and rear camera
  Future<void> switchCamera() async {
    if (_cameraController == null) return;

    try {
      AppLogger.info('🔄 Switching camera');

      // Stop streaming
      final wasStreaming = state.status == CameraStatus.streaming;
      if (wasStreaming) {
        await _cameraController?.stopImageStream();
        _fpsTimer?.cancel();
      }

      // Get cameras
      final cameras = await availableCameras();
      final newCamera = cameras.firstWhere(
        (camera) =>
            camera.lensDirection !=
            (state.isFrontCamera
                ? CameraLensDirection.front
                : CameraLensDirection.back),
        orElse: () => cameras.first,
      );

      // Dispose old controller
      await _cameraController?.dispose();

      // Initialize new camera
      await _initializeCamera(newCamera);

      state = state.copyWith(
        isFrontCamera: newCamera.lensDirection == CameraLensDirection.front,
        controller: _cameraController,
      );

      // Resume streaming if was streaming
      if (wasStreaming) {
        state = state.copyWith(status: CameraStatus.streaming);
        _startFpsCounter();
        _cameraController?.startImageStream(_processFrame);
      }

      AppLogger.info('✅ Camera switched');
    } catch (e, stack) {
      AppLogger.error('❌ Failed to switch camera', e, stack);
    }
  }

  /// Finish the current set
  Future<void> finishSet() async {
    if (state.status != CameraStatus.streaming &&
        state.status != CameraStatus.paused) {
      return;
    }

    try {
      AppLogger.info('🏁 Finishing set');

      // Stop streaming
      await _cameraController?.stopImageStream();
      _fpsTimer?.cancel();

      // Calculate final calories
      final duration = state.sessionDuration;
      if (duration != null) {
        final durationMinutes = duration.inSeconds / 60.0;
        const userWeightKg = 70.0; // Default weight
        // Get MET value from exercise (would need to load from DB)
        const metValue = 5.0; // Default MET value
        final calories = (metValue * userWeightKg * durationMinutes) / 60.0;

        state = state.copyWith(estimatedCalories: calories);
      }

      // Voice feedback
      await _voiceService.speak(
        'Set complete — ${state.repCount} reps',
      );

      state = state.copyWith(status: CameraStatus.finished);
      AppLogger.info('✅ Set finished: ${state.repCount} reps');
    } catch (e, stack) {
      AppLogger.error('❌ Failed to finish set', e, stack);
    }
  }

  /// Process a single camera frame (CORE AI PIPELINE)
  Future<void> _processFrame(CameraImage image) async {
    // Skip if busy processing previous frame
    if (_busy) return;
    _busy = true;

    try {
      _frameCount++;

      // Convert CameraImage to InputImage
      final camera = _cameraController?.description;
      if (camera == null) return;

      final inputImage = convertCameraImageToInputImage(
        image,
        camera,
        DeviceOrientation.portraitUp,
      );

      if (inputImage == null) {
        AppLogger.warning('⚠️ Failed to convert camera image');
        return;
      }

      // Detect pose
      final poses = await _poseDetector!.processImage(inputImage);
      if (poses.isEmpty) {
        state = state.copyWith(
          isPersonDetected: false,
          feedbackMessage: 'Position yourself in frame',
          feedbackSeverity: FeedbackSeverity.warning,
        );
        return;
      }

      final pose = poses.first;
      
      // Calculate average confidence
      final avgConfidence = pose.landmarks.values
          .map((l) => l.likelihood)
          .reduce((a, b) => a + b) / pose.landmarks.length;

      if (avgConfidence < 0.3) {
        state = state.copyWith(
          isPersonDetected: true,
          poseConfidence: avgConfidence,
          feedbackMessage: 'Adjust your position for better detection',
          feedbackSeverity: FeedbackSeverity.warning,
        );
        return;
      }

      // Compute joint angles
      final angles = _jointAngleEngine.compute(pose);
      _currentRepAngles.add(angles);

      // Update rep counter
      final repCompleted = _repCounter.update(angles);

      if (repCompleted) {
        // Evaluate rep quality
        final wasCorrect = _evaluateRepQuality(_currentRepAngles);
        final newRepQuality = List<bool>.from(state.repQuality)..add(wasCorrect);

        // Voice feedback
        final repNumber = _repCounter.reps;
        if (state.voiceEnabled) {
          if (wasCorrect) {
            await _voiceService.speak('Rep $repNumber');
          } else {
            // Get current feedback for voice
            final feedback = _feedbackEngine.generate(
              angles,
              state.exerciseId,
              _repCounter.phase,
              _lastRepAngles,
            );
            if (feedback.voiceText != null) {
              await _voiceService.speak('Rep $repNumber — ${feedback.voiceText}');
            } else {
              await _voiceService.speak('Rep $repNumber');
            }
          }
        }

        // Store rep angles for next rep evaluation
        _lastRepAngles = List.from(_currentRepAngles);
        _currentRepAngles.clear();

        // Check if target reached
        if (state.targetReps > 0 && repNumber >= state.targetReps) {
          await finishSet();
          return;
        }

        state = state.copyWith(
          repCount: repNumber,
          lastRepWasCorrect: wasCorrect,
          repQuality: newRepQuality,
          currentPhase: _repCounter.phase,
        );
      }

      // Generate form feedback
      final feedback = _feedbackEngine.generate(
        angles,
        state.exerciseId,
        _repCounter.phase,
        _lastRepAngles,
      );

      // Get primary angle for display
      final config = _repCounter.getConfig();
      double primaryAngle = 180.0;
      if (config != null) {
        if (config.useSymmetry) {
          final leftKey = 'left_${config.primaryAngleKey}';
          final rightKey = 'right_${config.primaryAngleKey}';
          final left = angles[leftKey] ?? 180.0;
          final right = angles[rightKey] ?? 180.0;
          primaryAngle = (left + right) / 2;
        } else {
          primaryAngle = angles[config.primaryAngleKey] ?? 180.0;
        }
      }

      // Check lighting and distance
      final isLightingGood = _checkLighting(pose);
      final isDistanceGood = _checkDistance(pose);

      // Update state
      state = state.copyWith(
        currentPose: pose,
        poseConfidence: avgConfidence,
        isPersonDetected: true,
        currentPhase: _repCounter.phase,
        feedbackMessage: feedback.text,
        feedbackSeverity: feedback.severity,
        currentAngle: primaryAngle,
        isLightingGood: isLightingGood,
        isDistanceGood: isDistanceGood,
        angleSequence: List.from(state.angleSequence)..add(angles),
      );
    } catch (e, stack) {
      AppLogger.error('❌ Frame processing error', e, stack);
    } finally {
      _busy = false;
    }
  }

  /// Evaluate if the last rep was performed correctly
  bool _evaluateRepQuality(List<Map<String, double>> repAngles) {
    if (repAngles.isEmpty) return false;

    // Check for consistent movement (angles should change smoothly)
    // This is a simple heuristic - can be enhanced
    final config = _repCounter.getConfig();
    if (config == null) return true;

    try {
      // Get primary angle throughout rep
      final angles = repAngles.map((angleMap) {
        if (config.useSymmetry) {
          final leftKey = 'left_${config.primaryAngleKey}';
          final rightKey = 'right_${config.primaryAngleKey}';
          final left = angleMap[leftKey] ?? 180.0;
          final right = angleMap[rightKey] ?? 180.0;
          return (left + right) / 2;
        } else {
          return angleMap[config.primaryAngleKey] ?? 180.0;
        }
      }).toList();

      if (angles.isEmpty) return false;

      // Check if rep reached proper depth
      final minAngle = angles.reduce((a, b) => a < b ? a : b);
      final maxAngle = angles.reduce((a, b) => a > b ? a : b);

      final reachedDepth = minAngle <= config.downThreshold * 1.1;
      final reachedLockout = maxAngle >= config.upThreshold * 0.9;

      return reachedDepth && reachedLockout;
    } catch (e, stack) {
      AppLogger.warning('⚠️ Failed to evaluate rep quality', e, stack);
      return true; // Give benefit of doubt
    }
  }

  /// Check if lighting is adequate
  bool _checkLighting(Pose pose) {
    // Simple heuristic: if average confidence is low, lighting might be poor
    final avgConfidence = pose.landmarks.values
        .map((l) => l.likelihood)
        .reduce((a, b) => a + b) / pose.landmarks.length;
    
    return avgConfidence > 0.5;
  }

  /// Check if person is at good distance from camera
  bool _checkDistance(Pose pose) {
    // Check if full body is visible
    final hasHead = (pose.landmarks[PoseLandmarkType.nose]?.likelihood ?? 0) > 0.5;
    final hasFeet = ((pose.landmarks[PoseLandmarkType.leftAnkle]?.likelihood ?? 0) > 0.5) &&
                    ((pose.landmarks[PoseLandmarkType.rightAnkle]?.likelihood ?? 0) > 0.5);
    
    return hasHead && hasFeet;
  }

  /// Start FPS counter
  void _startFpsCounter() {
    _frameCount = 0;
    _fpsTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      state = state.copyWith(fps: _frameCount);
      _frameCount = 0;
    });
  }

  /// Toggle voice guidance
  void toggleVoice() {
    final newState = !state.voiceEnabled;
    _voiceService.setEnabled(newState);
    state = state.copyWith(voiceEnabled: newState);
    AppLogger.info('🔊 Voice ${newState ? 'enabled' : 'disabled'}');
  }

  /// Toggle skeleton overlay
  void toggleSkeleton() {
    state = state.copyWith(showSkeleton: !state.showSkeleton);
    AppLogger.info('💀 Skeleton ${state.showSkeleton ? 'enabled' : 'disabled'}');
  }

  /// Set target reps
  void setTargetReps(int reps) {
    state = state.copyWith(targetReps: reps);
    AppLogger.info('🎯 Target reps set to $reps');
  }

  /// Set countdown seconds
  void setCountdownSeconds(int seconds) {
    state = state.copyWith(countdownSeconds: seconds);
    AppLogger.info('⏱️ Countdown set to $seconds seconds');
  }

  @override
  void dispose() {
    AppLogger.info('🧹 Disposing camera notifier');
    
    _countdownTimer?.cancel();
    _fpsTimer?.cancel();
    _cameraController?.stopImageStream();
    _cameraController?.dispose();
    _poseDetector?.close();
    _voiceService.dispose();
    
    super.dispose();
  }
}

/// Camera provider
final cameraProvider = StateNotifierProvider<CameraNotifier, CameraState>((ref) {
  return CameraNotifier(
    exerciseRepository: ExerciseRepository(),
  );
});
