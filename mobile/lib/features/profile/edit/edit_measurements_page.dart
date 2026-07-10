import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/providers/providers.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/unit_converter.dart';
import '../../../core/utils/bmi_calculator.dart';
import '../../../shared/widgets/glass_card.dart';
import '../../../shared/widgets/gradient_button.dart';

/// Edit body measurements screen
class EditMeasurementsPage extends ConsumerStatefulWidget {
  const EditMeasurementsPage({super.key});

  @override
  ConsumerState<EditMeasurementsPage> createState() => _EditMeasurementsPageState();
}

class _EditMeasurementsPageState extends ConsumerState<EditMeasurementsPage> {
  final _formKey = GlobalKey<FormState>();
  final _heightController = TextEditingController();
  final _feetController = TextEditingController();
  final _inchesController = TextEditingController();
  final _weightController = TextEditingController();

  String _localUnits = 'metric';

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      final userId = ref.read(currentUserProvider)?.id;
      if (userId != null) {
        final state = ref.read(profileNotifierProvider(userId));
        _localUnits = state.editPreferredUnits;
        _updateControllers(state);
      }
    });
  }

  void _updateControllers(dynamic state) {
    if (_localUnits == 'metric') {
      _heightController.text = state.editHeightCm?.round().toString() ?? '';
      _weightController.text = state.editWeightKg?.round().toString() ?? '';
    } else {
      if (state.editHeightCm != null) {
        final converted = UnitConverter.cmToFeetInches(state.editHeightCm!);
        _feetController.text = converted.feet.toString();
        _inchesController.text = converted.inches.toString();
      }
      if (state.editWeightKg != null) {
        _weightController.text = UnitConverter.kgToLbs(state.editWeightKg!).round().toString();
      }
    }
  }

  @override
  void dispose() {
    _heightController.dispose();
    _feetController.dispose();
    _inchesController.dispose();
    _weightController.dispose();
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
        if (state.hasMeasurementChanges) {
          return await _showDiscardDialog(context);
        }
        return true;
      },
      child: Scaffold(
        backgroundColor: AppTheme.backgroundDark,
        appBar: AppBar(
          backgroundColor: AppTheme.surfaceDark,
          title: const Text('Body Measurements'),
        ),
        body: Form(
          key: _formKey,
          child: Column(
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    // Unit Toggle
                    GlassCard(
                      child: Row(
                        children: [
                          Expanded(
                            child: _buildUnitButton('Metric', 'metric'),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _buildUnitButton('Imperial', 'imperial'),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Height
                    GlassCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Height',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                              fontFamily: 'Manrope',
                            ),
                          ),
                          const SizedBox(height: 12),
                          if (_localUnits == 'metric')
                            TextFormField(
                              controller: _heightController,
                              keyboardType: TextInputType.number,
                              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                              style: const TextStyle(color: Colors.white),
                              decoration: InputDecoration(
                                hintText: '175',
                                suffixText: 'cm',
                                hintStyle: TextStyle(color: Colors.white.withOpacity(0.4)),
                                filled: true,
                                fillColor: Colors.white.withOpacity(0.05),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide.none,
                                ),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) return null;
                                final height = double.tryParse(value);
                                if (height == null || height < 50 || height > 300) {
                                  return 'Height must be between 50 and 300 cm';
                                }
                                return null;
                              },
                              onChanged: (value) {
                                final height = double.tryParse(value);
                                notifier.updateHeightCm(height);
                              },
                            )
                          else
                            Row(
                              children: [
                                Expanded(
                                  child: TextFormField(
                                    controller: _feetController,
                                    keyboardType: TextInputType.number,
                                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                                    style: const TextStyle(color: Colors.white),
                                    decoration: InputDecoration(
                                      hintText: '5',
                                      suffixText: 'ft',
                                      hintStyle: TextStyle(color: Colors.white.withOpacity(0.4)),
                                      filled: true,
                                      fillColor: Colors.white.withOpacity(0.05),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: BorderSide.none,
                                      ),
                                    ),
                                    validator: (value) {
                                      if (value == null || value.isEmpty) return null;
                                      final feet = int.tryParse(value);
                                      if (feet == null || feet < 1 || feet > 9) {
                                        return '1-9 ft';
                                      }
                                      return null;
                                    },
                                    onChanged: (_) => _updateHeightFromImperial(notifier),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: TextFormField(
                                    controller: _inchesController,
                                    keyboardType: TextInputType.number,
                                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                                    style: const TextStyle(color: Colors.white),
                                    decoration: InputDecoration(
                                      hintText: '11',
                                      suffixText: 'in',
                                      hintStyle: TextStyle(color: Colors.white.withOpacity(0.4)),
                                      filled: true,
                                      fillColor: Colors.white.withOpacity(0.05),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: BorderSide.none,
                                      ),
                                    ),
                                    validator: (value) {
                                      if (value == null || value.isEmpty) return null;
                                      final inches = int.tryParse(value);
                                      if (inches == null || inches < 0 || inches > 11) {
                                        return '0-11 in';
                                      }
                                      return null;
                                    },
                                    onChanged: (_) => _updateHeightFromImperial(notifier),
                                  ),
                                ),
                              ],
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Weight
                    GlassCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Weight',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                              fontFamily: 'Manrope',
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _weightController,
                            keyboardType: TextInputType.number,
                            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                            style: const TextStyle(color: Colors.white),
                            decoration: InputDecoration(
                              hintText: _localUnits == 'metric' ? '75' : '165',
                              suffixText: _localUnits == 'metric' ? 'kg' : 'lbs',
                              hintStyle: TextStyle(color: Colors.white.withOpacity(0.4)),
                              filled: true,
                              fillColor: Colors.white.withOpacity(0.05),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) return null;
                              final weight = double.tryParse(value);
                              if (_localUnits == 'metric') {
                                if (weight == null || weight < 20 || weight > 500) {
                                  return 'Weight must be between 20 and 500 kg';
                                }
                              } else {
                                if (weight == null || weight < 44 || weight > 1100) {
                                  return 'Weight must be between 44 and 1100 lbs';
                                }
                              }
                              return null;
                            },
                            onChanged: (value) {
                              final weight = double.tryParse(value);
                              if (weight != null) {
                                final kg = _localUnits == 'metric' ? weight : UnitConverter.lbsToKg(weight);
                                notifier.updateWeightKg(kg);
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // BMI
                    if (state.editHeightCm != null && state.editWeightKg != null) ...[
                      _buildBmiCard(state.editHeightCm!, state.editWeightKg!),
                    ],
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
                  onPressed: state.hasMeasurementChanges && !state.isSavingMeasurements
                      ? () => _save(context, notifier)
                      : null,
                  isLoading: state.isSavingMeasurements,
                  child: const Text('Save Changes'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUnitButton(String label, String value) {
    final isSelected = _localUnits == value;
    return GestureDetector(
      onTap: () {
        setState(() {
          _localUnits = value;
        });
        final userId = ref.read(currentUserProvider)?.id;
        if (userId != null) {
          ref.read(profileNotifierProvider(userId).notifier).setPreferredUnits(value);
          final state = ref.read(profileNotifierProvider(userId));
          _updateControllers(state);
        }
      },
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
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: isSelected ? AppTheme.electricBlue : Colors.white,
            fontFamily: 'Manrope',
          ),
        ),
      ),
    );
  }

  Widget _buildBmiCard(double heightCm, double weightKg) {
    final bmi = BmiCalculator.calculate(heightCm: heightCm, weightKg: weightKg);
    final category = BmiCalculator.getCategory(bmi);

    if (bmi == null || category == null) return const SizedBox.shrink();

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Body Mass Index (BMI)',
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
              Text(
                BmiCalculator.format(bmi),
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  fontFamily: 'PlusJakartaSans',
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: category.color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  category.label,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: category.color,
                    fontFamily: 'Manrope',
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            BmiCalculator.disclaimer,
            style: TextStyle(
              fontSize: 12,
              color: Colors.white.withOpacity(0.6),
              fontStyle: FontStyle.italic,
              fontFamily: 'Manrope',
            ),
          ),
        ],
      ),
    );
  }

  void _updateHeightFromImperial(dynamic notifier) {
    final feet = int.tryParse(_feetController.text) ?? 0;
    final inches = int.tryParse(_inchesController.text) ?? 0;
    if (feet > 0 || inches > 0) {
      final cm = UnitConverter.feetInchesToCm(feet, inches);
      notifier.updateHeightCm(cm);
    }
  }

  Future<void> _save(BuildContext context, dynamic notifier) async {
    if (!_formKey.currentState!.validate()) return;

    try {
      await notifier.saveMeasurements();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Measurements updated')),
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
