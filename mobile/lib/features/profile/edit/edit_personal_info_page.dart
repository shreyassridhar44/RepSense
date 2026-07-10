import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/providers/providers.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/glass_card.dart';
import '../../../shared/widgets/gradient_button.dart';

/// Edit personal information screen
class EditPersonalInfoPage extends ConsumerStatefulWidget {
  const EditPersonalInfoPage({super.key});

  @override
  ConsumerState<EditPersonalInfoPage> createState() => _EditPersonalInfoPageState();
}

class _EditPersonalInfoPageState extends ConsumerState<EditPersonalInfoPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();

  final List<String> _availableGoals = [
    'Build Muscle',
    'Lose Fat',
    'Improve Strength',
    'Improve Flexibility',
    'Athletic Performance',
    'Injury Rehabilitation',
    'General Fitness',
  ];

  final List<String> _experienceLevels = ['Beginner', 'Intermediate', 'Advanced', 'Elite'];

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      final userId = ref.read(currentUserProvider)?.id;
      if (userId != null) {
        final state = ref.read(profileNotifierProvider(userId));
        _nameController.text = state.editDisplayName ?? '';
      }
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final userId = ref.watch(currentUserProvider)?.id;
    if (userId == null) return const Scaffold(body: Center(child: Text('Not authenticated')));

    final state = ref.watch(profileNotifierProvider(userId));
    final notifier = ref.read(profileNotifierProvider(userId).notifier);

    return WillPopScope(
      onWillPop: () async {
        if (state.hasPersonalInfoChanges) {
          return await _showDiscardDialog(context);
        }
        return true;
      },
      child: Scaffold(
        backgroundColor: AppTheme.backgroundDark,
        appBar: AppBar(
          backgroundColor: AppTheme.surfaceDark,
          title: const Text('Personal Info'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: () async {
              if (state.hasPersonalInfoChanges) {
                final discard = await _showDiscardDialog(context);
                if (discard && context.mounted) {
                  context.pop();
                }
              } else {
                context.pop();
              }
            },
          ),
        ),
        body: Form(
          key: _formKey,
          child: Column(
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    // Display Name
                    GlassCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Display Name',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                              fontFamily: 'Manrope',
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _nameController,
                            style: const TextStyle(color: Colors.white),
                            decoration: InputDecoration(
                              hintText: 'Enter your name',
                              hintStyle: TextStyle(color: Colors.white.withOpacity(0.4)),
                              filled: true,
                              fillColor: Colors.white.withOpacity(0.05),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                              counterText: _nameController.text.length > 30
                                  ? '${_nameController.text.length}/40'
                                  : null,
                            ),
                            validator: (value) {
                              if (value == null || value.trim().length < 2) {
                                return 'Name must be at least 2 characters';
                              }
                              if (value.trim().length > 40) {
                                return 'Name must be 40 characters or less';
                              }
                              final sanitized = value.trim().replaceAll(RegExp(r"[^\w\s\-']"), '');
                              if (value.trim() != sanitized) {
                                return 'Name contains invalid characters';
                              }
                              return null;
                            },
                            onChanged: (value) => notifier.updateDisplayName(value),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Date of Birth
                    GlassCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Date of Birth',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                              fontFamily: 'Manrope',
                            ),
                          ),
                          const SizedBox(height: 12),
                          InkWell(
                            onTap: () => _pickDate(context, notifier, state.editDateOfBirth),
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.05),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.calendar_today_rounded, color: Colors.white.withOpacity(0.6)),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      state.editDateOfBirth != null
                                          ? _formatDate(state.editDateOfBirth!)
                                          : 'Tap to set',
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: state.editDateOfBirth != null
                                            ? Colors.white
                                            : Colors.white.withOpacity(0.4),
                                        fontFamily: 'Manrope',
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          if (state.editDateOfBirth != null) ...[
                            const SizedBox(height: 8),
                            Text(
                              '${_calculateAge(state.editDateOfBirth!)} years old',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.white.withOpacity(0.6),
                                fontFamily: 'Manrope',
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Biological Sex
                    GlassCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Biological Sex',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                              fontFamily: 'Manrope',
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(child: _buildSexButton('Male', state, notifier)),
                              const SizedBox(width: 8),
                              Expanded(child: _buildSexButton('Female', state, notifier)),
                              const SizedBox(width: 8),
                              Expanded(child: _buildSexButton('Prefer not to say', state, notifier)),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Training Experience
                    GlassCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Training Experience',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                              fontFamily: 'Manrope',
                            ),
                          ),
                          const SizedBox(height: 12),
                          ..._experienceLevels.map((level) => _buildExperienceCard(level, state, notifier)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Goals
                    GlassCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Goals',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                              fontFamily: 'Manrope',
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Select at least one',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.white.withOpacity(0.6),
                              fontFamily: 'Manrope',
                            ),
                          ),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: _availableGoals.map((goal) {
                              final isSelected = state.editGoals.contains(goal);
                              return FilterChip(
                                label: Text(goal),
                                selected: isSelected,
                                onSelected: (_) {
                                  if (state.editGoals.length == 1 && isSelected) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('At least one goal must be selected')),
                                    );
                                    return;
                                  }
                                  notifier.toggleGoal(goal);
                                },
                                backgroundColor: Colors.white.withOpacity(0.05),
                                selectedColor: AppTheme.electricBlue.withOpacity(0.3),
                                checkmarkColor: AppTheme.electricBlue,
                                labelStyle: TextStyle(
                                  color: isSelected ? AppTheme.electricBlue : Colors.white,
                                  fontFamily: 'Manrope',
                                ),
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Save Button
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceDark,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 10,
                      offset: const Offset(0, -5),
                    ),
                  ],
                ),
                child: GradientButton(
                  onPressed: state.hasPersonalInfoChanges && !state.isSavingPersonalInfo
                      ? () => _save(context, notifier)
                      : null,
                  isLoading: state.isSavingPersonalInfo,
                  child: const Text('Save Changes'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSexButton(String label, dynamic state, dynamic notifier) {
    final isSelected = state.editBiologicalSex?.toLowerCase() == label.toLowerCase();
    return GestureDetector(
      onTap: () => notifier.updateBiologicalSex(label.toLowerCase()),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.electricBlue.withOpacity(0.3) : Colors.white.withOpacity(0.05),
          border: Border.all(
            color: isSelected ? AppTheme.electricBlue : Colors.transparent,
            width: 2,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label == 'Prefer not to say' ? 'Prefer\nnot to say' : label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: isSelected ? AppTheme.electricBlue : Colors.white,
            fontFamily: 'Manrope',
          ),
        ),
      ),
    );
  }

  Widget _buildExperienceCard(String level, dynamic state, dynamic notifier) {
    final isSelected = state.editTrainingExperience == level;
    return GestureDetector(
      onTap: () => notifier.updateTrainingExperience(level),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.electricBlue.withOpacity(0.2) : Colors.white.withOpacity(0.05),
          border: Border.all(
            color: isSelected ? AppTheme.electricBlue : Colors.transparent,
            width: 2,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(
              isSelected ? Icons.check_circle_rounded : Icons.circle_outlined,
              color: isSelected ? AppTheme.electricBlue : Colors.white.withOpacity(0.3),
            ),
            const SizedBox(width: 12),
            Text(
              level,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: isSelected ? AppTheme.electricBlue : Colors.white,
                fontFamily: 'Manrope',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickDate(BuildContext context, dynamic notifier, DateTime? currentDate) async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: currentDate ?? DateTime(now.year - 25),
      firstDate: DateTime(now.year - 100),
      lastDate: DateTime(now.year - 13),
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppTheme.electricBlue,
              surface: AppTheme.surfaceDark,
            ),
          ),
          child: child!,
        );
      },
    );

    if (date != null) {
      notifier.updateDateOfBirth(date);
    }
  }

  String _formatDate(DateTime date) {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  int _calculateAge(DateTime birthDate) {
    final now = DateTime.now();
    int age = now.year - birthDate.year;
    if (now.month < birthDate.month || (now.month == birthDate.month && now.day < birthDate.day)) {
      age--;
    }
    return age;
  }

  Future<void> _save(BuildContext context, dynamic notifier) async {
    if (!_formKey.currentState!.validate()) return;

    try {
      await notifier.savePersonalInfo();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Personal info updated')),
        );
        context.pop();
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save: ${e.toString()}')),
        );
      }
    }
  }

  Future<bool> _showDiscardDialog(BuildContext context) async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: AppTheme.surfaceDark,
            title: const Text('Discard changes?', style: TextStyle(color: Colors.white)),
            content: const Text(
              'You have unsaved changes. Are you sure you want to discard them?',
              style: TextStyle(color: Colors.white70),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Keep Editing'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Discard', style: TextStyle(color: AppTheme.errorRed)),
              ),
            ],
          ),
        ) ??
        false;
  }
}
