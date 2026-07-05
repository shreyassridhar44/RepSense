import 'package:equatable/equatable.dart';

enum ProfileSetupStep { personalInfo, measurements, experience, goals }

enum BiologicalSex { male, female, preferNotToSay }

enum TrainingExperience { beginner, intermediate, advanced, elite }

enum FitnessGoal {
  buildMuscle,
  loseFat,
  improveStrength,
  improveFlexibility,
  athleticPerformance,
  injuryRehabilitation,
  generalFitness,
}

class ProfileSetupState extends Equatable {
  final ProfileSetupStep currentStep;
  final bool isLoading;
  final String? errorMessage;
  
  // Step 1: Personal Info
  final String? displayName;
  final DateTime? dateOfBirth;
  final BiologicalSex? biologicalSex;
  
  // Step 2: Measurements
  final double? heightCm;
  final double? weightKg;
  final bool useMetric;
  
  // Step 3: Experience
  final TrainingExperience? trainingExperience;
  
  // Step 4: Goals
  final Set<FitnessGoal> selectedGoals;

  const ProfileSetupState({
    this.currentStep = ProfileSetupStep.personalInfo,
    this.isLoading = false,
    this.errorMessage,
    this.displayName,
    this.dateOfBirth,
    this.biologicalSex,
    this.heightCm,
    this.weightKg,
    this.useMetric = true,
    this.trainingExperience,
    this.selectedGoals = const {},
  });

  ProfileSetupState copyWith({
    ProfileSetupStep? currentStep,
    bool? isLoading,
    String? errorMessage,
    String? displayName,
    DateTime? dateOfBirth,
    BiologicalSex? biologicalSex,
    double? heightCm,
    double? weightKg,
    bool? useMetric,
    TrainingExperience? trainingExperience,
    Set<FitnessGoal>? selectedGoals,
  }) {
    return ProfileSetupState(
      currentStep: currentStep ?? this.currentStep,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      displayName: displayName ?? this.displayName,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      biologicalSex: biologicalSex ?? this.biologicalSex,
      heightCm: heightCm ?? this.heightCm,
      weightKg: weightKg ?? this.weightKg,
      useMetric: useMetric ?? this.useMetric,
      trainingExperience: trainingExperience ?? this.trainingExperience,
      selectedGoals: selectedGoals ?? this.selectedGoals,
    );
  }

  bool get isStep1Valid =>
      displayName != null &&
      displayName!.isNotEmpty &&
      dateOfBirth != null &&
      biologicalSex != null;

  bool get isStep2Valid =>
      heightCm != null &&
      heightCm! >= 50 &&
      heightCm! <= 300 &&
      weightKg != null &&
      weightKg! >= 20 &&
      weightKg! <= 500;

  bool get isStep3Valid => trainingExperience != null;

  bool get isStep4Valid => selectedGoals.isNotEmpty;

  bool get canContinue {
    switch (currentStep) {
      case ProfileSetupStep.personalInfo:
        return isStep1Valid;
      case ProfileSetupStep.measurements:
        return isStep2Valid;
      case ProfileSetupStep.experience:
        return isStep3Valid;
      case ProfileSetupStep.goals:
        return isStep4Valid;
    }
  }

  @override
  List<Object?> get props => [
        currentStep,
        isLoading,
        errorMessage,
        displayName,
        dateOfBirth,
        biologicalSex,
        heightCm,
        weightKg,
        useMetric,
        trainingExperience,
        selectedGoals,
      ];
}
