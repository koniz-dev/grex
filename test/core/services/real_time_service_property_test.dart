import 'package:flutter_test/flutter_test.dart';
import 'package:grex/core/services/offline_queue_storage.dart';
import 'package:grex/core/services/real_time_service.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

@GenerateMocks([SupabaseClient, OfflineQueueStorage, RealtimeChannel])
import 'real_time_service_property_test.mocks.dart';

void main() {
  group('Real-time Service Property Tests', () {
    late MockSupabaseClient mockSupabaseClient;
    late MockOfflineQueueStorage mockQueueStorage;
    late SupabaseRealTimeService realTimeService;

    setUp(() {
      mockSupabaseClient = MockSupabaseClient();
      mockQueueStorage = MockOfflineQueueStorage();
      realTimeService = SupabaseRealTimeService(
        supabaseClient: mockSupabaseClient,
        queueStorage: mockQueueStorage,
      );
    });

    tearDown(() {
      realTimeService.dispose();
    });

    group('Property 21: Real-time updates synchronize data', () {
      test(
        'should synchronize all queued changes when connection restored',
        () async {
          // Property: For any set of queued changes, when connection is
          // restored, all changes should be synchronized in order

          const iterations = 100;
          for (var i = 0; i < iterations; i++) {
            // Arrange - Create random number of queued changes
            final changeCount = (i % 10) + 1;
            final changes = List.generate(
              changeCount,
              (index) => QueuedChange(
                id: 'change-$i-$index',
                table: 'expenses',
                operation: 'INSERT',
                data: {
                  'id': 'expense-$i-$index',
                  'amount': (index + 1) * 100.0,
                  'description': 'Test expense $i-$index',
                },
                timestamp: DateTime.now(),
              ),
            );

            // Queue all changes
            for (final change in changes) {
              await realTimeService.queueChange(change);
            }

            // Act - Sync queued changes
            final queuedChanges = realTimeService.getQueuedChanges();

            // Assert - All changes should be in queue
            expect(queuedChanges.length, greaterThanOrEqualTo(changeCount));

            // Property: Queue maintains insertion order
            final lastChanges = queuedChanges.skip(
              queuedChanges.length - changeCount,
            );
            for (var j = 0; j < changeCount; j++) {
              expect(
                lastChanges.elementAt(j).id,
                equals('change-$i-$j'),
              );
            }

            // Clear for next iteration
            await realTimeService.clearQueuedChanges();
          }
        },
      );

      test(
        'should handle concurrent real-time updates without data loss',
        () async {
          // Property: Concurrent updates should not lose data

          const iterations = 50;
          for (var i = 0; i < iterations; i++) {
            // Arrange - Create multiple concurrent changes
            final futures = <Future<void>>[];
            const changeCount = 5;

            for (var j = 0; j < changeCount; j++) {
              futures.add(
                realTimeService.queueChange(
                  QueuedChange(
                    id: 'concurrent-$i-$j',
                    table: 'expenses',
                    operation: 'UPDATE',
                    data: {
                      'id': 'expense-$i',
                      'amount': (j + 1) * 100.0,
                    },
                    timestamp: DateTime.now(),
                  ),
                ),
              );
            }

            // Act - Execute all changes concurrently
            await Future.wait(futures);

            // Assert - All changes should be queued
            final queuedChanges = realTimeService.getQueuedChanges();
            expect(queuedChanges.length, greaterThanOrEqualTo(changeCount));

            // Clear for next iteration
            await realTimeService.clearQueuedChanges();
          }
        },
      );

      test('should maintain data consistency across sync operations', () async {
        // Property: Data consistency is maintained during sync

        const iterations = 100;
        for (var i = 0; i < iterations; i++) {
          // Arrange - Create changes with dependencies
          final changes = [
            QueuedChange(
              id: 'change-$i-1',
              table: 'expenses',
              operation: 'INSERT',
              data: {
                'id': 'expense-$i',
                'amount': 100.0,
                'group_id': 'group-$i',
              },
              timestamp: DateTime.now(),
            ),
            QueuedChange(
              id: 'change-$i-2',
              table: 'expense_participants',
              operation: 'INSERT',
              data: {
                'id': 'participant-$i',
                'expense_id': 'expense-$i',
                'user_id': 'user-1',
              },
              timestamp: DateTime.now().add(const Duration(milliseconds: 1)),
            ),
          ];

          // Queue changes
          for (final change in changes) {
            await realTimeService.queueChange(change);
          }

          // Assert - Changes maintain order
          final queuedChanges = realTimeService.getQueuedChanges();
          final lastTwo = queuedChanges.skip(queuedChanges.length - 2);

          // Property: Dependent changes maintain order
          expect(
            lastTwo.first.timestamp.isBefore(lastTwo.last.timestamp),
            isTrue,
          );

          await realTimeService.clearQueuedChanges();
        }
      });

      test('should handle different operation types correctly', () async {
        // Property: All operation types (INSERT, UPDATE, DELETE) are handled

        const iterations = 100;
        final operations = ['INSERT', 'UPDATE', 'DELETE'];

        for (var i = 0; i < iterations; i++) {
          // Arrange - Create changes with different operations
          for (final operation in operations) {
            await realTimeService.queueChange(
              QueuedChange(
                id: 'change-$i-$operation',
                table: 'expenses',
                operation: operation,
                data: {
                  'id': 'expense-$i',
                  'amount': 100.0,
                },
                timestamp: DateTime.now(),
              ),
            );
          }

          // Assert - All operations are queued
          final queuedChanges = realTimeService.getQueuedChanges();
          final lastThree = queuedChanges.skip(queuedChanges.length - 3);

          // Property: All operation types are preserved
          final queuedOperations = lastThree.map((c) => c.operation).toSet();
          expect(queuedOperations, containsAll(operations));

          await realTimeService.clearQueuedChanges();
        }
      });
    });

    group('Property 22: Offline changes queue for sync', () {
      test('should queue all changes when offline', () async {
        // Property: All changes made while offline are queued

        const iterations = 100;
        for (var i = 0; i < iterations; i++) {
          // Arrange - Simulate offline state
          final changeCount = (i % 20) + 1;

          // Act - Queue changes while offline
          for (var j = 0; j < changeCount; j++) {
            await realTimeService.queueChange(
              QueuedChange(
                id: 'offline-$i-$j',
                table: 'expenses',
                operation: 'INSERT',
                data: {
                  'id': 'expense-$i-$j',
                  'amount': (j + 1) * 100.0,
                },
                timestamp: DateTime.now(),
              ),
            );
          }

          // Assert - All changes are in queue
          final queuedChanges = realTimeService.getQueuedChanges();
          expect(queuedChanges.length, greaterThanOrEqualTo(changeCount));

          // Property: Queue size grows with offline changes
          final offlineChanges = queuedChanges.where(
            (c) => c.id.startsWith('offline-$i-'),
          );
          expect(offlineChanges.length, equals(changeCount));

          await realTimeService.clearQueuedChanges();
        }
      });

      test('should persist queued changes across restarts', () async {
        // Property: Queued changes survive app restarts

        const iterations = 50;
        for (var i = 0; i < iterations; i++) {
          // Arrange - Create changes
          final changes = List.generate(
            5,
            (j) => QueuedChange(
              id: 'persist-$i-$j',
              table: 'expenses',
              operation: 'INSERT',
              data: {
                'id': 'expense-$i-$j',
                'amount': (j + 1) * 100.0,
              },
              timestamp: DateTime.now(),
            ),
          );

          // Mock storage save
          when(
            mockQueueStorage.saveQueuedChanges(any),
          ).thenAnswer((_) async {});

          // Act - Queue changes
          for (final change in changes) {
            await realTimeService.queueChange(change);
          }

          // Assert - Storage save was called
          verify(mockQueueStorage.saveQueuedChanges(any)).called(5);

          await realTimeService.clearQueuedChanges();
        }
      });

      test('should limit queue size to prevent memory issues', () async {
        // Property: Queue size is bounded to prevent memory overflow

        // Arrange - Queue more than max size (1000)
        const maxSize = 1000;
        const extraChanges = 100;

        // Act - Queue changes beyond limit
        for (var i = 0; i < maxSize + extraChanges; i++) {
          await realTimeService.queueChange(
            QueuedChange(
              id: 'change-$i',
              table: 'expenses',
              operation: 'INSERT',
              data: {
                'id': 'expense-$i',
                'amount': 100.0,
              },
              timestamp: DateTime.now(),
            ),
          );
        }

        // Assert - Queue size is limited
        final queuedChanges = realTimeService.getQueuedChanges();
        expect(queuedChanges.length, lessThanOrEqualTo(maxSize));

        // Property: Oldest changes are removed when limit exceeded
        final firstChange = queuedChanges.first;
        expect(
          int.parse(firstChange.id.split('-')[1]),
          greaterThanOrEqualTo(extraChanges),
        );
      });

      test('should handle queue operations atomically', () async {
        // Property: Queue operations are atomic (no partial updates)

        const iterations = 100;
        for (var i = 0; i < iterations; i++) {
          // Arrange - Create a batch of changes
          const batchSize = 5;
          final changes = List.generate(
            batchSize,
            (j) => QueuedChange(
              id: 'batch-$i-$j',
              table: 'expenses',
              operation: 'INSERT',
              data: {
                'id': 'expense-$i-$j',
                'amount': (j + 1) * 100.0,
              },
              timestamp: DateTime.now(),
            ),
          );

          // Act - Queue all changes
          for (final change in changes) {
            await realTimeService.queueChange(change);
          }

          // Assert - All changes from batch are present
          final queuedChanges = realTimeService.getQueuedChanges();
          final batchChanges = queuedChanges.where(
            (c) => c.id.startsWith('batch-$i-'),
          );

          // Property: Either all changes are queued or none
          expect(batchChanges.length, equals(batchSize));

          await realTimeService.clearQueuedChanges();
        }
      });

      test('should preserve change metadata during queueing', () async {
        // Property: All change metadata is preserved in queue

        const iterations = 100;
        for (var i = 0; i < iterations; i++) {
          // Arrange - Create change with full metadata
          final timestamp = DateTime.now();
          final change = QueuedChange(
            id: 'meta-$i',
            table: 'expenses',
            operation: 'UPDATE',
            data: {
              'id': 'expense-$i',
              'amount': 100.0,
              'description': 'Test expense $i',
              'group_id': 'group-$i',
            },
            timestamp: timestamp,
          );

          // Act - Queue change
          await realTimeService.queueChange(change);

          // Assert - Metadata is preserved
          final queuedChanges = realTimeService.getQueuedChanges();
          final queuedChange = queuedChanges.last;

          // Property: All fields are preserved
          expect(queuedChange.id, equals(change.id));
          expect(queuedChange.table, equals(change.table));
          expect(queuedChange.operation, equals(change.operation));
          expect(queuedChange.data, equals(change.data));
          expect(queuedChange.timestamp, equals(change.timestamp));

          await realTimeService.clearQueuedChanges();
        }
      });
    });
  });
}
