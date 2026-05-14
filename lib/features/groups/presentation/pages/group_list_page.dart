import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:grex/core/di/injection.dart';
import 'package:grex/core/routing/navigation_extensions.dart';
import 'package:grex/features/groups/domain/entities/group.dart';
import 'package:grex/features/groups/presentation/bloc/group_bloc.dart';
import 'package:grex/features/groups/presentation/bloc/group_event.dart';
import 'package:grex/features/groups/presentation/bloc/group_state.dart';
import 'package:grex/features/groups/presentation/widgets/empty_groups_widget.dart';
import 'package:grex/features/groups/presentation/widgets/group_list_error_widget.dart';
import 'package:grex/features/groups/presentation/widgets/group_list_item.dart';
import 'package:grex/features/groups/presentation/widgets/group_list_skeleton.dart';
import 'package:grex/shared/extensions/context_extensions.dart';
import 'package:grex/shared/theme/app_radius.dart';
import 'package:grex/shared/theme/app_spacing.dart';

/// Page that displays the user's groups.
class GroupListPage extends StatelessWidget {
  /// Creates a [GroupListPage].
  const GroupListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => getIt<GroupBloc>()..add(const GroupsLoadRequested()),
      child: const GroupListView(),
    );
  }
}

/// View component for the group list page.
///
/// Mobile UX:
///   * Pull-to-refresh is always available, even on empty/error states —
///     users learn the gesture once and expect it everywhere.
///   * Loading uses a skeleton that mirrors the row layout so the page
///     doesn't visually "snap" when data arrives.
///   * FAB has an extended label so the primary action is discoverable to
///     first-time users without an onboarding tooltip.
class GroupListView extends StatelessWidget {
  /// Creates a [GroupListView].
  const GroupListView({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.myGroups),
        elevation: 0,
        backgroundColor: theme.colorScheme.surface,
        foregroundColor: theme.colorScheme.onSurface,
        scrolledUnderElevation: 1,
      ),
      body: BlocBuilder<GroupBloc, GroupState>(
        builder: (context, state) {
          return RefreshIndicator(
            onRefresh: () async {
              HapticFeedback.lightImpact();
              context.read<GroupBloc>().add(const GroupsLoadRequested());
            },
            child: _GroupListBody(state: state),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          HapticFeedback.lightImpact();
          context.goToCreateGroup();
        },
        icon: const Icon(Icons.add_rounded),
        label: Text(l10n.createNewGroup),
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.brLg),
      ),
    );
  }
}

class _GroupListBody extends StatelessWidget {
  const _GroupListBody({required this.state});

  final GroupState state;

  @override
  Widget build(BuildContext context) {
    return switch (state) {
      GroupInitial() || GroupLoading() => const GroupListSkeleton(),
      GroupsLoaded(:final groups) ||
      GroupOperationSuccess(:final groups) ||
      GroupRealTimeUpdate(:final groups) => _GroupsList(groups: groups),
      // Keep stale data on screen if we still have it; otherwise show the
      // empty / friendly error illustration.
      GroupError(:final groups) when groups != null && groups.isNotEmpty =>
        _GroupsList(groups: groups),
      GroupError() => GroupListErrorWidget(
        onRetry: () =>
            context.read<GroupBloc>().add(const GroupsLoadRequested()),
      ),
      _ => const GroupListSkeleton(),
    };
  }
}

class _GroupsList extends StatelessWidget {
  const _GroupsList({required this.groups});

  final List<Group> groups;

  @override
  Widget build(BuildContext context) {
    if (groups.isEmpty) {
      return const EmptyGroupsWidget();
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.lg,
        // Enough space at the bottom so the extended FAB never covers the
        // last list item.
        AppSpacing.huge + AppSpacing.lg,
      ),
      itemCount: groups.length,
      itemBuilder: (context, index) {
        final group = groups[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.md),
          child: GroupListItem(
            group: group,
            onTap: () => context.goToGroupDetails(group.id),
          ),
        );
      },
    );
  }
}
