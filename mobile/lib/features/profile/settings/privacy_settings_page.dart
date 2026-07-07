import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/providers.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/glass_card.dart';

/// Privacy settings screen
class PrivacySettingsPage extends ConsumerStatefulWidget {
  const PrivacySettingsPage({super.key});

  @override
  ConsumerState<PrivacySettingsPage> createState() => _PrivacySettingsPageState();
}

class _PrivacySettingsPageState extends ConsumerState<PrivacySettingsPage> {
  bool _showSuccessIcon = false;
  String? _lastSavedKey;
  bool _dataExpanded = false;

  void _showSuccess(String key) {
    setState(() {
      _showSuccessIcon = true;
      _lastSavedKey = key;
    });
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) {
        setState(() {
          _showSuccessIcon = false;
          _lastSavedKey = null;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final userId = ref.watch(authProvider).currentUser?.id;
    if (userId == null) return const Scaffold(body: Center(child: Text('Not authenticated')));

    final state = ref.watch(profileNotifierProvider(userId));
    final notifier = ref.read(profileNotifierProvider(userId).notifier);
    final privacy = state.editPrivacy;

    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      appBar: AppBar(
        backgroundColor: AppTheme.surfaceDark,
        title: const Text('Privacy'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Privacy toggles
          GlassCard(
            child: Column(
              children: [
                _buildToggleTile(
                  key: 'appearOnLeaderboard',
                  title: 'Appear on Leaderboard',
                  subtitle: 'Your display name and weekly XP appear in the global leaderboard',
                  value: privacy.appearOnLeaderboard,
                  onChanged: (value) async {
                    notifier.togglePrivacy('appearOnLeaderboard');
                    await Future.delayed(const Duration(milliseconds: 500));
                    await notifier.savePrivacySettings();
                    _showSuccess('appearOnLeaderboard');
                  },
                ),
                const Divider(height: 1),
                _buildToggleTile(
                  key: 'shareProgress',
                  title: 'Share Progress',
                  subtitle: 'Allow friends to see your workout stats (future feature)',
                  value: privacy.shareProgress,
                  badge: 'Coming soon',
                  onChanged: (value) async {
                    notifier.togglePrivacy('shareProgress');
                    await Future.delayed(const Duration(milliseconds: 500));
                    await notifier.savePrivacySettings();
                    _showSuccess('shareProgress');
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Data section
          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Your Data',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                    fontFamily: 'Manrope',
                  ),
                ),
                const SizedBox(height: 16),
                InkWell(
                  onTap: () async {
                    try {
                      await notifier.exportData();
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Data exported successfully')),
                        );
                      }
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Export failed: $e')),
                        );
                      }
                    }
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      children: [
                        Icon(Icons.download_rounded, color: AppTheme.electricBlue),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Text(
                            'Download My Data',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                              fontFamily: 'Manrope',
                            ),
                          ),
                        ),
                        if (state.status == ProfileStatus.exportingData)
                          const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        else
                          Icon(Icons.chevron_right_rounded, color: Colors.white.withOpacity(0.3)),
                      ],
                    ),
                  ),
                ),
                const Divider(height: 24),
                InkWell(
                  onTap: () {
                    setState(() {
                      _dataExpanded = !_dataExpanded;
                    });
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline_rounded, color: Colors.white.withOpacity(0.6)),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Text(
                            'What data we collect',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                              fontFamily: 'Manrope',
                            ),
                          ),
                        ),
                        Icon(
                          _dataExpanded ? Icons.expand_less_rounded : Icons.expand_more_rounded,
                          color: Colors.white.withOpacity(0.3),
                        ),
                      ],
                    ),
                  ),
                ),
                if (_dataExpanded) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Workout history, form scores, rep analyses, achievements, and profile information.',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.white.withOpacity(0.8),
                            fontFamily: 'Manrope',
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'We never sell your data. All data is stored securely on Supabase servers.',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.white.withOpacity(0.8),
                            fontFamily: 'Manrope',
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'You can delete your account and all associated data at any time.',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.white.withOpacity(0.8),
                            fontFamily: 'Manrope',
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToggleTile({
    required String key,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
    String? badge,
  }) {
    final showSuccess = _showSuccessIcon && _lastSavedKey == key;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                        fontFamily: 'Manrope',
                      ),
                    ),
                    if (badge != null) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppTheme.amber.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          badge,
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.amber,
                            fontFamily: 'Manrope',
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white.withOpacity(0.6),
                    fontFamily: 'Manrope',
                  ),
                ),
              ],
            ),
          ),
          if (showSuccess)
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: 1.0),
              duration: const Duration(milliseconds: 300),
              builder: (context, value, child) {
                return Opacity(
                  opacity: value,
                  child: Icon(Icons.check_circle_rounded, color: AppTheme.emerald, size: 24),
                );
              },
            )
          else
            Switch(
              value: value,
              onChanged: onChanged,
              activeColor: AppTheme.electricBlue,
            ),
        ],
      ),
    );
  }
}
