import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:grex/core/di/injection.dart';
import 'package:grex/core/routing/navigation_extensions.dart';
import 'package:grex/features/groups/domain/entities/group.dart';
import 'package:grex/features/groups/presentation/bloc/group_bloc.dart';
import 'package:grex/features/groups/presentation/bloc/group_event.dart';
import 'package:grex/features/groups/presentation/bloc/group_state.dart';
import 'package:grex/features/groups/presentation/widgets/empty_groups_widget.dart';
import 'package:grex/features/groups/presentation/widgets/group_list_item.dart';

/// Page that displays a list of the user's groups
class GroupListPage extends StatelessWidget {
  /// Creates a [GroupListPage] instance
  const GroupListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => getIt<GroupBloc>()..add(const GroupsLoadRequested()),
      child: const GroupListView(),
    );
  }
}

/// View component for the group list page
class GroupListView extends StatelessWidget {
  /// Creates a [GroupListView] instance
  const GroupListView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nhóm của tôi'),
        elevation: 0,
        backgroundColor: Theme.of(context).colorScheme.surface,
        foregroundColor: Theme.of(context).colorScheme.onSurface,
      ),
      body: BlocBuilder<GroupBloc, GroupState>(
        builder: (context, state) {
          return RefreshIndicator(
            onRefresh: () async {
              context.read<GroupBloc>().add(const GroupsLoadRequested());
            },
            child: _buildBody(context, state),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.goToCreateGroup(),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildBody(BuildContext context, GroupState state) {
    return switch (state) {
      GroupInitial() => const _LoadingWidget(),
      GroupLoading() => const _LoadingWidget(),
      GroupsLoaded() => _buildGroupsList(context, state.groups),
      GroupError() => _buildErrorWidget(context, state.failure.toString()),
      _ => const _LoadingWidget(),
    };
  }

  Widget _buildGroupsList(BuildContext context, List<Group> groups) {
    if (groups.isEmpty) {
      return const EmptyGroupsWidget();
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: groups.length,
      itemBuilder: (context, index) {
        final group = groups[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: GroupListItem(
            group: group,
            onTap: () => _navigateToGroupDetails(context, group),
          ),
        );
      },
    );
  }

  Widget _buildErrorWidget(BuildContext context, String error) {
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
            'Có lỗi xảy ra',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            error,
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              context.read<GroupBloc>().add(const GroupsLoadRequested());
            },
            child: const Text('Thử lại'),
          ),
        ],
      ),
    );
  }

  void _navigateToGroupDetails(BuildContext context, Group group) {
    context.goToGroupDetails(group.id);
  }
}

class _LoadingWidget extends StatelessWidget {
  const _LoadingWidget();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: CircularProgressIndicator(),
    );
  }
}
