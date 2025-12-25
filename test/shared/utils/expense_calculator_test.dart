import 'package:flutter_test/flutter_test.dart';
import 'package:grex/features/expenses/domain/entities/expense_participant.dart';
import 'package:grex/features/expenses/domain/entities/split_method.dart';
import 'package:grex/features/expenses/domain/utils/expense_calculator.dart';

void main() {
  group('ExpenseCalculator', () {
    group('splitEqually', () {
      test('should split amount equally among participants', () {
        final result = ExpenseCalculator.splitEqually(
          totalAmount: 100,
          participantIds: ['user1', 'user2', 'user3', 'user4'],
        );

        expect(result.length, equals(4));
        expect(result['user1'], equals(25));
        expect(result['user2'], equals(25));
        expect(result['user3'], equals(25));
        expect(result['user4'], equals(25));
      });

      test('should handle rounding correctly', () {
        final result = ExpenseCalculator.splitEqually(
          totalAmount: 100.01,
          participantIds: ['user1', 'user2', 'user3'],
        );

        expect(result.length, equals(3));
        final total = result.values.fold<double>(
          0,
          (sum, amount) => sum + amount,
        );
        expect(total, closeTo(100.01, 0.02));
      });

      test('should throw error for empty participants', () {
        expect(
          () => ExpenseCalculator.splitEqually(
            totalAmount: 100,
            participantIds: [],
          ),
          throwsArgumentError,
        );
      });
    });

    group('splitByPercentage', () {
      test('should split amount by percentage correctly', () {
        final result = ExpenseCalculator.splitByPercentage(
          totalAmount: 100,
          percentages: {
            'user1': 50,
            'user2': 30,
            'user3': 20,
          },
        );

        expect(result['user1'], equals(50));
        expect(result['user2'], equals(30));
        expect(result['user3'], equals(20));
      });

      test('should handle rounding in percentage splits', () {
        final result = ExpenseCalculator.splitByPercentage(
          totalAmount: 100,
          percentages: {
            'user1': 33.33,
            'user2': 33.33,
            'user3': 33.34,
          },
        );

        final total = result.values.fold<double>(
          0,
          (sum, amount) => sum + amount,
        );
        expect(total, closeTo(100, 0.01));
      });

      test('should throw error for invalid percentage total', () {
        expect(
          () => ExpenseCalculator.splitByPercentage(
            totalAmount: 100,
            percentages: {
              'user1': 50,
              'user2': 30,
            },
          ),
          throwsArgumentError,
        );
      });
    });

    group('splitByExactAmounts', () {
      test('should split by exact amounts correctly', () {
        final result = ExpenseCalculator.splitByExactAmounts(
          totalAmount: 100,
          exactAmounts: {
            'user1': 60,
            'user2': 25,
            'user3': 15,
          },
        );

        expect(result['user1'], equals(60));
        expect(result['user2'], equals(25));
        expect(result['user3'], equals(15));
      });

      test('should throw error for invalid total', () {
        expect(
          () => ExpenseCalculator.splitByExactAmounts(
            totalAmount: 100,
            exactAmounts: {
              'user1': 60,
              'user2': 30,
            },
          ),
          throwsArgumentError,
        );
      });
    });

    group('splitByShares', () {
      test('should split by shares correctly', () {
        final result = ExpenseCalculator.splitByShares(
          totalAmount: 120,
          shares: {
            'user1': 2,
            'user2': 1,
            'user3': 1,
          },
        );

        expect(result['user1'], equals(60));
        expect(result['user2'], equals(30));
        expect(result['user3'], equals(30));
      });

      test('should handle rounding in share splits', () {
        final result = ExpenseCalculator.splitByShares(
          totalAmount: 100,
          shares: {
            'user1': 1,
            'user2': 1,
            'user3': 1,
          },
        );

        final total = result.values.fold<double>(
          0,
          (sum, amount) => sum + amount,
        );
        expect(total, closeTo(100, 0.01));
      });
    });

    group('validateSplit', () {
      test('should validate correct split', () {
        final isValid = ExpenseCalculator.validateSplit(
          totalAmount: 100,
          splitAmounts: {
            'user1': 50,
            'user2': 30,
            'user3': 20,
          },
        );

        expect(isValid, isTrue);
      });

      test('should reject incorrect split', () {
        final isValid = ExpenseCalculator.validateSplit(
          totalAmount: 100,
          splitAmounts: {
            'user1': 50,
            'user2': 30,
          },
        );

        expect(isValid, isFalse);
      });
    });

    group('calculateSplit with domain entities', () {
      test('should calculate equal split with participants', () {
        final participantData = [
          {'userId': 'user1', 'displayName': 'User 1'},
          {'userId': 'user2', 'displayName': 'User 2'},
          {'userId': 'user3', 'displayName': 'User 3'},
        ];

        final result = ExpenseCalculator.calculateSplit(
          totalAmount: 150,
          splitMethod: SplitMethod.equal,
          participantData: participantData,
        );

        expect(result.length, equals(3));
        expect(result[0].shareAmount, equals(50));
        expect(result[0].sharePercentage, closeTo(33.33, 0.01));
        expect(result[0].userId, equals('user1'));
        expect(result[0].displayName, equals('User 1'));
      });

      test('should calculate percentage split with participants', () {
        final participantData = [
          {'userId': 'user1', 'displayName': 'User 1', 'percentage': 60},
          {'userId': 'user2', 'displayName': 'User 2', 'percentage': 40},
        ];

        final result = ExpenseCalculator.calculateSplit(
          totalAmount: 100,
          splitMethod: SplitMethod.percentage,
          participantData: participantData,
        );

        expect(result.length, equals(2));
        expect(result[0].shareAmount, equals(60));
        expect(result[0].sharePercentage, equals(60));
        expect(result[1].shareAmount, equals(40));
        expect(result[1].sharePercentage, equals(40));
      });
    });

    group('validateSplitConfiguration', () {
      test('should validate equal split configuration', () {
        final participantData = [
          {'userId': 'user1', 'displayName': 'User 1'},
          {'userId': 'user2', 'displayName': 'User 2'},
        ];

        final error = ExpenseCalculator.validateSplitConfiguration(
          totalAmount: 100,
          splitMethod: SplitMethod.equal,
          participantData: participantData,
        );

        expect(error, isNull);
      });

      test('should reject invalid percentage configuration', () {
        final participantData = [
          {'userId': 'user1', 'displayName': 'User 1', 'percentage': 60},
          {'userId': 'user2', 'displayName': 'User 2', 'percentage': 30},
        ];

        final error = ExpenseCalculator.validateSplitConfiguration(
          totalAmount: 100,
          splitMethod: SplitMethod.percentage,
          participantData: participantData,
        );

        expect(error, isNotNull);
        expect(error, contains('100%'));
      });

      test('should reject duplicate participants', () {
        final participantData = [
          {'userId': 'user1', 'displayName': 'User 1'},
          {'userId': 'user1', 'displayName': 'User 1 Duplicate'},
        ];

        final error = ExpenseCalculator.validateSplitConfiguration(
          totalAmount: 100,
          splitMethod: SplitMethod.equal,
          participantData: participantData,
        );

        expect(error, isNotNull);
        expect(error, contains('Duplicate'));
      });
    });

    group('recalculateSplit', () {
      test('should recalculate split when amount changes', () {
        final currentParticipants = [
          const ExpenseParticipant(
            userId: 'user1',
            displayName: 'User 1',
            shareAmount: 50,
            sharePercentage: 50,
          ),
          const ExpenseParticipant(
            userId: 'user2',
            displayName: 'User 2',
            shareAmount: 50,
            sharePercentage: 50,
          ),
        ];

        final result = ExpenseCalculator.recalculateSplit(
          newTotalAmount: 200,
          currentParticipants: currentParticipants,
          splitMethod: SplitMethod.equal,
        );

        expect(result.length, equals(2));
        expect(result[0].shareAmount, equals(100));
        expect(result[1].shareAmount, equals(100));
      });
    });

    group('utility methods', () {
      test('canModifyParticipants should return correct values', () {
        expect(
          ExpenseCalculator.canModifyParticipants(SplitMethod.equal),
          isTrue,
        );
        expect(
          ExpenseCalculator.canModifyParticipants(SplitMethod.shares),
          isTrue,
        );
        expect(
          ExpenseCalculator.canModifyParticipants(SplitMethod.percentage),
          isFalse,
        );
        expect(
          ExpenseCalculator.canModifyParticipants(SplitMethod.exact),
          isFalse,
        );
      });

      test('getDefaultParticipantData should return appropriate defaults', () {
        final equalData = ExpenseCalculator.getDefaultParticipantData(
          splitMethod: SplitMethod.equal,
          userId: 'user1',
          displayName: 'User 1',
        );

        expect(equalData['userId'], equals('user1'));
        expect(equalData['displayName'], equals('User 1'));
        expect(equalData.containsKey('percentage'), isFalse);

        final percentageData = ExpenseCalculator.getDefaultParticipantData(
          splitMethod: SplitMethod.percentage,
          userId: 'user1',
          displayName: 'User 1',
          participantCount: 4,
        );

        expect(percentageData['percentage'], equals(25));
      });
    });
  });
}
