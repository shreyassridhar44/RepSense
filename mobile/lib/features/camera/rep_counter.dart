import 'dart:math';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';

enum RepPhase { down, pause, up, lockout }

/// Calculates joint angles every frame and counts repetitions using
/// movement *phases* (down → pause → up → lockout) rather than naive
/// per-frame classification, per the technical specification.
class RepCounter {
  RepPhase _phase = RepPhase.lockout;
  int reps = 0;
  double lastKneeAngle = 180;

  // Thresholds tuned for a squat-style movement; swap per exercise.
  static const double downThreshold = 110;
  static const double upThreshold = 160;

  /// Returns the updated angle (degrees) at the knee, using hip-knee-ankle.
  double? kneeAngle(Pose pose, {bool left = true}) {
    final hip = pose.landmarks[left ? PoseLandmarkType.leftHip : PoseLandmarkType.rightHip];
    final knee = pose.landmarks[left ? PoseLandmarkType.leftKnee : PoseLandmarkType.rightKnee];
    final ankle = pose.landmarks[left ? PoseLandmarkType.leftAnkle : PoseLandmarkType.rightAnkle];
    if (hip == null || knee == null || ankle == null) return null;
    return _angleBetween(hip.x, hip.y, knee.x, knee.y, ankle.x, ankle.y);
  }

  double _angleBetween(double ax, double ay, double bx, double by, double cx, double cy) {
    final v1 = Point(ax - bx, ay - by);
    final v2 = Point(cx - bx, cy - by);
    final dot = v1.x * v2.x + v1.y * v2.y;
    final mag1 = sqrt(v1.x * v1.x + v1.y * v1.y);
    final mag2 = sqrt(v2.x * v2.x + v2.y * v2.y);
    if (mag1 == 0 || mag2 == 0) return 180;
    final cosAngle = (dot / (mag1 * mag2)).clamp(-1.0, 1.0);
    return acos(cosAngle) * 180 / pi;
  }

  /// Feed a new frame's knee angle through the phase state machine.
  /// Returns true exactly when a full repetition completes.
  bool update(double angle) {
    lastKneeAngle = angle;
    bool completed = false;

    switch (_phase) {
      case RepPhase.lockout:
        if (angle < downThreshold) _phase = RepPhase.down;
        break;
      case RepPhase.down:
        _phase = RepPhase.pause;
        break;
      case RepPhase.pause:
        if (angle > downThreshold) _phase = RepPhase.up;
        break;
      case RepPhase.up:
        if (angle > upThreshold) {
          _phase = RepPhase.lockout;
          reps++;
          completed = true;
        }
        break;
    }
    return completed;
  }

  void reset() {
    reps = 0;
    _phase = RepPhase.lockout;
  }
}
