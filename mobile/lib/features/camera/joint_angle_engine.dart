import 'dart:math';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';

/// Engine for computing joint angles from pose landmarks
class JointAngleEngine {
  /// Compute all relevant joint angles from a pose
  Map<String, double> compute(Pose pose) {
    final landmarks = pose.landmarks;
    final angles = <String, double>{};

    // Left side angles
    angles['left_knee_flexion'] = _computeKneeFlexion(
      landmarks[PoseLandmarkType.leftHip],
      landmarks[PoseLandmarkType.leftKnee],
      landmarks[PoseLandmarkType.leftAnkle],
    );

    angles['left_hip_flexion'] = _computeHipFlexion(
      landmarks[PoseLandmarkType.leftShoulder],
      landmarks[PoseLandmarkType.leftHip],
      landmarks[PoseLandmarkType.leftKnee],
    );

    angles['left_elbow_extension'] = _computeElbowExtension(
      landmarks[PoseLandmarkType.leftShoulder],
      landmarks[PoseLandmarkType.leftElbow],
      landmarks[PoseLandmarkType.leftWrist],
    );

    angles['left_shoulder_elevation'] = _computeShoulderElevation(
      landmarks[PoseLandmarkType.leftHip],
      landmarks[PoseLandmarkType.leftShoulder],
      landmarks[PoseLandmarkType.leftElbow],
    );

    angles['left_ankle_dorsiflexion'] = _computeAnkleDorsiflexion(
      landmarks[PoseLandmarkType.leftKnee],
      landmarks[PoseLandmarkType.leftAnkle],
      landmarks[PoseLandmarkType.leftFootIndex],
    );

    // Right side angles
    angles['right_knee_flexion'] = _computeKneeFlexion(
      landmarks[PoseLandmarkType.rightHip],
      landmarks[PoseLandmarkType.rightKnee],
      landmarks[PoseLandmarkType.rightAnkle],
    );

    angles['right_hip_flexion'] = _computeHipFlexion(
      landmarks[PoseLandmarkType.rightShoulder],
      landmarks[PoseLandmarkType.rightHip],
      landmarks[PoseLandmarkType.rightKnee],
    );

    angles['right_elbow_extension'] = _computeElbowExtension(
      landmarks[PoseLandmarkType.rightShoulder],
      landmarks[PoseLandmarkType.rightElbow],
      landmarks[PoseLandmarkType.rightWrist],
    );

    angles['right_shoulder_elevation'] = _computeShoulderElevation(
      landmarks[PoseLandmarkType.rightHip],
      landmarks[PoseLandmarkType.rightShoulder],
      landmarks[PoseLandmarkType.rightElbow],
    );

    angles['right_ankle_dorsiflexion'] = _computeAnkleDorsiflexion(
      landmarks[PoseLandmarkType.rightKnee],
      landmarks[PoseLandmarkType.rightAnkle],
      landmarks[PoseLandmarkType.rightFootIndex],
    );

    // Spine and trunk angles
    angles['spine_angle'] = _computeSpineAngle(
      landmarks[PoseLandmarkType.leftShoulder],
      landmarks[PoseLandmarkType.rightShoulder],
      landmarks[PoseLandmarkType.leftHip],
      landmarks[PoseLandmarkType.rightHip],
    );

    angles['trunk_lean'] = _computeTrunkLean(
      landmarks[PoseLandmarkType.leftShoulder],
      landmarks[PoseLandmarkType.rightShoulder],
      landmarks[PoseLandmarkType.leftHip],
      landmarks[PoseLandmarkType.rightHip],
    );

    angles['neck_angle'] = _computeNeckAngle(
      landmarks[PoseLandmarkType.nose],
      landmarks[PoseLandmarkType.leftShoulder],
      landmarks[PoseLandmarkType.rightShoulder],
    );

    // Knee valgus (knee caving)
    angles['knee_valgus_left'] = _computeKneeValgus(
      landmarks[PoseLandmarkType.leftHip],
      landmarks[PoseLandmarkType.leftKnee],
      landmarks[PoseLandmarkType.leftAnkle],
    );

    angles['knee_valgus_right'] = _computeKneeValgus(
      landmarks[PoseLandmarkType.rightHip],
      landmarks[PoseLandmarkType.rightKnee],
      landmarks[PoseLandmarkType.rightAnkle],
    );

    return angles;
  }

  /// Compute angle between three points (angle at vertex b)
  double _angleBetweenThreePoints(
    PoseLandmark? a,
    PoseLandmark? b,
    PoseLandmark? c,
  ) {
    // Return 180° if any landmark is missing or has low confidence
    if (a == null || b == null || c == null) return 180.0;
    if (a.likelihood < 0.3 || b.likelihood < 0.3 || c.likelihood < 0.3) {
      return 180.0;
    }

    // Create vectors b→a and b→c
    final double ba_x = a.x - b.x;
    final double ba_y = a.y - b.y;
    final double ba_z = a.z - b.z;

    final double bc_x = c.x - b.x;
    final double bc_y = c.y - b.y;
    final double bc_z = c.z - b.z;

    // Compute dot product
    final double dotProduct = ba_x * bc_x + ba_y * bc_y + ba_z * bc_z;

    // Compute magnitudes
    final double magnitudeBA = sqrt(ba_x * ba_x + ba_y * ba_y + ba_z * ba_z);
    final double magnitudeBC = sqrt(bc_x * bc_x + bc_y * bc_y + bc_z * bc_z);

    // Avoid division by zero
    if (magnitudeBA == 0 || magnitudeBC == 0) return 180.0;

    // Compute angle using dot product formula: cos(θ) = (v1 · v2) / (|v1| |v2|)
    double cosTheta = dotProduct / (magnitudeBA * magnitudeBC);
    
    // Clamp to [-1, 1] to handle floating point errors
    cosTheta = cosTheta.clamp(-1.0, 1.0);

    // Convert to degrees
    final double angleRadians = acos(cosTheta);
    final double angleDegrees = angleRadians * 180 / pi;

    return angleDegrees;
  }

  // Specific joint angle computations
  double _computeKneeFlexion(PoseLandmark? hip, PoseLandmark? knee, PoseLandmark? ankle) {
    return _angleBetweenThreePoints(hip, knee, ankle);
  }

  double _computeHipFlexion(PoseLandmark? shoulder, PoseLandmark? hip, PoseLandmark? knee) {
    return _angleBetweenThreePoints(shoulder, hip, knee);
  }

  double _computeElbowExtension(PoseLandmark? shoulder, PoseLandmark? elbow, PoseLandmark? wrist) {
    return _angleBetweenThreePoints(shoulder, elbow, wrist);
  }

  double _computeShoulderElevation(PoseLandmark? hip, PoseLandmark? shoulder, PoseLandmark? elbow) {
    return _angleBetweenThreePoints(hip, shoulder, elbow);
  }

  double _computeAnkleDorsiflexion(PoseLandmark? knee, PoseLandmark? ankle, PoseLandmark? foot) {
    return _angleBetweenThreePoints(knee, ankle, foot);
  }

  /// Compute spine angle (angle from vertical)
  double _computeSpineAngle(
    PoseLandmark? leftShoulder,
    PoseLandmark? rightShoulder,
    PoseLandmark? leftHip,
    PoseLandmark? rightHip,
  ) {
    if (leftShoulder == null || rightShoulder == null || 
        leftHip == null || rightHip == null) {
      return 180.0;
    }

    // Compute midpoints
    final double shoulderX = (leftShoulder.x + rightShoulder.x) / 2;
    final double shoulderY = (leftShoulder.y + rightShoulder.y) / 2;
    final double hipX = (leftHip.x + rightHip.x) / 2;
    final double hipY = (leftHip.y + rightHip.y) / 2;

    // Compute angle from vertical (Y-axis)
    final double dx = shoulderX - hipX;
    final double dy = shoulderY - hipY;
    
    if (dy == 0) return 180.0;

    // Angle from vertical
    final double angleRadians = atan2(dx.abs(), dy.abs());
    final double angleDegrees = angleRadians * 180 / pi;

    // Return as angle from vertical (0° = perfectly vertical, 90° = horizontal)
    // Convert to spine angle where 180° = perfectly straight
    return 180.0 - angleDegrees;
  }

  /// Compute trunk lean (forward lean angle)
  double _computeTrunkLean(
    PoseLandmark? leftShoulder,
    PoseLandmark? rightShoulder,
    PoseLandmark? leftHip,
    PoseLandmark? rightHip,
  ) {
    if (leftShoulder == null || rightShoulder == null || 
        leftHip == null || rightHip == null) {
      return 0.0;
    }

    // Compute midpoints
    final double shoulderX = (leftShoulder.x + rightShoulder.x) / 2;
    final double shoulderY = (leftShoulder.y + rightShoulder.y) / 2;
    final double hipX = (leftHip.x + rightHip.x) / 2;
    final double hipY = (leftHip.y + rightHip.y) / 2;

    // Compute forward lean angle
    final double dx = shoulderX - hipX;
    final double dy = shoulderY - hipY;
    
    if (dy == 0) return 0.0;

    final double angleRadians = atan2(dx, dy);
    return angleRadians * 180 / pi;
  }

  /// Compute neck angle
  double _computeNeckAngle(
    PoseLandmark? nose,
    PoseLandmark? leftShoulder,
    PoseLandmark? rightShoulder,
  ) {
    if (nose == null || leftShoulder == null || rightShoulder == null) {
      return 180.0;
    }

    // Compute shoulder midpoint
    final double shoulderX = (leftShoulder.x + rightShoulder.x) / 2;
    final double shoulderY = (leftShoulder.y + rightShoulder.y) / 2;

    // Compute angle
    final double dx = nose.x - shoulderX;
    final double dy = nose.y - shoulderY;
    
    if (dy == 0) return 180.0;

    final double angleRadians = atan2(dx.abs(), dy.abs());
    return (angleRadians * 180 / pi).abs();
  }

  /// Compute knee valgus (lateral deviation - knee caving)
  double _computeKneeValgus(
    PoseLandmark? hip,
    PoseLandmark? knee,
    PoseLandmark? ankle,
  ) {
    if (hip == null || knee == null || ankle == null) return 0.0;
    if (hip.likelihood < 0.5 || knee.likelihood < 0.5 || ankle.likelihood < 0.5) {
      return 0.0;
    }

    // Compute the horizontal (X) offset of knee relative to hip-ankle line
    // Positive = knee caving inward
    final double hipAnkleX = ankle.x - hip.x;
    final double hipAnkleY = ankle.y - hip.y;
    final double hipKneeX = knee.x - hip.x;
    final double hipKneeY = knee.y - hip.y;

    // If hip and ankle are at same position, no valgus
    if (hipAnkleX == 0 && hipAnkleY == 0) return 0.0;

    // Project knee onto hip-ankle line
    final double t = (hipKneeX * hipAnkleX + hipKneeY * hipAnkleY) /
        (hipAnkleX * hipAnkleX + hipAnkleY * hipAnkleY);
    
    final double projX = hip.x + t * hipAnkleX;
    
    // Lateral deviation (normalized)
    final double lateralDeviation = (knee.x - projX).abs();
    
    return lateralDeviation;
  }
}
