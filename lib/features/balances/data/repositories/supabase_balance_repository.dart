import 'package:dartz/dartz.dart';
import 'package:grex/features/balances/data/models/balance_model.dart';
import 'package:grex/features/balances/data/models/settlement_model.dart';
import 'package:grex/features/balances/domain/entities/balance.dart';
import 'package:grex/features/balances/domain/entities/settlement.dart';
import 'package:grex/features/balances/domain/failures/balance_failure.dart';
import 'package:grex/features/balances/domain/repositories/balance_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Supabase implementation of BalanceRepository
class SupabaseBalanceRepository implements BalanceRepository {
  /// Creates a [SupabaseBalanceRepository] instance
  const SupabaseBalanceRepository({
    required SupabaseClient supabaseClient,
  }) : _supabaseClient = supabaseClient;
  final SupabaseClient _supabaseClient;

  /// Get current user ID
  String? get _currentUserId => _supabaseClient.auth.currentUser?.id;

  @override
  Future<Either<BalanceFailure, List<Balance>>> getGroupBalances(
    String groupId,
  ) async {
    try {
      final userId = _currentUserId;
      if (userId == null) {
        return const Left(BalanceAuthenticationFailure());
      }

      // Check if user is member of the group
      final isMember = await _checkGroupMembership(groupId, userId);
      if (!isMember) {
        return const Left(InsufficientPermissionsFailure('view balances'));
      }

      // Use Supabase function to calculate group balances
      final response = await _supabaseClient.rpc<List<dynamic>>(
        'calculate_group_balances',
        params: {
          'group_id_param': groupId,
        },
      );

      final balances = response
          .map((json) => BalanceModel.fromJson(json as Map<String, dynamic>))
          .cast<Balance>()
          .toList();

      return Right(balances);
    } on PostgrestException catch (e) {
      return Left(_mapPostgrestException(e));
    } on Exception catch (e) {
      return Left(UnknownBalanceFailure(e.toString()));
    }
  }

  @override
  Future<Either<BalanceFailure, List<Settlement>>> getSettlementPlan(
    String groupId,
  ) async {
    try {
      final userId = _currentUserId;
      if (userId == null) {
        return const Left(BalanceAuthenticationFailure());
      }

      // Check if user is member of the group
      final isMember = await _checkGroupMembership(groupId, userId);
      if (!isMember) {
        return const Left(
          InsufficientPermissionsFailure('view settlement plan'),
        );
      }

      // Use Supabase function to generate settlement plan
      final response = await _supabaseClient.rpc<List<dynamic>>(
        'generate_settlement_plan',
        params: {
          'group_id_param': groupId,
        },
      );

      final settlements = response
          .map((json) => SettlementModel.fromJson(json as Map<String, dynamic>))
          .cast<Settlement>()
          .toList();

      return Right(settlements);
    } on PostgrestException catch (e) {
      return Left(_mapPostgrestException(e));
    } on Exception catch (e) {
      return Left(UnknownBalanceFailure(e.toString()));
    }
  }

  @override
  Stream<List<Balance>> watchGroupBalances(String groupId) {
    final userId = _currentUserId;
    if (userId == null) {
      return Stream.error(const BalanceAuthenticationFailure());
    }

    // Watch for changes in expenses and payments that affect balances
    return _supabaseClient
        .from('expenses')
        .stream(primaryKey: ['id'])
        .eq('group_id', groupId)
        .asyncMap((_) async {
          // Recalculate balances when expenses change
          final result = await getGroupBalances(groupId);
          return result.fold(
            (failure) => throw Exception(failure.message),
            (balances) => balances,
          );
        });
  }

  @override
  Stream<List<Settlement>> watchSettlementPlan(String groupId) {
    final userId = _currentUserId;
    if (userId == null) {
      return Stream.error(const BalanceAuthenticationFailure());
    }

    // Watch for changes that affect settlement plan
    return _supabaseClient
        .from('payments')
        .stream(primaryKey: ['id'])
        .eq('group_id', groupId)
        .asyncMap((_) async {
          // Recalculate settlement plan when payments change
          final result = await getSettlementPlan(groupId);
          return result.fold(
            (failure) => throw Exception(failure.message),
            (settlements) => settlements,
          );
        });
  }

  @override
  Future<Either<BalanceFailure, Balance>> getUserBalance(
    String groupId,
    String userId,
  ) async {
    try {
      final currentUserId = _currentUserId;
      if (currentUserId == null) {
        return const Left(BalanceAuthenticationFailure());
      }

      // Check if current user is member of the group
      final isMember = await _checkGroupMembership(groupId, currentUserId);
      if (!isMember) {
        return const Left(InsufficientPermissionsFailure('view balances'));
      }

      // Get all group balances and find the specific user
      final balancesResult = await getGroupBalances(groupId);
      return balancesResult.fold(
        Left.new,
        (balances) {
          final userBalance = balances.firstWhere(
            (balance) => balance.userId == userId,
            orElse: () => Balance(
              userId: userId,
              displayName: 'Unknown User',
              balance: 0,
              currency: 'USD', // Default currency
            ),
          );
          return Right(userBalance);
        },
      );
    } on Exception catch (e) {
      return Left(UnknownBalanceFailure(e.toString()));
    }
  }

  @override
  Future<Either<BalanceFailure, List<Balance>>> getBalancesBetweenUsers(
    String userId1,
    String userId2,
  ) async {
    try {
      final currentUserId = _currentUserId;
      if (currentUserId == null) {
        return const Left(BalanceAuthenticationFailure());
      }

      // Check if current user is one of the specified users
      if (currentUserId != userId1 && currentUserId != userId2) {
        return const Left(InsufficientPermissionsFailure('view user balances'));
      }

      // Get all groups where both users are members
      final commonGroupsResponse = await _supabaseClient
          .from('group_members')
          .select('group_id')
          .eq('user_id', userId1)
          .then((groups1) async {
            final groupIds1 = (groups1 as List<dynamic>)
                .map((g) => (g as Map<String, dynamic>)['group_id'])
                .toSet();

            final groups2 = await _supabaseClient
                .from('group_members')
                .select('group_id')
                .eq('user_id', userId2);

            final groupIds2 = (groups2 as List<dynamic>)
                .map((g) => (g as Map<String, dynamic>)['group_id'])
                .toSet();

            return groupIds1.intersection(groupIds2).toList();
          });

      final balances = <Balance>[];

      // Get balances for each common group
      for (final groupId in commonGroupsResponse) {
        final groupBalancesResult = await getGroupBalances(groupId as String);
        groupBalancesResult.fold(
          (failure) {}, // Skip failed groups
          (groupBalances) {
            final user1Balance = groupBalances.firstWhere(
              (b) => b.userId == userId1,
              orElse: () => Balance(
                userId: userId1,
                displayName: 'User 1',
                balance: 0,
                currency: 'USD',
              ),
            );
            final user2Balance = groupBalances.firstWhere(
              (b) => b.userId == userId2,
              orElse: () => Balance(
                userId: userId2,
                displayName: 'User 2',
                balance: 0,
                currency: 'USD',
              ),
            );
            balances.addAll([user1Balance, user2Balance]);
          },
        );
      }

      return Right(balances);
    } on PostgrestException catch (e) {
      return Left(_mapPostgrestException(e));
    } on Exception catch (e) {
      return Left(UnknownBalanceFailure(e.toString()));
    }
  }

  @override
  Future<Either<BalanceFailure, List<Balance>>> recalculateGroupBalances(
    String groupId,
  ) async {
    try {
      final userId = _currentUserId;
      if (userId == null) {
        return const Left(BalanceAuthenticationFailure());
      }

      // Check if user is member of the group
      final isMember = await _checkGroupMembership(groupId, userId);
      if (!isMember) {
        return const Left(
          InsufficientPermissionsFailure('recalculate balances'),
        );
      }

      // Force recalculation by calling the function
      await _supabaseClient.rpc<dynamic>(
        'calculate_group_balances',
        params: {
          'group_id_param': groupId,
        },
      );

      // Return fresh balances
      return getGroupBalances(groupId);
    } on PostgrestException catch (e) {
      return Left(_mapPostgrestException(e));
    } on Exception catch (e) {
      return Left(UnknownBalanceFailure(e.toString()));
    }
  }

  @override
  Future<Either<BalanceFailure, List<Balance>>> getUserBalanceSummary(
    String userId,
  ) async {
    try {
      final currentUserId = _currentUserId;
      if (currentUserId == null) {
        return const Left(BalanceAuthenticationFailure());
      }

      // Check if current user is requesting their own summary or has permission
      if (currentUserId != userId) {
        return const Left(
          InsufficientPermissionsFailure('view user balance summary'),
        );
      }

      // Get all groups where user is a member
      final userGroupsResponse = await _supabaseClient
          .from('group_members')
          .select('group_id')
          .eq('user_id', userId);

      final groupIds = (userGroupsResponse as List<dynamic>)
          .map((g) => (g as Map<String, dynamic>)['group_id'] as String)
          .toList();

      final allBalances = <Balance>[];

      // Get balances for each group
      for (final groupId in groupIds) {
        final groupBalancesResult = await getGroupBalances(groupId);
        groupBalancesResult.fold(
          (failure) {}, // Skip failed groups
          (groupBalances) {
            final userBalance = groupBalances.firstWhere(
              (b) => b.userId == userId,
              orElse: () => Balance(
                userId: userId,
                displayName: 'User',
                balance: 0,
                currency: 'USD',
              ),
            );
            if (userBalance.balance != 0.0) {
              allBalances.add(userBalance);
            }
          },
        );
      }

      return Right(allBalances);
    } on PostgrestException catch (e) {
      return Left(_mapPostgrestException(e));
    } on Exception catch (e) {
      return Left(UnknownBalanceFailure(e.toString()));
    }
  }

  @override
  Future<Either<BalanceFailure, bool>> isGroupSettled(String groupId) async {
    try {
      final userId = _currentUserId;
      if (userId == null) {
        return const Left(BalanceAuthenticationFailure());
      }

      // Check if user is member of the group
      final isMember = await _checkGroupMembership(groupId, userId);
      if (!isMember) {
        return const Left(
          InsufficientPermissionsFailure('check settlement status'),
        );
      }

      // Get group balances
      final balancesResult = await getGroupBalances(groupId);
      return balancesResult.fold(
        Left.new,
        (balances) {
          // Group is settled if all balances are zero (within tolerance)
          const tolerance = 0.01;
          final isSettled = balances.every(
            (balance) => balance.balance.abs() < tolerance,
          );
          return Right(isSettled);
        },
      );
    } on Exception catch (e) {
      return Left(UnknownBalanceFailure(e.toString()));
    }
  }

  // Helper methods

  Future<bool> _checkGroupMembership(String groupId, String userId) async {
    final response = await _supabaseClient
        .from('group_members')
        .select('id')
        .eq('group_id', groupId)
        .eq('user_id', userId)
        .maybeSingle();

    return response != null;
  }

  BalanceFailure _mapPostgrestException(PostgrestException e) {
    switch (e.code) {
      case '23505': // Unique violation
        return const InvalidBalanceDataFailure('Duplicate data');
      case '23503': // Foreign key violation
        return const InvalidBalanceDataFailure('Invalid reference');
      case '42501': // Insufficient privilege
        return const InsufficientPermissionsFailure();
      case 'PGRST116': // Not found
        return const BalanceNotFoundFailure();
      default:
        return BalanceDatabaseFailure(e.message);
    }
  }
}
