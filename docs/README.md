# Grex Documentation

Welcome to the comprehensive documentation for the Grex expense splitting application.

## Documentation Structure

```
docs/
├── README.md                    # This file - main documentation index
├── database/                    # Database documentation
│   ├── README.md               # Database documentation overview
│   ├── schema/                 # Database schema documentation
│   │   ├── overview.md         # Schema overview and ER diagram
│   │   ├── tables.md           # Detailed table documentation
│   │   ├── relationships.md    # Table relationships and constraints
│   │   └── indexes.md          # Index documentation and performance
│   ├── functions/              # Database functions documentation
│   │   └── overview.md         # Functions overview
│   ├── triggers/               # Database triggers documentation
│   ├── security/               # Security and RLS documentation
│   │   └── rls-policies.md     # Row Level Security policies
│   ├── operations/             # Database operations documentation
│   │   └── migrations.md       # Migration management guide
│   └── examples/               # Query and workflow examples
│       ├── queries.md          # Common database queries
│       └── workflows.md        # Business workflow examples
├── api/                        # API documentation (existing)
├── architecture/               # Architecture documentation (existing)
├── deployment/                 # Deployment documentation (existing)
├── features/                   # Feature documentation (existing)
└── guides/                     # User guides (existing)
```

## Quick Navigation

### For Developers
- **New to the project?** Start with [Database Schema Overview](database/schema/overview.md)
- **Need database queries?** Check [Common Queries](database/examples/queries.md)
- **Working with business logic?** See [Workflow Examples](database/examples/workflows.md)
- **Security questions?** Review [RLS Policies](database/security/rls-policies.md)

### For DevOps/DBAs
- **Schema changes?** Follow the [Migration Guide](database/operations/migrations.md)
- **Database scripts?** Use scripts in `scripts/database/`
- **Performance issues?** Check [Index Documentation](database/schema/indexes.md)
- **Backup procedures?** See backup scripts in `scripts/database/backup/`

### For QA/Testing
- **Database testing?** Review [Workflow Examples](database/examples/workflows.md)
- **Test data setup?** Use scripts in `scripts/database/testing/`

## Database Overview

The Grex application uses a PostgreSQL database hosted on Supabase with:

- **7 Core Tables**: Complete expense splitting data model
- **33 RLS Policies**: Comprehensive row-level security
- **6+ Functions**: Business logic and calculations
- **Multiple Triggers**: Automatic data management
- **Real-time Updates**: WebSocket-based synchronization
- **Multi-currency Support**: ISO 4217 currency validation

## Scripts and Tools

### Database Scripts Location
All database-related scripts are organized in `scripts/database/`:

```
scripts/database/
├── migrations/          # Migration management scripts
├── backup/             # Backup and restore scripts
├── maintenance/        # Database maintenance scripts
├── testing/           # Testing and validation scripts
└── utilities/         # Administrative utilities
```

### Common Operations

```powershell
# Apply database migrations
.\scripts\database\migrations\manage-migrations.ps1 -Action apply -Environment development

# Create database backup
.\scripts\database\backup\backup-database.ps1 -Environment production -Verify

# Run database tests
.\scripts\database\testing\run-db-tests.ps1
```

## Key Features

### Security
- **Row Level Security**: Database-level access control
- **Role-based Permissions**: Administrator, Editor, Viewer roles
- **Audit Logging**: Complete modification history
- **Data Isolation**: Groups cannot access each other's data

### Performance
- **Strategic Indexing**: Optimized for common query patterns
- **Efficient Functions**: Business logic executed in database
- **Query Optimization**: Designed for scalability
- **Real-time Updates**: Instant synchronization across devices

### Data Integrity
- **Foreign Key Constraints**: Maintain referential integrity
- **Check Constraints**: Validate data ranges and formats
- **Triggers**: Automatic timestamp and audit management
- **Soft Delete**: Recoverable deletion with integrity preservation

## Getting Started

### For New Developers

1. **Read the Database Overview**: [Database Schema Overview](database/schema/overview.md)
2. **Understand the Data Model**: [Table Documentation](database/schema/tables.md)
3. **Learn the Security Model**: [RLS Policies](database/security/rls-policies.md)
4. **Practice with Examples**: [Common Queries](database/examples/queries.md)

### For Database Administrators

1. **Set up Migration Tools**: Review [Migration Guide](database/operations/migrations.md)
2. **Configure Backup Scripts**: Set up automated backups
3. **Monitor Performance**: Use database monitoring scripts
4. **Review Security**: Audit RLS policies and permissions

### For Application Developers

1. **Study Business Workflows**: [Workflow Examples](database/examples/workflows.md)
2. **Use Common Queries**: [Query Examples](database/examples/queries.md)
3. **Understand Functions**: [Database Functions](database/functions/overview.md)
4. **Follow Security Guidelines**: Always use parameterized queries

## Contributing

When updating documentation:

1. **Keep it Current**: Ensure documentation matches actual implementation
2. **Include Examples**: Provide practical examples for complex concepts
3. **Test Code Samples**: Verify all code examples work correctly
4. **Update Navigation**: Update this README when adding new sections
5. **Follow Structure**: Maintain the established organization

## Support and Resources

### Internal Resources
- [Database Documentation](database/README.md) - Comprehensive database docs
- [API Documentation](api/) - REST API documentation
- [Architecture Documentation](architecture/) - System architecture
- [Deployment Documentation](deployment/) - Deployment procedures

### External Resources
- [Supabase Documentation](https://supabase.com/docs) - Platform documentation
- [PostgreSQL Documentation](https://www.postgresql.org/docs/) - Database documentation
- [Flutter Documentation](https://flutter.dev/docs) - Mobile app framework

### Getting Help

1. **Check Documentation**: Search relevant documentation sections first
2. **Review Examples**: Look for similar patterns in examples
3. **Check Troubleshooting**: Review troubleshooting sections
4. **Create Issues**: Create detailed issues with logs and context
5. **Ask the Team**: Reach out to team members for complex issues

## Recent Updates

- **2024-01-15**: Reorganized database documentation into structured format
- **2024-01-15**: Added comprehensive query examples and workflows
- **2024-01-15**: Created organized script structure in `scripts/database/`
- **2024-01-15**: Enhanced migration management with new PowerShell scripts

---

This documentation is maintained by the Grex development team. For questions or suggestions, please create an issue or reach out to the team.