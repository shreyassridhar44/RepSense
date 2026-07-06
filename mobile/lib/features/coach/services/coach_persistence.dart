import 'package:hive_flutter/hive_flutter.dart';
import '../../../core/utils/app_logger.dart';
import '../../../data/models/chat_models.dart';

/// Persistence for coach conversations using Hive
class CoachPersistence {
  static const String _boxName = 'coach_conversations';
  static const String _draftKey = 'input_draft';
  static const int _maxPersistedMessages = 50;

  Box<dynamic>? _box;

  /// Initialize Hive box
  Future<void> init() async {
    try {
      _box = await Hive.openBox(_boxName);
    } catch (e) {
      AppLogger.error('Failed to open coach persistence box', e);
    }
  }

  /// Save messages for a user
  Future<void> saveMessages(String userId, List<ChatMessage> messages) async {
    try {
      if (_box == null) await init();
      if (_box == null) return;

      // Only save last _maxPersistedMessages
      final toSave = messages.length > _maxPersistedMessages
          ? messages.sublist(messages.length - _maxPersistedMessages)
          : messages;

      // Serialize messages (exclude imageBase64)
      final serialized = toSave.map((msg) {
        final json = msg.toJson();
        // Replace image content with placeholder
        if (msg.type == MessageType.image) {
          json['content'] = '[Image]';
        }
        return json;
      }).toList();

      await _box!.put('messages_$userId', serialized);
      AppLogger.debug('💾 Saved ${toSave.length} messages for user $userId');
    } catch (e, stack) {
      AppLogger.error('Failed to save messages', e, stack);
    }
  }

  /// Load messages for a user
  Future<List<ChatMessage>> loadMessages(String userId) async {
    try {
      if (_box == null) await init();
      if (_box == null) return [];

      final data = _box!.get('messages_$userId') as List<dynamic>?;
      if (data == null) return [];

      final messages = data
          .map((json) {
            try {
              final message = ChatMessage.fromJson(json as Map<String, dynamic>);
              // All loaded messages are in sent state, not animating
              return message.copyWith(
                status: MessageStatus.sent,
                isAnimating: false,
              );
            } catch (e) {
              AppLogger.error('Failed to deserialize message', e);
              return null;
            }
          })
          .whereType<ChatMessage>()
          .toList();

      AppLogger.debug('📂 Loaded ${messages.length} messages for user $userId');
      return messages;
    } catch (e, stack) {
      AppLogger.error('Failed to load messages', e, stack);
      // If corruption, try to delete and recreate
      try {
        await _box?.delete('messages_$userId');
      } catch (_) {}
      return [];
    }
  }

  /// Save input draft
  Future<void> saveDraft(String userId, String draft) async {
    try {
      if (_box == null) await init();
      if (_box == null) return;

      await _box!.put('${_draftKey}_$userId', draft);
    } catch (e) {
      AppLogger.debug('Failed to save draft');
    }
  }

  /// Load input draft
  Future<String> loadDraft(String userId) async {
    try {
      if (_box == null) await init();
      if (_box == null) return '';

      final draft = _box!.get('${_draftKey}_$userId') as String?;
      return draft ?? '';
    } catch (e) {
      AppLogger.debug('Failed to load draft');
      return '';
    }
  }

  /// Clear messages for a user
  Future<void> clearMessages(String userId) async {
    try {
      if (_box == null) await init();
      if (_box == null) return;

      await _box!.delete('messages_$userId');
      await _box!.delete('${_draftKey}_$userId');
      AppLogger.info('🗑️ Cleared messages for user $userId');
    } catch (e) {
      AppLogger.error('Failed to clear messages', e);
    }
  }

  /// Clear all persisted data
  Future<void> clearAll() async {
    try {
      if (_box == null) await init();
      if (_box == null) return;

      await _box!.clear();
      AppLogger.info('🗑️ Cleared all coach persistence');
    } catch (e) {
      AppLogger.error('Failed to clear all', e);
    }
  }

  /// Close the box
  Future<void> close() async {
    await _box?.close();
    _box = null;
  }
}
