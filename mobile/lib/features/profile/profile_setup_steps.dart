import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/strings.dart';
import '../../core/theme/app_colors.dart';
import '../../shared/widgets/glass_card.dart';
import 'profile_setup_controller.dart';
import 'profile_setup_state.dart';

// Step 3: Training Experience
class Step3Experience extends ConsumerWidget {
  const Step3Experience({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(profileSetupControllerProvider);
    final controller = ref.read(profileSetupControllerProvider.notifier);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppStrings.yourExperience,
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: 8),
        Text(
          'Select your training experience level',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 32),
        
        _ExperienceCard(
          title: AppStrings.beginner,
          description: AppStrings.beginnerDesc,
          icon: Icons.flag_outlined,
          isSelected: state.trainingExperience == TrainingExperience.beginner,
          onTap: () => controller.setTrainingExperience(TrainingExperience.beginner),
        ),
        const SizedBox(height: 16),
        
        _ExperienceCard(
          title: AppStrings.intermediate,
          description: AppStrings.intermediateDesc,
          icon: Icons.trending_up,
          isSelected: state.trainingExperience == TrainingExperience.intermediate,
          onTap: () => controller.setTrainingExperience(TrainingExperience.intermediate),
        ),
        const SizedBox(height: 16),
        
        _ExperienceCard(
          title: AppStrings.advanced,
          description: AppStrings.advancedDesc,
          icon: Icons.fitness_center,
          isSelected: state.trainingExperience == TrainingExperience.advanced,
          onTap: () => controller.setTrainingExperience(TrainingExperience.advanced),
        ),
        const SizedBox(height: 16),
        
        _ExperienceCard(
          title: AppStrings.elite,
          description: AppStrings.eliteDesc,
          icon: Icons.emoji_events_outlined,
          isSelected: state.trainingExperience == TrainingExperience.elite,
          onTap: () => controller.setTrainingExperience(TrainingExperience.elite),
        ),
      ],
    );
  }
}

class _ExperienceCard extends StatelessWidget {
  const _ExperienceCard({
    required this.title,
    required this.description,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  final String title;
  final String description;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      onTap: onTap,
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: isSelected ? AppColors.primaryGradient : null,
              color: isSelected ? null : AppColors.surfaceElevated,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              size: 28,
              color: isSelected ? Colors.white : AppColors.textSecondary,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: isSelected ? AppColors.electricBlue : AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
          if (isSelected)
            const Icon(
              Icons.check_circle,
              color: AppColors.electricBlue,
              size: 24,
            ),
        ],
      ),
    );
  }
}

// Step 4: Goals
class Step4Goals extends ConsumerWidget {
  const Step4Goals({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(profileSetupControllerProvider);
    final controller = ref.read(profileSetupControllerProvider.notifier);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppStrings.yourGoals,
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: 8),
        Text(
          'Select one or more goals (at least one required)',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 32),
        
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _GoalChip(
              label: AppStrings.buildMuscle,
              icon: Icons.fitness_center,
              isSelected: state.selectedGoals.contains(FitnessGoal.buildMuscle),
              onTap: () => controller.toggleGoal(FitnessGoal.buildMuscle),
            ),
            _GoalChip(
              label: AppStrings.loseFat,
              icon: Icons.local_fire_department,
              isSelected: state.selectedGoals.contains(FitnessGoal.loseFat),
              onTap: () => controller.toggleGoal(FitnessGoal.loseFat),
            ),
            _GoalChip(
              label: AppStrings.improveStrength,
              icon: Icons.trending_up,
              isSelected: state.selectedGoals.contains(FitnessGoal.improveStrength),
              onTap: () => controller.toggleGoal(FitnessGoal.improveStrength),
            ),
            _GoalChip(
              label: AppStrings.improveFlexibility,
              icon: Icons.self_improvement,
              isSelected: state.selectedGoals.contains(FitnessGoal.improveFlexibility),
              onTap: () => controller.toggleGoal(FitnessGoal.improveFlexibility),
            ),
            _GoalChip(
              label: AppStrings.athleticPerformance,
              icon: Icons.sports,
              isSelected: state.selectedGoals.contains(FitnessGoal.athleticPerformance),
              onTap: () => controller.toggleGoal(FitnessGoal.athleticPerformance),
            ),
            _GoalChip(
              label: AppStrings.injuryRehabilitation,
              icon: Icons.healing,
              isSelected: state.selectedGoals.contains(FitnessGoal.injuryRehabilitation),
              onTap: () => controller.toggleGoal(FitnessGoal.injuryRehabilitation),
            ),
            _GoalChip(
              label: AppStrings.generalFitness,
              icon: Icons.favorite,
              isSelected: state.selectedGoals.contains(FitnessGoal.generalFitness),
              onTap: () => controller.toggleGoal(FitnessGoal.generalFitness),
            ),
          ],
        ),
        
        if (!state.isStep4Valid && state.selectedGoals.isEmpty) ...[
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.amber.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.amber.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline, color: AppColors.amber, size: 20),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    AppStrings.selectAtLeastOneGoal,
                    style: TextStyle(color: AppColors.amber, fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
        ],
        
        const SizedBox(height: 20),
        
        // Selected count
        if (state.selectedGoals.isNotEmpty)
          Center(
            child: Text(
              '${state.selectedGoals.length} goal${state.selectedGoals.length > 1 ? 's' : ''} selected',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.emerald,
              ),
            ),
          ),
      ],
    );
  }
}

class _GoalChip extends StatelessWidget {
  const _GoalChip({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          gradient: isSelected ? AppColors.primaryGradient : null,
          color: isSelected ? null : AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? Colors.transparent
                : Colors.white.withOpacity(0.1),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 18,
              color: isSelected ? Colors.white : AppColors.textSecondary,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : AppColors.textPrimary,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                fontSize: 14,
              ),
            ),
            if (isSelected) ...[
              const SizedBox(width: 8),
              const Icon(Icons.check, size: 16, color: Colors.white),
            ],
          ],
        ),
      ),
    );
  }
}
