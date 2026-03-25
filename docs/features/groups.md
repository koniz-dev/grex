# Groups Feature

The Groups feature manages the spaces where users collaborate, share expenses, and settle balances.

## Overview
- **Group Management**: Users can create, edit, delete, and join groups.
- **Roles & Permissions**: Fine-grained access control (Owner, Admin, Member).
- **Invitations**: Invite users via email or invite links.
- **Members List**: View and manage active participants in the group.

## Architecture Highlights
This module strictly follows the Clean Architecture pattern with Data, Domain, and Presentation layers.

### Domain Layer
- **Entity**: `Group`, `GroupMember`, `GroupRole`
- **Use Cases**: `CreateGroupUseCase`, `JoinGroupUseCase`, `GetGroupsUseCase`

### Data Layer
- **Models**: `GroupModel` (Freezed classes for JSON serialization)
- **Repositories**: `GroupsRepositoryImpl` implementation backed by Supabase.

### Presentation Layer
- **State Management**: Uses BLoC for page-specific state (`GroupBloc`, `GroupState`).
- **Pages**: `GroupsListScreen`, `GroupDetailScreen`, `CreateGroupScreen`.

## Related Features
Groups form the foundation for tracking **[Expenses](expenses.md)** and calculating **[Balances](balances.md)**.
