import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/providers/providers.dart';
import '../../shared/widgets/glass_card.dart';
import 'coach_state.dart';
import 'widgets/chat_bubble.dart';
import 'widgets/typing_indicator.dart';

/// AI Coach chat screen
class CoachPage extends ConsumerStatefulWidget {
  const CoachPage({super.key});

  @override
  ConsumerState<CoachPage> createState() => _CoachPageState();
}

class _CoachPageState extends ConsumerState<CoachPage> {
  final TextEditingController _inputController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _contextBannerDismissed = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(coachProvider.notifier).initialize();
    });
  }

  @override
  void dispose() {
    _inputController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(coachProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: _buildAppBar(state),
      body: Column(
        children: [
          // Context banner
          if (state.isContextLoaded && !_contextBannerDismissed)
            _buildContextBanner(state),

          // Service unavailable banner
          if (!state.isServiceAvailable) _buildOfflineBanner(),

          // Messages list
          Expanded(
            child: _buildMessagesList(state),
          ),

          // Input area
          _buildInputArea(state),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(CoachState state) {
    return AppBar(
      backgroundColor: AppColors.backgroundDark,
      title: Row(
        children: [
          const Text('AI Coach'),
          const SizedBox(width: 8),
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: state.isServiceAvailable ? AppColors.success : Colors.grey,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            state.isServiceAvailable ? 'Online' : 'Offline',
            style: TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh),
          onPressed: () {
            ref.read(coachProvider.notifier).refreshContext();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Context updated with latest workout data')),
            );
          },
        ),
        IconButton(
          icon: const Icon(Icons.more_vert),
          onPressed: () => _showMoreMenu(context),
        ),
      ],
    );
  }

  Widget _buildContextBanner(CoachState state) {
    final context = state.context;
    if (context == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.electricBlue.withOpacity(0.1),
        border: const Border(
          left: BorderSide(color: AppColors.electricBlue, width: 4),
        ),
      ),
      child: Row(
        children: [
          const Text('🧠', style: TextStyle(fontSize: 20)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Personalized with your ${context.totalWorkouts} workouts and ${context.trainingExperience ?? 'your'} profile',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 20),
            onPressed: () {
              setState(() {
                _contextBannerDismissed = true;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildOfflineBanner() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: AppColors.warning.withOpacity(0.2),
      child: Row(
        children: [
          const Icon(Icons.warning_amber, color: AppColors.warning, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              '⚠ Coach service offline — answers may be limited',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessagesList(CoachState state) {
    if (state.status == CoachStatus.loadingContext) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(color: AppColors.electricBlue),
            const SizedBox(height: 16),
            Text(
              'Personalizing your coach…',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Loading your workout history and goals',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ],
        ),
      );
    }

    if (state.messages.isEmpty) {
      return _buildEmptyState(state);
    }

    // Calculate where to show divider (between 20th and 21st message from bottom)
    final showDivider = state.messages.length > 20;
    final dividerIndex = showDivider ? state.messages.length - 20 : -1;

    return ListView.builder(
      controller: _scrollController,
      reverse: true,
      padding: const EdgeInsets.only(top: 16, bottom: 16),
      itemCount: state.messages.length + (state.isTyping ? 1 : 0) + (showDivider ? 1 : 0),
      itemBuilder: (context, index) {
        // Typing indicator at top (index 0 when reverse: true)
        if (index == 0 && state.isTyping) {
          return const TypingIndicator();
        }

        final adjustedIndex = state.isTyping ? index - 1 : index;

        // Context window divider
        if (showDivider && adjustedIndex == dividerIndex) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
            child: Row(
              children: [
                Expanded(child: Divider(color: AppColors.textSecondary.withOpacity(0.3))),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Text(
                    '— Earlier messages not in AI context —',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
                Expanded(child: Divider(color: AppColors.textSecondary.withOpacity(0.3))),
              ],
            ),
          );
        }

        // Adjust index for divider offset
        final messageIndex = showDivider && adjustedIndex > dividerIndex
            ? adjustedIndex - 1
            : adjustedIndex;

        final message = state.messages[state.messages.length - 1 - messageIndex];

        return ChatBubble(
          message: message,
          showFollowups: messageIndex == 0 && message.isAssistant,
          onFollowupTap: (question) {
            ref.read(coachProvider.notifier).useQuickReply(question);
          },
          onRetry: message.isError
              ? () => ref.read(coachProvider.notifier).retryMessage(message.id)
              : null,
        );
      },
    );
  }

  Widget _buildEmptyState(CoachState state) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [
                    AppColors.electricBlue,
                    AppColors.electricBlue.withOpacity(0.6),
                  ],
                ),
              ),
              child: const Icon(
                Icons.smart_toy_rounded,
                size: 50,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Ask me anything about your training',
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              state.context != null
                  ? 'I know your ${state.context!.totalWorkouts} workouts, ${state.context!.trainingExperience ?? 'your'} level, and ${state.context!.goals.isEmpty ? 'more' : state.context!.goals.join(', ')}'
                  : 'Ask about form, programming, recovery, nutrition, and more',
              style: TextStyle(color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            // Suggested questions
            Wrap(
              spacing: 12,
              runSpacing: 12,
              alignment: WrapAlignment.center,
              children: state.suggestedQuestions.map((question) {
                return GestureDetector(
                  onTap: () {
                    ref.read(coachProvider.notifier).useQuickReply(question);
                  },
                  child: GlassCard(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Flexible(
                          child: Text(
                            question,
                            style: TextStyle(fontSize: 14),
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Icon(Icons.arrow_forward, size: 16),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputArea(CoachState state) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.backgroundLight,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.attach_file),
              onPressed: () => _showAttachmentOptions(),
            ),
            if (state.isRecordingVoice)
              IconButton(
                icon: const Icon(Icons.mic, color: AppColors.error),
                onPressed: () {
                  ref.read(coachProvider.notifier).stopVoiceInput();
                },
              )
            else
              IconButton(
                icon: const Icon(Icons.mic),
                onPressed: () {
                  ref.read(coachProvider.notifier).startVoiceInput();
                },
              ),
            Expanded(
              child: TextField(
                controller: _inputController,
                maxLines: null,
                maxLength: 1000,
                textInputAction: TextInputAction.send,
                decoration: InputDecoration(
                  hintText: 'Ask your coach…',
                  border: InputBorder.none,
                  counterText: _inputController.text.length > 800
                      ? '${_inputController.text.length}/1000'
                      : '',
                ),
                onChanged: (text) {
                  ref.read(coachProvider.notifier).setInputDraft(text);
                },
                onSubmitted: (text) => _sendMessage(),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.send_rounded),
              color: _inputController.text.trim().isEmpty
                  ? Colors.grey
                  : AppColors.electricBlue,
              onPressed: _inputController.text.trim().isEmpty ? null : _sendMessage,
            ),
          ],
        ),
      ),
    );
  }

  void _sendMessage() {
    final text = _inputController.text.trim();
    if (text.isEmpty) return;

    ref.read(coachProvider.notifier).sendMessage(text);
    _inputController.clear();

    // Scroll to bottom
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _showAttachmentOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Choose from Gallery'),
                onTap: () async {
                  Navigator.pop(context);
                  final result = await ref.read(imagePickerServiceProvider).pickFromGallery();
                  if (result != null) {
                    ref.read(coachProvider.notifier).sendImage(
                      result.base64,
                      result.mediaType,
                      _inputController.text.trim(),
                    );
                    _inputController.clear();
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Take Photo'),
                onTap: () async {
                  Navigator.pop(context);
                  final result = await ref.read(imagePickerServiceProvider).pickFromCamera();
                  if (result != null) {
                    ref.read(coachProvider.notifier).sendImage(
                      result.base64,
                      result.mediaType,
                      _inputController.text.trim(),
                    );
                    _inputController.clear();
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showMoreMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.share),
                title: const Text('Export conversation'),
                onTap: () {
                  Navigator.pop(context);
                  ref.read(coachProvider.notifier).exportConversation();
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete),
                title: const Text('Clear conversation'),
                onTap: () {
                  Navigator.pop(context);
                  _showClearConfirmation();
                },
              ),
              ListTile(
                leading: const Icon(Icons.info),
                title: const Text('About AI Coach'),
                onTap: () {
                  Navigator.pop(context);
                  _showAboutDialog();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showClearConfirmation() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Clear Conversation'),
          content: Text(
            'This will permanently delete all ${ref.read(coachProvider).messages.length} messages in this conversation.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                ref.read(coachProvider.notifier).clearConversation();
              },
              style: TextButton.styleFrom(foregroundColor: AppColors.error),
              child: const Text('Delete All'),
            ),
          ],
        );
      },
    );
  }

  void _showAboutDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('About AI Coach'),
          content: const Text(
            'The RepSense AI Coach uses advanced language models to provide '
            'personalized training advice based on your workout history, form '
            'analysis, and fitness goals.\n\n'
            'The coach can help with:\n'
            '• Exercise form and technique\n'
            '• Program design and progression\n'
            '• Recovery and injury prevention\n'
            '• Nutrition for your goals\n\n'
            'For medical concerns, always consult a qualified professional.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Got it'),
            ),
          ],
        );
      },
    );
  }
}
