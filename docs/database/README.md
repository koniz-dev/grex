# Database Documentation

This directory contains comprehensive documentation for the Grex expense splitting application database.

## Documentation Structure

```
docs/database/
├── README.md                    # This file - overview and navigation
├── schema/
│   ├── overview.md             # Database schema overview and ER diagram
│   ├── tables.md               # Detailed table documentation
│   ├── relationships.md        # Table relationships and constraints
│   └── indexes.md              # Index documentation and performance
├── functions/
│   ├── overview.md             # Database functions overview
│   ├── business-logic.md       # Business logic functions
│   ├── validation.md           # Validation functions
│   └── utilities.md            # Utility functions
├── triggers/
│   ├── overview.md             # Triggers overview
│   ├── timestamps.md           # Timestamp management triggers
│   ├── audit.md                # Audit logging triggers
│   └── validation.md           # Data validation triggers
├── security/
│   ├── overview.md             # Security overview
│   ├── rls-policies.md         # Row Level Security policies
│   ├── permissions.md          # Permission model and roles
│   └── best-practices.md       # Security best practices
├── operations/
│   ├── migrations.md           # Migration management guide
│   ├── backup-restore.md       # Backup and restore procedures
│   ├── monitoring.md           # Database monitoring
│   └── troubleshooting.md      # Common issues and solutions
└── examples/
    ├── queries.md              # Common query examples
    ├── workflows.md            # Business workflow examples
    └── testing.md              # Testing examples and patterns
```

## Quick Navigation

### For Developers
- [Schema Overview](schema/overview.md) - Start here for database structure
- [Functions](functions/overview.md) - Business logic and utilities
- [Security](security/overview.md) - RLS policies and permissions
- [Query Examples](examples/queries.md) - Common database operations

### For DevOps/DBAs
- [Migration Guide](operations/migrations.md) - Schema change management
- [Backup & Restore](operations/backup-restore.md) - Data protection procedures
- [Monitoring](operations/monitoring.md) - Performance and health monitoring
- [Troubleshooting](operations/troubleshooting.md) - Issue resolution

### For QA/Testing
- [Testing Guide](examples/testing.md) - Database testing patterns
- [Workflows](examples/workflows.md) - End-to-end business processes

## Database Overview

The Grex database is built on PostgreSQL (via Supabase) and includes:

- **7 Core Tables**: users, groups, group_members, expenses, expense_participants, payments, audit_logs
- **3 Enum Types**: member_role, split_method, action_type
- **6+ Functions**: Balance calculation, validation, settlement planning
- **Multiple Triggers**: Timestamp management, audit logging, validation
- **33 RLS Policies**: Comprehensive row-level security
- **Real-time**: WebSocket-based real-time updates

## Key Features

- **Multi-tenant Architecture**: Complete data isolation between groups
- **Role-based Access Control**: Administrator, Editor, Viewer roles
- **Audit Trail**: Complete history of all data modifications
- **Soft Delete**: Recoverable deletion with referential integrity
- **Real-time Updates**: Instant synchronization across devices
- **Currency Support**: Multi-currency with validation
- **Performance Optimized**: Strategic indexing and query optimization

## Getting Started

1. **New to the project?** Start with [Schema Overview](schema/overview.md)
2. **Need to make changes?** Check [Migration Guide](operations/migrations.md)
3. **Security questions?** Review [RLS Policies](security/rls-policies.md)
4. **Performance issues?** See [Monitoring](operations/monitoring.md)

## Contributing

When updating database documentation:

1. Keep documentation in sync with actual schema
2. Include examples for complex concepts
3. Update this README when adding new sections
4. Test all code examples before committing
5. Follow the established documentation structure

## Support

For questions about the database:
- Check [Troubleshooting](operations/troubleshooting.md) first
- Review relevant documentation sections
- Create an issue with specific details
- Include relevant logs and error messages