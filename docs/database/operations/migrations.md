# Database Migration Guide

## Overview

This guide provides comprehensive instructions for managing database schema migrations in the Grex expense splitting application. The migration system ensures safe, versioned, and reproducible database schema changes across different environments.

## Migration System Architecture

### Migration Structure

```
supabase/
├── migrations/
│   ├── 00001_create_enum_types.sql
│   ├── 00002_create_users_table.sql
│   ├── 00003_create_groups_table.sql
│   ├── 00004_create_group_members_table.sql
│   ├── 00005_create_expenses_table.sql
│   ├── 00006_create_expense_participants_table.sql
│   ├── 00007_create_payments_table.sql
│   ├── 00008_create_audit_logs_table.sql
│   ├── 00009_create_database_functions.sql
│   ├── 00010_create_database_triggers.sql
│   ├── 00011_enable_row_level_security.sql
│   ├── 00012_create_rls_policies.sql
│   ├── 00013_create_currency_validation.sql
│   ├── 00014_create_soft_delete_functions.sql
│   ├── 00015_create_migration_management.sql
│   └── README.md
├── tests/
└── scripts/
    └── manage-migrations.ps1
```

### Migration Naming Convention

**Format**: `{version}_{description}.sql`

- **Version**: 5-digit zero-padded number (00001, 00002, etc.)
- **Description**: Snake_case description of the migration
- **Extension**: Always `.sql`

**Examples**:
- `00001_create_enum_types.sql`
- `00016_add_expense_categories.sql`
- `00017_update_currency_validation.sql`

---

## Migration Management System

### Migration Tracking Table

The system uses a `schema_migrations` table to track applied migrations:

```sql
CREATE TABLE IF NOT EXISTS schema_migrations (
    version TEXT PRIMARY KEY,
    applied_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    checksum TEXT NOT NULL,
    execution_time_ms INTEGER,
    success BOOLEAN NOT NULL DEFAULT TRUE
);
```

### Migration Functions

#### apply_migration(migration_file TEXT)

**Purpose**: Applies a single migration file with error handling and rollback.

**Parameters**:
- `migration_file` (TEXT): Path to the migration file

**Returns**: BOOLEAN (success/failure)

**Features**:
- Automatic transaction management
- Checksum validation
- Execution time tracking
- Rollback on failure

#### get_pending_migrations()

**Purpose**: Returns list of migrations that haven't been applied yet.

**Returns**: TABLE with migration files and their status

#### verify_schema_integrity()

**Purpose**: Validates that the current schema matches expected state.

**Returns**: BOOLEAN with detailed validation results

---

## Migration Workflow

### 1. Development Environment Setup

#### Prerequisites

1. **Supabase CLI**: Install the latest version
   ```bash
   npm install -g supabase
   ```

2. **Project Initialization**: Initialize Supabase in your project
   ```bash
   supabase init
   ```

3. **Local Development**: Start local Supabase instance
   ```bash
   supabase start
   ```

#### Local Migration Application

```bash
# Apply all pending migrations
supabase db reset

# Apply specific migration
supabase db push --include-all

# Check migration status
supabase migration list
```

### 2. Creating New Migrations

#### Step 1: Generate Migration File

```bash
# Create new migration file
supabase migration new add_expense_categories

# This creates: supabase/migrations/00016_add_expense_categories.sql
```

#### Step 2: Write Migration Content

```sql
-- Migration: 00016_add_expense_categories.sql
-- Description: Add expense categories functionality
-- Author: Developer Name
-- Date: 2024-01-15

BEGIN;

-- Create expense_categories enum
CREATE TYPE expense_category AS ENUM (
    'food',
    'transportation', 
    'accommodation',
    'entertainment',
    'utilities',
    'other'
);

-- Add category column to expenses table
ALTER TABLE expenses 
ADD COLUMN category expense_category DEFAULT 'other';

-- Create index for category filtering
CREATE INDEX idx_expenses_category ON expenses(category);

-- Update existing expenses to have default category
UPDATE expenses SET category = 'other' WHERE category IS NULL;

-- Add constraint to ensure category is not null
ALTER TABLE expenses 
ALTER COLUMN category SET NOT NULL;

COMMIT;
```

#### Step 3: Test Migration Locally

```bash
# Apply migration locally
supabase db reset

# Verify schema changes
supabase db diff

# Run tests
npm run test:db
```

#### Step 4: Create Rollback Script (Optional)

```sql
-- Rollback: 00016_add_expense_categories_rollback.sql
-- Description: Rollback expense categories functionality

BEGIN;

-- Remove category column
ALTER TABLE expenses DROP COLUMN IF EXISTS category;

-- Drop index
DROP INDEX IF EXISTS idx_expenses_category;

-- Drop enum type
DROP TYPE IF EXISTS expense_category;

COMMIT;
```

### 3. Migration Validation

#### Pre-Migration Checks

```sql
-- Check for pending migrations
SELECT * FROM get_pending_migrations();

-- Verify current schema state
SELECT verify_schema_integrity();

-- Check for data conflicts
SELECT COUNT(*) FROM expenses WHERE category IS NULL;
```

#### Post-Migration Validation

```sql
-- Verify migration was applied
SELECT * FROM schema_migrations WHERE version = '00016';

-- Test new functionality
SELECT category, COUNT(*) FROM expenses GROUP BY category;

-- Run integrity checks
SELECT verify_schema_integrity();
```

---

## Environment-Specific Procedures

### Local Development

#### Initial Setup

```bash
# Clone repository
git clone <repository-url>
cd grex-app

# Install dependencies
npm install

# Start Supabase locally
supabase start

# Apply all migrations
supabase db reset

# Seed test data (optional)
npm run db:seed
```

#### Daily Development

```bash
# Pull latest changes
git pull origin main

# Apply new migrations
supabase db reset

# Start development
npm run dev
```

### Staging Environment

#### Migration Deployment

```bash
# Connect to staging project
supabase link --project-ref <staging-project-id>

# Apply migrations
supabase db push

# Verify deployment
supabase db diff --linked
```

#### Validation Steps

1. **Schema Verification**: Ensure all tables, indexes, and constraints exist
2. **Data Integrity**: Verify existing data wasn't corrupted
3. **Performance Testing**: Check query performance with new schema
4. **Integration Testing**: Run full test suite against staging

### Production Environment

#### Pre-Deployment Checklist

- [ ] All migrations tested in staging
- [ ] Database backup created
- [ ] Rollback plan prepared
- [ ] Maintenance window scheduled
- [ ] Team notified of deployment

#### Deployment Process

```bash
# 1. Create backup
supabase db dump --linked > backup_$(date +%Y%m%d_%H%M%S).sql

# 2. Connect to production
supabase link --project-ref <production-project-id>

# 3. Apply migrations
supabase db push

# 4. Verify deployment
supabase db diff --linked

# 5. Run post-deployment tests
npm run test:production
```

#### Post-Deployment Validation

1. **Schema Integrity**: Verify all changes applied correctly
2. **Application Testing**: Test critical user flows
3. **Performance Monitoring**: Monitor query performance
4. **Error Monitoring**: Watch for application errors

---

## Rollback Procedures

### Automatic Rollback

The migration system includes automatic rollback for failed migrations:

```sql
-- Example migration with automatic rollback
BEGIN;

-- Migration steps here
CREATE TABLE new_table (...);

-- If any step fails, entire transaction is rolled back
-- No manual intervention needed

COMMIT;
```

### Manual Rollback

#### Step 1: Identify Problem Migration

```sql
-- Find the problematic migration
SELECT * FROM schema_migrations 
WHERE success = FALSE 
ORDER BY applied_at DESC 
LIMIT 1;
```

#### Step 2: Prepare Rollback Script

```sql
-- Create rollback migration
-- File: 00017_rollback_expense_categories.sql

BEGIN;

-- Reverse the changes from 00016
ALTER TABLE expenses DROP COLUMN IF EXISTS category;
DROP INDEX IF EXISTS idx_expenses_category;
DROP TYPE IF EXISTS expense_category;

-- Mark original migration as rolled back
UPDATE schema_migrations 
SET success = FALSE 
WHERE version = '00016';

COMMIT;
```

#### Step 3: Apply Rollback

```bash
# Apply rollback migration
supabase db push --include-all

# Verify rollback
supabase db diff --linked
```

### Emergency Rollback

For critical production issues:

#### Database Restore

```bash
# 1. Stop application traffic (if possible)

# 2. Restore from backup
psql -h <host> -U <user> -d <database> < backup_file.sql

# 3. Verify restore
supabase db diff --linked

# 4. Resume application traffic
```

#### Point-in-Time Recovery

```bash
# Restore to specific timestamp (Supabase Pro feature)
# Contact Supabase support for assistance with PITR
```

---

## Best Practices

### Migration Design

1. **Atomic Operations**: Each migration should be a single atomic unit
2. **Backward Compatibility**: Avoid breaking changes when possible
3. **Data Preservation**: Never delete data without explicit approval
4. **Performance Consideration**: Consider impact on large tables
5. **Rollback Planning**: Always have a rollback strategy

### Code Quality

```sql
-- Good migration example
BEGIN;

-- Clear comments explaining the change
-- Add expense categories to improve expense organization

-- Create enum type first
CREATE TYPE expense_category AS ENUM (
    'food',
    'transportation',
    'accommodation',
    'entertainment',
    'utilities',
    'other'
);

-- Add column with default value (safe for existing data)
ALTER TABLE expenses 
ADD COLUMN category expense_category DEFAULT 'other';

-- Create index for performance
CREATE INDEX CONCURRENTLY idx_expenses_category ON expenses(category);

-- Update constraint after data is populated
ALTER TABLE expenses 
ALTER COLUMN category SET NOT NULL;

COMMIT;
```

### Testing Strategy

1. **Unit Tests**: Test individual migration components
2. **Integration Tests**: Test migration with existing data
3. **Performance Tests**: Measure migration execution time
4. **Rollback Tests**: Verify rollback procedures work

### Documentation

1. **Migration Comments**: Document purpose and impact
2. **Change Log**: Maintain detailed change history
3. **Schema Documentation**: Update schema docs after changes
4. **Rollback Instructions**: Document rollback procedures

---

## Troubleshooting

### Common Issues

#### Migration Fails to Apply

**Symptoms**: Migration execution fails with error

**Diagnosis**:
```sql
-- Check migration status
SELECT * FROM schema_migrations WHERE success = FALSE;

-- Check PostgreSQL logs
SELECT * FROM pg_stat_activity WHERE state = 'active';
```

**Solutions**:
1. Fix syntax errors in migration file
2. Resolve data conflicts before migration
3. Check for missing dependencies
4. Verify permissions

#### Schema Drift

**Symptoms**: Local schema differs from production

**Diagnosis**:
```bash
# Compare schemas
supabase db diff --linked

# Check migration history
supabase migration list
```

**Solutions**:
1. Apply missing migrations
2. Reset local database
3. Regenerate migration from schema diff

#### Performance Issues

**Symptoms**: Migration takes too long or locks tables

**Diagnosis**:
```sql
-- Check long-running queries
SELECT pid, now() - pg_stat_activity.query_start AS duration, query 
FROM pg_stat_activity 
WHERE (now() - pg_stat_activity.query_start) > interval '5 minutes';
```

**Solutions**:
1. Use `CREATE INDEX CONCURRENTLY` for large tables
2. Break large migrations into smaller chunks
3. Schedule migrations during low-traffic periods
4. Use connection pooling

#### Data Corruption

**Symptoms**: Data is missing or incorrect after migration

**Diagnosis**:
```sql
-- Check data integrity
SELECT COUNT(*) FROM table_name;
SELECT * FROM table_name WHERE suspicious_condition;
```

**Solutions**:
1. Restore from backup
2. Apply data fix migration
3. Implement additional validation

---

## Migration Scripts

### PowerShell Management Script

The migration management scripts provide automated migration management:

**Windows:** `scripts/windows/database/migrations/manage-migrations.ps1`  
**Linux/macOS:** `scripts/linux/database/migrations/manage-migrations.sh`

**Windows:**
```powershell
# Apply all pending migrations
.\scripts\windows\database\migrations\manage-migrations.ps1 -Action apply

# Check migration status
.\scripts\windows\database\migrations\manage-migrations.ps1 -Action status

# Validate schema integrity
.\scripts\windows\database\migrations\manage-migrations.ps1 -Action validate

# Create new migration
.\scripts\windows\database\migrations\manage-migrations.ps1 -Action create -MigrationName "add_expense_tags"
```

**Linux/macOS:**
```bash
# Apply all pending migrations
./scripts/linux/database/migrations/manage-migrations.sh apply

# Check migration status
./scripts/linux/database/migrations/manage-migrations.sh status

# Validate schema integrity
./scripts/linux/database/migrations/manage-migrations.sh validate

# Create new migration
./scripts/linux/database/migrations/manage-migrations.sh create --migration-name "add_expense_tags"
```

### Bash Scripts (Alternative)

```bash
#!/bin/bash
# apply-migrations.sh

set -e

echo "Applying database migrations..."

# Check Supabase connection
supabase status

# Apply migrations
supabase db push

# Verify schema
supabase db diff --linked

echo "Migrations applied successfully!"
```

---

## Schema Versioning Strategy

### Version Numbers

- **Major Version** (X.0.0): Breaking changes, major features
- **Minor Version** (X.Y.0): New features, backward compatible
- **Patch Version** (X.Y.Z): Bug fixes, small improvements

### Migration Numbering

- **00001-00099**: Initial schema setup
- **00100-00199**: Core functionality additions
- **00200-00299**: Performance optimizations
- **00300-00399**: Security enhancements
- **00400+**: Feature additions and improvements

### Branching Strategy

```
main branch:     00001 -> 00002 -> 00003 -> 00004
feature branch:                    00003 -> 00005 (new feature)
                                          \
merge:           00001 -> 00002 -> 00003 -> 00004 -> 00005
```

---

## Monitoring and Maintenance

### Migration Monitoring

```sql
-- Monitor migration performance
SELECT 
    version,
    applied_at,
    execution_time_ms,
    success
FROM schema_migrations
ORDER BY applied_at DESC
LIMIT 10;

-- Check for failed migrations
SELECT * FROM schema_migrations WHERE success = FALSE;
```

### Regular Maintenance

1. **Weekly**: Review migration performance metrics
2. **Monthly**: Clean up old rollback scripts
3. **Quarterly**: Review and optimize migration procedures
4. **Annually**: Archive old migration history

### Backup Strategy

1. **Pre-Migration**: Always backup before major changes
2. **Daily**: Automated daily backups
3. **Weekly**: Full database dumps
4. **Monthly**: Long-term archive backups

This comprehensive migration guide ensures safe, reliable, and maintainable database schema evolution for the Grex expense splitting application.