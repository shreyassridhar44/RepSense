import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/providers/providers.dart';
import '../../core/theme/app_theme.dart';
import 'camera_state.dart';
import 'pose_painter.dart';
import 'widgets/permission_denied_view.dart';
import 'widgets/top_status_bar.dart';
import 'widgets/rep_counter_widget.dart';
import 'widgets/feedback_banner.dart';
import 'widgets/bottom_controls.dart';
import 'widgets/rep_quality_strip.dart';
import 'widgets/countdown_overlay.dart';
import 'widgets/paused_overlay.dart';
import 'widgets/set_config_sheet.dart';

/// Main camera page for real-time pose detection and rep counting
class CameraPage extends ConsumerStatefulWidget {
  final String exerciseId;

  const CameraPage({
    super.key,
    required this.exerciseId,
  });

  @override
  ConsumerState<CameraPage> createState() => _CameraPageState();
}

class _CameraPageState extends ConsumerState<CameraPage> {
  @override
  void initState() {
    super.initState();
    
    // Lock orientation to portrait
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
    ]);

    // Initialize camera
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(cameraProvider.notifier).initialize(widget.exerciseId);
    });
  }

  @override
  void dispose() {
    // Restore all orientations
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(cameraProvider);

    return Scaffold(
      backgroundColor: AppTheme.richBlack,
      body: SafeArea(
        child: _buildBody(context, state),
      ),
    );
  }

  Widget _buildBody(BuildContext context, CameraState state) {
    switch (state.status) {
      case CameraStatus.permissionDenied:
      case CameraStatus.permissionPermanentlyDenied:
        return PermissionDeniedView(
          isPermanent: state.status == CameraStatus.permissionPermanentlyDenied,
          onRequestPermission: () {
            ref.read(cameraProvider.notifier).initialize(widget.exerciseId);
          },
        );

      case CameraStatus.initializing:
        return const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: AppTheme.electricBlue),
              SizedBox(height: 16),
              Text(
                'Initializing camera...',
                style: TextStyle(color: AppTheme.platinum),
              ),
            ],
          ),
        );

      case CameraStatus.ready:
        return _buildReadyView(context, state);

      case CameraStatus.countdown:
      case CameraStatus.streaming:
      case CameraStatus.paused:
        return _buildStreamingView(context, state);

      case CameraStatus.error:
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 64),
              const SizedBox(height: 16),
              Text(
                state.errorMessage ?? 'An error occurred',
                style: const TextStyle(color: AppTheme.platinum),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Go Back'),
              ),
            ],
          ),
        );

      case CameraStatus.finished:
        // Navigate to summary with workout data
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            context.go('/summary', extra: {
              'exerciseId': state.exerciseId,
              'exerciseName': state.exerciseName,
              'reps': state.repCount,
              'correctReps': state.correctReps,
              'incorrectReps': state.incorrectReps,
              'repQuality': state.repQuality,
              'durationSeconds': state.sessionDuration?.inSeconds ?? 0,
              'estimatedCalories': state.estimatedCalories,
              'sessionStartTime': state.sessionStartTime?.toIso8601String(),
              'angleSequence': state.angleSequence,
            });
          }
        });
        return const SizedBox.shrink();
    }
  }

  /// Ready state - show configuration sheet
  Widget _buildReadyView(BuildContext context, CameraState state) {
    final controller = state.controller;
    if (controller == null || !controller.value.isInitialized) {
      return const Center(child: CircularProgressIndicator());
    }

    return Stack(
      children: [
        // Camera preview
        Center(
          child: AspectRatio(
            aspectRatio: controller.value.aspectRatio,
            child: _buildCameraPreview(state),
          ),
        ),

        // Top bar
        TopStatusBar(
          exerciseName: state.exerciseName,
          fps: state.fps,
          isLightingGood: state.isLightingGood,
          isDistanceGood: state.isDistanceGood,
          onBack: () => Navigator.of(context).pop(),
        ),

        // Configure & Start button
        Positioned(
          left: 0,
          right: 0,
          bottom: 32,
          child: Center(
            child: ElevatedButton(
              onPressed: () => _showConfigSheet(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.electricBlue,
                padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 16),
              ),
              child: const Text(
                'Configure & Start',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// Streaming state - show full UI
  Widget _buildStreamingView(BuildContext context, CameraState state) {
    final controller = state.controller;
    if (controller == null || !controller.value.isInitialized) {
      return const Center(child: CircularProgressIndicator());
    }

    return Stack(
      children: [
        // Camera preview with skeleton overlay
        Center(
          child: AspectRatio(
            aspectRatio: controller.value.aspectRatio,
            child: _buildCameraPreview(state),
          ),
        ),

        // Top bar
        TopStatusBar(
          exerciseName: state.exerciseName,
          fps: state.fps,
          isLightingGood: state.isLightingGood,
          isDistanceGood: state.isDistanceGood,
          onBack: () => _handleBack(context),
        ),

        // Rep counter (center)
        Positioned(
          left: 0,
          right: 0,
          top: MediaQuery.of(context).size.height * 0.35,
          child: RepCounterWidget(
            repCount: state.repCount,
            targetReps: state.targetReps,
            currentPhase: state.currentPhase,
            lastRepWasCorrect: state.lastRepWasCorrect,
          ),
        ),

        // Feedback banner
        Positioned(
          left: 16,
          right: 16,
          top: MediaQuery.of(context).size.height * 0.5,
          child: FeedbackBanner(
            message: state.feedbackMessage,
            severity: state.feedbackSeverity,
          ),
        ),

        // Rep quality strip
        if (state.repQuality.isNotEmpty)
          Positioned(
            left: 16,
            right: 16,
            bottom: 140,
            child: RepQualityStrip(repQuality: state.repQuality),
          ),

        // Bottom controls
        Positioned(
          left: 0,
          right: 0,
          bottom: 32,
          child: BottomControls(
            showSkeleton: state.showSkeleton,
            isStreaming: state.status == CameraStatus.streaming,
            onToggleSkeleton: () {
              ref.read(cameraProvider.notifier).toggleSkeleton();
            },
            onPauseResume: () {
              if (state.status == CameraStatus.streaming) {
                ref.read(cameraProvider.notifier).pauseStreaming();
              } else {
                ref.read(cameraProvider.notifier).resumeStreaming();
              }
            },
            onFinish: () => _handleFinish(context),
          ),
        ),

        // Countdown overlay
        if (state.status == CameraStatus.countdown)
          CountdownOverlay(countdown: state.countdownSeconds),

        // Paused overlay
        if (state.status == CameraStatus.paused)
          PausedOverlay(
            onResume: () {
              ref.read(cameraProvider.notifier).resumeStreaming();
            },
          ),
      ],
    );
  }

  /// Build camera preview with optional skeleton overlay
  Widget _buildCameraPreview(CameraState state) {
    final controller = state.controller;
    if (controller == null) return const SizedBox.shrink();

    return Stack(
      fit: StackFit.expand,
      children: [
        // Camera preview
        controller.buildPreview(),

        // Skeleton overlay
        if (state.showSkeleton && state.currentPose != null)
          CustomPaint(
            painter: PosePainter(
              pose: state.currentPose,
              imageSize: Size(
                controller.value.previewSize?.height ?? 1,
                controller.value.previewSize?.width ?? 1,
              ),
              isFrontCamera: state.isFrontCamera,
              primaryJoint: _getPrimaryJoint(state.exerciseId),
            ),
          ),
      ],
    );
  }

  /// Show configuration sheet
  void _showConfigSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.richBlack,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SetConfigSheet(
        currentTargetReps: ref.read(cameraProvider).targetReps,
        currentCountdown: ref.read(cameraProvider).countdownSeconds,
        voiceEnabled: ref.read(cameraProvider).voiceEnabled,
        isFrontCamera: ref.read(cameraProvider).isFrontCamera,
        onStart: (targetReps, countdown, voiceEnabled) {
          ref.read(cameraProvider.notifier).setTargetReps(targetReps);
          ref.read(cameraProvider.notifier).setCountdownSeconds(countdown);
          if (voiceEnabled != ref.read(cameraProvider).voiceEnabled) {
            ref.read(cameraProvider.notifier).toggleVoice();
          }
          ref.read(cameraProvider.notifier).startCountdown();
        },
        onCameraSwitch: () {
          ref.read(cameraProvider.notifier).switchCamera();
        },
      ),
    );
  }

  /// Handle back button during streaming
  void _handleBack(BuildContext context) {
    if (ref.read(cameraProvider).status == CameraStatus.streaming) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: AppTheme.richBlack,
          title: const Text('Exit Workout?', style: TextStyle(color: AppTheme.platinum)),
          content: const Text(
            'Your progress will be lost if you exit now.',
            style: TextStyle(color: AppTheme.platinum),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close dialog
                Navigator.of(context).pop(); // Close camera page
              },
              child: const Text('Exit', style: TextStyle(color: Colors.red)),
            ),
          ],
        ),
      );
    } else {
      Navigator.of(context).pop();
    }
  }

  /// Handle finish button
  void _handleFinish(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.richBlack,
        title: const Text('Finish Set?', style: TextStyle(color: AppTheme.platinum)),
        content: Text(
          'Complete your set with ${ref.read(cameraProvider).repCount} reps?',
          style: const TextStyle(color: AppTheme.platinum),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(); // Close dialog
              ref.read(cameraProvider.notifier).finishSet();
            },
            child: const Text('Finish', style: TextStyle(color: AppTheme.emerald)),
          ),
        ],
      ),
    );
  }

  /// Get primary joint to highlight based on exercise
  String? _getPrimaryJoint(String exerciseId) {
    switch (exerciseId.toLowerCase()) {
      case 'squat':
      case 'lunges':
      case 'leg-press':
        return 'knee';
      case 'deadlift':
        return 'hip';
      case 'bench-press':
      case 'push-up':
      case 'pull-up':
      case 'overhead-press':
      case 'bicep-curl':
      case 'tricep-extension':
      case 'rows':
      case 'lat-pulldown':
      case 'shoulder-press':
        return 'elbow';
      default:
        return null;
    }
  }
}
