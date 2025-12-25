import 'package:equatable/equatable.dart';
import 'package:grex/features/balances/domain/entities/balance.dart';
import 'package:grex/features/balances/domain/entities/settlement.dart';

/// Base class for all balance-related states
abstract class BalanceState extends Equatable {
  /// Creates a [BalanceState] instance
  const BalanceState();

  @override
  List<Object?> get props => [];
}

/// Initial state of the balance feature
class BalanceInitial extends BalanceState {
  /// Creates a [BalanceInitial] instance
  const BalanceInitial();
}

/// State indicating that balance data is being loaded
class BalanceLoading extends BalanceState {
  /// Creates a [BalanceLoading] instance
  const BalanceLoading();
}

/// State indicating that group balances have been successfully loaded
class BalancesLoaded extends BalanceState {
  /// Creates a [BalancesLoaded] instance
  const BalancesLoaded({required this.balances});

  /// The list of balances for the group
  final List<Balance> balances;

  @override
  List<Object?> get props => [balances];
}

/// State indicating that a settlement plan has been successfully loaded
class SettlementLoaded extends BalanceState {
  /// Creates a [SettlementLoaded] instance
  const SettlementLoaded({required this.settlements});

  /// The generated settlement plan
  final List<Settlement> settlements;

  @override
  List<Object?> get props => [settlements];
}

/// State indicating that an error occurred while loading balance data
class BalanceError extends BalanceState {
  /// Creates a [BalanceError] instance
  const BalanceError({required this.message});

  /// The error message
  final String message;

  @override
  List<Object?> get props => [message];
}
