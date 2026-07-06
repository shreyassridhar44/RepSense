import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import 'package:uuid/uuid.dart';
import '../../core/exceptions/app_exception.dart';
import '../../core/utils/app_logger.dart';
import '../../data/models/chat_models.dart';
import '../../data/repositories/coach_repository.dart';
import '../auth/auth_provider.dart';
import 'coach_state.dart';
import 'services/coach_context_builder.dart';
import 'services/coach_persistence.dart';
import 'services/image_picker_service.dart';
import 'services/voice_input_service.dart';

/// Notifier for coach chat screen
class CoachNotifier extends StateNotifier<CoachState> {
  final CoachRepository _repository;
  final CoachContextBuilder _contextBuilder;
  final CoachPersistence _persistence;
  final VoiceInputService _voiceService;
  final ImagePickerService _imageService;
  final Ref _ref;

  bool _disposed = false;
  Timer? _healthCheckTimer;
  final _uuid = const Uuid();

  CoachNotifier({
    required CoachRepository repository,
    required CoachContextBuilder contextBuilder,
    required CoachPersistence persistence,
    required VoiceInputService voiceService,
    required ImagePickerService imageService,
    required Ref ref,
  })  : _repository = repository,
        _contextBuilder = contextBuilder,
        _persistence = persistence,
        _voiceService = voiceService,
        _imageService = imageService,
        _ref = ref,
        super(const CoachState());

  @override
  void dispose() {
    _disposed = true;
    _healthCheckTimer?.cancel();
    _voiceService.dispose();
    super.dispose();
  }

  /// Initialize the coach screen
  Future<void> initialize() async {
    try {
      AppLogger.info('🚀 Initializing coach screen');

      // Check service availability
      final isAvailable = await _repository.isAvailable();

      if (_disposed) return;

      if (!isAvailable) {
        state = state.copyWith(
          status: CoachStatus.unavailable,
          isServiceAvailable: false,
          suggestedQuestions: _getOfflineSuggestions(),
        );
        return;
      }

      // Load context
      final userId = _getUserId();
      if (userId == null) {
        if (_disposed) return;
        state = state.copyWith(
          status: CoachStatus.error,
          errorMessage: 'User not authenticated',
        );
        return;
      }

      final context = await _contextBuilder.build(userId);

      if (_disposed) return;

      // Load conversation history
      final messages = await _persistence.loadMessages(userId);

      if (_disposed) return;

      // Load draft
      final draft = await _persistence.loadDraft(userId);

      if (_disposed) return;

      // Build initial suggestions
      final suggestions = messages.isEmpty
          ? _buildInitialSuggestions(context)
          : <String>[];

      state = state.copyWith(
        status: CoachStatus.ready,
        context: context,
        isContextLoaded: true,
        messages: messages,
        inputDraft: draft,
        suggestedQuestions: suggestions,
        totalMessagesInSession: messages.length,
      );

      // Start periodic health check
      _startHealthCheck();

      AppLogger.info('✅ Coach initialized successfully');
    } catch (e, stack) {
      AppLogger.error('❌ Failed to initialize coach', e, stack);
      if (_disposed) return;
      state = state.copyWith(
        status: CoachStatus.error,
        errorMessage: 'Failed to initialize coach',
      );
    }
  }

  /// Send a text message
  Future<void> sendMessage(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty || trimmed.length > 1000) return;
    if (state.status == CoachStatus.sending) return;

    try {
      final userId = _getUserId();
      if (userId == null) return;

      // Add user message immediately
      final userMessage = ChatMessage(
        id: _uuid.v4(),
        role: MessageRole.user,
        content: trimmed,
        type: MessageType.text,
        status: MessageStatus.sending,
        timestamp: DateTime.now(),
      );

      final updatedMessages = [...state.messages, userMessage];

      state = state.copyWith(
        status: CoachStatus.sending,
        messages: updatedMessages,
        isTyping: true,
        inputDraft: '',
      );

      // Clear draft
      await _persistence.saveDraft(userId, '');

      // Try local answer first if offline
      if (!state.isServiceAvailable) {
        final localAnswer = _tryAnswerLocally(trimmed, state.context);
        if (localAnswer != null) {
          _handleLocalAnswer(userId, userMessage, localAnswer);
          return;
        } else {
          _handleOfflineError(userId, userMessage);
          return;
        }
      }

      // Trim history if needed
      _trimHistoryIfNeeded();

      // Call API
      final result = await _repository.ask(
        question: trimmed,
        conversationHistory: state.messages.where((m) => m.status == MessageStatus.sent).toList(),
        context: state.context,
      );

      if (_disposed) return;

      // Update user message to sent
      final sentUserMessage = userMessage.copyWith(status: MessageStatus.sent);

      // Create assistant message with animation
      final assistantMessage = ChatMessage(
        id: _uuid.v4(),
        role: MessageRole.assistant,
        content: result.answer,
        type: MessageType.text,
        status: MessageStatus.sent,
        timestamp: DateTime.now(),
        suggestedFollowups: result.followups,
        isAnimating: true,
      );

      final finalMessages = [
        ...updatedMessages.where((m) => m.id != userMessage.id),
        sentUserMessage,
        assistantMessage,
      ];

      state = state.copyWith(
        status: CoachStatus.ready,
        messages: finalMessages,
        isTyping: false,
        totalMessagesInSession: finalMessages.length,
      );

      // Persist
      await _persistence.saveMessages(userId, finalMessages);

      AppLogger.info('✅ Message sent successfully');
    } catch (e) {
      AppLogger.error('❌ Failed to send message', e);
      if (_disposed) return;

      final errorMessage = e is AppException ? e.userMessage : 'Failed to send message';

      // Update user message to error
      final updatedMessages = state.messages.map((m) {
        if (m.id == state.messages.last.id && m.role == MessageRole.user) {
          return m.copyWith(
            status: MessageStatus.error,
            errorMessage: errorMessage,
          );
        }
        return m;
      }).toList();

      state = state.copyWith(
        status: CoachStatus.ready,
        messages: updatedMessages,
        isTyping: false,
      );
    }
  }

  /// Send an image message
  Future<void> sendImage(String imageBase64, String mediaType, String caption) async {
    if (state.status == CoachStatus.sending) return;

    try {
      final userId = _getUserId();
      if (userId == null) return;

      // Add user message with image
      final userMessage = ChatMessage(
        id: _uuid.v4(),
        role: MessageRole.user,
        content: caption,
        type: MessageType.image,
        status: MessageStatus.sending,
        timestamp: DateTime.now(),
        imageBase64: imageBase64,
      );

      final updatedMessages = [...state.messages, userMessage];

      state = state.copyWith(
        status: CoachStatus.sending,
        messages: updatedMessages,
        isTyping: true,
      );

      // Call API
      final result = await _repository.analyzeImage(
        imageBase64: imageBase64,
        mediaType: mediaType,
        question: caption.isEmpty ? 'Analyze this image' : caption,
        context: state.context,
      );

      if (_disposed) return;

      // Update user message to sent
      final sentUserMessage = userMessage.copyWith(status: MessageStatus.sent);

      // Create assistant message
      final assistantMessage = ChatMessage(
        id: _uuid.v4(),
        role: MessageRole.assistant,
        content: result.answer,
        type: MessageType.text,
        status: MessageStatus.sent,
        timestamp: DateTime.now(),
        suggestedFollowups: result.followups,
        isAnimating: true,
      );

      final finalMessages = [
        ...updatedMessages.where((m) => m.id != userMessage.id),
        sentUserMessage,
        assistantMessage,
      ];

      state = state.copyWith(
        status: CoachStatus.ready,
        messages: finalMessages,
        isTyping: false,
        totalMessagesInSession: finalMessages.length,
      );

      // Persist (without image data)
      await _persistence.saveMessages(userId, finalMessages);

      AppLogger.info('✅ Image sent successfully');
    } catch (e) {
      AppLogger.error('❌ Failed to send image', e);
      if (_disposed) return;

      final errorMessage = e is AppException ? e.userMessage : 'Failed to send image';

      final updatedMessages = state.messages.map((m) {
        if (m.id == state.messages.last.id && m.role == MessageRole.user) {
          return m.copyWith(
            status: MessageStatus.error,
            errorMessage: errorMessage,
          );
        }
        return m;
      }).toList();

      state = state.copyWith(
        status: CoachStatus.ready,
        messages: updatedMessages,
        isTyping: false,
      );
    }
  }

  /// Set input draft
  void setInputDraft(String text) {
    state = state.copyWith(inputDraft: text);

    // Persist asynchronously
    final userId = _getUserId();
    if (userId != null) {
      _persistence.saveDraft(userId, text);
    }
  }

  /// Retry a failed message
  Future<void> retryMessage(String messageId) async {
    final message = state.messages.firstWhere(
      (m) => m.id == messageId,
      orElse: () => throw Exception('Message not found'),
    );

    if (message.type == MessageType.image && message.imageBase64 != null) {
      await sendImage(message.imageBase64!, 'image/jpeg', message.content);
    } else {
      await sendMessage(message.content);
    }
  }

  /// Clear conversation
  Future<void> clearConversation() async {
    try {
      final userId = _getUserId();
      if (userId == null) return;

      await _persistence.clearMessages(userId);
      await _repository.clearContext();

      if (_disposed) return;

      state = state.copyWith(
        messages: [],
        inputDraft: '',
        suggestedQuestions: _buildInitialSuggestions(state.context),
        totalMessagesInSession: 0,
      );

      AppLogger.info('🗑️ Conversation cleared');
    } catch (e) {
      AppLogger.error('Failed to clear conversation', e);
    }
  }

  /// Start voice input
  Future<void> startVoiceInput() async {
    final available = await _voiceService.initialize();
    if (!available) return;

    state = state.copyWith(isRecordingVoice: true);

    await _voiceService.startListening(
      onPartialResult: (text) {
        if (_disposed) return;
        state = state.copyWith(inputDraft: text);
      },
      onFinalResult: (text) {
        if (_disposed) return;
        state = state.copyWith(
          inputDraft: text,
          isRecordingVoice: false,
        );
      },
      onError: (error) {
        if (_disposed) return;
        state = state.copyWith(isRecordingVoice: false);
        AppLogger.error('Voice input error', error);
      },
    );
  }

  /// Stop voice input
  Future<void> stopVoiceInput() async {
    await _voiceService.stopListening();
    if (_disposed) return;
    state = state.copyWith(isRecordingVoice: false);
  }

  /// Export conversation
  Future<void> exportConversation() async {
    try {
      final export = ConversationExport(
        title: 'RepSense Coach Session — ${DateTime.now().toString().split(' ')[0]}',
        exportedAt: DateTime.now(),
        messages: state.messages,
      );

      final plainText = export.toPlainText();

      await Share.share(
        plainText,
        subject: export.title,
      );

      AppLogger.info('📤 Conversation exported');
    } catch (e) {
      AppLogger.error('Failed to export conversation', e);
    }
  }

  /// Use a quick reply
  void useQuickReply(String question) {
    sendMessage(question);
  }

  /// Refresh context
  Future<void> refreshContext() async {
    try {
      final userId = _getUserId();
      if (userId == null) return;

      final context = await _contextBuilder.build(userId);

      if (_disposed) return;

      state = state.copyWith(context: context);

      AppLogger.info('🔄 Context refreshed');
    } catch (e) {
      AppLogger.error('Failed to refresh context', e);
    }
  }

  // === Private helpers ===

  String? _getUserId() {
    final user = _ref.read(currentUserProvider);
    return user?.id;
  }

  void _trimHistoryIfNeeded() {
    // Context window: last 20 messages
    // This doesn't affect UI, only what's sent to API
  }

  List<String> _buildInitialSuggestions(CoachContext? ctx) {
    if (ctx == null) return _getGeneralSuggestions();

    final suggestions = <String>[];

    // Always include one general question
    suggestions.add('What should I focus on in my next session?');

    // Context-specific suggestions
    if (ctx.weakestMuscleGroup != null) {
      suggestions.add('How do I improve my ${ctx.weakestMuscleGroup} training?');
    }

    if (ctx.recentIssues.isNotEmpty) {
      suggestions.add('How do I fix: ${ctx.recentIssues.first}?');
    }

    if (ctx.mostTrainedExercise != null) {
      suggestions.add('How can I progress my ${ctx.mostTrainedExercise}?');
    }

    if (ctx.currentStreakDays >= 5) {
      suggestions.add(
          "I've trained ${ctx.currentStreakDays} days in a row — how do I avoid overtraining?");
    }

    if (ctx.avgFormScoreLast7Days != null && ctx.avgFormScoreLast7Days! < 70) {
      suggestions.add(
          "My form score is ${ctx.avgFormScoreLast7Days!.round()} — what's the fastest way to improve it?");
    }

    if (ctx.goals.contains('Lose Fat')) {
      suggestions.add('What cardio should I add to my strength training?');
    }

    if (ctx.goals.contains('Build Muscle')) {
      suggestions.add('How much protein do I need for muscle building?');
    }

    // Cap at 4
    return suggestions.take(4).toList();
  }

  List<String> _getGeneralSuggestions() {
    return [
      'What should I focus on in my next session?',
      'How do I improve my squat form?',
      'What are the best exercises for building strength?',
      'How often should I train each week?',
    ];
  }

  List<String> _getOfflineSuggestions() {
    return [
      'Show my recent workout history',
      "What's my current streak?",
      "What's my average form score?",
    ];
  }

  String? _tryAnswerLocally(String question, CoachContext? ctx) {
    if (ctx == null) return null;

    final q = question.toLowerCase();

    if (q.contains('streak')) {
      return "You're on a ${ctx.currentStreakDays}-day streak.";
    }

    if (q.contains('form score') || q.contains('form')) {
      return 'Your average form score over the last 7 days is ${ctx.avgFormScoreLast7Days?.round() ?? 'N/A'}/100.';
    }

    if (q.contains('workout') && q.contains('total')) {
      return "You've completed ${ctx.totalWorkouts} workouts in total.";
    }

    if (q.contains('goal')) {
      return 'Your goals are: ${ctx.goals.join(', ')}.';
    }

    return null;
  }

  void _handleLocalAnswer(String userId, ChatMessage userMessage, String answer) {
    final sentUserMessage = userMessage.copyWith(status: MessageStatus.sent);

    final assistantMessage = ChatMessage(
      id: _uuid.v4(),
      role: MessageRole.assistant,
      content: answer,
      type: MessageType.text,
      status: MessageStatus.sent,
      timestamp: DateTime.now(),
    );

    final finalMessages = [
      ...state.messages.where((m) => m.id != userMessage.id),
      sentUserMessage,
      assistantMessage,
    ];

    state = state.copyWith(
      status: CoachStatus.ready,
      messages: finalMessages,
      isTyping: false,
    );

    _persistence.saveMessages(userId, finalMessages);
  }

  void _handleOfflineError(String userId, ChatMessage userMessage) {
    final contextSummary = _buildContextSummary(state.context);

    final errorMessage = ChatMessage(
      id: _uuid.v4(),
      role: MessageRole.assistant,
      content:
          'Your AI coach is currently unavailable. Here\'s what I know from your data:\n\n$contextSummary\n\nPlease try again when connected.',
      type: MessageType.text,
      status: MessageStatus.sent,
      timestamp: DateTime.now(),
    );

    final sentUserMessage = userMessage.copyWith(status: MessageStatus.sent);

    final finalMessages = [
      ...state.messages.where((m) => m.id != userMessage.id),
      sentUserMessage,
      errorMessage,
    ];

    state = state.copyWith(
      status: CoachStatus.ready,
      messages: finalMessages,
      isTyping: false,
    );

    _persistence.saveMessages(userId, finalMessages);
  }

  String _buildContextSummary(CoachContext? ctx) {
    if (ctx == null) return 'No data available';

    final buffer = StringBuffer();

    buffer.writeln('• Total workouts: ${ctx.totalWorkouts}');
    buffer.writeln('• Current streak: ${ctx.currentStreakDays} days');

    if (ctx.avgFormScoreLast7Days != null) {
      buffer.writeln(
          '• Avg form score (7 days): ${ctx.avgFormScoreLast7Days!.round()}/100');
    }

    if (ctx.mostTrainedExercise != null) {
      buffer.writeln('• Most trained: ${ctx.mostTrainedExercise}');
    }

    return buffer.toString();
  }

  void _startHealthCheck() {
    _healthCheckTimer = Timer.periodic(const Duration(seconds: 30), (timer) async {
      if (_disposed) {
        timer.cancel();
        return;
      }

      final isAvailable = await _repository.isAvailable();

      if (_disposed) return;

      if (isAvailable != state.isServiceAvailable) {
        state = state.copyWith(isServiceAvailable: isAvailable);

        if (isAvailable) {
          AppLogger.info('✅ Coach service back online');
        }
      }
    });
  }
}
