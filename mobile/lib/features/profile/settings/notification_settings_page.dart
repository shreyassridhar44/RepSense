import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../../core/providers/providers.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/glass_card.dart';
import '../../../data/models/profile_models.dart';

/// Notification settings screen
class NotificationSettingsPage extends ConsumerStatefulWidget {
  const NotificationSettingsPage({super.key});

  @override
  ConsumerState<NotificationSettingsPage> createState() => _NotificationSettingsPageState();
}

class _NotificationSettingsPageState extends ConsumerState<NotificationSettingsPage> {
  bool _permissionGranted = true;
  bool _showSuccessIcon = false;
  String? _lastSavedKey;

  @override
  void initState() {
    super.initState();
    _checkPermission();
  }

  Future<void> _checkPermission() async {
    final status = await Permission.notification.status;
    setState(() {
      _permissionGranted = status.isGranted || status.isProvisional;
    });
  }

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
    final userId = ref.watch(currentUserProvider)?.id;
    if (userId == null) return const Scaffold(body: Center(child: Text('Not authenticated')));

    final state = ref.watch(profileNotifierProvider(userId));
    final notifier = ref.read(profileNotifierProvider(userId).notifier);
    final notifications = state.editNotifications;

    final anyReminderOn = notifications.workoutReminder ||
        notifications.streakReminder ||
        notifications.achievementUnlock ||
        notifications.weeklySummary;

    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      appBar: AppBar(
        backgroundColor: AppTheme.surfaceDark,
        title: const Text('Notifications'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Permission banner
          if (!_permissionGranted)
            GlassCard(
              gradient: LinearGradient(
                colors: [
                  AppTheme.amber.withOpacity(0.2),
                  AppTheme.amber.withOpacity(0.1),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.notifications_off_rounded, color: AppTheme.amber),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'Notifications are disabled',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                            fontFamily: 'Manrope',
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Enable them to receive workout reminders and achievement alerts',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.white.withOpacity(0.8),
                      fontFamily: 'Manrope',
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () async {
                        await openAppSettings();
                        await _checkPermission();
                      },
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: AppTheme.amber),
                        foregroundColor: AppTheme.amber,
                      ),
                      child: const Text('Open Settings'),
                    ),
                  ),
                ],
              ),
            ),
          if (!_permissionGranted) const SizedBox(height: 16),

          // Toggle rows
          GlassCard(
            child: Column(
              children: [
                _buildToggleTile(
                  key: 'workoutReminder',
                  title: 'Workout Reminders',
                  subtitle: 'Daily reminder to complete your workout',
                  value: notifications.workoutReminder,
                  enabled: _permissionGranted,
                  onChanged: (value) async {
                    notifier.toggleNotification('workoutReminder');
                    await Future.delayed(const Duration(milliseconds: 500));
                    await notifier.saveNotificationsSettings();
                    _showSuccess('workoutReminder');
                  },
                ),
                const Divider(height: 1),
                _buildToggleTile(
                  key: 'streakReminder',
                  title: 'Streak Protection',
                  subtitle: 'Alert when your streak is at risk',
                  value: notifications.streakReminder,
                  enabled: _permissionGranted,
                  onChanged: (value) async {
                    notifier.toggleNotification('streakReminder');
                    await Future.delayed(const Duration(milliseconds: 500));
                    await notifier.saveNotificationsSettings();
                    _showSuccess('streakReminder');
                  },
                ),
                const Divider(height: 1),
                _buildToggleTile(
                  key: 'achievementUnlock',
                  title: 'Achievement Unlocks',
                  subtitle: 'Notified when you earn a badge or level up',
                  value: notifications.achievementUnlock,
                  enabled: _permissionGranted,
                  onChanged: (value) async {
                    notifier.toggleNotification('achievementUnlock');
                    await Future.delayed(const Duration(milliseconds: 500));
                    await notifier.saveNotificationsSettings();
                    _showSuccess('achievementUnlock');
                  },
                ),
                const Divider(height: 1),
                _buildToggleTile(
                  key: 'weeklySummary',
                  title: 'Weekly Progress Summary',
                  subtitle: 'Sunday evening recap of your week',
                  value: notifications.weeklySummary,
                  enabled: _permissionGranted,
                  onChanged: (value) async {
                    notifier.toggleNotification('weeklySummary');
                    await Future.delayed(const Duration(milliseconds: 500));
                    await notifier.saveNotificationsSettings();
                    _showSuccess('weeklySummary');
                  },
                ),
              ],
            ),
          ),

          // Reminder time picker
          if (anyReminderOn) ...[
            const SizedBox(height: 16),
            GlassCard(
              child: InkWell(
                onTap: () => _pickTime(context, notifier, notifications.reminderTime),
                child: Row(
                  children: [
                    Icon(Icons.access_time_rounded, color: AppTheme.electricBlue),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Reminder Time',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                              fontFamily: 'Manrope',
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'You\'ll be reminded at ${_formatTime(notifications.reminderTime)} each day',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.white.withOpacity(0.6),
                              fontFamily: 'Manrope',
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      _formatTime(notifications.reminderTime),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.electricBlue,
                        fontFamily: 'Manrope',
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(Icons.chevron_right_rounded, color: Colors.white.withOpacity(0.3)),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildToggleTile({
    required String key,
    required String title,
    required String subtitle,
    required bool value,
    required bool enabled,
    required ValueChanged<bool> onChanged,
  }) {
    final showSuccess = _showSuccessIcon && _lastSavedKey == key;
    return Opacity(
      opacity: enabled ? 1.0 : 0.5,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
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
                onChanged: enabled ? onChanged : null,
                activeColor: AppTheme.electricBlue,
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickTime(BuildContext context, dynamic notifier, TimeOfDay currentTime) async {
    final time = await showTimePicker(
      context: context,
      initialTime: currentTime,
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

    if (time != null) {
      notifier.updateReminderTime(time);
      await Future.delayed(const Duration(milliseconds: 500));
      await notifier.saveNotificationsSettings();
    }
  }

  String _formatTime(TimeOfDay time) {
    final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.period == DayPeriod.am ? 'AM' : 'PM';
    return '$hour:$minute $period';
  }
}
