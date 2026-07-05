import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/strings.dart';
import '../../core/utils/app_logger.dart';
import '../../data/supabase/supabase_service.dart';
import '../auth/auth_provider.dart';
import 'profile_setup_state.dart';

class ProfileSetupController extends StateNotifier<ProfileSetupState> {
  ProfileSetupController(this.ref) : super(const ProfileSetupState());

  final Ref ref;
  final _service = SupabaseService.instance;

  void setDisplayName(String name) {
    state = state.copyWith(displayName: name);
  }

  void setDateOfBirth(DateTime date) {
    state = state.copyWith(dateOfBirth: date);
  }

  void setBiologicalSex(BiologicalSex sex) {
    state = state.copyWith(biologicalSex: sex);
  }

  void setHeight(double heightCm) {
    state = state.copyWith(heightCm: heightCm);
  }

  void setWeight(double weightKg) {
    state = state.copyWith(weightKg: weightKg);
  }

  void toggleUnit() {
    state = state.copyWith(useMetric: !state.useMetric);
  }

  void setTrainingExperience(TrainingExperience experience) {
    state = state.copyWith(trainingExperience: experience);
  }

  void toggleGoal(FitnessGoal goal) {
    final newGoals = Set<FitnessGoal>.from(state.selectedGoals);
    if (newGoals.contains(goal)) {
      newGoals.remove(goal);
    } else {
      newGoals.add(goal);
    }
    state = state.copyWith(selectedGoals: newGoals);
  }

  bool validateAge(DateTime birthDate) {
    final now = DateTime.now();
    final age = now.year - birthDate.year;
    if (now.month < birthDate.month ||
        (now.month == birthDate.month && now.day < birthDate.day)) {
      return age - 1 >= 13;
    }
    return age >= 13;
  }

  void nextStep() {
    if (!state.canContinue) return;

    final nextStep = ProfileSetupStep.values[state.currentStep.index + 1];
    state = state.copyWith(currentStep: nextStep);
    AppLogger.debug('📝 Profile setup: moved to step ${nextStep.name}');
  }

  void previousStep() {
    if (state.currentStep == ProfileSetupStep.personalInfo) return;

    final prevStep = ProfileSetupStep.values[state.currentStep.index - 1];
    state = state.copyWith(currentStep: prevStep);
    AppLogger.debug('📝 Profile setup: moved back to step ${prevStep.name}');
  }

  String _experienceToString(TrainingExperience experience) {
    switch (experience) {
      case TrainingExperience.beginner:
        return 'Beginner';
      case TrainingExperience.intermediate:
        return 'Intermediate';
      case TrainingExperience.advanced:
        return 'Advanced';
      case TrainingExperience.elite:
        return 'Elite';
    }
  }

  String _goalToString(FitnessGoal goal) {
    switch (goal) {
      case FitnessGoal.buildMuscle:
        return 'Build Muscle';
      case FitnessGoal.loseFat:
        return 'Lose Fat';
      case FitnessGoal.improveStrength:
        return 'Improve Strength';
      case FitnessGoal.improveFlexibility:
        return 'Improve Flexibility';
      case FitnessGoal.athleticPerformance:
        return 'Athletic Performance';
      case FitnessGoal.injuryRehabilitation:
        return 'Injury Rehabilitation';
      case FitnessGoal.generalFitness:
        return 'General Fitness';
    }
  }

  Future<bool> saveProfile() async {
    if (!state.canContinue) {
      AppLogger.warning('⚠️ Attempted to save incomplete profile');
      return false;
    }

    state = state.copyWith(isLoading: true, errorMessage: null);
    AppLogger.info('💾 Saving profile to Supabase');

    try {
      final user = _service.currentUser;
      if (user == null) {
        throw Exception('No authenticated user');
      }

      final profileData = {
        'id': user.id,
        'display_name': state.displayName!.trim(),
        'height_cm': state.heightCm!,
        'weight_kg': state.weightKg!,
        'training_experience': _experienceToString(state.trainingExperience!),
        'preferred_units': state.useMetric ? 'metric' : 'imperial',
        'goals': state.selectedGoals.map(_goalToString).toList(),
      };

      AppLogger.debug('📝 Profile data: $profileData');

      await _service.upsertProfile(profileData);

      state = state.copyWith(isLoading: false);
      AppLogger.info('✅ Profile saved successfully');

      // Refresh profile completeness cache
      ref.read(profileCompletenessProvider.notifier).refresh();

      return true;
    } catch (e, stack) {
      AppLogger.error('❌ Failed to save profile', e, stack);
      state = state.copyWith(
        isLoading: false,
        errorMessage: AppStrings.profileSaveError,
      );
      return false;
    }
  }
}

final profileSetupControllerProvider =
    StateNotifierProvider<ProfileSetupController, ProfileSetupState>(
  (ref) => ProfileSetupController(ref),
);
