# Database Migrations

This directory contains all database migration files for the Grex expense splitting application.

## Migration Naming Convention

Migrations are numbered sequentially using the format: `NNNNN_description.sql`
- NNNNN: 5-digit zero-padded number (00001, 00002, etc.)
- description: Brief description of the migration purpose using snake_case

## Migration Order and Dependencies

Migrations must be applied in numerical order. Each migration depends on all previous migrations.

### Migration List

| File | Version | Description | Requirements |
|------|---------|-------------|--------------|
| `00001_create_enum_types.sql` | 00001 | Create custom enum types (member_role, split_method, action_type) | 13.1, 13.2, 13.3 |
| `00002_create_users_table.sql` | 00002 | Create users table with constraints and indexes | 1.1, 1.2 |
| `00003_create_groups_table.sql` | 00003 | Create groups table with foreign keys to users | 2.1, 2.2 |
| `00004_create_group_members_table.sql` | 00004 | Create group membership table with role management | 3.1, 3.2 |
| `00005_create_expenses_table.sql` | 00005 | Create expenses table for tracking shared costs | 4.1, 4.2 |
| `00006_create_expense_participants_table.sql` | 00006 | Create expense participants for split calculations | 5.1, 5.2 |
| `00007_create_payments_table.sql` | 00007 | Create payments table for settlement tracking | 6.1, 6.2 |
| `00008_create_audit_logs_table.sql` | 00008 | Create audit logs for change tracking | 7.1, 7.2, 7.4 |
| `00009_create_database_functions.sql` | 00009 | Create utility functions (balance calculation, validation, etc.) | 10.1, 10.2, 10.3, 10.4 |
| `00010_create_database_triggers.sql` | 00010 | Create triggers for timestamps and audit logging | 9.1, 9.2, 9.3, 9.4, 9.5 |
| `00011_enable_row_level_security.sql` | 00011 | Enable RLS and create security policies | 8.1, 8.2, 8.3, 8.4, 8.5 |
| `00012_enable_realtime_publications.sql` | 00012 | Enable real-time subscriptions for all tables | 11.1, 11.2, 11.3 |
| `00013_create_currency_validation.sql` | 00013 | Create currency validation functions | 14.1, 14.2 |
| `00014_create_soft_delete_functions.sql` | 00014 | Create soft delete helper functions | 15.1, 15.3, 15.4 |

## Migration Categories

### Core Schema (00001-00008)
- Enum types and base tables
- Primary data structures for the application
- Foreign key relationships and constraints

### Business Logic (00009-00010)
- Database functions for calculations and validation
- Triggers for automatic data management

### Security & Access Control (00011)
- Row Level Security policies
- Role-based access control

### Real-time & Advanced Features (00012-00014)
- Real-time subscriptions
- Currency validation
- Soft delete functionality

## Rollback Strategy

Each migration should be designed to be reversible. If a migration fails:
1. The transaction will be rolled back automatically
2. Check the error message for specific issues
3. Fix the migration file and retry
4. Never modify applied migrations - create a new migration instead

## Best Practices

1. **Idempotency**: Use `IF EXISTS` and `IF NOT EXISTS` clauses where appropriate
2. **Transactions**: Each migration runs in a transaction and will rollback on error
3. **Documentation**: Include comments explaining the purpose and requirements
4. **Testing**: Test migrations on a copy of production data before applying
5. **Backup**: Always backup the database before applying migrations in production

## Verification

After applying migrations, verify the schema using:
```sql
-- Check all tables exist
SELECT table_name FROM information_schema.tables 
WHERE table_schema = 'public' 
ORDER BY table_name;

-- Check all functions exist
SELECT routine_name FROM information_schema.routines 
WHERE routine_schema = 'public' 
ORDER BY routine_name;

-- Check RLS is enabled
SELECT schemaname, tablename, rowsecurity 
FROM pg_tables 
WHERE schemaname = 'public';
```

## Migration Execution

Migrations are automatically applied by Supabase CLI in numerical order:
```bash
supabase db reset  # Apply all migrations from scratch
supabase db push   # Apply new migrations to remote database
```