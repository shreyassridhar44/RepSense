import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import '../../../core/theme/app_colors.dart';
import '../../../data/models/chat_models.dart';
import 'animated_text_reveal.dart';

/// Chat bubble widget for messages
class ChatBubble extends StatefulWidget {
  final ChatMessage message;
  final VoidCallback? onRetry;
  final VoidCallback? onAnimationComplete;
  final bool showFollowups;
  final Function(String)? onFollowupTap;

  const ChatBubble({
    super.key,
    required this.message,
    this.onRetry,
    this.onAnimationComplete,
    this.showFollowups = false,
    this.onFollowupTap,
  });

  @override
  State<ChatBubble> createState() => _ChatBubbleState();
}

class _ChatBubbleState extends State<ChatBubble> {
  bool _showTimestamp = false;
  bool _showFollowupChips = false;

  @override
  void initState() {
    super.initState();

    // Show followup chips after animation completes
    if (widget.showFollowups && widget.message.isAnimating) {
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted) {
          setState(() {
            _showFollowupChips = true;
          });
        }
      });
    } else if (widget.showFollowups) {
      _showFollowupChips = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: widget.message.isUser
            ? CrossAxisAlignment.end
            : CrossAxisAlignment.start,
        children: [
          // Assistant label
          if (widget.message.isAssistant)
            Padding(
              padding: const EdgeInsets.only(bottom: 4, left: 12),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      color: AppColors.success,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'RepSense AI',
                    style: TextStyle(
                      fontSize: 10,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),

          // Bubble
          GestureDetector(
            onLongPress: widget.message.isAssistant ? _copyToClipboard : _toggleTimestamp,
            child: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.78,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: widget.message.isUser
                    ? AppColors.electricBlue
                    : AppColors.backgroundLight,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(18),
                  topRight: const Radius.circular(18),
                  bottomLeft: Radius.circular(widget.message.isUser ? 18 : 4),
                  bottomRight: Radius.circular(widget.message.isUser ? 4 : 18),
                ),
                gradient: widget.message.isUser
                    ? LinearGradient(
                        colors: [
                          AppColors.electricBlue,
                          AppColors.electricBlue.withOpacity(0.8),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                    : null,
                border: widget.message.isAssistant
                    ? Border(
                        left: BorderSide(
                          color: AppColors.electricBlue,
                          width: 2,
                        ),
                      )
                    : null,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Image if present
                  if (widget.message.type == MessageType.image &&
                      widget.message.imageBase64 != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.memory(
                          base64Decode(widget.message.imageBase64!),
                          width: 200,
                          height: 150,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),

                  // Text content
                  if (widget.message.isAnimating && widget.message.isAssistant)
                    AnimatedTextReveal(
                      text: widget.message.content,
                      style: TextStyle(
                        fontSize: 14,
                        color: widget.message.isUser
                            ? Colors.white
                            : AppColors.textPrimary,
                        fontFamily: 'Manrope',
                      ),
                      onComplete: () {
                        widget.onAnimationComplete?.call();
                        if (widget.showFollowups) {
                          Future.delayed(const Duration(milliseconds: 300), () {
                            if (mounted) {
                              setState(() {
                                _showFollowupChips = true;
                              });
                            }
                          });
                        }
                      },
                    )
                  else
                    Text(
                      widget.message.content,
                      style: TextStyle(
                        fontSize: 14,
                        color: widget.message.isUser
                            ? Colors.white
                            : AppColors.textPrimary,
                        fontFamily: 'Manrope',
                      ),
                    ),

                  // Status indicator for user messages
                  if (widget.message.isUser) ...[
                    const SizedBox(height: 4),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        if (widget.message.status == MessageStatus.sending)
                          const SizedBox(
                            width: 8,
                            height: 8,
                            child: CircularProgressIndicator(
                              strokeWidth: 1,
                              color: Colors.white70,
                            ),
                          )
                        else if (widget.message.status == MessageStatus.sent)
                          const Icon(
                            Icons.check,
                            size: 12,
                            color: Colors.white70,
                          )
                        else if (widget.message.status == MessageStatus.error)
                          GestureDetector(
                            onTap: widget.onRetry,
                            child: const Icon(
                              Icons.error_outline,
                              size: 12,
                              color: AppColors.error,
                            ),
                          ),
                      ],
                    ),
                  ],

                  // Error message
                  if (widget.message.errorMessage != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      widget.message.errorMessage!,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.error,
                      ),
                    ),
                    if (widget.onRetry != null)
                      TextButton(
                        onPressed: widget.onRetry,
                        child: const Text('Retry'),
                      ),
                  ],
                ],
              ),
            ),
          ),

          // Timestamp
          if (_showTimestamp || widget.message.isAssistant)
            Padding(
              padding: const EdgeInsets.only(top: 4, left: 12, right: 12),
              child: Text(
                DateFormat('HH:mm').format(widget.message.timestamp),
                style: TextStyle(
                  fontSize: 10,
                  color: AppColors.textSecondary,
                ),
              ),
            ),

          // Followup chips
          if (_showFollowupChips &&
              widget.message.suggestedFollowups.isNotEmpty &&
              widget.onFollowupTap != null)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: widget.message.suggestedFollowups.map((followup) {
                  return _FollowupChip(
                    text: followup,
                    onTap: () => widget.onFollowupTap?.call(followup),
                  );
                }).toList(),
              ),
            ),
        ],
      ),
    );
  }

  void _toggleTimestamp() {
    setState(() {
      _showTimestamp = !_showTimestamp;
    });
  }

  void _copyToClipboard() {
    Clipboard.setData(ClipboardData(text: widget.message.content));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Copied to clipboard'),
        duration: Duration(seconds: 1),
      ),
    );
  }
}

class _FollowupChip extends StatelessWidget {
  final String text;
  final VoidCallback onTap;

  const _FollowupChip({
    required this.text,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.backgroundLight,
          border: Border.all(color: AppColors.electricBlue),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          text,
          style: TextStyle(
            fontSize: 12,
            color: AppColors.textPrimary,
          ),
        ),
      ),
    );
  }
}
