import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import 'connectivity_service.dart';

/// Queue for storing operations that failed due to network issues
/// Will retry when network is restored
class PendingOperationsQueue {
  static const String _boxName = 'pending_operations';
  static Box? _box;
  static final _uuid = const Uuid();

  /// Initialize the queue
  static Future<void> initialize() async {
    try {
      _box = await Hive.openBox(_boxName);
      debugPrint('✅ Pending operations queue initialized');
    } catch (e) {
      debugPrint('⚠️ Failed to initialize pending operations queue: $e');
    }
  }

  /// Add an operation to the queue
  static Future<void> enqueue(PendingOperation operation) async {
    try {
      if (_box == null) await initialize();
      await _box!.put(operation.id, operation.toJson());
      debugPrint('📝 Queued operation: ${operation.type}');
    } catch (e) {
      debugPrint('⚠️ Failed to enqueue operation: $e');
    }
  }

  /// Get all pending operations
  static List<PendingOperation> getAll() {
    try {
      if (_box == null) return [];
      return _box!.values
          .map((json) => PendingOperation.fromJson(Map<String, dynamic>.from(json)))
          .toList()
        ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
    } catch (e) {
      debugPrint('⚠️ Failed to get pending operations: $e');
      return [];
    }
  }

  /// Remove an operation from the queue
  static Future<void> remove(String operationId) async {
    try {
      await _box?.delete(operationId);
      debugPrint('✅ Removed operation: $operationId');
    } catch (e) {
      debugPrint('⚠️ Failed to remove operation: $e');
    }
  }

  /// Clear all pending operations
  static Future<void> clear() async {
    try {
      await _box?.clear();
      debugPrint('✅ Cleared all pending operations');
    } catch (e) {
      debugPrint('⚠️ Failed to clear pending operations: $e');
    }
  }

  /// Process all pending operations (called when network is restored)
  static Future<void> processAll() async {
    final operations = getAll();
    if (operations.isEmpty) {
      debugPrint('✅ No pending operations to process');
      return;
    }

    debugPrint('🔄 Processing ${operations.length} pending operations...');

    for (final operation in operations) {
      try {
        // TODO: Execute the operation based on type
        // This should call the appropriate repository method
        debugPrint('Processing: ${operation.type}');

        switch (operation.type) {
          case OperationType.createWorkout:
            // await WorkoutRepository.createWorkout(operation.data);
            break;
          case OperationType.updateProfile:
            // await ProfileRepository.updateProfile(operation.data);
            break;
          case OperationType.logSet:
            // await WorkoutRepository.logSet(operation.data);
            break;
          case OperationType.sendFeedback:
            // await ProfileRepository.sendFeedback(operation.data);
            break;
        }

        // Remove from queue if successful
        await remove(operation.id);
        debugPrint('✅ Operation completed: ${operation.type}');
      } catch (e) {
        debugPrint('⚠️ Operation failed: ${operation.type} - $e');
        // Keep in queue for next retry
      }
    }
  }
}

/// Type of operation
enum OperationType {
  createWorkout,
  updateProfile,
  logSet,
  sendFeedback,
}

/// Pending operation model
class PendingOperation {
  final String id;
  final OperationType type;
  final Map<String, dynamic> data;
  final DateTime timestamp;

  PendingOperation({
    required this.id,
    required this.type,
    required this.data,
    required this.timestamp,
  });

  factory PendingOperation.create({
    required OperationType type,
    required Map<String, dynamic> data,
  }) {
    return PendingOperation(
      id: const Uuid().v4(),
      type: type,
      data: data,
      timestamp: DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.name,
      'data': data,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory PendingOperation.fromJson(Map<String, dynamic> json) {
    return PendingOperation(
      id: json['id'],
      type: OperationType.values.firstWhere((e) => e.name == json['type']),
      data: Map<String, dynamic>.from(json['data']),
      timestamp: DateTime.parse(json['timestamp']),
    );
  }
}
