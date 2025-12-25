import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:grex/core/di/injection.dart';
import 'package:grex/features/balances/domain/entities/balance.dart';
import 'package:grex/features/balances/presentation/bloc/balance_bloc.dart';
import 'package:grex/features/balances/presentation/bloc/balance_event.dart';
import 'package:grex/features/balances/presentation/bloc/balance_state.dart';
import 'package:grex/features/balances/presentation/widgets/balance_list_item.dart';
import 'package:grex/features/balances/presentation/widgets/balance_summary_card.dart';
import 'package:grex/features/balances/presentation/widgets/empty_balances_widget.dart';
import 'package:grex/shared/utils/currency_formatter.dart';

/// Page displaying group member balances and settlement options
class BalancePage extends StatefulWidget {
  /// Creates a [BalancePage] instance
  const BalancePage({
    required this.groupId,
    required this.groupName,
    required this.groupCurrency,
    super.key,
  });

  /// The ID of the group
  final String groupId;

  /// The name of the group
  final String groupName;

  /// The currency code of the group
  final String groupCurrency;

  @override
  State<BalancePage> createState() => _BalancePageState();
}

class _BalancePageState extends State<BalancePage> {
  late final BalanceBloc _balanceBloc;

  @override
  void initState() {
    super.initState();
    _balanceBloc = getIt<BalanceBloc>();
    _loadBalances();
  }

  @override
  void dispose() {
    unawaited(_balanceBloc.close());
    super.dispose();
  }

  void _loadBalances() {
    _balanceBloc.add(BalancesLoadRequested(groupId: widget.groupId));
  }

  void _generateSettlementPlan() {
    unawaited(
      Navigator.of(context).pushNamed(
        '/settlement-plan',
        arguments: {
          'groupId': widget.groupId,
          'groupName': widget.groupName,
          'groupCurrency': widget.groupCurrency,
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _balanceBloc,
      child: Scaffold(
        appBar: AppBar(
          title: Text('${widget.groupName} - Balances'),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _loadBalances,
              tooltip: 'Refresh balances',
            ),
          ],
        ),
        body: BlocBuilder<BalanceBloc, BalanceState>(
          builder: (context, state) {
            if (state is BalanceLoading) {
              return const Center(
                child: CircularProgressIndicator(),
              );
            }

            if (state is BalanceError) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 64,
                      color: Theme.of(context).colorScheme.error,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Error loading balances',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      state.message,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: _loadBalances,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Retry'),
                    ),
                  ],
                ),
              );
            }

            if (state is BalancesLoaded) {
              if (state.balances.isEmpty) {
                return const EmptyBalancesWidget();
              }

              return RefreshIndicator(
                onRefresh: () async {
                  _loadBalances();
                },
                child: CustomScrollView(
                  slivers: [
                    // Balance summary card
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: BalanceSummaryCard(
                          balances: state.balances,
                          currency: widget.groupCurrency,
                          onGenerateSettlement: _generateSettlementPlan,
                        ),
                      ),
                    ),

                    // Balance list header
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                        child: Row(
                          children: [
                            Text(
                              'Member Balances',
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                            const Spacer(),
                            Text(
                              '${state.balances.length} members',
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onSurfaceVariant,
                                  ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Balance list
                    SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final balance = state.balances[index];
                          return Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 4,
                            ),
                            child: BalanceListItem(
                              balance: balance,
                              onTap: () => _showBalanceDetails(balance),
                            ),
                          );
                        },
                        childCount: state.balances.length,
                      ),
                    ),

                    // Bottom padding
                    const SliverToBoxAdapter(
                      child: SizedBox(height: 16),
                    ),
                  ],
                ),
              );
            }

            return const EmptyBalancesWidget();
          },
        ),
        floatingActionButton: BlocBuilder<BalanceBloc, BalanceState>(
          builder: (context, state) {
            if (state is BalancesLoaded && state.balances.isNotEmpty) {
              final hasUnsettledBalances = state.balances.any(
                (b) => !b.isSettled,
              );

              if (hasUnsettledBalances) {
                return FloatingActionButton.extended(
                  onPressed: _generateSettlementPlan,
                  icon: const Icon(Icons.account_balance_wallet),
                  label: const Text('Settle Up'),
                );
              }
            }
            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }

  void _showBalanceDetails(Balance balance) {
    unawaited(
      showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        builder: (context) => DraggableScrollableSheet(
          initialChildSize: 0.4,
          minChildSize: 0.3,
          maxChildSize: 0.8,
          expand: false,
          builder: (context, scrollController) {
            return Container(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Handle bar
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Member info
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 24,
                        child: Text(
                          balance.displayName.isNotEmpty
                              ? balance.displayName[0].toUpperCase()
                              : '?',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              balance.displayName,
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            Text(
                              balance.balanceStatusText,
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(
                                    color: _getBalanceColor(
                                      context,
                                      balance.status,
                                    ),
                                  ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Balance amount
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color:
                          Theme.of(
                            context,
                          ).colorScheme.surfaceContainerHighest.withValues(
                            alpha: 0.3,
                          ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        Text(
                          'Balance',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurfaceVariant,
                              ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          CurrencyFormatter.format(
                            amount: balance.absoluteBalance,
                            currencyCode: balance.currency,
                          ),
                          style: Theme.of(context).textTheme.headlineMedium
                              ?.copyWith(
                                color: _getBalanceColor(
                                  context,
                                  balance.status,
                                ),
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Action buttons
                  if (!balance.isSettled) ...[
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _generateSettlementPlan,
                        icon: const Icon(Icons.account_balance_wallet),
                        label: const Text('View Settlement Plan'),
                      ),
                    ),
                  ],
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Color _getBalanceColor(BuildContext context, BalanceStatus status) {
    switch (status) {
      case BalanceStatus.owes:
        return Theme.of(context).colorScheme.error;
      case BalanceStatus.owed:
        return Colors.green;
      case BalanceStatus.settled:
        return Theme.of(context).colorScheme.onSurfaceVariant;
    }
  }
}
