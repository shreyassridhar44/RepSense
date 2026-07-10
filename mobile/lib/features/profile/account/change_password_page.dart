import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/providers/providers.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/password_validator.dart';
import '../../../shared/widgets/glass_card.dart';
import '../../../shared/widgets/gradient_button.dart';

/// Change password screen
class ChangePasswordPage extends ConsumerStatefulWidget {
  const ChangePasswordPage({super.key});

  @override
  ConsumerState<ChangePasswordPage> createState() => _ChangePasswordPageState();
}

class _ChangePasswordPageState extends ConsumerState<ChangePasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;
  bool _isLoading = false;
  String? _currentPasswordError;

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final isOAuthUser = user?.appMetadata?['provider'] != 'email';

    if (isOAuthUser) {
      return Scaffold(
        backgroundColor: AppTheme.backgroundDark,
        appBar: AppBar(
          backgroundColor: AppTheme.surfaceDark,
          title: const Text('Change Password'),
        ),
        body: Padding(
          padding: const EdgeInsets.all(20),
          child: GlassCard(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.info_outline_rounded, color: AppTheme.electricBlue, size: 48),
                const SizedBox(height: 16),
                const Text(
                  'Password management handled by your provider',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                    fontFamily: 'Manrope',
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'You signed in with Google — password management is handled by your sign-in provider.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.white.withOpacity(0.6),
                    fontFamily: 'Manrope',
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final strength = PasswordValidator.getStrength(_newPasswordController.text);
    final passwordsMatch = _newPasswordController.text == _confirmPasswordController.text &&
        _newPasswordController.text.isNotEmpty;

    final canSubmit = _formKey.currentState?.validate() ?? false;

    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      appBar: AppBar(
        backgroundColor: AppTheme.surfaceDark,
        title: const Text('Change Password'),
      ),
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  // Current Password
                  GlassCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Current Password',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                            fontFamily: 'Manrope',
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _currentPasswordController,
                          obscureText: _obscureCurrent,
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            hintText: 'Enter current password',
                            hintStyle: TextStyle(color: Colors.white.withOpacity(0.4)),
                            filled: true,
                            fillColor: Colors.white.withOpacity(0.05),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                            errorText: _currentPasswordError,
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscureCurrent ? Icons.visibility_rounded : Icons.visibility_off_rounded,
                                color: Colors.white.withOpacity(0.6),
                              ),
                              onPressed: () {
                                setState(() {
                                  _obscureCurrent = !_obscureCurrent;
                                });
                              },
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Current password is required';
                            }
                            return null;
                          },
                          onChanged: (_) {
                            setState(() {
                              _currentPasswordError = null;
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // New Password
                  GlassCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'New Password',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                            fontFamily: 'Manrope',
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _newPasswordController,
                          obscureText: _obscureNew,
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            hintText: 'Enter new password',
                            hintStyle: TextStyle(color: Colors.white.withOpacity(0.4)),
                            filled: true,
                            fillColor: Colors.white.withOpacity(0.05),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscureNew ? Icons.visibility_rounded : Icons.visibility_off_rounded,
                                color: Colors.white.withOpacity(0.6),
                              ),
                              onPressed: () {
                                setState(() {
                                  _obscureNew = !_obscureNew;
                                });
                              },
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'New password is required';
                            }
                            if (value.length < 8) {
                              return 'Password must be at least 8 characters';
                            }
                            if (!RegExp(r'[A-Z]').hasMatch(value)) {
                              return 'Password must contain an uppercase letter';
                            }
                            if (!RegExp(r'[a-z]').hasMatch(value)) {
                              return 'Password must contain a lowercase letter';
                            }
                            if (!RegExp(r'[0-9]').hasMatch(value)) {
                              return 'Password must contain a number';
                            }
                            if (value == _currentPasswordController.text) {
                              return 'New password must be different from current password';
                            }
                            return null;
                          },
                          onChanged: (_) => setState(() {}),
                        ),
                        if (_newPasswordController.text.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          _buildStrengthIndicator(strength),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Confirm Password
                  GlassCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Confirm New Password',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                            fontFamily: 'Manrope',
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _confirmPasswordController,
                          obscureText: _obscureConfirm,
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            hintText: 'Re-enter new password',
                            hintStyle: TextStyle(color: Colors.white.withOpacity(0.4)),
                            filled: true,
                            fillColor: Colors.white.withOpacity(0.05),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscureConfirm ? Icons.visibility_rounded : Icons.visibility_off_rounded,
                                color: Colors.white.withOpacity(0.6),
                              ),
                              onPressed: () {
                                setState(() {
                                  _obscureConfirm = !_obscureConfirm;
                                });
                              },
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please confirm your password';
                            }
                            if (value != _newPasswordController.text) {
                              return 'Passwords don\'t match';
                            }
                            return null;
                          },
                          onChanged: (_) => setState(() {}),
                        ),
                        if (_confirmPasswordController.text.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Icon(
                                passwordsMatch ? Icons.check_circle_rounded : Icons.cancel_rounded,
                                size: 16,
                                color: passwordsMatch ? AppTheme.emerald : AppTheme.errorRed,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                passwordsMatch ? 'Passwords match' : 'Passwords don\'t match',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: passwordsMatch ? AppTheme.emerald : AppTheme.errorRed,
                                  fontFamily: 'Manrope',
                                ),
                              ),
                            ],
                          ),
                        ],
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
                onPressed: canSubmit && !_isLoading ? _save : null,
                isLoading: _isLoading,
                child: const Text('Change Password'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStrengthIndicator(PasswordStrength strength) {
    final color = strength == PasswordStrength.strong
        ? AppTheme.emerald
        : strength == PasswordStrength.fair
            ? AppTheme.amber
            : AppTheme.errorRed;

    final label = strength == PasswordStrength.strong
        ? 'Strong'
        : strength == PasswordStrength.fair
            ? 'Fair'
            : 'Weak';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: color,
          fontFamily: 'Manrope',
        ),
      ),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _currentPasswordError = null;
    });

    try {
      final userId = ref.read(currentUserProvider)?.id;
      if (userId == null) throw Exception('Not authenticated');

      await ref.read(profileNotifierProvider(userId).notifier).changePassword(
            _currentPasswordController.text,
            _newPasswordController.text,
          );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Password updated successfully')),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        if (e.toString().contains('Invalid login credentials') ||
            e.toString().contains('wrong password')) {
          setState(() {
            _currentPasswordError = 'Current password is incorrect';
          });
        } else if (e.toString().contains('recent')) {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              backgroundColor: AppTheme.surfaceDark,
              title: const Text('Re-authentication Required', style: TextStyle(color: Colors.white)),
              content: const Text(
                'Please sign in again to change your password',
                style: TextStyle(color: Colors.white70),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    context.go('/auth');
                  },
                  child: const Text('Sign In'),
                ),
              ],
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to change password: ${e.toString()}')),
          );
        }
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}
