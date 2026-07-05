import 'camera_state.dart';

/// Per-exercise configuration for rep counting
class ExerciseConfig {
  final String primaryAngleKey;
  final double downThreshold;
  final double upThreshold;
  final bool useSymmetry; // Average left and right sides
  final bool isTimerBased; // For plank
  final double? minHoldSeconds; // For plank

  const ExerciseConfig({
    required this.primaryAngleKey,
    required this.downThreshold,
    required this.upThreshold,
    this.useSymmetry = false,
    this.isTimerBased = false,
    this.minHoldSeconds,
  });
}

/// Rep counter with per-exercise phase detection
class RepCounter {
  String _currentExerciseId = '';
  RepPhase _phase = RepPhase.lockout;
  int _reps = 0;
  DateTime? _phaseStartTime;
  DateTime? _plankStartTime;

  static const double _minRepDuration = 0.5; // 500ms minimum per rep

  /// Exercise-specific configurations
  static const Map<String, ExerciseConfig> _configs = {
    'squat': ExerciseConfig(
      primaryAngleKey: 'knee_flexion',
      downThreshold: 100,
      upThreshold: 160,
      useSymmetry: true,
    ),
    'deadlift': ExerciseConfig(
      primaryAngleKey: 'hip_flexion',
      downThreshold: 70,
      upThreshold: 160,
      useSymmetry: true,
    ),
    'bench-press': ExerciseConfig(
      primaryAngleKey: 'elbow_extension',
      downThreshold: 80,
      upThreshold: 155,
      useSymmetry: true,
    ),
    'push-up': ExerciseConfig(
      primaryAngleKey: 'elbow_extension',
      downThreshold: 90,
      upThreshold: 155,
      useSymmetry: true,
    ),
    'pull-up': ExerciseConfig(
      primaryAngleKey: 'elbow_extension',
      downThreshold: 75, // Inverted: down is extended
      upThreshold: 155, // Up is flexed
      useSymmetry: true,
    ),
    'overhead-press': ExerciseConfig(
      primaryAngleKey: 'elbow_extension',
      downThreshold: 90,
      upThreshold: 165,
      useSymmetry: true,
    ),
    'lunges': ExerciseConfig(
      primaryAngleKey: 'knee_flexion',
      downThreshold: 95,
      upThreshold: 160,
      useSymmetry: true,
    ),
    'bicep-curl': ExerciseConfig(
      primaryAngleKey: 'elbow_extension',
      downThreshold: 55,
      upThreshold: 155,
      useSymmetry: true,
    ),
    'tricep-extension': ExerciseConfig(
      primaryAngleKey: 'elbow_extension',
      downThreshold: 80,
      upThreshold: 155,
      useSymmetry: true,
    ),
    'rows': ExerciseConfig(
      primaryAngleKey: 'elbow_extension',
      downThreshold: 80,
      upThreshold: 150,
      useSymmetry: true,
    ),
    'lat-pulldown': ExerciseConfig(
      primaryAngleKey: 'elbow_extension',
      downThreshold: 80,
      upThreshold: 155,
      useSymmetry: true,
    ),
    'leg-press': ExerciseConfig(
      primaryAngleKey: 'knee_flexion',
      downThreshold: 90,
      upThreshold: 160,
      useSymmetry: true,
    ),
    'plank': ExerciseConfig(
      primaryAngleKey: 'spine_angle',
      downThreshold: 160,
      upThreshold: 180,
      isTimerBased: true,
      minHoldSeconds: 30.0,
    ),
    'shoulder-press': ExerciseConfig(
      primaryAngleKey: 'elbow_extension',
      downThreshold: 90,
      upThreshold: 165,
      useSymmetry: true,
    ),
  };

  int get reps => _reps;
  RepPhase get phase => _phase;

  /// Initialize for a specific exercise
  void initialize(String exerciseId) {
    _currentExerciseId = exerciseId;
    reset();
  }

  /// Reset counter state
  void reset() {
    _reps = 0;
    _phase = RepPhase.lockout;
    _phaseStartTime = DateTime.now();
    _plankStartTime = null;
  }

  /// Update with new angle data
  /// Returns true when a rep is completed
  bool update(Map<String, double> angles) {
    final config = _configs[_currentExerciseId];
    if (config == null) return false;

    // Special handling for plank (timer-based)
    if (config.isTimerBased) {
      return _updatePlank(angles, config);
    }

    // Get primary angle (average left/right if needed)
    final angle = _getPrimaryAngle(angles, config);
    if (angle == null) return false;

    return _updatePhase(angle, config);
  }

  /// Get primary angle for the exercise
  double? _getPrimaryAngle(Map<String, double> angles, ExerciseConfig config) {
    if (!config.useSymmetry) {
      return angles[config.primaryAngleKey];
    }

    // Average left and right sides
    final leftKey = 'left_${config.primaryAngleKey}';
    final rightKey = 'right_${config.primaryAngleKey}';
    
    final leftAngle = angles[leftKey];
    final rightAngle = angles[rightKey];

    if (leftAngle == null && rightAngle == null) return null;
    if (leftAngle == null) return rightAngle;
    if (rightAngle == null) return leftAngle;

    return (leftAngle + rightAngle) / 2;
  }

  /// Update phase state machine
  bool _updatePhase(double angle, ExerciseConfig config) {
    final now = DateTime.now();
    bool completed = false;

    // Check minimum rep duration
    if (_phaseStartTime != null) {
      final phaseDuration = now.difference(_phaseStartTime!).inMilliseconds / 1000;
      if (phaseDuration < _minRepDuration && _phase != RepPhase.lockout) {
        return false; // Too fast, ignore
      }
    }

    // Handle pull-up (inverted logic)
    final bool isPullUp = _currentExerciseId == 'pull-up';
    final effectiveAngle = isPullUp ? 180 - angle : angle;
    final effectiveDown = isPullUp ? 180 - config.upThreshold : config.downThreshold;
    final effectiveUp = isPullUp ? 180 - config.downThreshold : config.upThreshold;

    switch (_phase) {
      case RepPhase.lockout:
        if (effectiveAngle < effectiveDown) {
          _phase = RepPhase.down;
          _phaseStartTime = now;
        }
        break;

      case RepPhase.down:
        // Stay in down phase briefly
        if (now.difference(_phaseStartTime!).inMilliseconds > 100) {
          _phase = RepPhase.pause;
        }
        break;

      case RepPhase.pause:
        if (effectiveAngle > effectiveDown) {
          _phase = RepPhase.up;
          _phaseStartTime = now;
        }
        break;

      case RepPhase.up:
        if (effectiveAngle > effectiveUp) {
          _phase = RepPhase.lockout;
          _phaseStartTime = now;
          _reps++;
          completed = true;
        }
        break;
    }

    return completed;
  }

  /// Update plank (timer-based)
  bool _updatePlank(Map<String, double> angles, ExerciseConfig config) {
    final spineAngle = angles['spine_angle'];
    if (spineAngle == null) return false;

    final now = DateTime.now();
    final isGoodForm = spineAngle >= config.downThreshold && 
                       spineAngle <= config.upThreshold;

    if (isGoodForm) {
      _plankStartTime ??= now;
      
      final holdDuration = now.difference(_plankStartTime!).inSeconds;
      if (holdDuration >= (config.minHoldSeconds ?? 30)) {
        // Complete one "rep" every 30 seconds of good plank
        _reps++;
        _plankStartTime = now; // Reset timer for next rep
        return true;
      }
    } else {
      _plankStartTime = null; // Reset if form breaks
    }

    return false;
  }

  /// Get current exercise configuration
  ExerciseConfig? getConfig() {
    return _configs[_currentExerciseId];
  }
}
