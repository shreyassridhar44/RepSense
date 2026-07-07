import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/providers.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/glass_card.dart';

/// AI and Camera preferences screen
class AiPreferencesPage extends ConsumerStatefulWidget {
  const AiPreferencesPage({super.key});

  @override
  ConsumerState<AiPreferencesPage> createState() => _AiPreferencesPageState();
}

class _AiPreferencesPageState extends ConsumerState<AiPreferencesPage> {
  @override
  Widget build(BuildContext context) {
    final userId = ref.watch(authProvider).currentUser?.id;
    if (userId == null) return const Scaffold(body: Center(child: Text('Not authenticated')));

    final state = ref.watch(profileNotifierProvider(userId));
    final notifier = ref.read(profileNotifierProvider(userId).notifier);
    final preferences = state.editPreferences;

    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      appBar: AppBar(
        backgroundColor: AppTheme.surfaceDark,
        title: const Text('AI & Camera'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Voice Guidance
          GlassCard(
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Voice Coaching',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                          fontFamily: 'Manrope',
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Spoken feedback during workouts',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.white.withOpacity(0.6),
                          fontFamily: 'Manrope',
                        ),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: preferences.voiceGuidanceEnabled,
                  onChanged: (value) async {
                    notifier.updatePreferences(preferences.copyWith(voiceGuidanceEnabled: value));
                    await Future.delayed(const Duration(milliseconds: 500));
                    await notifier.savePreferences();
                  },
                  activeColor: AppTheme.electricBlue,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Camera Quality
          const Text(
            'Camera Quality',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.white,
              fontFamily: 'Manrope',
            ),
          ),
          const SizedBox(height: 12),
          _buildQualityCard(
            'Low',
            'Lower resolution, better battery life, recommended for older devices',
            preferences.cameraQuality == 'low',
            () => _updateQuality('low', notifier),
          ),
          const SizedBox(height: 8),
          _buildQualityCard(
            'Medium',
            'Balanced quality and performance — recommended',
            preferences.cameraQuality == 'medium',
            () => _updateQuality('medium', notifier),
            recommended: true,
          ),
          const SizedBox(height: 8),
          _buildQualityCard(
            'High',
            'Best pose detection accuracy, higher battery usage',
            preferences.cameraQuality == 'high',
            () => _updateQuality('high', notifier),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.electricBlue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline_rounded, color: AppTheme.electricBlue, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'This affects how clearly the AI can see your movements',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white.withOpacity(0.8),
                      fontFamily: 'Manrope',
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // AI Mode
          const Text(
            'AI Mode',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.white,
              fontFamily: 'Manrope',
            ),
          ),
          const SizedBox(height: 12),
          _buildModeCard(
            'Cloud',
            'Full biomechanical analysis sent to AI servers. Requires internet. Most accurate.',
            preferences.inferenceMode == 'cloud',
            () => _updateMode('cloud', notifier),
          ),
          const SizedBox(height: 8),
          _buildModeCard(
            'On-Device',
            'Basic analysis runs on your phone. Works offline. Less detailed.',
            preferences.inferenceMode == 'ondevice',
            () => _updateMode('ondevice', notifier),
          ),
          const SizedBox(height: 8),
          _buildModeCard(
            'Auto',
            'Uses cloud when connected, falls back to on-device when offline.',
            preferences.inferenceMode == 'auto',
            () => _updateMode('auto', notifier),
            recommended: true,
          ),
          if (preferences.inferenceMode == 'ondevice') ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.amber.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(Icons.warning_amber_rounded, color: AppTheme.amber, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'On-device mode provides basic rep counting and form feedback only. Cloud mode provides full biomechanical scoring and AI coaching.',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white.withOpacity(0.8),
                        fontFamily: 'Manrope',
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 24),

          // Performance info
          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Performance Impact',
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
                    Icon(Icons.battery_charging_full_rounded, color: _getBatteryColor(preferences)),
                    const SizedBox(width: 8),
                    Text(
                      'Estimated battery impact: ${_getBatteryImpact(preferences)}',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.white.withOpacity(0.8),
                        fontFamily: 'Manrope',
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQualityCard(String title, String description, bool isSelected, VoidCallback onTap,
      {bool recommended = false}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
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
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: isSelected ? AppTheme.electricBlue : Colors.white,
                          fontFamily: 'Manrope',
                        ),
                      ),
                      if (recommended) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppTheme.emerald.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'Recommended',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.emerald,
                              fontFamily: 'Manrope',
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white.withOpacity(0.6),
                      fontFamily: 'Manrope',
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModeCard(String title, String description, bool isSelected, VoidCallback onTap,
      {bool recommended = false}) {
    return _buildQualityCard(title, description, isSelected, onTap, recommended: recommended);
  }

  Future<void> _updateQuality(String quality, dynamic notifier) async {
    final userId = ref.read(authProvider).currentUser?.id;
    if (userId == null) return;
    
    final state = ref.read(profileNotifierProvider(userId));
    notifier.setCameraQuality(quality);
    await Future.delayed(const Duration(milliseconds: 500));
    await notifier.savePreferences();
  }

  Future<void> _updateMode(String mode, dynamic notifier) async {
    final userId = ref.read(authProvider).currentUser?.id;
    if (userId == null) return;
    
    notifier.setInferenceMode(mode);
    await Future.delayed(const Duration(milliseconds: 500));
    await notifier.savePreferences();
  }

  String _getBatteryImpact(dynamic preferences) {
    final quality = preferences.cameraQuality;
    final mode = preferences.inferenceMode;

    if (quality == 'high' && mode == 'cloud') return 'High';
    if (quality == 'low' && mode == 'ondevice') return 'Low';
    return 'Medium';
  }

  Color _getBatteryColor(dynamic preferences) {
    final impact = _getBatteryImpact(preferences);
    if (impact == 'Low') return AppTheme.emerald;
    if (impact == 'High') return AppTheme.errorRed;
    return AppTheme.amber;
  }
}
