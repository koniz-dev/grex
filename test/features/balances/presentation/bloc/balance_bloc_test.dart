import 'dart:async';
import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:grex/features/balances/domain/entities/balance.dart';
import 'package:grex/features/balances/domain/entities/settlement.dart';
import 'package:grex/features/balances/domain/failures/balance_failure.dart';
import 'package:grex/features/balances/domain/repositories/balance_repository.dart';
import 'package:grex/features/balances/presentation/bloc/balance_bloc.dart';
import 'package:grex/features/balances/presentation/bloc/balance_event.dart';
import 'package:grex/features/balances/presentation/bloc/balance_state.dart';

// Simple fake repository for testing
class FakeBalanceRepository implements BalanceRepository {
  List<Balance> _balances = [];
  List<Settlement> _settlements = [];
  bool _shouldFail = false;
  late BalanceFailure _failureToReturn;
  final StreamController<List<Balance>> _balanceStreamController =
      StreamController<List<Balance>>.broadcast();
  final StreamController<List<Settlement>> _settlementStreamController =
      StreamController<List<Settlement>>.broadcast();

  void setBalances(List<Balance> balances) {
    _balances = balances;
    _balanceStreamController.add(balances);
  }

  void setSettlements(List<Settlement> settlements) {
    _settlements = settlements;
    _settlementStreamController.add(settlements);
  }

  void setShouldFail({required bool shouldFail, BalanceFailure? failure}) {
    _shouldFail = shouldFail;
    _failureToReturn = failure ?? const BalanceNotFoundFailure();
  }

  @override
  Future<Either<BalanceFailure, List<Balance>>> getGroupBalances(
    String groupId,
  ) async {
    if (_shouldFail) {
      return Left(_failureToReturn);
    }
    return Right(_balances);
  }

  @override
  Stream<List<Balance>> watchGroupBalances(String groupId) {
    return _balanceStreamController.stream;
  }

  @override
  Future<Either<BalanceFailure, List<Settlement>>> getSettlementPlan(
    String groupId,
  ) async {
    if (_shouldFail) {
      return Left(_failureToReturn);
    }
    return Right(_settlements);
  }

  @override
  Stream<List<Settlement>> watchSettlementPlan(String groupId) {
    return _settlementStreamController.stream;
  }

  @override
  Future<Either<BalanceFailure, Balance>> getUserBalance(
    String groupId,
    String userId,
  ) async {
    if (_shouldFail) return Left(_failureToReturn);
    return Right(_balances.firstWhere((b) => b.userId == userId));
  }

  @override
  Future<Either<BalanceFailure, List<Balance>>> getBalancesBetweenUsers(
    String userId1,
    String userId2,
  ) async {
    if (_shouldFail) return Left(_failureToReturn);
    return const Right([]);
  }

  @override
  Future<Either<BalanceFailure, List<Balance>>> recalculateGroupBalances(
    String groupId,
  ) async {
    if (_shouldFail) return Left(_failureToReturn);
    return Right(_balances);
  }

  @override
  Future<Either<BalanceFailure, List<Balance>>> getUserBalanceSummary(
    String userId,
  ) async {
    if (_shouldFail) return Left(_failureToReturn);
    return const Right([]);
  }

  @override
  Future<Either<BalanceFailure, bool>> isGroupSettled(String groupId) async {
    if (_shouldFail) return Left(_failureToReturn);
    return Right(_balances.every((b) => b.balance == 0));
  }
}

void main() {
  group('BalanceBloc', () {
    late FakeBalanceRepository repository;
    late BalanceBloc balanceBloc;

    const testGroupId = 'group-1';
    final testBalances = [
      const Balance(
        userId: 'user-1',
        displayName: 'User One',
        balance: 100,
        currency: 'USD',
      ),
      const Balance(
        userId: 'user-2',
        displayName: 'User Two',
        balance: -100,
        currency: 'USD',
      ),
    ];

    final testSettlements = [
      const Settlement(
        payerId: 'user-2',
        payerName: 'User Two',
        recipientId: 'user-1',
        recipientName: 'User One',
        amount: 100,
        currency: 'USD',
      ),
    ];

    setUp(() {
      repository = FakeBalanceRepository();
      balanceBloc = BalanceBloc(balanceRepository: repository);
    });

    tearDown(() async {
      await balanceBloc.close();
    });

    test('initial state should be BalanceInitial', () {
      expect(balanceBloc.state, equals(const BalanceInitial()));
    });

    blocTest<BalanceBloc, BalanceState>(
      'emits [BalanceLoading, BalancesLoaded] when '
      'BalancesLoadRequested is added',
      build: () {
        repository.setBalances(testBalances);
        return balanceBloc;
      },
      act: (bloc) =>
          bloc.add(const BalancesLoadRequested(groupId: testGroupId)),
      expect: () => [
        const BalanceLoading(),
        BalancesLoaded(balances: testBalances),
      ],
    );

    blocTest<BalanceBloc, BalanceState>(
      'emits [BalanceLoading, SettlementLoaded] when '
      'SettlementPlanRequested is added',
      build: () {
        repository.setSettlements(testSettlements);
        return balanceBloc;
      },
      act: (bloc) =>
          bloc.add(const SettlementPlanRequested(groupId: testGroupId)),
      expect: () => [
        const BalanceLoading(),
        SettlementLoaded(settlements: testSettlements),
      ],
    );

    blocTest<BalanceBloc, BalanceState>(
      'emits [BalanceLoading, BalanceError] when loading fails',
      build: () {
        repository.setShouldFail(shouldFail: true);
        return balanceBloc;
      },
      act: (bloc) =>
          bloc.add(const BalancesLoadRequested(groupId: testGroupId)),
      expect: () => [
        const BalanceLoading(),
        isA<BalanceError>(),
      ],
    );

    blocTest<BalanceBloc, BalanceState>(
      'should handle real-time updates',
      build: () {
        repository.setBalances(testBalances);
        return balanceBloc;
      },
      act: (bloc) async {
        bloc.add(const BalancesLoadRequested(groupId: testGroupId));
        await Future<void>.delayed(Duration.zero);
        repository.setBalances([]);
      },
      skip: 1, // Skip Loading state
      expect: () => [
        BalancesLoaded(balances: testBalances),
        const BalancesLoaded(balances: []),
      ],
    );
  });
}
