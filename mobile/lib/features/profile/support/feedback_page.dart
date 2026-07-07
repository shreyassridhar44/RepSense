import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/providers/providers.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/widgets/gradient_button.dart';

/// Feedback submission screen
class FeedbackPage extends ConsumerStatefulWidget {
  const FeedbackPage({super.key});

  @override
  ConsumerState<FeedbackPage> createState() => _FeedbackPageState();
}

class _FeedbackPageState extends ConsumerState<FeedbackPage> {
  final _messageController = TextEditingController();
  String _selectedCategory = 'general';
  bool _includeDeviceInfo = true;
  bool _isSubmitting = false;

  final Map<String, Map<String, dynamic>> _categories = {
    'bug': {
      'icon': Icons.bug_report_rounded,
      'label': '🐛 Bug Report',
      'placeholder': 'Describe what happened, what you expected, and steps to reproduce...',
    },
    'feature': {
      'icon': Icons.lightbulb_rounded,
      'label': '✨ Feature Request',
      'placeholder': 'Describe the feature you\'d like to see...',
    },
    'general': {
      'icon': Icons.chat_bubble_rounded,
      'label': '💬 General Feedback',
      'placeholder': 'Share your thoughts about RepSense...',
    },
    'ai': {
      'icon': Icons.psychology_rounded,
      'label': '🤖 AI Feedback',
      'placeholder': 'Describe the AI feedback or analysis issue...',
    },
  };

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final canSubmit = _messageController.text.trim().length >= 10 && !_isSubmitting;

    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      appBar: AppBar(
        backgroundColor: AppTheme.surfaceDark,
        title: const Text('Send Feedback'),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                // Category selector
                GlassCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Category',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                          fontFamily: 'Manrope',
                        ),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _categories.entries.map((entry) {
                          final isSelected = _selectedCategory == entry.key;
                          return ChoiceChip(
                            label: Text(entry.value['label']!),
                            selected: isSelected,
                            onSelected: (_) {
                              setState(() {
                                _selectedCategory = entry.key;
                              });
                            },
                            backgroundColor: Colors.white.withOpacity(0.05),
                            selectedColor: AppTheme.electricBlue.withOpacity(0.3),
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
                const SizedBox(height: 16),

                // Message field
                GlassCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Message',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                          fontFamily: 'Manrope',
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _messageController,
                        maxLines: 8,
                        maxLength: 500,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          hintText: _categories[_selectedCategory]!['placeholder'],
                          hintStyle: TextStyle(color: Colors.white.withOpacity(0.4)),
                          filled: true,
                          fillColor: Colors.white.withOpacity(0.05),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          counterStyle: TextStyle(
                            color: _messageController.text.length > 450
                                ? AppTheme.amber
                                : Colors.white.withOpacity(0.6),
                          ),
                        ),
                        onChanged: (_) => setState(() {}),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Include device info toggle
                GlassCard(
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Include device info',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                                fontFamily: 'Manrope',
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'App version, OS version, and device model (no personal data)',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.white.withOpacity(0.6),
                                fontFamily: 'Manrope',
                              ),
                            ),
                          ],
                        ),
                      ),
                      Switch(
                        value: _includeDeviceInfo,
                        onChanged: (value) => setState(() => _includeDeviceInfo = value),
                        activeColor: AppTheme.electricBlue,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Submit Button
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
              onPressed: canSubmit ? _submit : null,
              isLoading: _isSubmitting,
              child: const Text('Submit Feedback'),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _submit() async {
    if (_messageController.text.trim().length < 10) return;

    setState(() => _isSubmitting = true);

    try {
      final userId = ref.read(authProvider).currentUser?.id;
      if (userId == null) throw Exception('Not authenticated');

      await ref.read(profileNotifierProvider(userId).notifier).submitFeedback(
            _selectedCategory,
            _messageController.text.trim(),
          );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Thanks for your feedback!')),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Couldn\'t send feedback — try again')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }
}
