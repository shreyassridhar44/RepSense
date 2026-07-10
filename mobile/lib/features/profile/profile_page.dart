import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/providers/providers.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/widgets/glass_card.dart';
import '../../data/services/xp_service.dart';

/// Main profile and settings page
class ProfilePage extends ConsumerStatefulWidget {
  const ProfilePage({super.key});

  @override
  ConsumerState<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends ConsumerState<ProfilePage> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      final userId = ref.read(currentUserProvider)?.id;
      if (userId != null) {
        ref.read(profileNotifierProvider(userId).notifier).load();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final userId = ref.watch(currentUserProvider)?.id;

    if (userId == null) {
      return const Scaffold(
        body: Center(child: Text('Please log in')),
      );
    }

    final state = ref.watch(profileNotifierProvider(userId));
    final profile = state.profile;

    if (state.isLoading) {
      return const Scaffold(
        backgroundColor: AppTheme.backgroundDark,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (profile == null) {
      return const Scaffold(
        backgroundColor: AppTheme.backgroundDark,
        body: Center(child: Text('Failed to load profile')),
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      body: RefreshIndicator(
        onRefresh: () async {
          await ref.read(profileNotifierProvider(userId).notifier).load();
        },
        child: CustomScrollView(
          slivers: [
            // Profile Header
            _buildProfileHeader(context, profile, state, userId),
            
            // Content
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    // Stats strip
                    _buildStatsStrip(context, profile),
                    const SizedBox(height: 20),

                    // Personal Info section
                    _buildSection(
                      context,
                      'Personal Info',
                      [
                        _buildTile('Display Name', profile.displayName ?? 'Not set', () {
                          context.push('/profile/edit/personal');
                        }),
                        _buildTile('Date of Birth',
                            profile.age != null ? '${profile.age} years old' : 'Not set', () {
                          context.push('/profile/edit/personal');
                        }),
                        _buildTile('Biological Sex', profile.biologicalSex ?? 'Not set', () {
                          context.push('/profile/edit/personal');
                        }),
                        _buildTile('Goals', profile.goals.join(', '), () {
                          context.push('/profile/edit/personal');
                        }),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Training section
                    _buildSection(
                      context,
                      'Training',
                      [
                        _buildTile('Experience Level', profile.trainingExperience, () {
                          context.push('/profile/edit/personal');
                        }),
                        _buildTile('Preferred Units',
                            profile.preferredUnits == 'metric' ? 'Metric (kg, cm)' : 'Imperial (lbs, ft)', () {
                          context.push('/profile/edit/measurements');
                        }),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Measurements section
                    _buildSection(
                      context,
                      'Body Measurements',
                      [
                        _buildTile('Height', profile.displayHeight, () {
                          context.push('/profile/edit/measurements');
                        }),
                        _buildTile('Weight', profile.displayWeight, () {
                          context.push('/profile/edit/measurements');
                        }),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // AI & Camera
                    _buildSection(
                      context,
                      'AI & Camera',
                      [
                        _buildSwitchTile(
                          'Voice Guidance',
                          profile.preferences.voiceGuidanceEnabled,
                          () {
                            ref.read(profileNotifierProvider(userId).notifier).toggleVoiceGuidance();
                          },
                        ),
                        _buildTile('Camera Quality', profile.preferences.cameraQuality.toUpperCase(), () {
                          context.push('/profile/settings/ai');
                        }),
                        _buildTile('AI Mode', profile.preferences.inferenceMode.toUpperCase(), () {
                          context.push('/profile/settings/ai');
                        }),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Notifications
                    _buildSection(
                      context,
                      'Notifications',
                      [
                        _buildTile('Manage Notifications', '', () {
                          context.push('/profile/settings/notifications');
                        }),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Privacy
                    _buildSection(
                      context,
                      'Privacy',
                      [
                        _buildTile('Privacy Settings', '', () {
                          context.push('/profile/settings/privacy');
                        }),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Account
                    _buildSection(
                      context,
                      'Account',
                      [
                        _buildTile('Email', profile.email ?? 'Not set', () {
                          context.push('/profile/account/change-email');
                        }),
                        _buildTile('Change Password', '', () {
                          context.push('/profile/account/change-password');
                        }),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Support
                    _buildSection(
                      context,
                      'Support',
                      [
                        _buildTile('Send Feedback', '', () {
                          context.push('/profile/support/feedback');
                        }),
                        _buildTile('App Version', 'v0.1.0+1', null),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Danger zone
                    _buildDangerZone(context, userId),
                    const SizedBox(height: 20),

                    // Sign out button
                    _buildSignOutButton(context, userId),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader(BuildContext context, dynamic profile, dynamic state, String userId) {
    return SliverAppBar(
      expandedHeight: 200,
      pinned: true,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppTheme.electricBlue, AppTheme.violet],
            ),
          ),
          child: SafeArea(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                // Avatar
                GestureDetector(
                  onTap: () => _showAvatarOptions(context, userId),
                  child: Stack(
                    children: [
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 3),
                        ),
                        child: ClipOval(
                          child: state.pendingAvatarBase64 != null
                              ? Image.memory(
                                  base64Decode(state.pendingAvatarBase64!),
                                  fit: BoxFit.cover,
                                )
                              : profile.avatarUrl != null
                                  ? CachedNetworkImage(
                                      imageUrl: profile.avatarUrl!,
                                      fit: BoxFit.cover,
                                      placeholder: (_, __) => const CircularProgressIndicator(),
                                      errorWidget: (_, __, ___) => _buildInitialsAvatar(profile.initials),
                                    )
                                  : _buildInitialsAvatar(profile.initials),
                        ),
                      ),
                      if (state.isUploadingAvatar)
                        Positioned.fill(
                          child: Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.black54,
                            ),
                            child: const Center(
                              child: CircularProgressIndicator(color: Colors.white),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // Display name
                Text(
                  profile.displayName ?? 'Athlete',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    fontFamily: 'PlusJakartaSans',
                  ),
                ),
                const SizedBox(height: 4),

                // Level badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: LevelSystem.levelColor(profile.level),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${LevelSystem.levelTitle(profile.level)} · Level ${profile.level}',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                      fontFamily: 'Manrope',
                    ),
                  ),
                ),
                const SizedBox(height: 8),

                // XP Progress
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 60),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: LevelSystem.progressToNextLevel(profile.xpTotal),
                      minHeight: 4,
                      backgroundColor: Colors.white.withOpacity(0.2),
                      valueColor: const AlwaysStoppedAnimation(Colors.white),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInitialsAvatar(String initials) {
    return Container(
      decoration: BoxDecoration(
        gradient: AppTheme.primaryGradient,
      ),
      child: Center(
        child: Text(
          initials,
          style: const TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.w800,
            color: Colors.white,
            fontFamily: 'PlusJakartaSans',
          ),
        ),
      ),
    );
  }

  Widget _buildStatsStrip(BuildContext context, dynamic profile) {
    return Row(
      children: [
        Expanded(
          child: GlassCard(
            child: Column(
              children: [
                const Icon(Icons.emoji_events_rounded, color: AppTheme.amber, size: 24),
                const SizedBox(height: 4),
                Text(
                  '0',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    fontFamily: 'PlusJakartaSans',
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Badges',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: Colors.white.withOpacity(0.6),
                    fontFamily: 'Manrope',
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: GlassCard(
            child: Column(
              children: [
                const Icon(Icons.local_fire_department_rounded, color: AppTheme.errorRed, size: 24),
                const SizedBox(height: 4),
                Text(
                  '0',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    fontFamily: 'PlusJakartaSans',
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Streak',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: Colors.white.withOpacity(0.6),
                    fontFamily: 'Manrope',
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: GlassCard(
            child: Column(
              children: [
                const Icon(Icons.fitness_center_rounded, color: AppTheme.emerald, size: 24),
                const SizedBox(height: 4),
                Text(
                  '0',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    fontFamily: 'PlusJakartaSans',
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Workouts',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: Colors.white.withOpacity(0.6),
                    fontFamily: 'Manrope',
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSection(BuildContext context, String title, List<Widget> tiles) {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.white,
              fontFamily: 'Manrope',
            ),
          ),
          const SizedBox(height: 12),
          ...tiles,
        ],
      ),
    );
  }

  Widget _buildTile(String label, String value, VoidCallback? onTap) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.white,
                      fontFamily: 'Manrope',
                    ),
                  ),
                  if (value.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      value,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w400,
                        color: Colors.white.withOpacity(0.6),
                        fontFamily: 'Manrope',
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (onTap != null)
              Icon(
                Icons.chevron_right_rounded,
                color: Colors.white.withOpacity(0.4),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSwitchTile(String label, bool value, VoidCallback onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.white,
                fontFamily: 'Manrope',
              ),
            ),
          ),
          Switch(
            value: value,
            onChanged: (_) => onChanged(),
            activeColor: AppTheme.electricBlue,
          ),
        ],
      ),
    );
  }

  Widget _buildDangerZone(BuildContext context, String userId) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.errorRed.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.errorRed.withOpacity(0.3)),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Danger Zone',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppTheme.errorRed,
              fontFamily: 'Manrope',
            ),
          ),
          const SizedBox(height: 12),
          _buildTile('Export My Data', '', () async {
            try {
              await ref.read(profileNotifierProvider(userId).notifier).exportData();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Data exported successfully')),
                );
              }
            } catch (e) {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Export failed: ${e.toString()}')),
                );
              }
            }
          }),
          _buildTile('Delete Account', '', () {
            context.push('/profile/account/delete');
          }),
        ],
      ),
    );
  }

  Widget _buildSignOutButton(BuildContext context, String userId) {
    return OutlinedButton(
      onPressed: () => _showSignOutDialog(context, userId),
      style: OutlinedButton.styleFrom(
        minimumSize: const Size.fromHeight(50),
        side: const BorderSide(color: AppTheme.errorRed, width: 2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child: const Text(
        'Sign Out',
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: AppTheme.errorRed,
          fontFamily: 'Manrope',
        ),
      ),
    );
  }

  void _showSignOutDialog(BuildContext context, String userId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surfaceDark,
        title: const Text('Sign out of RepSense?', style: TextStyle(color: Colors.white)),
        content: const Text(
          'You can always sign back in at any time.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await ref.read(profileNotifierProvider(userId).notifier).signOut();
              if (context.mounted) {
                context.go('/auth');
              }
            },
            child: const Text('Sign Out', style: TextStyle(color: AppTheme.errorRed)),
          ),
        ],
      ),
    );
  }

  void _showAvatarOptions(BuildContext context, String userId) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surfaceDark,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt_rounded, color: Colors.white),
              title: const Text('Take Photo', style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                ref.read(profileNotifierProvider(userId).notifier)
                    .pickAndUploadAvatar(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_rounded, color: Colors.white),
              title: const Text('Choose from Gallery', style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                ref.read(profileNotifierProvider(userId).notifier)
                    .pickAndUploadAvatar(ImageSource.gallery);
              },
            ),
            if (ref.read(profileNotifierProvider(userId)).profile?.avatarUrl != null)
              ListTile(
                leading: const Icon(Icons.delete_rounded, color: AppTheme.errorRed),
                title: const Text('Remove Photo', style: TextStyle(color: AppTheme.errorRed)),
                onTap: () {
                  Navigator.pop(context);
                  ref.read(profileNotifierProvider(userId).notifier).removeAvatar();
                },
              ),
            ListTile(
              leading: const Icon(Icons.close_rounded, color: Colors.white70),
              title: const Text('Cancel', style: TextStyle(color: Colors.white70)),
              onTap: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }
}
