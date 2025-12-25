import 'package:flutter/material.dart';
import 'package:grex/features/groups/domain/entities/group_member.dart';

/// Widget for selecting participants for an expense
class ParticipantSelectionWidget extends StatelessWidget {
  /// Creates a [ParticipantSelectionWidget] instance
  const ParticipantSelectionWidget({
    required this.groupMembers,
    required this.selectedParticipants,
    required this.onSelectionChanged,
    super.key,
  });

  /// The list of members available in the group
  final List<GroupMember> groupMembers;

  /// The list of currently selected participants
  final List<Map<String, dynamic>> selectedParticipants;

  /// Callback when the participant selection changes
  final ValueChanged<List<Map<String, dynamic>>> onSelectionChanged;

  @override
  Widget build(BuildContext context) {
    if (groupMembers.isEmpty) {
      return const Text('No group members found');
    }

    return Column(
      children: [
        // Select all/none buttons
        Row(
          children: [
            TextButton(
              onPressed: _selectAll,
              child: const Text('Select All'),
            ),
            const SizedBox(width: 8),
            TextButton(
              onPressed: _selectNone,
              child: const Text('Select None'),
            ),
            const Spacer(),
            Text(
              '${selectedParticipants.length} selected',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.outline,
              ),
            ),
          ],
        ),

        const SizedBox(height: 8),

        // Participant list
        ...groupMembers.map((member) {
          final isSelected = selectedParticipants.any(
            (participant) => participant['userId'] == member.userId,
          );

          return CheckboxListTile(
            title: Text(member.displayName),
            subtitle: Text(member.role.displayName),
            value: isSelected,
            onChanged: (selected) {
              _toggleParticipant(member, selected ?? false);
            },
            secondary: CircleAvatar(
              child: Text(
                member.displayName.isNotEmpty
                    ? member.displayName[0].toUpperCase()
                    : '?',
              ),
            ),
          );
        }),
      ],
    );
  }

  void _toggleParticipant(GroupMember member, bool selected) {
    final updatedParticipants = List<Map<String, dynamic>>.from(
      selectedParticipants,
    );

    if (selected) {
      // Add participant if not already selected
      if (!updatedParticipants.any((p) => p['userId'] == member.userId)) {
        updatedParticipants.add({
          'userId': member.userId,
          'displayName': member.displayName,
        });
      }
    } else {
      // Remove participant
      updatedParticipants.removeWhere((p) => p['userId'] == member.userId);
    }

    onSelectionChanged(updatedParticipants);
  }

  void _selectAll() {
    final allParticipants = groupMembers
        .map(
          (member) => {
            'userId': member.userId,
            'displayName': member.displayName,
          },
        )
        .toList();

    onSelectionChanged(allParticipants);
  }

  void _selectNone() {
    onSelectionChanged([]);
  }
}
