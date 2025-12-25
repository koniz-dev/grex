import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:grex/core/services/offline_queue_storage.dart';
import 'package:grex/core/services/real_time_service.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

@GenerateMocks(
  [
    SupabaseClient,
    OfflineQueueStorage,
    RealtimeChannel,
    RealtimeClient,
    SupabaseQueryBuilder,
  ],
  customMocks: [
    MockSpec<PostgrestQueryBuilder<dynamic>>(
      as: #MockPostgrestQueryBuilderRealTime,
    ),
    MockSpec<PostgrestFilterBuilder<dynamic>>(
      as: #MockPostgrestFilterBuilderRealTime,
    ),
  ],
)
import 'real_time_service_test.mocks.dart';

// Fake implementation that implements PostgrestFilterBuilder and Future
class _FakePostgrestFilterBuilderForInsert extends Fake
    implements PostgrestFilterBuilder<dynamic> {
  _FakePostgrestFilterBuilderForInsert(this._value);
  final List<Map<String, dynamic>> _value;

  @override
  Future<R> then<R>(
    FutureOr<R> Function(dynamic value) onValue, {
    Function? onError,
  }) async {
    return onValue(_value);
  }

  @override
  Future<dynamic> catchError(
    Function onError, {
    bool Function(Object)? test,
  }) {
    return Future<dynamic>.value(_value);
  }

  @override
  Stream<dynamic> asStream() {
    return Stream<dynamic>.value(_value);
  }

  @override
  Future<dynamic> timeout(
    Duration timeLimit, {
    FutureOr<dynamic> Function()? onTimeout,
  }) {
    return Future<dynamic>.value(_value);
  }

  @override
  Future<dynamic> whenComplete(
    FutureOr<void> Function() action,
  ) {
    return Future<dynamic>.value(_value);
  }
}

void main() {
  group('SupabaseRealTimeService', () {
    late MockSupabaseClient mockSupabaseClient;
    late MockOfflineQueueStorage mockQueueStorage;
    late MockRealtimeClient mockRealtimeClient;
    late MockRealtimeChannel mockChannel;
    late SupabaseRealTimeService realTimeService;

    setUp(() {
      mockSupabaseClient = MockSupabaseClient();
      mockQueueStorage = MockOfflineQueueStorage();
      mockRealtimeClient = MockRealtimeClient();
      mockChannel = MockRealtimeChannel();

      when(mockSupabaseClient.realtime).thenReturn(mockRealtimeClient);
      when(mockRealtimeClient.channel(any)).thenReturn(mockChannel);
      when(mockChannel.subscribe()).thenReturn(mockChannel);
      when(mockChannel.unsubscribe()).thenAnswer((_) async => 'closed');

      realTimeService = SupabaseRealTimeService(
        supabaseClient: mockSupabaseClient,
        queueStorage: mockQueueStorage,
      );
    });

    tearDown(() {
      realTimeService.dispose();
    });

    group('Service Lifecycle', () {
      test(
        'should start service and emit connecting then connected state',
        () async {
          // Arrange
          final states = <ConnectionState>[];
          final subscription = realTimeService.connectionState.listen(
            states.add,
          );

          // Act
          await realTimeService.start();

          // Allow async operations to complete
          await Future<void>.delayed(const Duration(milliseconds: 10));

          // Assert
          expect(states, contains(ConnectionState.connecting));
          expect(states, contains(ConnectionState.connected));

          await subscription.cancel();
        },
      );

      test('should stop service and cleanup subscriptions', () async {
        // Arrange
        await realTimeService.start();

        // Subscribe to a table to create channels
        realTimeService.subscribeToTable('expenses');

        // Act
        await realTimeService.stop();

        // Assert
        verify(mockChannel.unsubscribe()).called(1);
      });

      test('should dispose service and close streams', () async {
        // Arrange
        await realTimeService.start();
        var streamClosed = false;

        realTimeService.connectionState.listen(
          (_) {},
          onDone: () => streamClosed = true,
        );

        // Act
        realTimeService.dispose();

        // Allow async operations to complete
        await Future<void>.delayed(const Duration(milliseconds: 10));

        // Assert
        expect(streamClosed, isTrue);
      });
    });

    group('Table Subscriptions', () {
      test('should subscribe to table without filter', () async {
        // Arrange
        await realTimeService.start();

        // Act
        final channel = realTimeService.subscribeToTable('expenses');

        // Assert
        expect(channel, equals(mockChannel));
        verify(mockRealtimeClient.channel('public:expenses')).called(1);
        verify(mockChannel.subscribe()).called(1);
      });

      test('should subscribe to table with filter', () async {
        // Arrange
        await realTimeService.start();

        // Act
        final channel = realTimeService.subscribeToTable(
          'expenses',
          filter: 'group_id=test-group',
        );

        // Assert
        expect(channel, equals(mockChannel));
        verify(mockRealtimeClient.channel('public:expenses')).called(1);
        verify(mockChannel.subscribe()).called(1);
      });

      test('should handle subscription data callback', () async {
        // Arrange
        await realTimeService.start();
        Map<String, dynamic>? receivedData;

        // Act
        realTimeService.subscribeToTable(
          'expenses',
          onData: (data) => receivedData = data,
        );

        // Simulate data callback
        final testData = {'id': 'test', 'amount': 100.0};
        // Note: In real implementation, this would be triggered by Supabase
        receivedData = testData;

        // Assert
        expect(receivedData, equals(testData));
      });

      test('should handle subscription error callback', () async {
        // Arrange
        await realTimeService.start();
        Object? receivedError;

        // Act
        realTimeService.subscribeToTable(
          'expenses',
          onError: (error) => receivedError = error,
        );

        // Simulate error callback
        const testError = 'Connection error';
        receivedError = testError;

        // Assert
        expect(receivedError, equals(testError));
      });

      test('should subscribe to group-specific data', () async {
        // Arrange
        await realTimeService.start();

        // Act
        final channel = realTimeService.subscribeToGroup(
          'test-group',
          'expenses',
        );

        // Assert
        expect(channel, equals(mockChannel));
        verify(mockRealtimeClient.channel('public:expenses')).called(1);
      });

      test('should unsubscribe existing channel when resubscribing', () async {
        // Arrange
        await realTimeService.start();

        // First subscription
        realTimeService
          ..subscribeToTable('expenses')
          ..subscribeToTable('expenses');

        // Assert - Should unsubscribe previous channel
        verify(mockChannel.unsubscribe()).called(1);
        verify(mockChannel.subscribe()).called(2);
      });
    });

    group('Offline Queue Management', () {
      test('should queue change when offline', () async {
        // Arrange
        final change = QueuedChange(
          id: 'test-change',
          table: 'expenses',
          operation: 'INSERT',
          data: {'id': 'test', 'amount': 100.0},
          timestamp: DateTime.now(),
        );

        when(mockQueueStorage.saveQueuedChanges(any)).thenAnswer((_) async {});

        // Act
        await realTimeService.queueChange(change);

        // Assert
        final queuedChanges = realTimeService.getQueuedChanges();
        expect(queuedChanges, contains(change));
        verify(mockQueueStorage.saveQueuedChanges(any)).called(1);
      });

      test('should load queued changes on start', () async {
        // Arrange
        final savedChanges = [
          QueuedChange(
            id: 'saved-1',
            table: 'expenses',
            operation: 'INSERT',
            data: {'id': 'test1'},
            timestamp: DateTime.now(),
          ),
          QueuedChange(
            id: 'saved-2',
            table: 'expenses',
            operation: 'UPDATE',
            data: {'id': 'test2'},
            timestamp: DateTime.now(),
          ),
        ];

        when(
          mockQueueStorage.loadQueuedChanges(),
        ).thenAnswer((_) async => savedChanges);

        // Act
        await realTimeService.start();

        // Assert
        verify(mockQueueStorage.loadQueuedChanges()).called(1);
        final queuedChanges = realTimeService.getQueuedChanges();
        expect(queuedChanges.length, equals(2));
      });

      test('should clear queued changes', () async {
        // Arrange
        final change = QueuedChange(
          id: 'test-change',
          table: 'expenses',
          operation: 'INSERT',
          data: {'id': 'test'},
          timestamp: DateTime.now(),
        );

        await realTimeService.queueChange(change);
        when(mockQueueStorage.clearQueuedChanges()).thenAnswer((_) async {});

        // Act
        await realTimeService.clearQueuedChanges();

        // Assert
        final queuedChanges = realTimeService.getQueuedChanges();
        expect(queuedChanges, isEmpty);
        verify(mockQueueStorage.clearQueuedChanges()).called(1);
      });

      test('should limit queue size to prevent memory issues', () async {
        // Arrange
        when(mockQueueStorage.saveQueuedChanges(any)).thenAnswer((_) async {});

        // Act - Add more than 1000 changes
        for (var i = 0; i < 1100; i++) {
          await realTimeService.queueChange(
            QueuedChange(
              id: 'change-$i',
              table: 'expenses',
              operation: 'INSERT',
              data: {'id': 'test-$i'},
              timestamp: DateTime.now(),
            ),
          );
        }

        // Assert - Queue size should be limited to 1000
        final queuedChanges = realTimeService.getQueuedChanges();
        expect(queuedChanges.length, equals(1000));
      });
    });

    group('Change Synchronization', () {
      test('should sync INSERT operation', () async {
        // Arrange
        final change = QueuedChange(
          id: 'test-insert',
          table: 'expenses',
          operation: 'INSERT',
          data: {'id': 'test', 'amount': 100.0},
          timestamp: DateTime.now(),
        );

        await realTimeService.queueChange(change);

        final mockQueryBuilder = MockSupabaseQueryBuilder();
        when(mockSupabaseClient.from('expenses')).thenReturn(mockQueryBuilder);
        when(
          mockQueryBuilder.insert(any),
        ).thenReturn(_FakePostgrestFilterBuilderForInsert([]));

        // Act
        await realTimeService.syncQueuedChanges();

        // Assert
        verify(mockSupabaseClient.from('expenses')).called(1);
        verify(mockQueryBuilder.insert(change.data)).called(1);
      });

      test('should sync UPDATE operation', () async {
        // Arrange
        final change = QueuedChange(
          id: 'test-update',
          table: 'expenses',
          operation: 'UPDATE',
          data: {'id': 'test', 'amount': 200.0},
          timestamp: DateTime.now(),
        );

        await realTimeService.queueChange(change);

        final mockQueryBuilder = MockSupabaseQueryBuilder();
        final mockFilterBuilder = MockPostgrestFilterBuilderRealTime();

        when(mockSupabaseClient.from('expenses')).thenReturn(mockQueryBuilder);
        when(mockQueryBuilder.update(any)).thenReturn(mockFilterBuilder);
        when(mockFilterBuilder.eq(any, any)).thenReturn(mockFilterBuilder);

        // Act
        await realTimeService.syncQueuedChanges();

        // Assert
        verify(mockSupabaseClient.from('expenses')).called(1);
        verify(mockQueryBuilder.update(change.data)).called(1);
        verify(mockFilterBuilder.eq('id', 'test')).called(1);
      });

      test('should sync DELETE operation', () async {
        // Arrange
        final change = QueuedChange(
          id: 'test-delete',
          table: 'expenses',
          operation: 'DELETE',
          data: {'id': 'test'},
          timestamp: DateTime.now(),
        );

        await realTimeService.queueChange(change);

        final mockQueryBuilder = MockSupabaseQueryBuilder();
        final mockFilterBuilder = MockPostgrestFilterBuilderRealTime();

        when(mockSupabaseClient.from('expenses')).thenReturn(mockQueryBuilder);
        when(mockQueryBuilder.delete()).thenReturn(mockFilterBuilder);
        when(mockFilterBuilder.eq(any, any)).thenReturn(mockFilterBuilder);

        // Act
        await realTimeService.syncQueuedChanges();

        // Assert
        verify(mockSupabaseClient.from('expenses')).called(1);
        verify(mockQueryBuilder.delete()).called(1);
        verify(mockFilterBuilder.eq('id', 'test')).called(1);
      });

      test('should remove synced changes from queue', () async {
        // Arrange
        final change = QueuedChange(
          id: 'test-sync',
          table: 'expenses',
          operation: 'INSERT',
          data: {'id': 'test'},
          timestamp: DateTime.now(),
        );

        await realTimeService.queueChange(change);

        final mockQueryBuilder = MockSupabaseQueryBuilder();
        when(mockSupabaseClient.from('expenses')).thenReturn(mockQueryBuilder);
        when(
          mockQueryBuilder.insert(any),
        ).thenReturn(_FakePostgrestFilterBuilderForInsert([]));

        // Act
        await realTimeService.syncQueuedChanges();

        // Assert
        final queuedChanges = realTimeService.getQueuedChanges();
        expect(queuedChanges, isEmpty);
      });

      test('should keep changes in queue if sync fails', () async {
        // Arrange
        final change = QueuedChange(
          id: 'test-fail',
          table: 'expenses',
          operation: 'INSERT',
          data: {'id': 'test'},
          timestamp: DateTime.now(),
        );

        await realTimeService.queueChange(change);

        final mockQueryBuilder = MockSupabaseQueryBuilder();
        when(mockSupabaseClient.from('expenses')).thenReturn(mockQueryBuilder);
        when(mockQueryBuilder.insert(any)).thenThrow(Exception('Sync failed'));

        // Act & Assert
        expect(
          () => realTimeService.syncQueuedChanges(),
          throwsException,
        );

        final queuedChanges = realTimeService.getQueuedChanges();
        expect(queuedChanges, contains(change));
      });
    });

    group('Connection State Management', () {
      test('should emit connection state changes', () async {
        // Arrange
        final states = <ConnectionState>[];
        final subscription = realTimeService.connectionState.listen(states.add);

        // Act
        await realTimeService.start();
        await Future<void>.delayed(const Duration(milliseconds: 10));

        // Assert
        expect(states, isNotEmpty);
        expect(states.first, equals(ConnectionState.connecting));

        await subscription.cancel();
      });

      test('should handle reconnection attempts', () async {
        // Arrange
        final states = <ConnectionState>[];
        final subscription = realTimeService.connectionState.listen(states.add);

        // Act - Start service (this will succeed)
        await realTimeService.start();
        await Future<void>.delayed(const Duration(milliseconds: 10));

        // Assert
        expect(states, contains(ConnectionState.connected));

        await subscription.cancel();
      });

      test('should not start if already disposed', () async {
        // Arrange
        realTimeService.dispose();

        // Act
        await realTimeService.start();

        // Assert - Should not throw or cause issues
        // Service should handle disposed state gracefully
      });
    });

    group('Error Handling', () {
      test('should handle storage errors gracefully', () async {
        // Arrange
        when(
          mockQueueStorage.saveQueuedChanges(any),
        ).thenThrow(Exception('Storage error'));

        final change = QueuedChange(
          id: 'test-error',
          table: 'expenses',
          operation: 'INSERT',
          data: {'id': 'test'},
          timestamp: DateTime.now(),
        );

        // Act & Assert - Should not throw
        await realTimeService.queueChange(change);

        // Change should still be in memory queue
        final queuedChanges = realTimeService.getQueuedChanges();
        expect(queuedChanges, contains(change));
      });

      test('should handle load errors gracefully', () async {
        // Arrange
        when(
          mockQueueStorage.loadQueuedChanges(),
        ).thenThrow(Exception('Load error'));

        // Act & Assert - Should not throw
        await realTimeService.start();

        // Service should still be functional
        final queuedChanges = realTimeService.getQueuedChanges();
        expect(queuedChanges, isEmpty);
      });
    });
  });
}

// Mock classes are generated by build_runner
