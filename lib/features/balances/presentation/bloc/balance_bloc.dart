import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:grex/features/balances/domain/entities/balance.dart';
import 'package:grex/features/balances/domain/failures/balance_failure.dart';
import 'package:grex/features/balances/domain/repositories/balance_repository.dart';
import 'package:grex/features/balances/presentation/bloc/balance_event.dart';
import 'package:grex/features/balances/presentation/bloc/balance_state.dart';

/// BLoC for managing group balances and settlement plans
class BalanceBloc extends Bloc<BalanceEvent, BalanceState> {
  /// Creates a [BalanceBloc] instance
  BalanceBloc({
    required BalanceRepository balanceRepository,
  }) : _balanceRepository = balanceRepository,
       super(const BalanceInitial()) {
    on<BalancesLoadRequested>(_onBalancesLoadRequested);
    on<SettlementPlanRequested>(_onSettlementPlanRequested);
  }
  final BalanceRepository _balanceRepository;
  StreamSubscription<List<Balance>>? _balanceSubscription;

  Future<void> _onBalancesLoadRequested(
    BalancesLoadRequested event,
    Emitter<BalanceState> emit,
  ) async {
    emit(const BalanceLoading());

    try {
      // Cancel any existing subscription
      await _balanceSubscription?.cancel();

      // Load initial balances
      final result = await _balanceRepository.getGroupBalances(event.groupId);
      result.fold(
        (failure) => emit(BalanceError(message: _mapFailureToMessage(failure))),
        (balances) {
          emit(BalancesLoaded(balances: balances));

          // Set up real-time subscription for balances after initial load
          _balanceSubscription = _balanceRepository
              .watchGroupBalances(event.groupId)
              .listen(
                (balances) {
                  if (!emit.isDone) {
                    emit(BalancesLoaded(balances: balances));
                  }
                },
                onError: (Object error) {
                  if (!emit.isDone) {
                    emit(
                      BalanceError(
                        message: _mapFailureToMessage(error as BalanceFailure),
                      ),
                    );
                  }
                },
              );
        },
      );
    } on Exception catch (e) {
      emit(BalanceError(message: 'Failed to load balances: $e'));
    }
  }

  Future<void> _onSettlementPlanRequested(
    SettlementPlanRequested event,
    Emitter<BalanceState> emit,
  ) async {
    emit(const BalanceLoading());

    try {
      final result = await _balanceRepository.getSettlementPlan(event.groupId);
      result.fold(
        (failure) => emit(BalanceError(message: _mapFailureToMessage(failure))),
        (settlements) => emit(SettlementLoaded(settlements: settlements)),
      );
    } on Exception catch (e) {
      emit(BalanceError(message: 'Failed to generate settlement plan: $e'));
    }
  }

  String _mapFailureToMessage(BalanceFailure failure) {
    switch (failure) {
      case BalanceCalculationFailure _:
        return 'Failed to calculate balances';
      case SettlementPlanFailure _:
        return 'Failed to generate settlement plan';
      case BalanceNetworkFailure _:
        return 'Network error. Please check your connection';
      case BalanceNotFoundFailure _:
        return 'Balance data not found';
      case NoTransactionsFailure _:
        return 'No transactions found for this group';
      case AlreadySettledFailure _:
        return 'All members are already settled';
      case InsufficientBalancePermissionsFailure _:
        return "You don't have permission to view balances";
      default:
        return failure.message;
    }
  }

  @override
  Future<void> close() async {
    await _balanceSubscription?.cancel();
    return super.close();
  }
}
