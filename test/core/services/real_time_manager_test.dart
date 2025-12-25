import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:grex/core/services/real_time_manager.dart';
import 'package:grex/core/services/real_time_service.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

@GenerateMocks([RealTimeService, RealtimeChannel])
import 'real_time_manager_test.mocks.dart';

void main() {
  group('RealTimeManager', () {
    late MockRealTimeService mockRealTimeService;
    late MockRealtimeChannel mockChannel;
    late RealTimeManager realTimeManager;

    setUp(() {
      mockRealTimeService = MockRealTimeService();
      mockChannel = MockRealtimeChannel();
      realTimeManager = RealTimeManager(realTimeService: mockRealTimeService);

      // Setup default mocks
      when(mockRealTimeService.start()).thenAnswer((_) async {});
      when(mockRealTimeService.stop()).thenAnswer((_) async {});
      when(mockRealTimeService.connectionState).thenAnswer(
        (_) => Stream.value(ConnectionState.connected),
      );
      when(
        mockRealTimeService.subscribeToTable(
          any,
          filter: anyNamed('filter'),
          onData: anyNamed('onData'),
          onError: anyNamed('onError'),
        ),
      ).thenReturn(mockChannel);
      when(
        mockRealTimeService.subscribeToGroup(
          any,
          any,
          onData: anyNamed('onData'),
          onError: anyNamed('onError'),
        ),
      ).thenReturn(mockChannel);
      when(mockChannel.unsubscribe()).thenAnswer((_) async => 'closed');
    });

    tearDown(() async {
      await realTimeManager.dispose();
    });

    group('Initialization', () {
      test('should initialize and start real-time service', () async {
        // Act
        await realTimeManager.initialize();

        // Assert
        verify(mockRealTimeService.start()).called(1);
      });

      test('should not initialize twice', () async {
        // Act
        await realTimeManager.initialize();
        await realTimeManager.initialize();

        // Assert
        verify(mockRealTimeService.start()).called(1);
      });

      test('should provide connection state stream', () async {
        // Arrange
        final connectionStateController = StreamController<ConnectionState>();
        when(
          mockRealTimeService.connectionState,
        ).thenAnswer((_) => connectionStateController.stream);

        // Act
        final stream = realTimeManager.connectionState;
        connectionStateController.add(ConnectionState.connected);

        // Assert
        expect(await stream.first, equals(ConnectionState.connected));
        await connectionStateController.close();
      });
    });

    group('User Groups Subscription', () {
      test('should subscribe to user groups', () async {
        // Arrange
        const userId = 'test-user-id';

        // Act
        final stream = realTimeManager.subscribeToUserGroups(userId);

        // Assert
        expect(stream, isA<Stream<Map<String, dynamic>>>());
        verify(
          mockRealTimeService.subscribeToTable(
            'group_members',
            filter: 'user_id=$userId',
            onData: anyNamed('onData'),
            onError: anyNamed('onError'),
          ),
        ).called(1);
      });

      test('should return existing stream for same user', () async {
        // Arrange
        const userId = 'test-user-id';

        // Act
        final stream1 = realTimeManager.subscribeToUserGroups(userId);
        final stream2 = realTimeManager.subscribeToUserGroups(userId);

        // Assert
        expect(identical(stream1, stream2), isTrue);
        verify(
          mockRealTimeService.subscribeToTable(
            'group_members',
            filter: 'user_id=$userId',
            onData: anyNamed('onData'),
            onError: anyNamed('onError'),
          ),
        ).called(1);
      });

      test('should handle data updates for user groups', () async {
        // Arrange
        const userId = 'test-user-id';
        final testData = {'id': 'group-1', 'name': 'Test Group'};

        // Capture the onData callback
        void Function(Map<String, dynamic>)? onDataCallback;
        when(
          mockRealTimeService.subscribeToTable(
            any,
            filter: anyNamed('filter'),
            onData: anyNamed('onData'),
            onError: anyNamed('onError'),
          ),
        ).thenAnswer((invocation) {
          onDataCallback =
              invocation.namedArguments[#onData]
                  as void Function(Map<String, dynamic>)?;
          return mockChannel;
        });

        // Act
        final stream = realTimeManager.subscribeToUserGroups(userId);
        final streamData = <Map<String, dynamic>>[];
        final subscription = stream.listen(streamData.add);

        // Simulate data update
        onDataCallback?.call(testData);
        await Future<void>.delayed(const Duration(milliseconds: 10));

        // Assert
        expect(streamData, contains(testData));
        await subscription.cancel();
      });
    });

    group('Group Members Subscription', () {
      test('should subscribe to group members', () async {
        // Arrange
        const groupId = 'test-group-id';

        // Act
        final stream = realTimeManager.subscribeToGroupMembers(groupId);

        // Assert
        expect(stream, isA<Stream<Map<String, dynamic>>>());
        verify(
          mockRealTimeService.subscribeToGroup(
            groupId,
            'group_members',
            onData: anyNamed('onData'),
            onError: anyNamed('onError'),
          ),
        ).called(1);
      });

      test('should handle member updates', () async {
        // Arrange
        const groupId = 'test-group-id';
        final testData = {
          'id': 'member-1',
          'user_id': 'user-1',
          'role': 'editor',
        };

        void Function(Map<String, dynamic>)? onDataCallback;
        when(
          mockRealTimeService.subscribeToGroup(
            any,
            any,
            onData: anyNamed('onData'),
            onError: anyNamed('onError'),
          ),
        ).thenAnswer((invocation) {
          onDataCallback =
              invocation.namedArguments[#onData]
                  as void Function(Map<String, dynamic>)?;
          return mockChannel;
        });

        // Act
        final stream = realTimeManager.subscribeToGroupMembers(groupId);
        final streamData = <Map<String, dynamic>>[];
        final subscription = stream.listen(streamData.add);

        onDataCallback?.call(testData);
        await Future<void>.delayed(const Duration(milliseconds: 10));

        // Assert
        expect(streamData, contains(testData));
        await subscription.cancel();
      });
    });

    group('Group Expenses Subscription', () {
      test('should subscribe to group expenses', () async {
        // Arrange
        const groupId = 'test-group-id';

        // Act
        final stream = realTimeManager.subscribeToGroupExpenses(groupId);

        // Assert
        expect(stream, isA<Stream<Map<String, dynamic>>>());
        verify(
          mockRealTimeService.subscribeToGroup(
            groupId,
            'expenses',
            onData: anyNamed('onData'),
            onError: anyNamed('onError'),
          ),
        ).called(1);
      });

      test('should handle expense updates', () async {
        // Arrange
        const groupId = 'test-group-id';
        final testData = {
          'id': 'expense-1',
          'amount': 100.0,
          'description': 'Test expense',
        };

        void Function(Map<String, dynamic>)? onDataCallback;
        when(
          mockRealTimeService.subscribeToGroup(
            any,
            any,
            onData: anyNamed('onData'),
            onError: anyNamed('onError'),
          ),
        ).thenAnswer((invocation) {
          onDataCallback =
              invocation.namedArguments[#onData]
                  as void Function(Map<String, dynamic>)?;
          return mockChannel;
        });

        // Act
        final stream = realTimeManager.subscribeToGroupExpenses(groupId);
        final streamData = <Map<String, dynamic>>[];
        final subscription = stream.listen(streamData.add);

        onDataCallback?.call(testData);
        await Future<void>.delayed(const Duration(milliseconds: 10));

        // Assert
        expect(streamData, contains(testData));
        await subscription.cancel();
      });
    });

    group('Group Payments Subscription', () {
      test('should subscribe to group payments', () async {
        // Arrange
        const groupId = 'test-group-id';

        // Act
        final stream = realTimeManager.subscribeToGroupPayments(groupId);

        // Assert
        expect(stream, isA<Stream<Map<String, dynamic>>>());
        verify(
          mockRealTimeService.subscribeToGroup(
            groupId,
            'payments',
            onData: anyNamed('onData'),
            onError: anyNamed('onError'),
          ),
        ).called(1);
      });

      test('should handle payment updates', () async {
        // Arrange
        const groupId = 'test-group-id';
        final testData = {
          'id': 'payment-1',
          'amount': 50.0,
          'from_user_id': 'user-1',
          'to_user_id': 'user-2',
        };

        void Function(Map<String, dynamic>)? onDataCallback;
        when(
          mockRealTimeService.subscribeToGroup(
            any,
            any,
            onData: anyNamed('onData'),
            onError: anyNamed('onError'),
          ),
        ).thenAnswer((invocation) {
          onDataCallback =
              invocation.namedArguments[#onData]
                  as void Function(Map<String, dynamic>)?;
          return mockChannel;
        });

        // Act
        final stream = realTimeManager.subscribeToGroupPayments(groupId);
        final streamData = <Map<String, dynamic>>[];
        final subscription = stream.listen(streamData.add);

        onDataCallback?.call(testData);
        await Future<void>.delayed(const Duration(milliseconds: 10));

        // Assert
        expect(streamData, contains(testData));
        await subscription.cancel();
      });
    });

    group('Group Balances Subscription', () {
      test(
        'should subscribe to group balances (expenses and payments)',
        () async {
          // Arrange
          const groupId = 'test-group-id';

          // Act
          final stream = realTimeManager.subscribeToGroupBalances(groupId);

          // Assert
          expect(stream, isA<Stream<Map<String, dynamic>>>());
          verify(
            mockRealTimeService.subscribeToGroup(
              groupId,
              'expenses',
              onData: anyNamed('onData'),
            ),
          ).called(1);
          verify(
            mockRealTimeService.subscribeToGroup(
              groupId,
              'payments',
              onData: anyNamed('onData'),
            ),
          ).called(1);
        },
      );

      test('should handle balance-affecting updates', () async {
        // Arrange
        const groupId = 'test-group-id';
        final expenseData = {'id': 'expense-1', 'amount': 100.0};
        final paymentData = {'id': 'payment-1', 'amount': 50.0};

        final onDataCallbacks = <void Function(Map<String, dynamic>)>[];
        when(
          mockRealTimeService.subscribeToGroup(
            any,
            any,
            onData: anyNamed('onData'),
          ),
        ).thenAnswer((invocation) {
          final callback =
              invocation.namedArguments[#onData]
                  as void Function(Map<String, dynamic>)?;
          if (callback != null) {
            onDataCallbacks.add(callback);
          }
          return mockChannel;
        });

        // Act
        final stream = realTimeManager.subscribeToGroupBalances(groupId);
        final streamData = <Map<String, dynamic>>[];
        final subscription = stream.listen(streamData.add);

        // Simulate updates from both expenses and payments
        onDataCallbacks[0].call(expenseData);
        onDataCallbacks[1].call(paymentData);
        await Future<void>.delayed(const Duration(milliseconds: 10));

        // Assert
        expect(streamData, contains(expenseData));
        expect(streamData, contains(paymentData));
        await subscription.cancel();
      });
    });

    group('Offline Queue Management', () {
      test('should queue changes for offline sync', () async {
        // Arrange
        const table = 'expenses';
        const operation = 'INSERT';
        final data = {'id': 'test', 'amount': 100.0};

        when(mockRealTimeService.queueChange(any)).thenAnswer((_) async {});

        // Act
        await realTimeManager.queueChange(
          table: table,
          operation: operation,
          data: data,
        );

        // Assert
        verify(mockRealTimeService.queueChange(any)).called(1);
      });

      test('should provide queued changes count', () async {
        // Arrange
        const queuedCount = 5;
        when(mockRealTimeService.getQueuedChanges()).thenReturn(
          List.generate(
            queuedCount,
            (i) => QueuedChange(
              id: 'change-$i',
              table: 'expenses',
              operation: 'INSERT',
              data: {'id': 'test-$i'},
              timestamp: DateTime.now(),
            ),
          ),
        );

        // Act
        final count = realTimeManager.queuedChangesCount;

        // Assert
        expect(count, equals(queuedCount));
      });

      test('should sync queued changes', () async {
        // Arrange
        when(mockRealTimeService.syncQueuedChanges()).thenAnswer((_) async {});

        // Act
        await realTimeManager.syncQueuedChanges();

        // Assert
        verify(mockRealTimeService.syncQueuedChanges()).called(1);
      });

      test('should handle sync errors', () async {
        // Arrange
        when(
          mockRealTimeService.syncQueuedChanges(),
        ).thenThrow(Exception('Sync failed'));

        // Act & Assert
        expect(
          () => realTimeManager.syncQueuedChanges(),
          throwsException,
        );
      });
    });

    group('Subscription Management', () {
      test('should unsubscribe from specific subscription', () async {
        // Arrange
        const groupId = 'test-group-id';
        realTimeManager.subscribeToGroupExpenses(groupId);

        // Act
        await realTimeManager.unsubscribe('group_expenses_$groupId');

        // Assert
        verify(mockChannel.unsubscribe()).called(1);
      });

      test('should unsubscribe from all group subscriptions', () async {
        // Arrange
        const groupId = 'test-group-id';
        realTimeManager
          ..subscribeToGroupExpenses(groupId)
          ..subscribeToGroupPayments(groupId)
          ..subscribeToGroupMembers(groupId);

        // Act
        await realTimeManager.unsubscribeFromGroup(groupId);

        // Assert
        verify(mockChannel.unsubscribe()).called(3);
      });

      test(
        'should handle unsubscribe from non-existent subscription',
        () async {
          // Act & Assert - Should not throw
          await realTimeManager.unsubscribe('non-existent-key');
        },
      );
    });

    group('Error Handling', () {
      test('should handle subscription errors', () async {
        // Arrange
        const groupId = 'test-group-id';
        const testError = 'Connection error';

        void Function(Object)? onErrorCallback;
        when(
          mockRealTimeService.subscribeToGroup(
            any,
            any,
            onData: anyNamed('onData'),
            onError: anyNamed('onError'),
          ),
        ).thenAnswer((invocation) {
          onErrorCallback =
              invocation.namedArguments[#onError] as void Function(Object)?;
          return mockChannel;
        });

        // Act
        final stream = realTimeManager.subscribeToGroupExpenses(groupId);
        final errors = <Object>[];
        final subscription = stream.listen(
          (_) {},
          onError: errors.add,
        );

        onErrorCallback?.call(testError);
        await Future<void>.delayed(const Duration(milliseconds: 10));

        // Assert
        expect(errors, contains(testError));
        await subscription.cancel();
      });

      test('should handle closed controller gracefully', () async {
        // Arrange
        const groupId = 'test-group-id';

        void Function(Map<String, dynamic>)? onDataCallback;
        when(
          mockRealTimeService.subscribeToGroup(
            any,
            any,
            onData: anyNamed('onData'),
            onError: anyNamed('onError'),
          ),
        ).thenAnswer((invocation) {
          onDataCallback =
              invocation.namedArguments[#onData]
                  as void Function(Map<String, dynamic>)?;
          return mockChannel;
        });

        // Act
        final stream = realTimeManager.subscribeToGroupExpenses(groupId);
        final subscription = stream.listen((_) {});

        // Close subscription first
        await subscription.cancel();

        // Then try to send data - should not throw
        onDataCallback?.call({'id': 'test'});
        await Future<void>.delayed(const Duration(milliseconds: 10));

        // Assert - No exception should be thrown
      });
    });

    group('Disposal', () {
      test('should dispose all resources', () async {
        // Arrange
        const groupId = 'test-group-id';
        realTimeManager
          ..subscribeToGroupExpenses(groupId)
          ..subscribeToGroupPayments(groupId);

        // Act
        await realTimeManager.dispose();

        // Assert
        verify(mockChannel.unsubscribe()).called(2);
        verify(mockRealTimeService.stop()).called(1);
      });

      test('should handle multiple dispose calls', () async {
        // Act
        await realTimeManager.dispose();
        await realTimeManager.dispose();

        // Assert - Should not throw
        verify(mockRealTimeService.stop()).called(2);
      });

      test('should not initialize after disposal', () async {
        // Arrange
        await realTimeManager.dispose();

        // Act
        await realTimeManager.initialize();

        // Assert - Should still work (creates new instance internally)
        verify(mockRealTimeService.start()).called(1);
      });
    });
  });
}
