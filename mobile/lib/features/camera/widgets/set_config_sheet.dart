import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

class SetConfigSheet extends StatefulWidget {
  final int currentTargetReps;
  final int currentCountdown;
  final bool voiceEnabled;
  final bool isFrontCamera;
  final Function(int targetReps, int countdown, bool voiceEnabled) onStart;
  final VoidCallback onCameraSwitch;

  const SetConfigSheet({
    super.key,
    required this.currentTargetReps,
    required this.currentCountdown,
    required this.voiceEnabled,
    required this.isFrontCamera,
    required this.onStart,
    required this.onCameraSwitch,
  });

  @override
  State<SetConfigSheet> createState() => _SetConfigSheetState();
}

class _SetConfigSheetState extends State<SetConfigSheet> {
  late int _targetReps;
  late int _countdown;
  late bool _voiceEnabled;

  final List<int> _repOptions = [0, 5, 8, 10, 12, 15, 20];
  final List<int> _countdownOptions = [0, 3, 5, 10];

  @override
  void initState() {
    super.initState();
    _targetReps = widget.currentTargetReps;
    _countdown = widget.currentCountdown;
    _voiceEnabled = widget.voiceEnabled;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Set Configuration',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: AppTheme.platinum,
                      fontWeight: FontWeight.bold,
                    ),
              ),
              IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close, color: AppTheme.platinum),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Target reps selector
          Text(
            'Target Reps',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppTheme.platinum,
                ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _repOptions.map((reps) {
              final isSelected = _targetReps == reps;
              return ChoiceChip(
                label: Text(reps == 0 ? 'No Limit' : '$reps'),
                selected: isSelected,
                onSelected: (selected) {
                  setState(() => _targetReps = reps);
                },
                backgroundColor: AppTheme.charcoal,
                selectedColor: AppTheme.electricBlue,
                labelStyle: TextStyle(
                  color: isSelected ? Colors.white : AppTheme.platinum,
                  fontWeight:
                      isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: 24),

          // Countdown selector
          Text(
            'Countdown',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppTheme.platinum,
                ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _countdownOptions.map((seconds) {
              final isSelected = _countdown == seconds;
              return ChoiceChip(
                label: Text(seconds == 0 ? 'None' : '${seconds}s'),
                selected: isSelected,
                onSelected: (selected) {
                  setState(() => _countdown = seconds);
                },
                backgroundColor: AppTheme.charcoal,
                selectedColor: AppTheme.electricBlue,
                labelStyle: TextStyle(
                  color: isSelected ? Colors.white : AppTheme.platinum,
                  fontWeight:
                      isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: 24),

          // Toggles
          _buildToggleRow(
            icon: Icons.volume_up,
            label: 'Voice Guidance',
            value: _voiceEnabled,
            onChanged: (value) => setState(() => _voiceEnabled = value),
          ),

          const SizedBox(height: 16),

          _buildToggleRow(
            icon: widget.isFrontCamera ? Icons.camera_front : Icons.camera_rear,
            label: widget.isFrontCamera ? 'Front Camera' : 'Rear Camera',
            value: false,
            showSwitch: false,
            onTap: () {
              widget.onCameraSwitch();
              Navigator.of(context).pop();
            },
          ),

          const SizedBox(height: 32),

          // Start button
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              widget.onStart(_targetReps, _countdown, _voiceEnabled);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.electricBlue,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: const Text(
              'Start Workout',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildToggleRow({
    required IconData icon,
    required String label,
    required bool value,
    bool showSwitch = true,
    ValueChanged<bool>? onChanged,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap ?? (showSwitch && onChanged != null ? () => onChanged(!value) : null),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: AppTheme.charcoal,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, color: AppTheme.electricBlue),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  color: AppTheme.platinum,
                  fontSize: 16,
                ),
              ),
            ),
            if (showSwitch)
              Switch(
                value: value,
                onChanged: onChanged,
                activeColor: AppTheme.electricBlue,
              )
            else
              const Icon(Icons.chevron_right, color: AppTheme.platinum),
          ],
        ),
      ),
    );
  }
}
