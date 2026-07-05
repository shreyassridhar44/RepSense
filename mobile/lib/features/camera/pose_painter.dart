import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';

/// Custom painter for rendering pose skeleton overlay
class PosePainter extends CustomPainter {
  final Pose? pose;
  final Size imageSize;
  final bool isFrontCamera;
  final String? primaryJoint; // Joint to highlight

  PosePainter({
    required this.pose,
    required this.imageSize,
    required this.isFrontCamera,
    this.primaryJoint,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (pose == null) return;

    final paint = Paint()
      ..style = PaintingStyle.fill
      ..strokeWidth = 4.0;

    final linePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round;

    // Draw connections first (below joints)
    _drawConnections(canvas, size, linePaint);

    // Draw joints on top
    _drawJoints(canvas, size, paint);
  }

  /// Draw skeleton connections
  void _drawConnections(Canvas canvas, Size size, Paint paint) {
    // Face connections
    _drawLine(canvas, size, paint,
        PoseLandmarkType.leftEye, PoseLandmarkType.rightEye, Colors.amber);
    _drawLine(canvas, size, paint,
        PoseLandmarkType.leftEye, PoseLandmarkType.nose, Colors.amber);
    _drawLine(canvas, size, paint,
        PoseLandmarkType.rightEye, PoseLandmarkType.nose, Colors.amber);
    _drawLine(canvas, size, paint,
        PoseLandmarkType.leftEar, PoseLandmarkType.leftEye, Colors.amber);
    _drawLine(canvas, size, paint,
        PoseLandmarkType.rightEar, PoseLandmarkType.rightEye, Colors.amber);
    _drawLine(canvas, size, paint,
        PoseLandmarkType.leftMouth, PoseLandmarkType.rightMouth, Colors.amber);

    // Upper body - arms
    _drawLine(canvas, size, paint,
        PoseLandmarkType.leftShoulder, PoseLandmarkType.rightShoulder, const Color(0xFF00F5FF));
    _drawLine(canvas, size, paint,
        PoseLandmarkType.leftShoulder, PoseLandmarkType.leftElbow, const Color(0xFF00F5FF));
    _drawLine(canvas, size, paint,
        PoseLandmarkType.leftElbow, PoseLandmarkType.leftWrist, const Color(0xFF00F5FF));
    _drawLine(canvas, size, paint,
        PoseLandmarkType.rightShoulder, PoseLandmarkType.rightElbow, const Color(0xFF00F5FF));
    _drawLine(canvas, size, paint,
        PoseLandmarkType.rightElbow, PoseLandmarkType.rightWrist, const Color(0xFF00F5FF));

    // Hands
    _drawLine(canvas, size, paint,
        PoseLandmarkType.leftWrist, PoseLandmarkType.leftPinky, const Color(0xFF00F5FF));
    _drawLine(canvas, size, paint,
        PoseLandmarkType.leftWrist, PoseLandmarkType.leftIndex, const Color(0xFF00F5FF));
    _drawLine(canvas, size, paint,
        PoseLandmarkType.leftWrist, PoseLandmarkType.leftThumb, const Color(0xFF00F5FF));
    _drawLine(canvas, size, paint,
        PoseLandmarkType.rightWrist, PoseLandmarkType.rightPinky, const Color(0xFF00F5FF));
    _drawLine(canvas, size, paint,
        PoseLandmarkType.rightWrist, PoseLandmarkType.rightIndex, const Color(0xFF00F5FF));
    _drawLine(canvas, size, paint,
        PoseLandmarkType.rightWrist, PoseLandmarkType.rightThumb, const Color(0xFF00F5FF));

    // Torso
    _drawLine(canvas, size, paint,
        PoseLandmarkType.leftShoulder, PoseLandmarkType.leftHip, const Color(0xFF00F5FF));
    _drawLine(canvas, size, paint,
        PoseLandmarkType.rightShoulder, PoseLandmarkType.rightHip, const Color(0xFF00F5FF));
    _drawLine(canvas, size, paint,
        PoseLandmarkType.leftHip, PoseLandmarkType.rightHip, const Color(0xFF00F5FF));

    // Lower body - legs
    _drawLine(canvas, size, paint,
        PoseLandmarkType.leftHip, PoseLandmarkType.leftKnee, const Color(0xFF00F5FF));
    _drawLine(canvas, size, paint,
        PoseLandmarkType.leftKnee, PoseLandmarkType.leftAnkle, const Color(0xFF00F5FF));
    _drawLine(canvas, size, paint,
        PoseLandmarkType.rightHip, PoseLandmarkType.rightKnee, const Color(0xFF00F5FF));
    _drawLine(canvas, size, paint,
        PoseLandmarkType.rightKnee, PoseLandmarkType.rightAnkle, const Color(0xFF00F5FF));

    // Feet
    _drawLine(canvas, size, paint,
        PoseLandmarkType.leftAnkle, PoseLandmarkType.leftHeel, const Color(0xFF00F5FF));
    _drawLine(canvas, size, paint,
        PoseLandmarkType.leftAnkle, PoseLandmarkType.leftFootIndex, const Color(0xFF00F5FF));
    _drawLine(canvas, size, paint,
        PoseLandmarkType.rightAnkle, PoseLandmarkType.rightHeel, const Color(0xFF00F5FF));
    _drawLine(canvas, size, paint,
        PoseLandmarkType.rightAnkle, PoseLandmarkType.rightFootIndex, const Color(0xFF00F5FF));
  }

  /// Draw joints
  void _drawJoints(Canvas canvas, Size size, Paint paint) {
    final landmarks = pose!.landmarks;

    for (final entry in landmarks.entries) {
      final landmark = entry.value;
      
      // Skip low confidence landmarks
      if (landmark.likelihood < 0.5) continue;

      // Determine color based on confidence
      final color = landmark.likelihood > 0.8
          ? const Color(0xFF10B981) // Emerald - high confidence
          : Colors.amber; // Medium confidence

      // Check if this is the primary joint (to highlight)
      final isPrimary = primaryJoint != null && 
                       entry.key.toString().toLowerCase().contains(primaryJoint!.toLowerCase());

      final position = _getOffset(landmark, size);
      
      // Draw outer glow for primary joint
      if (isPrimary) {
        paint.color = color.withOpacity(0.3);
        canvas.drawCircle(position, 12.0, paint);
      }

      // Draw joint
      paint.color = color;
      canvas.drawCircle(position, isPrimary ? 8.0 : 6.0, paint);

      // Draw white center
      paint.color = Colors.white;
      canvas.drawCircle(position, isPrimary ? 3.0 : 2.0, paint);
    }
  }

  /// Draw line between two landmarks
  void _drawLine(
    Canvas canvas,
    Size size,
    Paint paint,
    PoseLandmarkType type1,
    PoseLandmarkType type2,
    Color color,
  ) {
    final landmark1 = pose!.landmarks[type1];
    final landmark2 = pose!.landmarks[type2];

    if (landmark1 == null || landmark2 == null) return;
    if (landmark1.likelihood < 0.5 || landmark2.likelihood < 0.5) return;

    final offset1 = _getOffset(landmark1, size);
    final offset2 = _getOffset(landmark2, size);

    // Use high confidence color or amber
    final avgConfidence = (landmark1.likelihood + landmark2.likelihood) / 2;
    paint.color = avgConfidence > 0.8 ? color : Colors.amber;

    canvas.drawLine(offset1, offset2, paint);
  }

  /// Get screen offset from landmark coordinates
  Offset _getOffset(PoseLandmark landmark, Size size) {
    // Scale from image coordinates to canvas coordinates
    double x = landmark.x * size.width / imageSize.width;
    final double y = landmark.y * size.height / imageSize.height;

    // Mirror X coordinate for front camera
    if (isFrontCamera) {
      x = size.width - x;
    }

    return Offset(x, y);
  }

  @override
  bool shouldRepaint(PosePainter oldDelegate) {
    // Only repaint if pose actually changed
    return oldDelegate.pose != pose ||
           oldDelegate.isFrontCamera != isFrontCamera ||
           oldDelegate.primaryJoint != primaryJoint;
  }
}
