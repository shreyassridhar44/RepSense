import '../../domain/entities/exercise.dart';

class ExerciseModel {
  static Exercise fromJson(Map<String, dynamic> json, {bool isFavorited = false}) {
    return Exercise(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? 'Unknown Exercise',
      muscleGroups: _parseStringList(json['muscle_groups']),
      difficulty: json['difficulty'] as String? ?? 'Beginner',
      equipment: json['equipment'] as String?,
      description: json['description'] as String?,
      primaryMuscle: json['primary_muscle'] as String?,
      secondaryMuscles: _parseStringList(json['secondary_muscles']),
      commonMistakes: _parseStringList(json['common_mistakes']),
      instructions: _parseStringList(json['instructions']),
      benefits: _parseStringList(json['benefits']),
      metValue: _parseDouble(json['met_value']),
      isFavorited: isFavorited,
    );
  }

  static Map<String, dynamic> toJson(Exercise exercise) {
    return {
      'id': exercise.id,
      'name': exercise.name,
      'muscle_groups': exercise.muscleGroups,
      'difficulty': exercise.difficulty,
      'equipment': exercise.equipment,
      'description': exercise.description,
      'primary_muscle': exercise.primaryMuscle,
      'secondary_muscles': exercise.secondaryMuscles,
      'common_mistakes': exercise.commonMistakes,
      'instructions': exercise.instructions,
      'benefits': exercise.benefits,
      'met_value': exercise.metValue,
    };
  }

  static List<String> _parseStringList(dynamic value) {
    if (value == null) return [];
    if (value is List) {
      return value.map((e) => e.toString()).toList();
    }
    return [];
  }

  static double _parseDouble(dynamic value) {
    if (value == null) return 5.0;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 5.0;
    return 5.0;
  }
}
