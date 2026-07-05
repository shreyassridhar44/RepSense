import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../core/constants/strings.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/app_logger.dart';
import '../../shared/widgets/glass_card.dart';
import '../../shared/widgets/gradient_button.dart';
import '../auth/auth_provider.dart';
import 'profile_setup_controller.dart';
import 'profile_setup_state.dart';
import 'profile_setup_steps.dart';

class ProfileSetupPage extends ConsumerWidget {
  const ProfileSetupPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(profileSetupControllerProvider);
    final controller = ref.read(profileSetupControllerProvider.notifier);

    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) async {
        if (didPop) return;
        
        if (state.currentStep == ProfileSetupStep.personalInfo) {
          final shouldExit = await _showExitConfirmation(context);
          if (shouldExit == true && context.mounted) {
            // Sign out user and go back to auth
            await ref.read(authStateProvider.notifier).future;
            await clearGuestMode();
            if (context.mounted) {
              context.go('/auth');
            }
          }
        } else {
          controller.previousStep();
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: const Text(AppStrings.profileSetup),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () async {
              if (state.currentStep == ProfileSetupStep.personalInfo) {
                final shouldExit = await _showExitConfirmation(context);
                if (shouldExit == true && context.mounted) {
                  await ref.read(authStateProvider.notifier).future;
                  await clearGuestMode();
                  if (context.mounted) {
                    context.go('/auth');
                  }
                }
              } else {
                controller.previousStep();
              }
            },
          ),
        ),
        body: SafeArea(
          child: Column(
            children: [
              // Progress Indicator
              _buildProgressIndicator(state.currentStep),
              
              // Content
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    transitionBuilder: (child, animation) {
                      return FadeTransition(
                        opacity: animation,
                        child: SlideTransition(
                          position: Tween<Offset>(
                            begin: const Offset(0.1, 0),
                            end: Offset.zero,
                          ).animate(animation),
                          child: child,
                        ),
                      );
                    },
                    child: _buildStepContent(context, ref, state),
                  ),
                ),
              ),
              
              // Loading Overlay
              if (state.isLoading)
                Container(
                  color: Colors.black54,
                  child: const Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation(AppColors.electricBlue),
                    ),
                  ),
                ),
              
              // Bottom Navigation
              _buildBottomNavigation(context, ref, state),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProgressIndicator(ProfileSetupStep currentStep) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      child: Row(
        children: ProfileSetupStep.values.asMap().entries.map((entry) {
          final index = entry.key;
          final step = entry.value;
          final isActive = step.index <= currentStep.index;
          final isCurrent = step == currentStep;

          return Expanded(
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    height: 4,
                    decoration: BoxDecoration(
                      gradient: isActive
                          ? AppColors.primaryGradient
                          : null,
                      color: isActive ? null : AppColors.surface,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                if (index < ProfileSetupStep.values.length - 1)
                  const SizedBox(width: 4),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildStepContent(BuildContext context, WidgetRef ref, ProfileSetupState state) {
    switch (state.currentStep) {
      case ProfileSetupStep.personalInfo:
        return _Step1PersonalInfo(key: const ValueKey('step1'));
      case ProfileSetupStep.measurements:
        return _Step2Measurements(key: const ValueKey('step2'));
      case ProfileSetupStep.experience:
        return const Step3Experience(key: ValueKey('step3'));
      case ProfileSetupStep.goals:
        return const Step4Goals(key: ValueKey('step4'));
    }
  }

  Widget _buildBottomNavigation(BuildContext context, WidgetRef ref, ProfileSetupState state) {
    final controller = ref.read(profileSetupControllerProvider.notifier);
    final isLastStep = state.currentStep == ProfileSetupStep.goals;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: GradientButton(
          label: isLastStep ? AppStrings.finishButton : AppStrings.continueButton,
          onPressed: state.canContinue && !state.isLoading
              ? () async {
                  if (isLastStep) {
                    final success = await controller.saveProfile();
                    if (success && context.mounted) {
                      context.go('/home');
                    } else if (state.errorMessage != null && context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(state.errorMessage!),
                          backgroundColor: AppColors.error,
                        ),
                      );
                    }
                  } else {
                    controller.nextStep();
                  }
                }
              : () {},
          icon: isLastStep ? Icons.check_rounded : Icons.arrow_forward_rounded,
        ),
      ),
    );
  }

  Future<bool?> _showExitConfirmation(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text(AppStrings.exitProfileSetup),
        content: const Text(AppStrings.exitProfileSetupMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text(AppStrings.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text(AppStrings.exitAnyway),
          ),
        ],
      ),
    );
  }
}

// Step 1: Personal Info
class _Step1PersonalInfo extends ConsumerStatefulWidget {
  const _Step1PersonalInfo({super.key});

  @override
  ConsumerState<_Step1PersonalInfo> createState() => _Step1PersonalInfoState();
}

class _Step1PersonalInfoState extends ConsumerState<_Step1PersonalInfo> {
  final _nameController = TextEditingController();
  String? _ageError;

  @override
  void initState() {
    super.initState();
    final state = ref.read(profileSetupControllerProvider);
    if (state.displayName != null) {
      _nameController.text = state.displayName!;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(profileSetupControllerProvider);
    final controller = ref.read(profileSetupControllerProvider.notifier);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppStrings.tellUsAboutYourself,
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: 32),
        
        // Display Name
        TextField(
          controller: _nameController,
          decoration: InputDecoration(
            labelText: AppStrings.displayName,
            hintText: AppStrings.displayNameHint,
            prefixIcon: const Icon(Icons.person_outline, size: 20),
          ),
          onChanged: controller.setDisplayName,
        ),
        
        const SizedBox(height: 20),
        
        // Date of Birth
        GlassCard(
          onTap: () async {
            final now = DateTime.now();
            final initialDate = state.dateOfBirth ?? DateTime(now.year - 25);
            
            final date = await showDatePicker(
              context: context,
              initialDate: initialDate,
              firstDate: DateTime(1900),
              lastDate: now,
              builder: (context, child) {
                return Theme(
                  data: Theme.of(context).copyWith(
                    colorScheme: ColorScheme.dark(
                      primary: AppColors.electricBlue,
                      surface: AppColors.surface,
                    ),
                  ),
                  child: child!,
                );
              },
            );
            
            if (date != null) {
              if (controller.validateAge(date)) {
                controller.setDateOfBirth(date);
                setState(() => _ageError = null);
              } else {
                setState(() => _ageError = AppStrings.ageRestriction);
              }
            }
          },
          child: Row(
            children: [
              const Icon(Icons.calendar_today_outlined, size: 20, color: AppColors.electricBlue),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppStrings.dateOfBirth,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      state.dateOfBirth != null
                          ? DateFormat('MMM d, yyyy').format(state.dateOfBirth!)
                          : 'Select your date of birth',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: state.dateOfBirth != null
                            ? AppColors.textPrimary
                            : AppColors.textSecondary,
                      ),
                    ),
                    if (_ageError != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        _ageError!,
                        style: const TextStyle(color: AppColors.error, fontSize: 12),
                      ),
                    ],
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: AppColors.textSecondary),
            ],
          ),
        ),
        
        const SizedBox(height: 20),
        
        // Biological Sex
        Text(
          AppStrings.biologicalSex,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 12),
        
        Row(
          children: [
            Expanded(
              child: _SexOption(
                label: AppStrings.male,
                icon: Icons.male,
                isSelected: state.biologicalSex == BiologicalSex.male,
                onTap: () => controller.setBiologicalSex(BiologicalSex.male),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _SexOption(
                label: AppStrings.female,
                icon: Icons.female,
                isSelected: state.biologicalSex == BiologicalSex.female,
                onTap: () => controller.setBiologicalSex(BiologicalSex.female),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _SexOption(
          label: AppStrings.preferNotToSay,
          icon: Icons.person_outline,
          isSelected: state.biologicalSex == BiologicalSex.preferNotToSay,
          onTap: () => controller.setBiologicalSex(BiologicalSex.preferNotToSay),
        ),
      ],
    );
  }
}

class _SexOption extends StatelessWidget {
  const _SexOption({
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
    return GlassCard(
      onTap: onTap,
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: isSelected ? AppColors.primaryGradient : null,
              color: isSelected ? null : AppColors.surfaceElevated,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              size: 20,
              color: isSelected ? Colors.white : AppColors.textSecondary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: isSelected ? AppColors.electricBlue : AppColors.textPrimary,
              ),
            ),
          ),
          if (isSelected)
            const Icon(Icons.check_circle, color: AppColors.electricBlue, size: 20),
        ],
      ),
    );
  }
}

// Step 2: Measurements
class _Step2Measurements extends ConsumerStatefulWidget {
  const _Step2Measurements({super.key});

  @override
  ConsumerState<_Step2Measurements> createState() => _Step2MeasurementsState();
}

class _Step2MeasurementsState extends ConsumerState<_Step2Measurements> {
  final _heightController = TextEditingController();
  final _weightController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final state = ref.read(profileSetupControllerProvider);
    if (state.heightCm != null) {
      _heightController.text = state.heightCm!.toStringAsFixed(0);
    }
    if (state.weightKg != null) {
      _weightController.text = state.weightKg!.toStringAsFixed(1);
    }
  }

  @override
  void dispose() {
    _heightController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(profileSetupControllerProvider);
    final controller = ref.read(profileSetupControllerProvider.notifier);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppStrings.yourMeasurements,
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: 32),
        
        // Unit Toggle
        Center(
          child: GlassCard(
            padding: const EdgeInsets.all(4),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildUnitToggle('Metric', state.useMetric, () {
                  if (!state.useMetric) controller.toggleUnit();
                }),
                _buildUnitToggle('Imperial', !state.useMetric, () {
                  if (state.useMetric) controller.toggleUnit();
                }),
              ],
            ),
          ),
        ),
        
        const SizedBox(height: 32),
        
        // Height
        TextField(
          controller: _heightController,
          decoration: InputDecoration(
            labelText: state.useMetric ? AppStrings.heightCm : AppStrings.heightFt,
            hintText: state.useMetric ? '170' : '5\'8"',
            prefixIcon: const Icon(Icons.height, size: 20),
            suffixText: state.useMetric ? 'cm' : 'ft',
          ),
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          onChanged: (value) {
            final height = double.tryParse(value);
            if (height != null) {
              controller.setHeight(state.useMetric ? height : height * 30.48);
            }
          },
        ),
        
        const SizedBox(height: 20),
        
        // Weight
        TextField(
          controller: _weightController,
          decoration: InputDecoration(
            labelText: state.useMetric ? AppStrings.weightKg : AppStrings.weightLbs,
            hintText: state.useMetric ? '70' : '154',
            prefixIcon: const Icon(Icons.fitness_center, size: 20),
            suffixText: state.useMetric ? 'kg' : 'lbs',
          ),
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          onChanged: (value) {
            final weight = double.tryParse(value);
            if (weight != null) {
              controller.setWeight(state.useMetric ? weight : weight * 0.453592);
            }
          },
        ),
        
        if (!state.isStep2Valid && (state.heightCm != null || state.weightKg != null)) ...[
          const SizedBox(height: 12),
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
                Expanded(
                  child: Text(
                    'Height: 50-300 cm, Weight: 20-500 kg',
                    style: TextStyle(color: AppColors.amber.withOpacity(0.9), fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildUnitToggle(String label, bool isSelected, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        decoration: BoxDecoration(
          gradient: isSelected ? AppColors.primaryGradient : null,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : AppColors.textSecondary,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
      ),
    );
  }
}

