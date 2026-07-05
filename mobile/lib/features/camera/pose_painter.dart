import 'package:flutter/material.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import '../../core/theme/app_colors.dart';

/// Draws joint markers + connecting bones over the camera preview.
/// This is the "skeleton overlay" / "joint markers" / "movement path"
/// element described for the Camera Screen in the design document.
class PosePainter extends CustomPainter {
  PosePainter({
    required this.pose,
    required this.imageSize,
    required this.isFrontCamera,
  });

  final Pose? pose;
  final Size imageSize;
  final bool isFrontCamera;

  static const _connections = [
    [PoseLandmarkType.leftShoulder, PoseLandmarkType.rightShoulder],
    [PoseLandmarkType.leftShoulder, PoseLandmarkType.leftElbow],
    [PoseLandmarkType.leftElbow, PoseLandmarkType.leftWrist],
    [PoseLandmarkType.rightShoulder, PoseLandmarkType.rightElbow],
    [PoseLandmarkType.rightElbow, PoseLandmarkType.rightWrist],
    [PoseLandmarkType.leftShoulder, PoseLandmarkType.leftHip],
    [PoseLandmarkType.rightShoulder, PoseLandmarkType.rightHip],
    [PoseLandmarkType.leftHip, PoseLandmarkType.rightHip],
    [PoseLandmarkType.leftHip, PoseLandmarkType.leftKnee],
    [PoseLandmarkType.leftKnee, PoseLandmarkType.leftAnkle],
    [PoseLandmarkType.rightHip, PoseLandmarkType.rightKnee],
    [PoseLandmarkType.rightKnee, PoseLandmarkType.rightAnkle],
  ];

  @override
  void paint(Canvas canvas, Size size) {
    if (pose == null) return;
    final scaleX = size.width / imageSize.width;
    final scaleY = size.height / imageSize.height;

    Offset map(PoseLandmark l) {
      final dx = isFrontCamera ? size.width - (l.x * scaleX) : l.x * scaleX;
      return Offset(dx, l.y * scaleY);
    }

    final bonePaint = Paint()
      ..color = AppColors.electricBlue
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    final jointPaint = Paint()..color = AppColors.emerald;

    for (final conn in _connections) {
      final a = pose!.landmarks[conn[0]];
      final b = pose!.landmarks[conn[1]];
      if (a == null || b == null) continue;
      canvas.drawLine(map(a), map(b), bonePaint);
    }

    for (final landmark in pose!.landmarks.values) {
      canvas.drawCircle(map(landmark), 4, jointPaint);
    }
  }

  @override
  bool shouldRepaint(covariant PosePainter oldDelegate) => oldDelegate.pose != pose;
}
