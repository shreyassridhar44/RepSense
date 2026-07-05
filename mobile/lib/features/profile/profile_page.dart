import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../data/supabase/supabase_service.dart';
import '../../shared/widgets/glass_card.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = SupabaseService.instance.currentUser;

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
        children: [
          Text('Profile', style: Theme.of(context).textTheme.headlineLarge),
          const SizedBox(height: 20),
          GlassCard(
            child: Row(
              children: [
                const CircleAvatar(radius: 32, backgroundColor: AppColors.surfaceElevated,
                  child: Icon(Icons.person_rounded, size: 32, color: AppColors.textSecondary)),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(user?.email ?? 'Guest', style: Theme.of(context).textTheme.titleLarge),
                      Text('Intermediate Lifter', style: Theme.of(context).textTheme.bodyMedium),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          _settingsTile(context, Icons.straighten_rounded, 'Height & Weight'),
          _settingsTile(context, Icons.flag_rounded, 'Goals'),
          _settingsTile(context, Icons.speed_rounded, 'Training Experience'),
          _settingsTile(context, Icons.notifications_rounded, 'Notifications'),
          _settingsTile(context, Icons.lock_rounded, 'Privacy'),
          _settingsTile(context, Icons.palette_rounded, 'Theme'),
          _settingsTile(context, Icons.watch_rounded, 'Connected Devices'),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () async {
              await SupabaseService.instance.signOut();
              if (context.mounted) context.go('/auth');
            },
            icon: const Icon(Icons.logout_rounded, color: AppColors.error),
            label: const Text('Sign Out', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }

  Widget _settingsTile(BuildContext context, IconData icon, String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: GlassCard(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Icon(icon, color: AppColors.textSecondary, size: 20),
            const SizedBox(width: 14),
            Expanded(child: Text(label, style: Theme.of(context).textTheme.bodyLarge)),
            const Icon(Icons.chevron_right_rounded, color: AppColors.textSecondary),
          ],
        ),
      ),
    );
  }
}
