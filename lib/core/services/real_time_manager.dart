import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:grex/core/services/real_time_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Manages real-time subscriptions for different features
class RealTimeManager {
  /// Creates a [RealTimeManager] instance
  RealTimeManager({
    required RealTimeService realTimeService,
  }) : _realTimeService = realTimeService;
  final RealTimeService _realTimeService;
  final Map<String, RealtimeChannel> _channels = {};
  final Map<String, StreamController<Map<String, dynamic>>> _controllers = {};

  bool _isInitialized = false;

  /// Initialize the real-time manager
  Future<void> initialize() async {
    if (_isInitialized) return;

    await _realTimeService.start();
    _isInitialized = true;
  }

  /// Get connection state stream
  Stream<ConnectionState> get connectionState =>
      _realTimeService.connectionState;

  /// Subscribe to group changes for a specific user
  Stream<Map<String, dynamic>> subscribeToUserGroups(String userId) {
    final key = 'user_groups_$userId';

    if (_controllers.containsKey(key)) {
      return _controllers[key]!.stream;
    }

    final controller = StreamController<Map<String, dynamic>>.broadcast();
    _controllers[key] = controller;

    final channel = _realTimeService.subscribeToTable(
      'group_members',
      filter: 'user_id=$userId',
      onData: (data) {
        if (!controller.isClosed) {
          controller.add(data);
        }
      },
      onError: (Object error) {
        if (!controller.isClosed) {
          controller.addError(error);
        }
      },
    );

    _channels[key] = channel;
    return controller.stream;
  }

  /// Subscribe to group member changes
  Stream<Map<String, dynamic>> subscribeToGroupMembers(String groupId) {
    final key = 'group_members_$groupId';

    if (_controllers.containsKey(key)) {
      return _controllers[key]!.stream;
    }

    final controller = StreamController<Map<String, dynamic>>.broadcast();
    _controllers[key] = controller;

    final channel = _realTimeService.subscribeToGroup(
      groupId,
      'group_members',
      onData: (data) {
        if (!controller.isClosed) {
          controller.add(data);
        }
      },
      onError: (Object error) {
        if (!controller.isClosed) {
          controller.addError(error);
        }
      },
    );

    _channels[key] = channel;
    return controller.stream;
  }

  /// Subscribe to expense changes for a group
  Stream<Map<String, dynamic>> subscribeToGroupExpenses(String groupId) {
    final key = 'group_expenses_$groupId';

    if (_controllers.containsKey(key)) {
      return _controllers[key]!.stream;
    }

    final controller = StreamController<Map<String, dynamic>>.broadcast();
    _controllers[key] = controller;

    final channel = _realTimeService.subscribeToGroup(
      groupId,
      'expenses',
      onData: (data) {
        if (!controller.isClosed) {
          controller.add(data);
        }
      },
      onError: (Object error) {
        if (!controller.isClosed) {
          controller.addError(error);
        }
      },
    );

    _channels[key] = channel;
    return controller.stream;
  }

  /// Subscribe to payment changes for a group
  Stream<Map<String, dynamic>> subscribeToGroupPayments(String groupId) {
    final key = 'group_payments_$groupId';

    if (_controllers.containsKey(key)) {
      return _controllers[key]!.stream;
    }

    final controller = StreamController<Map<String, dynamic>>.broadcast();
    _controllers[key] = controller;

    final channel = _realTimeService.subscribeToGroup(
      groupId,
      'payments',
      onData: (data) {
        if (!controller.isClosed) {
          controller.add(data);
        }
      },
      onError: (Object error) {
        if (!controller.isClosed) {
          controller.addError(error);
        }
      },
    );

    _channels[key] = channel;
    return controller.stream;
  }

  /// Subscribe to balance changes for a group
  Stream<Map<String, dynamic>> subscribeToGroupBalances(String groupId) {
    final key = 'group_balances_$groupId';

    if (_controllers.containsKey(key)) {
      return _controllers[key]!.stream;
    }

    final controller = StreamController<Map<String, dynamic>>.broadcast();
    _controllers[key] = controller;

    // Subscribe to both expenses and payments as they affect balances
    final expenseChannel = _realTimeService.subscribeToGroup(
      groupId,
      'expenses',
      onData: (data) {
        if (!controller.isClosed) {
          controller.add(data);
        }
      },
    );

    final paymentChannel = _realTimeService.subscribeToGroup(
      groupId,
      'payments',
      onData: (data) {
        if (!controller.isClosed) {
          controller.add(data);
        }
      },
    );

    // Store both channels
    _channels['${key}_expenses'] = expenseChannel;
    _channels['${key}_payments'] = paymentChannel;

    return controller.stream;
  }

  /// Queue a change for offline sync
  Future<void> queueChange({
    required String table,
    required String operation,
    required Map<String, dynamic> data,
  }) async {
    final change = QueuedChange(
      id:
          (data['id'] as String?) ??
          DateTime.now().millisecondsSinceEpoch.toString(),
      table: table,
      operation: operation,
      data: data,
      timestamp: DateTime.now(),
    );

    await _realTimeService.queueChange(change);
  }

  /// Get queued changes count
  int get queuedChangesCount => _realTimeService.getQueuedChanges().length;

  /// Manually sync queued changes
  Future<void> syncQueuedChanges() async {
    try {
      await _realTimeService.syncQueuedChanges();
    } catch (e) {
      debugPrint('Failed to sync queued changes: $e');
      rethrow;
    }
  }

  /// Unsubscribe from a specific subscription
  Future<void> unsubscribe(String key) async {
    final channel = _channels.remove(key);
    await channel?.unsubscribe();

    final controller = _controllers.remove(key);
    await controller?.close();
  }

  /// Unsubscribe from all group-related subscriptions
  Future<void> unsubscribeFromGroup(String groupId) async {
    final keysToRemove = <String>[];

    for (final key in _channels.keys) {
      if (key.contains(groupId)) {
        keysToRemove.add(key);
      }
    }

    for (final key in keysToRemove) {
      await unsubscribe(key);
    }
  }

  /// Dispose the manager and cleanup all resources
  Future<void> dispose() async {
    // Unsubscribe all channels
    for (final channel in _channels.values) {
      await channel.unsubscribe();
    }
    _channels.clear();

    // Close all controllers
    for (final controller in _controllers.values) {
      await controller.close();
    }
    _controllers.clear();

    // Stop the real-time service
    await _realTimeService.stop();
    _realTimeService.dispose();

    _isInitialized = false;
  }
}
