import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:grex/core/di/injection.dart';
import 'package:grex/features/balances/domain/entities/settlement.dart';
import 'package:grex/features/balances/presentation/bloc/balance_bloc.dart';
import 'package:grex/features/balances/presentation/bloc/balance_event.dart';
import 'package:grex/features/balances/presentation/bloc/balance_state.dart';
import 'package:grex/features/balances/presentation/widgets/empty_settlement_widget.dart';
import 'package:grex/features/balances/presentation/widgets/settlement_list_item.dart';
import 'package:grex/features/balances/presentation/widgets/settlement_summary_card.dart';
import 'package:grex/features/payments/presentation/pages/create_payment_page.dart';
import 'package:grex/shared/utils/currency_formatter.dart';

/// Page displaying the settlement plan with recommended payments
class SettlementPlanPage extends StatefulWidget {
  /// Creates a [SettlementPlanPage] instance
  const SettlementPlanPage({
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
  State<SettlementPlanPage> createState() => _SettlementPlanPageState();
}

/// State class for SettlementPlanPage
class _SettlementPlanPageState extends State<SettlementPlanPage> {
  late final BalanceBloc _balanceBloc;

  @override
  void initState() {
    super.initState();
    _balanceBloc = getIt<BalanceBloc>();
    _loadSettlementPlan();
  }

  @override
  void dispose() {
    unawaited(_balanceBloc.close());
    super.dispose();
  }

  void _loadSettlementPlan() {
    _balanceBloc.add(SettlementPlanRequested(groupId: widget.groupId));
  }

  void _recordPayment(Settlement settlement) {
    unawaited(
      Navigator.of(context)
          .push(
            MaterialPageRoute<void>(
              builder: (context) => CreatePaymentPage(
                groupId: widget.groupId,
                groupCurrency: widget.groupCurrency,
              ),
            ),
          )
          .then((_) {
            // Refresh settlement plan after payment is recorded
            _loadSettlementPlan();
          }),
    );
  }

  void _recordSettlementPayment(Settlement settlement) {
    unawaited(
      showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Record Settlement Payment'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Record this settlement payment?',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(
                    context,
                  ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Payment Details',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text('From: ${settlement.payerName}'),
                    Text('To: ${settlement.recipientName}'),
                    Text(
                      'Amount: ${CurrencyFormatter.format(
                        amount: settlement.amount,
                        currencyCode: settlement.currency,
                      )}',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _recordPayment(settlement);
              },
              child: const Text('Record Payment'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _balanceBloc,
      child: Scaffold(
        appBar: AppBar(
          title: Text('${widget.groupName} - Settlement Plan'),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _loadSettlementPlan,
              tooltip: 'Refresh settlement plan',
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
                      'Error loading settlement plan',
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
                      onPressed: _loadSettlementPlan,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Retry'),
                    ),
                  ],
                ),
              );
            }

            if (state is SettlementLoaded) {
              if (state.settlements.isEmpty) {
                return const EmptySettlementWidget();
              }

              return RefreshIndicator(
                onRefresh: () async {
                  _loadSettlementPlan();
                },
                child: CustomScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  slivers: [
                    // Settlement summary card
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: SettlementSummaryCard(
                          settlements: state.settlements,
                          currency: widget.groupCurrency,
                        ),
                      ),
                    ),

                    // Settlement list header
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                        child: Row(
                          children: [
                            Text(
                              'Recommended Payments',
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                            const Spacer(),
                            Text(
                              '${state.settlements.length} payments',
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

                    // Settlement list
                    SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final settlement = state.settlements[index];
                          return Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 4,
                            ),
                            child: SettlementListItem(
                              settlement: settlement,
                              onRecordPayment: () =>
                                  _recordSettlementPayment(settlement),
                              onTap: () => _showSettlementDetails(settlement),
                            ),
                          );
                        },
                        childCount: state.settlements.length,
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

            return const EmptySettlementWidget();
          },
        ),
      ),
    );
  }

  void _showSettlementDetails(Settlement settlement) {
    unawaited(
      showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        builder: (context) => DraggableScrollableSheet(
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

                  // Settlement title
                  Text(
                    'Settlement Details',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Payer info
                  _buildPersonCard(
                    context,
                    'Payer',
                    settlement.payerName,
                    Icons.person_outline,
                    Theme.of(context).colorScheme.error,
                  ),

                  const SizedBox(height: 16),

                  // Arrow and amount
                  Row(
                    children: [
                      const Spacer(),
                      Column(
                        children: [
                          Icon(
                            Icons.arrow_downward,
                            size: 32,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: Theme.of(
                                context,
                              ).colorScheme.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              CurrencyFormatter.format(
                                amount: settlement.amount,
                                currencyCode: settlement.currency,
                              ),
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.primary,
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                          ),
                        ],
                      ),
                      const Spacer(),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Recipient info
                  _buildPersonCard(
                    context,
                    'Recipient',
                    settlement.recipientName,
                    Icons.person,
                    Colors.green,
                  ),

                  const SizedBox(height: 32),

                  // Action button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.of(context).pop();
                        _recordSettlementPayment(settlement);
                      },
                      icon: const Icon(Icons.payment),
                      label: const Text('Record This Payment'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Info text
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
                    child: Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          size: 20,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Recording this payment will update the group '
                            'balances and may change the settlement plan.',
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurfaceVariant,
                                ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildPersonCard(
    BuildContext context,
    String label,
    String name,
    IconData icon,
    Color color,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: color.withValues(alpha: 0.2),
            child: Icon(
              icon,
              color: color,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: color,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  name,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
