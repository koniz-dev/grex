import 'package:dartz/dartz.dart';
import 'package:grex/features/balances/domain/entities/balance.dart';
import 'package:grex/features/balances/domain/entities/settlement.dart';
import 'package:grex/features/balances/domain/failures/balance_failure.dart';

/// Repository interface for balance operations
abstract class BalanceRepository {
  /// Get all balances for a specific group
  Future<Either<BalanceFailure, List<Balance>>> getGroupBalances(
    String groupId,
  );

  /// Get settlement plan for a group (optimized payment suggestions)
  Future<Either<BalanceFailure, List<Settlement>>> getSettlementPlan(
    String groupId,
  );

  /// Watch balances for a group for real-time updates
  Stream<List<Balance>> watchGroupBalances(String groupId);

  /// Watch settlement plan for a group for real-time updates
  Stream<List<Settlement>> watchSettlementPlan(String groupId);

  /// Get balance for a specific user in a group
  Future<Either<BalanceFailure, Balance>> getUserBalance(
    String groupId,
    String userId,
  );

  /// Get balances between two users across all groups
  Future<Either<BalanceFailure, List<Balance>>> getBalancesBetweenUsers(
    String userId1,
    String userId2,
  );

  /// Recalculate balances for a group (force refresh)
  Future<Either<BalanceFailure, List<Balance>>> recalculateGroupBalances(
    String groupId,
  );

  /// Get balance summary for a user across all groups
  Future<Either<BalanceFailure, List<Balance>>> getUserBalanceSummary(
    String userId,
  );

  /// Check if group balances are settled (all balances are zero)
  Future<Either<BalanceFailure, bool>> isGroupSettled(String groupId);
}
