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

      test('should conserve the total exactly when it does not divide', () {
        final result = ExpenseCalculator.splitEqually(
          totalAmount: 100.01,
          participantIds: ['user1', 'user2', 'user3'],
        );

        expect(result.length, equals(3));
        expect(_sumCents(result), equals(_cents(100.01)));
      });

      test('should hand out leftover cents deterministically', () {
        // 100.00 over 7 is 14.28 with 4 cents left over, so four participants
        // get 14.29 and three get 14.28 — summing to exactly 100.00.
        final result = ExpenseCalculator.splitEqually(
          totalAmount: 100,
          participantIds: const [
            'user1',
            'user2',
            'user3',
            'user4',
            'user5',
            'user6',
            'user7',
          ],
        );

        expect(result['user1'], equals(14.29));
        expect(result['user2'], equals(14.29));
        expect(result['user3'], equals(14.29));
        expect(result['user4'], equals(14.29));
        expect(result['user5'], equals(14.28));
        expect(result['user6'], equals(14.28));
        expect(result['user7'], equals(14.28));
        expect(_sumCents(result), equals(_cents(100)));
      });

      test('should conserve the total for the counts that used to fail', () {
        // Regression: 100.00 over 6 returned 100.02 and over 3 returned 99.99,
        // both of which `_validateSplitTotals` rejects outright.
        for (final count in const [3, 6, 7]) {
          final result = ExpenseCalculator.splitEqually(
            totalAmount: 100,
            participantIds: List.generate(count, (i) => 'user$i'),
          );
          expect(
            _sumCents(result),
            equals(_cents(100)),
            reason: 'splitting 100.00 among $count must sum to 100.00',
          );
        }

        // Regression: 0.10 over 7 returned 0.07.
        final tiny = ExpenseCalculator.splitEqually(
          totalAmount: 0.10,
          participantIds: List.generate(7, (i) => 'user$i'),
        );
        expect(_sumCents(tiny), equals(_cents(0.10)));
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

        expect(_sumCents(result), equals(_cents(100)));
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

      test('should accept amounts with cents in them', () {
        // Regression: the fold truncated on every step, so {5.50, 4.50} summed
        // to 9 and threw, while the form's pre-check reported the split valid.
        final result = ExpenseCalculator.splitByExactAmounts(
          totalAmount: 10,
          exactAmounts: {
            'user1': 5.50,
            'user2': 4.50,
          },
        );

        expect(result['user1'], equals(5.50));
        expect(result['user2'], equals(4.50));
        expect(_sumCents(result), equals(_cents(10)));
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

        expect(_sumCents(result), equals(_cents(100)));
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

      test('should validate a split whose shares carry cents', () {
        // Regression: the fold truncated each share, so this exact split of
        // 10.00 summed to 9 and was reported invalid.
        final isValid = ExpenseCalculator.validateSplit(
          totalAmount: 10,
          splitAmounts: {
            'user1': 3.34,
            'user2': 3.33,
            'user3': 3.33,
          },
        );

        expect(isValid, isTrue);
      });

      test('should reject a split that is off by a single cent', () {
        final isValid = ExpenseCalculator.validateSplit(
          totalAmount: 10,
          splitAmounts: {
            'user1': 3.33,
            'user2': 3.33,
            'user3': 3.33,
          },
        );

        expect(isValid, isFalse);
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
        expect(result[0].sharePercentage, equals(33.33));
        expect(result[0].userId, equals('user1'));
        expect(result[0].displayName, equals('User 1'));
      });

      test('should calculate percentage split with participants', () {
        final participantData = <Map<String, dynamic>>[
          {'userId': 'user1', 'displayName': 'User 1', 'percentage': 60.0},
          {'userId': 'user2', 'displayName': 'User 2', 'percentage': 40.0},
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
          <String, dynamic>{
            'userId': 'user1',
            'displayName': 'User 1',
            'percentage': 60.0,
          },
          <String, dynamic>{
            'userId': 'user2',
            'displayName': 'User 2',
            'percentage': 30.0,
          },
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
      test('should preserve share ratios when the amount changes', () {
        // Regression: share counts were reconstructed from rounded percentages
        // against `currentParticipants.length * 1` -- one share each -- so a
        // 3:1 split silently became 2:1 and 100 -> 200 produced 133.33/66.67
        // instead of 150.00/50.00.
        final original = ExpenseCalculator.calculateSplit(
          totalAmount: 100,
          splitMethod: SplitMethod.shares,
          participantData: <Map<String, dynamic>>[
            {'userId': 'a', 'displayName': 'A', 'shares': 3},
            {'userId': 'b', 'displayName': 'B', 'shares': 1},
          ],
        );
        expect(original[0].shareAmount, equals(75.0));
        expect(original[1].shareAmount, equals(25.0));

        final doubled = ExpenseCalculator.recalculateSplit(
          newTotalAmount: 200,
          currentParticipants: original,
          splitMethod: SplitMethod.shares,
        );

        expect(doubled[0].shareAmount, equals(150.0));
        expect(doubled[1].shareAmount, equals(50.0));
        expect(_sumParticipantCents(doubled), equals(_cents(200)));
      });

      test('should survive repeated recalculation without drifting', () {
        var participants = ExpenseCalculator.calculateSplit(
          totalAmount: 100,
          splitMethod: SplitMethod.shares,
          participantData: <Map<String, dynamic>>[
            {'userId': 'a', 'displayName': 'A', 'shares': 3},
            {'userId': 'b', 'displayName': 'B', 'shares': 1},
          ],
        );

        for (final total in const [200.0, 50.0, 100.0]) {
          participants = ExpenseCalculator.recalculateSplit(
            newTotalAmount: total,
            currentParticipants: participants,
            splitMethod: SplitMethod.shares,
          );
          expect(
            _sumParticipantCents(participants),
            equals(_cents(total)),
            reason: 'recalculating to $total must conserve the total',
          );
        }

        // Back where it started, to the cent.
        expect(participants[0].shareAmount, equals(75.0));
        expect(participants[1].shareAmount, equals(25.0));
      });

      test('should scale exact amounts instead of throwing', () {
        // Regression: the old code fed the OLD amounts against the NEW total,
        // which cannot sum correctly by construction, so it threw
        // ArgumentError out of calculateSplit.
        final original = ExpenseCalculator.calculateSplit(
          totalAmount: 100,
          splitMethod: SplitMethod.exact,
          participantData: <Map<String, dynamic>>[
            {'userId': 'a', 'displayName': 'A', 'amount': 60.0},
            {'userId': 'b', 'displayName': 'B', 'amount': 40.0},
          ],
        );

        final rescaled = ExpenseCalculator.recalculateSplit(
          newTotalAmount: 200,
          currentParticipants: original,
          splitMethod: SplitMethod.exact,
        );

        expect(rescaled[0].shareAmount, equals(120.0));
        expect(rescaled[1].shareAmount, equals(80.0));
        expect(_sumParticipantCents(rescaled), equals(_cents(200)));
      });

      test('should keep percentage splits proportional', () {
        final original = ExpenseCalculator.calculateSplit(
          totalAmount: 100,
          splitMethod: SplitMethod.percentage,
          participantData: <Map<String, dynamic>>[
            {'userId': 'a', 'displayName': 'A', 'percentage': 70.0},
            {'userId': 'b', 'displayName': 'B', 'percentage': 30.0},
          ],
        );

        final rescaled = ExpenseCalculator.recalculateSplit(
          newTotalAmount: 250,
          currentParticipants: original,
          splitMethod: SplitMethod.percentage,
        );

        expect(rescaled[0].shareAmount, equals(175.0));
        expect(rescaled[1].shareAmount, equals(75.0));
        expect(_sumParticipantCents(rescaled), equals(_cents(250)));
      });

      test('should throw for an empty participant list', () {
        expect(
          () => ExpenseCalculator.recalculateSplit(
            newTotalAmount: 100,
            currentParticipants: const [],
            splitMethod: SplitMethod.equal,
          ),
          throwsArgumentError,
        );
      });

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

    group('conservation sweep', () {
      // Every cent from 0.01 to 1000.00 against 1 to 12 participants, for all
      // four split methods. The property is conservation: the shares handed
      // out must sum back to the total exactly, in minor units. Money is
      // compared as integer cents throughout — a tolerance here would hide
      // precisely the defect this sweep exists to catch.
      const maxCents = 100000;
      const maxParticipants = 12;

      final idsByCount = <int, List<String>>{
        for (var n = 1; n <= maxParticipants; n++)
          n: List<String>.generate(n, (i) => 'user$i'),
      };
      final percentagesByCount = <int, Map<String, double>>{
        for (var n = 1; n <= maxParticipants; n++)
          n: {for (final id in idsByCount[n]!) id: 100.0 / n},
      };
      final sharesByCount = <int, Map<String, int>>{
        for (var n = 1; n <= maxParticipants; n++)
          n: {for (final id in idsByCount[n]!) id: 1},
      };

      test('splitEqually conserves the total for every total and count', () {
        for (var cents = 1; cents <= maxCents; cents++) {
          final total = cents / 100;
          for (var n = 1; n <= maxParticipants; n++) {
            final result = ExpenseCalculator.splitEqually(
              totalAmount: total,
              participantIds: idsByCount[n]!,
            );

            expect(result.length, equals(n));
            expect(
              _sumCents(result),
              equals(cents),
              reason: 'splitEqually($total, n=$n) must sum to $total',
            );
          }
        }
      });

      test('splitByPercentage conserves the total for every total', () {
        for (var cents = 1; cents <= maxCents; cents++) {
          final total = cents / 100;
          for (var n = 1; n <= maxParticipants; n++) {
            final result = ExpenseCalculator.splitByPercentage(
              totalAmount: total,
              percentages: percentagesByCount[n]!,
            );

            expect(
              _sumCents(result),
              equals(cents),
              reason: 'splitByPercentage($total, n=$n) must sum to $total',
            );
          }
        }
      });

      test('splitByShares conserves the total for every total', () {
        for (var cents = 1; cents <= maxCents; cents++) {
          final total = cents / 100;
          for (var n = 1; n <= maxParticipants; n++) {
            final result = ExpenseCalculator.splitByShares(
              totalAmount: total,
              shares: sharesByCount[n]!,
            );

            expect(
              _sumCents(result),
              equals(cents),
              reason: 'splitByShares($total, n=$n) must sum to $total',
            );
          }
        }
      });

      test('splitByExactAmounts round-trips an equal split', () {
        // Feeding a conserving split straight back in must be accepted and
        // returned unchanged. This is where the truncating fold threw.
        for (var cents = 1; cents <= maxCents; cents++) {
          final total = cents / 100;
          for (var n = 1; n <= maxParticipants; n++) {
            final equalSplit = ExpenseCalculator.splitEqually(
              totalAmount: total,
              participantIds: idsByCount[n]!,
            );

            final result = ExpenseCalculator.splitByExactAmounts(
              totalAmount: total,
              exactAmounts: equalSplit,
            );

            expect(
              result,
              equals(equalSplit),
              reason: 'splitByExactAmounts($total, n=$n) must round-trip',
            );
            expect(_sumCents(result), equals(cents));
          }
        }
      });

      test('recalculateSplit conserves the new total for every method', () {
        // The methods that rescale (percentage, exact, shares) all go through
        // the same proportional path, so the sweep covers the branch for each
        // of them as well as the equal-split branch.
        // Start from an uneven split so the proportions being preserved are
        // not all identical. It depends only on the participant count, so it
        // is built once per count rather than per total.
        final seedByCount = <int, List<ExpenseParticipant>>{
          for (var n = 1; n <= maxParticipants; n++)
            n: ExpenseCalculator.calculateSplit(
              totalAmount: 100,
              splitMethod: SplitMethod.shares,
              participantData: <Map<String, dynamic>>[
                for (var i = 0; i < n; i++)
                  {
                    'userId': 'user$i',
                    'displayName': 'User $i',
                    'shares': i + 1,
                  },
              ],
            ),
        };

        for (final method in SplitMethod.values) {
          for (var cents = 1; cents <= maxCents; cents++) {
            final total = cents / 100;
            for (var n = 1; n <= maxParticipants; n++) {
              final seed = seedByCount[n]!;

              final rescaled = ExpenseCalculator.recalculateSplit(
                newTotalAmount: total,
                currentParticipants: seed,
                splitMethod: method,
              );

              expect(
                _sumParticipantCents(rescaled),
                equals(cents),
                reason:
                    'recalculateSplit(${method.name}, $total, n=$n) must sum '
                    'to $total',
              );
            }
          }
        }
      });

      test('validateSplit accepts every conserving split', () {
        for (var cents = 1; cents <= maxCents; cents++) {
          final total = cents / 100;
          for (var n = 1; n <= maxParticipants; n++) {
            final equalSplit = ExpenseCalculator.splitEqually(
              totalAmount: total,
              participantIds: idsByCount[n]!,
            );

            expect(
              ExpenseCalculator.validateSplit(
                totalAmount: total,
                splitAmounts: equalSplit,
              ),
              isTrue,
              reason: 'validateSplit($total, n=$n) must accept its own split',
            );
          }
        }
      });
    });
  });
}

/// Convert a currency amount to integer minor units.
///
/// Money is asserted in cents so the comparisons stay exact; `closeTo` on a
/// total would pass for a split that quietly loses or invents a cent.
int _cents(double amount) => (amount * 100).round();

/// Sum a split's shares in integer minor units.
int _sumCents(Map<String, double> split) =>
    split.values.fold<int>(0, (sum, amount) => sum + _cents(amount));

/// Sum recalculated participants' shares in integer minor units.
int _sumParticipantCents(List<ExpenseParticipant> participants) =>
    participants.fold<int>(
      0,
      (sum, participant) => sum + _cents(participant.shareAmount),
    );
