import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/providers/providers.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/glass_card.dart';
import '../profile_state.dart';

/// Account deletion confirmation screen
class DeleteAccountPage extends ConsumerStatefulWidget {
  const DeleteAccountPage({super.key});

  @override
  ConsumerState<DeleteAccountPage> createState() => _DeleteAccountPageState();
}

class _DeleteAccountPageState extends ConsumerState<DeleteAccountPage> {
  final _confirmController = TextEditingController();
  bool _isDeleting = false;

  @override
  void dispose() {
    _confirmController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final userId = ref.watch(currentUserProvider)?.id;
    if (userId == null) return const Scaffold(body: Center(child: Text('Not authenticated')));

    final state = ref.watch(profileNotifierProvider(userId));
    final profile = state.profile;
    
    // Count user data
    final workoutCount = 0; // This would come from a workout provider
    final badgeCount = state.profile?.xpTotal ?? 0;

    final canDelete = _confirmController.text.toUpperCase() == 'DELETE' && !_isDeleting;

    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      appBar: AppBar(
        backgroundColor: AppTheme.surfaceDark,
        title: const Text('Delete Account'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Warning card
          GlassCard(
            gradient: LinearGradient(
              colors: [
                AppTheme.errorRed.withOpacity(0.2),
                AppTheme.errorRed.withOpacity(0.1),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.warning_rounded, color: AppTheme.errorRed, size: 48),
                    const SizedBox(width: 16),
                    const Expanded(
                      child: Text(
                        'Delete your RepSense account',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          fontFamily: 'PlusJakartaSans',
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Text(
                  'This will permanently delete:',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                    fontFamily: 'Manrope',
                  ),
                ),
                const SizedBox(height: 12),
                _buildBulletPoint('All your workout history ($workoutCount workouts)'),
                _buildBulletPoint('All rep analyses and form scores'),
                _buildBulletPoint('Your achievements and XP'),
                _buildBulletPoint('Your profile and personal information'),
                _buildBulletPoint('All workout videos and uploaded media'),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.errorRed.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.block_rounded, color: AppTheme.errorRed, size: 20),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'This action cannot be undone.',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                            fontFamily: 'Manrope',
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Export reminder
          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.download_rounded, color: AppTheme.electricBlue),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Before you delete',
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
                  'Consider downloading your data first',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.white.withOpacity(0.6),
                    fontFamily: 'Manrope',
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: state.status == ProfileStatus.exportingData
                        ? null
                        : () async {
                            try {
                              await ref.read(profileNotifierProvider(userId).notifier).exportData();
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
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: AppTheme.electricBlue),
                      foregroundColor: AppTheme.electricBlue,
                    ),
                    child: state.status == ProfileStatus.exportingData
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Export My Data'),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Confirmation input
          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Type "DELETE" to confirm',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                    fontFamily: 'Manrope',
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _confirmController,
                  textCapitalization: TextCapitalization.characters,
                  style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600),
                  decoration: InputDecoration(
                    hintText: 'DELETE',
                    hintStyle: TextStyle(color: Colors.white.withOpacity(0.4)),
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.05),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: AppTheme.errorRed, width: 2),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: AppTheme.errorRed.withOpacity(0.3), width: 2),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: AppTheme.errorRed, width: 2),
                    ),
                  ),
                  onChanged: (_) => setState(() {}),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Delete button
          Container(
            width: double.infinity,
            height: 56,
            decoration: BoxDecoration(
              gradient: canDelete
                  ? LinearGradient(
                      colors: [AppTheme.errorRed, AppTheme.errorRed.withOpacity(0.8)],
                    )
                  : null,
              color: canDelete ? null : Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: ElevatedButton(
              onPressed: canDelete ? _showFinalConfirmation : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: _isDeleting
                  ? const SizedBox(
                      height: 24,
                      width: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Text(
                      'Delete My Account',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        fontFamily: 'PlusJakartaSans',
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBulletPoint(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '• ',
            style: TextStyle(
              fontSize: 14,
              color: Colors.white.withOpacity(0.8),
              fontFamily: 'Manrope',
            ),
          ),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 14,
                color: Colors.white.withOpacity(0.8),
                fontFamily: 'Manrope',
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showFinalConfirmation() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surfaceDark,
        title: const Text(
          'Are you absolutely sure?',
          style: TextStyle(color: Colors.white, fontFamily: 'PlusJakartaSans'),
        ),
        content: const Text(
          'This is permanent and cannot be reversed.',
          style: TextStyle(color: Colors.white70, fontFamily: 'Manrope'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppTheme.errorRed),
            child: const Text('Delete Forever'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await _deleteAccount();
    }
  }

  Future<void> _deleteAccount() async {
    setState(() {
      _isDeleting = true;
    });

    // Show full-screen loading overlay
    if (mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => WillPopScope(
          onWillPop: () async => false,
          child: Container(
            color: AppTheme.backgroundDark,
            child: const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 24),
                  Text(
                    'Deleting your account…',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white,
                      fontFamily: 'Manrope',
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    try {
      final userId = ref.read(currentUserProvider)?.id;
      if (userId == null) throw Exception('Not authenticated');

      await ref.read(profileNotifierProvider(userId).notifier).deleteAccount('DELETE');

      if (mounted) {
        // Pop the loading dialog
        Navigator.pop(context);
        
        // Navigate to auth with deletion message
        context.go('/auth', extra: {'accountDeleted': true});
      }
    } catch (e) {
      if (mounted) {
        // Pop the loading dialog
        Navigator.pop(context);
        
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: AppTheme.surfaceDark,
            title: const Text('Deletion Failed', style: TextStyle(color: Colors.white)),
            content: Text(
              'Deletion failed — ${e.toString()}. Your data is still safe.',
              style: const TextStyle(color: Colors.white70),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  _deleteAccount(); // Retry
                },
                child: const Text('Retry'),
              ),
            ],
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isDeleting = false;
        });
      }
    }
  }
}
