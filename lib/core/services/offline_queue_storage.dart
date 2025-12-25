import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:grex/core/services/real_time_service.dart';

/// Handles persistent storage of offline queue changes
class OfflineQueueStorage {
  /// Creates an [OfflineQueueStorage] instance
  const OfflineQueueStorage({
    required FlutterSecureStorage secureStorage,
  }) : _secureStorage = secureStorage;
  final FlutterSecureStorage _secureStorage;
  static const String _queueKey = 'offline_queue_changes';

  /// Save queued changes to persistent storage
  Future<void> saveQueuedChanges(List<QueuedChange> changes) async {
    try {
      final jsonList = changes
          .map(
            (change) => {
              'id': change.id,
              'table': change.table,
              'operation': change.operation,
              'data': change.data,
              'timestamp': change.timestamp.toIso8601String(),
            },
          )
          .toList();

      final jsonString = jsonEncode(jsonList);
      await _secureStorage.write(key: _queueKey, value: jsonString);
    } on Exception catch (e) {
      // Log error but don't throw to avoid breaking the app
      if (kDebugMode) {
        debugPrint('Failed to save queued changes: $e');
      }
    }
  }

  /// Load queued changes from persistent storage
  Future<List<QueuedChange>> loadQueuedChanges() async {
    try {
      final jsonString = await _secureStorage.read(key: _queueKey);
      if (jsonString == null) return [];

      final jsonList = jsonDecode(jsonString) as List<dynamic>;
      return jsonList.map(
        (json) {
          final map = json as Map<String, dynamic>;
          return QueuedChange(
            id: map['id'] as String,
            table: map['table'] as String,
            operation: map['operation'] as String,
            data: Map<String, dynamic>.from(map['data'] as Map),
            timestamp: DateTime.parse(map['timestamp'] as String),
          );
        },
      ).toList();
    } on Exception catch (e) {
      // Log error and return empty list
      if (kDebugMode) {
        debugPrint('Failed to load queued changes: $e');
      }
      return [];
    }
  }

  /// Clear all queued changes from storage
  Future<void> clearQueuedChanges() async {
    try {
      await _secureStorage.delete(key: _queueKey);
    } on Exception catch (e) {
      if (kDebugMode) {
        debugPrint('Failed to clear queued changes: $e');
      }
    }
  }

  /// Remove specific changes from storage
  Future<void> removeQueuedChanges(List<String> changeIds) async {
    try {
      final currentChanges = await loadQueuedChanges();
      final remainingChanges = currentChanges
          .where((change) => !changeIds.contains(change.id))
          .toList();

      await saveQueuedChanges(remainingChanges);
    } on Exception catch (e) {
      if (kDebugMode) {
        debugPrint('Failed to remove queued changes: $e');
      }
    }
  }
}
