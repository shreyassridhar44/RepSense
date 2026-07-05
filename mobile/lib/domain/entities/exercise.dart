import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import '../../core/constants/exercise_icons.dart';
import '../../core/theme/app_colors.dart';

class Exercise extends Equatable {
  final String id;
  final String name;
  final List<String> muscleGroups;
  final String difficulty;
  final String? equipment;
  final String? description;
  final String? primaryMuscle;
  final List<String> secondaryMuscles;
  final List<String> commonMistakes;
  final List<String> instructions;
  final List<String> benefits;
  final double metValue;
  final bool isFavorited;

  const Exercise({
    required this.id,
    required this.name,
    required this.muscleGroups,
    required this.difficulty,
    this.equipment,
    this.description,
    this.primaryMuscle,
    this.secondaryMuscles = const [],
    this.commonMistakes = const [],
    this.instructions = const [],
    this.benefits = const [],
    this.metValue = 5.0,
    this.isFavorited = false,
  });

  // Difficulty color mapping
  Color get difficultyColor {
    switch (difficulty.toLowerCase()) {
      case 'beginner':
        return AppColors.emerald;
      case 'intermediate':
        return AppColors.amber;
      case 'advanced':
        return AppColors.error;
      default:
        return AppColors.textSecondary;
    }
  }

  // Exercise icon mapping
  IconData get icon => ExerciseIcons.getIcon(id);

  Exercise copyWith({
    String? id,
    String? name,
    List<String>? muscleGroups,
    String? difficulty,
    String? equipment,
    String? description,
    String? primaryMuscle,
    List<String>? secondaryMuscles,
    List<String>? commonMistakes,
    List<String>? instructions,
    List<String>? benefits,
    double? metValue,
    bool? isFavorited,
  }) {
    return Exercise(
      id: id ?? this.id,
      name: name ?? this.name,
      muscleGroups: muscleGroups ?? this.muscleGroups,
      difficulty: difficulty ?? this.difficulty,
      equipment: equipment ?? this.equipment,
      description: description ?? this.description,
      primaryMuscle: primaryMuscle ?? this.primaryMuscle,
      secondaryMuscles: secondaryMuscles ?? this.secondaryMuscles,
      commonMistakes: commonMistakes ?? this.commonMistakes,
      instructions: instructions ?? this.instructions,
      benefits: benefits ?? this.benefits,
      metValue: metValue ?? this.metValue,
      isFavorited: isFavorited ?? this.isFavorited,
    );
  }

  @override
  List<Object?> get props => [
        id,
        name,
        muscleGroups,
        difficulty,
        equipment,
        description,
        primaryMuscle,
        secondaryMuscles,
        commonMistakes,
        instructions,
        benefits,
        metValue,
        isFavorited,
      ];
}
