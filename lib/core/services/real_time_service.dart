import 'dart:async';
import 'dart:collection';

import 'package:flutter/foundation.dart';
import 'package:grex/core/services/offline_queue_storage.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Enum representing the connection state of the real-time service
enum ConnectionState {
  /// Service is connected and active
  connected,

  /// Service is disconnected
  disconnected,

  /// Service is currently establishing a connection
  connecting,

  /// Service is attempting to reconnect after a lost connection
  reconnecting,
}

/// Represents a queued change that needs to be synced when connection is
/// restored
class QueuedChange {
  /// Creates a [QueuedChange] instance
  const QueuedChange({
    required this.id,
    required this.table,
    required this.operation,
    required this.data,
    required this.timestamp,
  });

  /// The unique identifier of the change
  final String id;

  /// The table name where the change occurred
  final String table;

  /// The database operation performed ('INSERT', 'UPDATE', 'DELETE')
  final String operation;

  /// The data associated with the change
  final Map<String, dynamic> data;

  /// The timestamp when the change was queued
  final DateTime timestamp;
}

/// Abstract interface for real-time service
abstract class RealTimeService {
  /// Current connection state
  Stream<ConnectionState> get connectionState;

  /// Subscribe to changes for a specific table
  RealtimeChannel subscribeToTable(
    String table, {
    String? filter,
    void Function(Map<String, dynamic>)? onData,
    void Function(Object)? onError,
  });

  /// Subscribe to changes for a specific group's data
  RealtimeChannel subscribeToGroup(
    String groupId,
    String table, {
    void Function(Map<String, dynamic>)? onData,
    void Function(Object)? onError,
  });

  /// Queue a change for offline sync
  Future<void> queueChange(QueuedChange change);

  /// Get all queued changes
  List<QueuedChange> getQueuedChanges();

  /// Clear queued changes (after successful sync)
  Future<void> clearQueuedChanges();

  /// Manually trigger sync of queued changes
  Future<void> syncQueuedChanges();

  /// Start the real-time service
  Future<void> start();

  /// Stop the real-time service and cleanup subscriptions
  Future<void> stop();

  /// Dispose the service
  void dispose();
}

/// Implementation of real-time service using Supabase
class SupabaseRealTimeService implements RealTimeService {
  /// Creates a [SupabaseRealTimeService] instance
  SupabaseRealTimeService({
    SupabaseClient? supabaseClient,
    OfflineQueueStorage? queueStorage,
  }) : _supabaseClient = supabaseClient ?? Supabase.instance.client,
       _queueStorage = queueStorage,
       _connectionStateController =
           StreamController<ConnectionState>.broadcast(),
       _queuedChanges = Queue<QueuedChange>(),
       _channels = <String, RealtimeChannel>{};
  final SupabaseClient _supabaseClient;
  final OfflineQueueStorage? _queueStorage;
  final StreamController<ConnectionState> _connectionStateController;
  final Queue<QueuedChange> _queuedChanges;
  final Map<String, RealtimeChannel> _channels;

  Timer? _reconnectTimer;
  Timer? _syncTimer;
  bool _isDisposed = false;
  bool _isQueueLoaded = false;

  @override
  Stream<ConnectionState> get connectionState =>
      _connectionStateController.stream;

  @override
  Future<void> start() async {
    if (_isDisposed) return;

    // Load queued changes from storage if available
    await _loadQueuedChanges();

    _connectionStateController.add(ConnectionState.connecting);

    try {
      // For now, just mark as connected since Supabase handles connection
      // internally
      _connectionStateController.add(ConnectionState.connected);
      _startSyncTimer();
    } on Exception catch (_) {
      if (!_isDisposed) {
        _connectionStateController.add(ConnectionState.disconnected);
        _scheduleReconnect();
      }
    }
  }

  @override
  Future<void> stop() async {
    _stopSyncTimer();
    _cancelReconnectTimer();

    // Unsubscribe all channels
    for (final channel in _channels.values) {
      await channel.unsubscribe();
    }
    _channels.clear();
  }

  @override
  RealtimeChannel subscribeToTable(
    String table, {
    String? filter,
    void Function(Map<String, dynamic>)? onData,
    void Function(Object)? onError,
  }) {
    final channelKey = '${table}_${filter ?? 'all'}';

    // Unsubscribe existing channel if any
    final existingChannel = _channels[channelKey];
    if (existingChannel != null) {
      unawaited(existingChannel.unsubscribe());
    }

    final channel = _supabaseClient.realtime.channel('public:$table');

    if (filter != null) {
      final filterParts = filter.split('=');
      if (filterParts.length == 2) {
        channel.onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: table,
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: filterParts[0],
            value: filterParts[1],
          ),
          callback: (payload) {
            if (onData != null) {
              onData(payload.newRecord);
            }
          },
        );
      }
    } else {
      channel.onPostgresChanges(
        event: PostgresChangeEvent.all,
        schema: 'public',
        table: table,
        callback: (payload) {
          if (onData != null) {
            onData(payload.newRecord);
          }
        },
      );
    }

    channel.subscribe();
    _channels[channelKey] = channel;

    return channel;
  }

  @override
  RealtimeChannel subscribeToGroup(
    String groupId,
    String table, {
    void Function(Map<String, dynamic>)? onData,
    void Function(Object)? onError,
  }) {
    return subscribeToTable(
      table,
      filter: 'group_id=$groupId',
      onData: onData,
      onError: onError,
    );
  }

  @override
  Future<void> queueChange(QueuedChange change) async {
    _queuedChanges.add(change);

    // Limit queue size to prevent memory issues
    while (_queuedChanges.length > 1000) {
      _queuedChanges.removeFirst();
    }

    // Save to persistent storage if available
    await _saveQueuedChanges();
  }

  @override
  List<QueuedChange> getQueuedChanges() {
    return _queuedChanges.toList();
  }

  @override
  Future<void> clearQueuedChanges() async {
    _queuedChanges.clear();
    await _queueStorage?.clearQueuedChanges();
  }

  @override
  Future<void> syncQueuedChanges() async {
    if (_queuedChanges.isEmpty) return;

    final changesToSync = _queuedChanges.toList();

    try {
      for (final change in changesToSync) {
        await _syncSingleChange(change);
        _queuedChanges.remove(change);
      }
    } catch (e) {
      // Keep changes in queue if sync fails
      rethrow;
    }
  }

  Future<void> _syncSingleChange(QueuedChange change) async {
    switch (change.operation) {
      case 'INSERT':
        await _supabaseClient.from(change.table).insert(change.data);
      case 'UPDATE':
        await _supabaseClient
            .from(change.table)
            .update(change.data)
            .eq('id', change.data['id'] as Object);
      case 'DELETE':
        await _supabaseClient
            .from(change.table)
            .delete()
            .eq('id', change.data['id'] as Object);
    }
  }

  void _scheduleReconnect() {
    _cancelReconnectTimer();

    _reconnectTimer = Timer(const Duration(seconds: 5), () async {
      if (!_isDisposed) {
        _connectionStateController.add(ConnectionState.reconnecting);
        await start();
      }
    });
  }

  void _cancelReconnectTimer() {
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
  }

  void _startSyncTimer() {
    _stopSyncTimer();

    _syncTimer = Timer.periodic(const Duration(minutes: 1), (timer) async {
      if (!_isDisposed && _queuedChanges.isNotEmpty) {
        try {
          await syncQueuedChanges();
        } on Exception catch (_) {
          // Log error but continue timer
        }
      }
    });
  }

  void _stopSyncTimer() {
    _syncTimer?.cancel();
    _syncTimer = null;
  }

  Future<void> _loadQueuedChanges() async {
    if (_isQueueLoaded || _queueStorage == null) return;

    try {
      final savedChanges = await _queueStorage.loadQueuedChanges();
      _queuedChanges.addAll(savedChanges);
      _isQueueLoaded = true;
    } on Exception catch (e) {
      // Log error but continue
      if (kDebugMode) {
        debugPrint('Failed to load queued changes: $e');
      }
    }
  }

  Future<void> _saveQueuedChanges() async {
    if (_queueStorage == null) return;

    try {
      await _queueStorage.saveQueuedChanges(_queuedChanges.toList());
    } on Exception catch (e) {
      // Log error but continue
      if (kDebugMode) {
        debugPrint('Failed to save queued changes: $e');
      }
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    unawaited(_connectionStateController.close());
    _cancelReconnectTimer();
    _stopSyncTimer();
    unawaited(stop());
  }
}
