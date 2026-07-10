import 'camera_state.dart';

class FeedbackMessage {
  final String text;
  final FeedbackSeverity severity;
  final String? voiceText;

  const FeedbackMessage({
    required this.text,
    required this.severity,
    this.voiceText,
  });
}

/// Engine for generating real-time form feedback
class FeedbackEngine {
  /// Generate feedback for current pose
  FeedbackMessage generate(
    Map<String, double> currentAngles,
    String exerciseId,
    RepPhase phase,
    List<Map<String, double>>? lastRepAngles,
  ) {
    // Priority order: distance > lighting > person detection > exercise form

    // Check for exercise-specific feedback
    switch (exerciseId.toLowerCase()) {
      case 'squat':
        return _squatFeedback(currentAngles, phase, lastRepAngles);
      case 'deadlift':
        return _deadliftFeedback(currentAngles, phase);
      case 'bench_press':
        return _benchPressFeedback(currentAngles, phase);
      case 'push_up':
        return _pushUpFeedback(currentAngles, phase);
      case 'pull_up':
        return _pullUpFeedback(currentAngles, phase);
      case 'overhead_press':
        return _overheadPressFeedback(currentAngles, phase);
      case 'bicep_curl':
        return _bicepCurlFeedback(currentAngles, phase);
      case 'lunges':
        return _lungesFeedback(currentAngles, phase);
      case 'plank':
        return _plankFeedback(currentAngles);
      default:
        return _genericFeedback(currentAngles, phase);
    }
  }

  FeedbackMessage _squatFeedback(
    Map<String, double> angles,
    RepPhase phase,
    List<Map<String, double>>? lastRepAngles,
  ) {
    // Check knee valgus (highest priority - safety)
    final leftValgus = angles['knee_valgus_left'] ?? 0.0;
    final rightValgus = angles['knee_valgus_right'] ?? 0.0;
    if (leftValgus > 0.05 || rightValgus > 0.05) {
      return const FeedbackMessage(
        text: 'Push your knees outward — they\'re caving in',
        severity: FeedbackSeverity.error,
        voiceText: 'Knees out',
      );
    }

    // Check spine angle
    final spineAngle = angles['spine_angle'] ?? 180.0;
    if (spineAngle < 130.0) {
      return const FeedbackMessage(
        text: 'Keep your chest up — you\'re leaning too far forward',
        severity: FeedbackSeverity.warning,
        voiceText: 'Chest up',
      );
    }

    // Check trunk lean
    final trunkLean = angles['trunk_lean'] ?? 0.0;
    if (trunkLean.abs() > 45.0) {
      return const FeedbackMessage(
        text: 'Reduce forward lean for better quad activation',
        severity: FeedbackSeverity.warning,
        voiceText: 'Less lean',
      );
    }

    // Check depth (only if we have last rep data)
    if (lastRepAngles != null && lastRepAngles.isNotEmpty && phase == RepPhase.lockout) {
      final minKnee = lastRepAngles
          .map((a) => (a['left_knee_flexion'] ?? 180.0))
          .reduce((a, b) => a < b ? a : b);
      if (minKnee > 110.0) {
        return const FeedbackMessage(
          text: 'Go deeper — aim for thighs parallel to the floor',
          severity: FeedbackSeverity.warning,
          voiceText: 'Go deeper',
        );
      }
    }

    // All good
    if (phase == RepPhase.lockout) {
      return const FeedbackMessage(
        text: 'Great squat — full lockout achieved',
        severity: FeedbackSeverity.good,
      );
    }

    return const FeedbackMessage(
      text: 'Good form — keep going',
      severity: FeedbackSeverity.good,
    );
  }

  FeedbackMessage _deadliftFeedback(Map<String, double> angles, RepPhase phase) {
    // Check spine angle during descent
    final spineAngle = angles['spine_angle'] ?? 180.0;
    if (spineAngle < 140.0 && phase == RepPhase.down) {
      return const FeedbackMessage(
        text: 'Maintain a neutral spine — avoid rounding your back',
        severity: FeedbackSeverity.error,
        voiceText: 'Neutral spine',
      );
    }

    // All good
    if (phase == RepPhase.lockout) {
      return const FeedbackMessage(
        text: 'Strong pull — excellent hip hinge',
        severity: FeedbackSeverity.good,
      );
    }

    return const FeedbackMessage(
      text: 'Good form — drive through your legs',
      severity: FeedbackSeverity.good,
    );
  }

  FeedbackMessage _benchPressFeedback(Map<String, double> angles, RepPhase phase) {
    // Check elbow symmetry
    final leftElbow = angles['left_elbow_extension'] ?? 180.0;
    final rightElbow = angles['right_elbow_extension'] ?? 180.0;
    final difference = (leftElbow - rightElbow).abs();
    
    if (difference > 15.0) {
      final laggingSide = leftElbow < rightElbow ? 'left' : 'right';
      return FeedbackMessage(
        text: 'Your $laggingSide side is lagging — focus on even pressing',
        severity: FeedbackSeverity.warning,
        voiceText: 'Even press',
      );
    }

    // Check shoulder elevation
    final shoulderElev = ((angles['left_shoulder_elevation'] ?? 0.0) + 
                         (angles['right_shoulder_elevation'] ?? 0.0)) / 2;
    if (shoulderElev > 60.0 && phase == RepPhase.up) {
      return const FeedbackMessage(
        text: 'Keep your shoulders packed — avoid shrugging',
        severity: FeedbackSeverity.warning,
        voiceText: 'Shoulders down',
      );
    }

    // All good
    if (phase == RepPhase.lockout) {
      return const FeedbackMessage(
        text: 'Smooth press — great control',
        severity: FeedbackSeverity.good,
      );
    }

    return const FeedbackMessage(
      text: 'Good form',
      severity: FeedbackSeverity.good,
    );
  }

  FeedbackMessage _pushUpFeedback(Map<String, double> angles, RepPhase phase) {
    final spineAngle = angles['spine_angle'] ?? 180.0;

    // Check for sagging hips
    if (spineAngle < 160.0) {
      return const FeedbackMessage(
        text: 'Keep your core tight — hips are dropping',
        severity: FeedbackSeverity.error,
        voiceText: 'Core tight',
      );
    }

    // Check for piking
    if (spineAngle > 200.0) {
      return const FeedbackMessage(
        text: 'Lower your hips — you\'re piking up',
        severity: FeedbackSeverity.warning,
        voiceText: 'Lower hips',
      );
    }

    // Check depth
    final elbowAngle = (angles['left_elbow_extension'] ?? 180.0);
    if (elbowAngle > 110.0 && phase == RepPhase.down) {
      return const FeedbackMessage(
        text: 'Lower your chest closer to the floor',
        severity: FeedbackSeverity.warning,
        voiceText: 'Lower chest',
      );
    }

    // All good
    if (phase == RepPhase.lockout) {
      return const FeedbackMessage(
        text: 'Perfect push-up form',
        severity: FeedbackSeverity.good,
      );
    }

    return const FeedbackMessage(
      text: 'Good form',
      severity: FeedbackSeverity.good,
    );
  }

  FeedbackMessage _pullUpFeedback(Map<String, double> angles, RepPhase phase) {
    // Check for swinging
    final spineAngle = angles['spine_angle'] ?? 180.0;
    if ((spineAngle - 180.0).abs() > 20.0) {
      return const FeedbackMessage(
        text: 'Keep your core engaged — avoid swinging',
        severity: FeedbackSeverity.warning,
        voiceText: 'No swing',
      );
    }

    // Check full extension at bottom
    final elbowAngle = (angles['left_elbow_extension'] ?? 180.0);
    if (elbowAngle < 150.0 && phase == RepPhase.lockout) {
      return const FeedbackMessage(
        text: 'Fully extend your arms at the bottom of each rep',
        severity: FeedbackSeverity.warning,
        voiceText: 'Full extension',
      );
    }

    // All good
    if (phase == RepPhase.down) {
      return const FeedbackMessage(
        text: 'Great pull — excellent range of motion',
        severity: FeedbackSeverity.good,
      );
    }

    return const FeedbackMessage(
      text: 'Good form',
      severity: FeedbackSeverity.good,
    );
  }

  FeedbackMessage _overheadPressFeedback(Map<String, double> angles, RepPhase phase) {
    // Check trunk lean
    final trunkLean = angles['trunk_lean'] ?? 0.0;
    if (trunkLean.abs() > 20.0) {
      return const FeedbackMessage(
        text: 'Keep your torso upright — avoid excessive lean back',
        severity: FeedbackSeverity.warning,
        voiceText: 'Stay upright',
      );
    }

    // Check neck angle
    final neckAngle = angles['neck_angle'] ?? 180.0;
    if (neckAngle < 160.0) {
      return const FeedbackMessage(
        text: 'Retract your chin slightly — avoid forward head posture',
        severity: FeedbackSeverity.warning,
        voiceText: 'Chin back',
      );
    }

    // All good
    if (phase == RepPhase.lockout) {
      return const FeedbackMessage(
        text: 'Strong press — full overhead extension',
        severity: FeedbackSeverity.good,
      );
    }

    return const FeedbackMessage(
      text: 'Good form',
      severity: FeedbackSeverity.good,
    );
  }

  FeedbackMessage _bicepCurlFeedback(Map<String, double> angles, RepPhase phase) {
    // Check shoulder elevation (swinging)
    final shoulderElev = (angles['left_shoulder_elevation'] ?? 0.0);
    if (shoulderElev > 30.0) {
      return const FeedbackMessage(
        text: 'Keep your elbows fixed — avoid swinging your shoulders',
        severity: FeedbackSeverity.error,
        voiceText: 'Elbows fixed',
      );
    }

    // Check trunk lean
    final trunkLean = angles['trunk_lean'] ?? 0.0;
    if (trunkLean.abs() > 15.0) {
      return const FeedbackMessage(
        text: 'Keep your torso upright — don\'t lean back',
        severity: FeedbackSeverity.warning,
        voiceText: 'Stay upright',
      );
    }

    // All good
    if (phase == RepPhase.lockout) {
      return const FeedbackMessage(
        text: 'Clean curl — elbows staying fixed',
        severity: FeedbackSeverity.good,
      );
    }

    return const FeedbackMessage(
      text: 'Good form',
      severity: FeedbackSeverity.good,
    );
  }

  FeedbackMessage _lungesFeedback(Map<String, double> angles, RepPhase phase) {
    // Check knee valgus on front leg
    final leftValgus = angles['knee_valgus_left'] ?? 0.0;
    final rightValgus = angles['knee_valgus_right'] ?? 0.0;
    if (leftValgus > 0.05 || rightValgus > 0.05) {
      return const FeedbackMessage(
        text: 'Keep your front knee aligned over your toes',
        severity: FeedbackSeverity.error,
        voiceText: 'Knee alignment',
      );
    }

    // All good
    if (phase == RepPhase.lockout) {
      return const FeedbackMessage(
        text: 'Great lunge — good knee alignment',
        severity: FeedbackSeverity.good,
      );
    }

    return const FeedbackMessage(
      text: 'Good form',
      severity: FeedbackSeverity.good,
    );
  }

  FeedbackMessage _plankFeedback(Map<String, double> angles) {
    final spineAngle = angles['spine_angle'] ?? 180.0;

    // Check for sagging
    if (spineAngle < 155.0) {
      return const FeedbackMessage(
        text: 'Lift your hips — your lower back is sagging',
        severity: FeedbackSeverity.error,
        voiceText: 'Lift hips',
      );
    }

    // Check for piking
    if (spineAngle > 200.0) {
      return const FeedbackMessage(
        text: 'Lower your hips — avoid piking',
        severity: FeedbackSeverity.warning,
        voiceText: 'Lower hips',
      );
    }

    // All good
    return const FeedbackMessage(
      text: 'Perfect plank — core is engaged',
      severity: FeedbackSeverity.good,
    );
  }

  FeedbackMessage _genericFeedback(Map<String, double> angles, RepPhase phase) {
    // Check elbow symmetry
    final leftElbow = angles['left_elbow_extension'] ?? 180.0;
    final rightElbow = angles['right_elbow_extension'] ?? 180.0;
    final difference = (leftElbow - rightElbow).abs();
    
    if (difference > 15.0) {
      return const FeedbackMessage(
        text: 'Keep both sides moving evenly',
        severity: FeedbackSeverity.warning,
        voiceText: 'Even movement',
      );
    }

    // Check spine
    final spineAngle = angles['spine_angle'] ?? 180.0;
    if (spineAngle < 140.0) {
      return const FeedbackMessage(
        text: 'Maintain a neutral spine',
        severity: FeedbackSeverity.warning,
        voiceText: 'Neutral spine',
      );
    }

    return const FeedbackMessage(
      text: 'Good form — keep it up',
      severity: FeedbackSeverity.good,
    );
  }
}
