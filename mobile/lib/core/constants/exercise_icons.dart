import 'package:flutter/material.dart';

class ExerciseIcons {
  ExerciseIcons._();

  static const Map<String, IconData> icons = {
    'squat': Icons.accessibility_new_rounded,
    'deadlift': Icons.fitness_center_rounded,
    'bench_press': Icons.airline_seat_flat_rounded,
    'push_up': Icons.self_improvement_rounded,
    'pull_up': Icons.upgrade_rounded,
    'overhead_press': Icons.arrow_upward_rounded,
    'lunges': Icons.directions_walk_rounded,
    'bicep_curl': Icons.sports_gymnastics_rounded,
    'tricep_extension': Icons.back_hand_rounded,
    'rows': Icons.rowing_rounded,
    'lat_pulldown': Icons.vertical_align_bottom_rounded,
    'leg_press': Icons.chair_rounded,
    'plank': Icons.horizontal_rule_rounded,
    'shoulder_press': Icons.keyboard_double_arrow_up_rounded,
  };

  static IconData getIcon(String exerciseId) {
    return icons[exerciseId] ?? Icons.fitness_center_rounded;
  }
}
