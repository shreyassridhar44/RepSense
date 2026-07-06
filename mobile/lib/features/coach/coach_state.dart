import 'package:equatable/equatable.dart';
import '../../data/models/chat_models.dart';

/// Coach screen status
enum CoachStatus {
  loadingContext,
  ready,
  sending,
  error,
  unavailable,
}

/// Coach screen state
class CoachState extends Equatable {
  final CoachStatus status;
  final List<ChatMessage> messages;
  final CoachContext? context;
  final bool isTyping;
  final bool isServiceAvailable;
  final bool isContextLoaded;
  final String? errorMessage;
  final List<String> suggestedQuestions;
  final bool isRecordingVoice;
  final String inputDraft;
  final int totalMessagesInSession;

  const CoachState({
    this.status = CoachStatus.loadingContext,
    this.messages = const [],
    this.context,
    this.isTyping = false,
    this.isServiceAvailable = true,
    this.isContextLoaded = false,
    this.errorMessage,
    this.suggestedQuestions = const [],
    this.isRecordingVoice = false,
    this.inputDraft = '',
    this.totalMessagesInSession = 0,
  });

  CoachState copyWith({
    CoachStatus? status,
    List<ChatMessage>? messages,
    CoachContext? context,
    bool? isTyping,
    bool? isServiceAvailable,
    bool? isContextLoaded,
    String? errorMessage,
    List<String>? suggestedQuestions,
    bool? isRecordingVoice,
    String? inputDraft,
    int? totalMessagesInSession,
  }) {
    return CoachState(
      status: status ?? this.status,
      messages: messages ?? this.messages,
      context: context ?? this.context,
      isTyping: isTyping ?? this.isTyping,
      isServiceAvailable: isServiceAvailable ?? this.isServiceAvailable,
      isContextLoaded: isContextLoaded ?? this.isContextLoaded,
      errorMessage: errorMessage ?? this.errorMessage,
      suggestedQuestions: suggestedQuestions ?? this.suggestedQuestions,
      isRecordingVoice: isRecordingVoice ?? this.isRecordingVoice,
      inputDraft: inputDraft ?? this.inputDraft,
      totalMessagesInSession: totalMessagesInSession ?? this.totalMessagesInSession,
    );
  }

  @override
  List<Object?> get props => [
        status,
        messages,
        context,
        isTyping,
        isServiceAvailable,
        isContextLoaded,
        errorMessage,
        suggestedQuestions,
        isRecordingVoice,
        inputDraft,
        totalMessagesInSession,
      ];
}
