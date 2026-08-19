// This file fires `discarded_futures` on Flutter APIs that are annotated
// `@awaitNotRequired` -- HapticFeedback.lightImpact and Navigator.pushNamed --
// called from synchronous callbacks, where there is nothing to await into.
//
// There is no per-line form that settles: wrapping such a call in `unawaited()`
// trips `unnecessary_unawaited` (the annotation makes the wrapper redundant),
// and leaving it bare trips `discarded_futures` (which does not consult the
// annotation). Fixing one call moved the diagnostic to the other and back
// across successive analyzer runs, so the exemption is file-scoped rather than
// chased line by line. Scoped to this file, not the project, and not applied to
// any future that carries a result worth handling. See issue #42.
// ignore_for_file: discarded_futures

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:grex/core/di/injection.dart';
import 'package:grex/features/balances/domain/entities/balance.dart';
import 'package:grex/features/balances/presentation/bloc/balance_bloc.dart';
import 'package:grex/features/balances/presentation/bloc/balance_event.dart';
import 'package:grex/features/balances/presentation/bloc/balance_state.dart';
import 'package:grex/features/balances/presentation/widgets/balance_list_error_widget.dart';
import 'package:grex/features/balances/presentation/widgets/balance_list_item.dart';
import 'package:grex/features/balances/presentation/widgets/balance_list_skeleton.dart';
import 'package:grex/features/balances/presentation/widgets/balance_summary_card.dart';
import 'package:grex/features/balances/presentation/widgets/empty_balances_widget.dart';
import 'package:grex/shared/extensions/context_extensions.dart';
import 'package:grex/shared/theme/app_radius.dart';
import 'package:grex/shared/theme/app_spacing.dart';
import 'package:grex/shared/utils/currency_formatter.dart';

/// Page displaying group member balances and settlement options.
class BalancePage extends StatefulWidget {
  /// Creates a [BalancePage].
  const BalancePage({
    required this.groupId,
    required this.groupName,
    required this.groupCurrency,
    super.key,
  });

  /// The ID of the group whose balances are being displayed.
  final String groupId;

  /// The display name of the group (rendered in the app bar).
  final String groupName;

  /// The currency used for the group's balances.
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
    HapticFeedback.lightImpact();
    Navigator.of(context).pushNamed(
      '/settlement-plan',
      arguments: {
        'groupId': widget.groupId,
        'groupName': widget.groupName,
        'groupCurrency': widget.groupCurrency,
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;

    return BlocProvider.value(
      value: _balanceBloc,
      child: Scaffold(
        appBar: AppBar(
          title: Text(l10n.balancesPageTitle(widget.groupName)),
          backgroundColor: theme.colorScheme.surface,
          foregroundColor: theme.colorScheme.onSurface,
          elevation: 0,
          scrolledUnderElevation: 1,
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh_rounded),
              onPressed: () {
                HapticFeedback.lightImpact();
                _loadBalances();
              },
              tooltip: l10n.refreshBalances,
            ),
          ],
        ),
        body: BlocBuilder<BalanceBloc, BalanceState>(
          builder: (context, state) {
            return RefreshIndicator(
              onRefresh: () async {
                await HapticFeedback.lightImpact();
                _loadBalances();
              },
              child: _BalanceBody(
                state: state,
                groupCurrency: widget.groupCurrency,
                onRetry: _loadBalances,
                onGenerateSettlement: _generateSettlementPlan,
                onShowBalanceDetail: _showBalanceDetails,
              ),
            );
          },
        ),
        floatingActionButton: BlocBuilder<BalanceBloc, BalanceState>(
          builder: (context, state) {
            if (state is! BalancesLoaded || state.balances.isEmpty) {
              return const SizedBox.shrink();
            }
            final hasUnsettled = state.balances.any((b) => !b.isSettled);
            if (!hasUnsettled) return const SizedBox.shrink();
            return FloatingActionButton.extended(
              onPressed: _generateSettlementPlan,
              icon: const Icon(Icons.account_balance_wallet_rounded),
              label: Text(l10n.settleUp),
              shape: const RoundedRectangleBorder(
                borderRadius: AppRadius.brLg,
              ),
            );
          },
        ),
      ),
    );
  }

  // ---------------- Balance detail sheet ----------------

  void _showBalanceDetails(Balance balance) {
    unawaited(HapticFeedback.selectionClick());
    unawaited(
      showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        showDragHandle: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppRadius.lg),
          ),
        ),
        builder: (sheetContext) => _BalanceDetailSheet(
          balance: balance,
          onViewSettlementPlan: () {
            Navigator.of(sheetContext).pop();
            _generateSettlementPlan();
          },
        ),
      ),
    );
  }
}

class _BalanceBody extends StatelessWidget {
  const _BalanceBody({
    required this.state,
    required this.groupCurrency,
    required this.onRetry,
    required this.onGenerateSettlement,
    required this.onShowBalanceDetail,
  });

  final BalanceState state;
  final String groupCurrency;
  final VoidCallback onRetry;
  final VoidCallback onGenerateSettlement;
  final void Function(Balance balance) onShowBalanceDetail;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);

    if (state is BalanceLoading) {
      return const BalanceListSkeleton();
    }
    if (state is BalanceError) {
      return BalanceListErrorWidget(onRetry: onRetry);
    }
    if (state is BalancesLoaded) {
      final loaded = state as BalancesLoaded;
      if (loaded.balances.isEmpty) {
        return const EmptyBalancesWidget();
      }
      return CustomScrollView(
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.lg,
              AppSpacing.lg,
              AppSpacing.sm,
            ),
            sliver: SliverToBoxAdapter(
              child: BalanceSummaryCard(
                balances: loaded.balances,
                currency: groupCurrency,
                onGenerateSettlement: onGenerateSettlement,
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.sm,
              AppSpacing.lg,
              AppSpacing.sm,
            ),
            sliver: SliverToBoxAdapter(
              child: Row(
                children: [
                  Text(
                    l10n.memberBalances,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    l10n.membersCount(loaded.balances.length),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              0,
              AppSpacing.lg,
              AppSpacing.huge + AppSpacing.lg,
            ),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final balance = loaded.balances[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.md),
                    child: BalanceListItem(
                      balance: balance,
                      onTap: () => onShowBalanceDetail(balance),
                    ),
                  );
                },
                childCount: loaded.balances.length,
              ),
            ),
          ),
        ],
      );
    }
    return const EmptyBalancesWidget();
  }
}

class _BalanceDetailSheet extends StatelessWidget {
  const _BalanceDetailSheet({
    required this.balance,
    required this.onViewSettlementPlan,
  });

  final Balance balance;
  final VoidCallback onViewSettlementPlan;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final l10n = context.l10n;
    final accent = _statusColor(theme, balance.status);
    final subtitle = balance.isSettled
        ? l10n.balanceStatusSettled
        : (balance.owesMoneyToGroup
              ? l10n.balanceStatusOwes
              : l10n.balanceStatusOwed);

    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.sm,
        AppSpacing.lg,
        MediaQuery.viewInsetsOf(context).bottom + AppSpacing.lg,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: accent.withValues(alpha: 0.1),
                child: Text(
                  balance.displayName.isNotEmpty
                      ? balance.displayName.characters.first.toUpperCase()
                      : '?',
                  style: TextStyle(
                    color: accent,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.lg),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      balance.displayName,
                      style: theme.textTheme.titleLarge,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: AppSpacing.xxs),
                    Text(
                      subtitle,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: accent,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xxl),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              color: scheme.surfaceContainerHighest.withValues(alpha: 0.3),
              borderRadius: AppRadius.brMd,
            ),
            child: Column(
              children: [
                Text(
                  l10n.balanceAmountLabel,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  CurrencyFormatter.format(
                    amount: balance.absoluteBalance,
                    currencyCode: balance.currency,
                  ),
                  style: theme.textTheme.headlineMedium?.copyWith(
                    color: accent,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          if (!balance.isSettled) ...[
            const SizedBox(height: AppSpacing.lg),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: onViewSettlementPlan,
                icon: const Icon(Icons.account_balance_wallet_rounded),
                label: Text(l10n.viewSettlementPlan),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                  shape: const RoundedRectangleBorder(
                    borderRadius: AppRadius.brMd,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Color _statusColor(ThemeData theme, BalanceStatus status) {
    return switch (status) {
      BalanceStatus.owes => theme.colorScheme.error,
      BalanceStatus.owed => Colors.green,
      BalanceStatus.settled => theme.colorScheme.onSurfaceVariant,
    };
  }
}
