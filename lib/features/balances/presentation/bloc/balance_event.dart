import 'package:equatable/equatable.dart';

/// Base class for all balance-related events
abstract class BalanceEvent extends Equatable {
  /// Creates a [BalanceEvent] instance
  const BalanceEvent();

  @override
  List<Object?> get props => [];
}

/// Event triggered when group balances need to be loaded
class BalancesLoadRequested extends BalanceEvent {
  /// Creates a [BalancesLoadRequested] instance
  const BalancesLoadRequested({required this.groupId});

  /// The ID of the group whose balances are requested
  final String groupId;

  @override
  List<Object?> get props => [groupId];
}

/// Event triggered when a settlement plan is requested for a group
class SettlementPlanRequested extends BalanceEvent {
  /// Creates a [SettlementPlanRequested] instance
  const SettlementPlanRequested({required this.groupId});

  /// The ID of the group for which the settlement plan is requested
  final String groupId;

  @override
  List<Object?> get props => [groupId];
}
