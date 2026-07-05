import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import '../../core/theme/app_colors.dart';
import 'pose_painter.dart';
import 'rep_counter.dart';

/// The Camera Screen — "the most important screen" per the RepSense design
/// document. Minimal chrome, full-screen camera, live skeleton overlay,
/// real-time AI feedback, and an animated rep counter.
///
/// Pose estimation runs ON-DEVICE via ML Kit (fast, lightweight, matches the
/// "Local AI Inference Layer" subsystem in the technical spec). Frames /
/// joint-angle sequences can optionally be streamed to the Inference Service
/// for deeper biomechanical scoring — see `lib/data/repositories` for the
/// Dio client hook-up point.
class CameraPage extends StatefulWidget {
  const CameraPage({super.key, required this.exerciseId});
  final String exerciseId;

  @override
  State<CameraPage> createState() => _CameraPageState();
}

class _CameraPageState extends State<CameraPage> {
  CameraController? _controller;
  late final PoseDetector _poseDetector;
  final _repCounter = RepCounter();

  Pose? _pose;
  Size _imageSize = const Size(480, 640);
  bool _isFrontCamera = true;
  bool _isStreaming = false;
  bool _busy = false;
  String _feedback = 'Step into frame to begin.';

  @override
  void initState() {
    super.initState();
    _poseDetector = PoseDetector(
      options: PoseDetectorOptions(mode: PoseDetectionMode.stream),
    );
    _initCamera();
  }

  Future<void> _initCamera() async {
    final cameras = await availableCameras();
    final camera = cameras.firstWhere(
      (c) => c.lensDirection == CameraLensDirection.front,
      orElse: () => cameras.first,
    );
    _isFrontCamera = camera.lensDirection == CameraLensDirection.front;

    final controller = CameraController(
      camera,
      ResolutionPreset.medium,
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.nv21,
    );
    await controller.initialize();
    if (!mounted) return;
    setState(() => _controller = controller);
  }

  void _toggleStream() {
    if (_controller == null) return;
    if (_isStreaming) {
      _controller!.stopImageStream();
      setState(() => _isStreaming = false);
    } else {
      _controller!.startImageStream(_processFrame);
      setState(() => _isStreaming = true);
    }
  }

  Future<void> _processFrame(CameraImage image) async {
    if (_busy) return;
    _busy = true;
    try {
      final inputImage = _toInputImage(image);
      if (inputImage == null) return;
      final poses = await _poseDetector.processImage(inputImage);
      if (poses.isNotEmpty) {
        final pose = poses.first;
        final angle = _repCounter.kneeAngle(pose);
        if (angle != null) {
          final completed = _repCounter.update(angle);
          if (completed && mounted) {
            setState(() => _feedback = 'Great rep! Maintain a neutral spine.');
          }
        }
        if (mounted) {
          setState(() {
            _pose = pose;
            _imageSize = Size(image.width.toDouble(), image.height.toDouble());
          });
        }
      }
    } finally {
      _busy = false;
    }
  }

  InputImage? _toInputImage(CameraImage image) {
    // NOTE: production builds should use a platform-specific converter
    // (see google_mlkit_commons examples) to correctly build the
    // InputImageRotation/format per Android vs iOS. Stubbed here for
    // brevity — wire up `camera` -> `InputImage` conversion utilities.
    return null;
  }

  void _finishSet() {
    if (_isStreaming) _toggleStream();
    context.pushReplacement('/summary', extra: {
      'exerciseId': widget.exerciseId,
      'reps': _repCounter.reps,
      'avgScore': 91,
    });
  }

  @override
  void dispose() {
    _controller?.dispose();
    _poseDetector.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Positioned.fill(
            child: _controller != null && _controller!.value.isInitialized
                ? CameraPreview(_controller!)
                : const Center(child: CircularProgressIndicator(color: AppColors.electricBlue)),
          ),
          Positioned.fill(
            child: CustomPaint(
              painter: PosePainter(pose: _pose, imageSize: _imageSize, isFrontCamera: _isFrontCamera),
            ),
          ),
          // Top status bar
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    onPressed: () => context.pop(),
                    icon: const Icon(Icons.close_rounded, color: Colors.white),
                  ),
                  Row(children: const [
                    _StatusChip(icon: Icons.wifi_rounded, label: 'AI Ready'),
                    SizedBox(width: 8),
                    _StatusChip(icon: Icons.bolt_rounded, label: '30 FPS'),
                  ]),
                ],
              ),
            ),
          ),
          // Rep counter
          Positioned(
            top: 90,
            left: 0,
            right: 0,
            child: Center(
              child: Text(
                '${_repCounter.reps}',
                style: const TextStyle(
                  fontSize: 72,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  shadows: [Shadow(blurRadius: 20, color: AppColors.electricBlue)],
                ),
              ).animate(target: 1).scale(duration: 200.ms),
            ),
          ),
          // Real-time feedback banner
          Positioned(
            bottom: 140,
            left: 16,
            right: 16,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: Container(
                key: ValueKey(_feedback),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.55),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.white.withOpacity(0.1)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.smart_toy_rounded, color: AppColors.emerald, size: 18),
                    const SizedBox(width: 8),
                    Expanded(child: Text(_feedback, style: const TextStyle(color: Colors.white, fontSize: 13))),
                  ],
                ),
              ),
            ),
          ),
          // Bottom controls
          Positioned(
            bottom: 24,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _RoundButton(icon: Icons.cameraswitch_rounded, onTap: () {}),
                _RoundButton(
                  icon: _isStreaming ? Icons.pause_rounded : Icons.play_arrow_rounded,
                  big: true,
                  onTap: _toggleStream,
                ),
                _RoundButton(icon: Icons.stop_rounded, onTap: _finishSet),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.4),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 14, color: AppColors.emerald),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(color: Colors.white, fontSize: 11)),
      ]),
    );
  }
}

class _RoundButton extends StatelessWidget {
  const _RoundButton({required this.icon, required this.onTap, this.big = false});
  final IconData icon;
  final VoidCallback onTap;
  final bool big;

  @override
  Widget build(BuildContext context) {
    final size = big ? 72.0 : 52.0;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: big ? AppColors.primaryGradient : null,
          color: big ? null : Colors.white.withOpacity(0.12),
        ),
        child: Icon(icon, color: Colors.white, size: big ? 32 : 22),
      ),
    );
  }
}
