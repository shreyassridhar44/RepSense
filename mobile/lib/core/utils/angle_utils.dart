import 'app_logger.dart';

/// Utility functions for handling angle sequences
class AngleUtils {
  AngleUtils._();

  /// Subsample angle sequence if it's too large
  static List<Map<String, double>> subsampleAngles(
    List<Map<String, double>> angles, {
    int maxFrames = 1500,
  }) {
    if (angles.length <= maxFrames) {
      return angles;
    }

    AppLogger.info(
      '⚙️ Subsampling ${angles.length} frames to $maxFrames',
    );

    final step = angles.length / maxFrames;
    return List.generate(
      maxFrames,
      (i) => angles[(i * step).floor()],
    );
  }

  /// Estimate payload size in KB
  static int estimatePayloadSizeKB(List<Map<String, double>> angles) {
    // Each frame has ~15 angle values × 8 bytes = 120 bytes
    // Add overhead for JSON structure
    final estimatedBytes = angles.length * 120;
    final estimatedKB = (estimatedBytes / 1024).ceil();

    if (estimatedKB > 500) {
      AppLogger.warning(
        '⚠️ Large payload estimated: ${estimatedKB}KB',
      );
    }

    return estimatedKB;
  }
}
