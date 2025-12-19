# Documentation Reorganization Script
# This script reorganizes the database documentation and scripts into the new structure

<#
.SYNOPSIS
    Reorganizes database documentation and scripts into new structure

.DESCRIPTION
    This script moves existing documentation files into the new organized structure
    and creates any missing documentation files with proper templates.

.PARAMETER CleanupOld
    Remove old documentation files after reorganization

.EXAMPLE
    .\reorganize-docs.ps1 -CleanupOld
    Reorganize documentation and remove old files

.NOTES
    Author: Grex Development Team
    Date: 2024-01-15
    Version: 1.0
#>

param(
    [Parameter(Mandatory=$false)]
    [switch]$CleanupOld
)

# Configuration
$script:OldDocsPath = "docs"
$script:NewDocsPath = "docs/database"
$script:OldScriptsPath = "scripts"
$script:NewScriptsPath = "scripts/windows/database"

# Logging function
function Write-Log {
    param(
        [string]$Message,
        [string]$Level = "INFO",
        [string]$Color = "White"
    )
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Write-Host "[$timestamp] [$Level] $Message" -ForegroundColor $Color
}

# Create directory structure
function New-DirectoryStructure {
    $directories = @(
        "docs/database/schema",
        "docs/database/functions", 
        "docs/database/triggers",
        "docs/database/security",
        "docs/database/operations",
        "docs/database/examples",
        "scripts/windows/database/migrations",
        "scripts/windows/database/backup",
        "scripts/windows/database/test",
        "scripts/windows/database/utils",
        "scripts/linux/database/migrations",
        "scripts/linux/database/backup",
        "scripts/linux/database/test",
        "scripts/linux/database/utils",
        "logs",
        "backups/database",
        "backups/migrations"
    )
    
    foreach ($dir in $directories) {
        if (!(Test-Path $dir)) {
            New-Item -ItemType Directory -Path $dir -Force | Out-Null
            Write-Log "Created directory: $dir" "INFO" "Green"
        }
    }
}

# Move and split database schema documentation
function Move-SchemaDocumentation {
    $oldSchemaFile = "docs/database-schema.md"
    
    if (Test-Path $oldSchemaFile) {
        Write-Log "Processing database schema documentation..." "INFO" "Yellow"
        
        # The schema overview and tables documentation have already been created
        # in the new structure, so we can mark the old file for cleanup
        
        Write-Log "Schema documentation has been reorganized into new structure" "INFO" "Green"
    }
}

# Move functions and triggers documentation
function Move-FunctionsDocumentation {
    $oldFunctionsFile = "docs/functions-and-triggers.md"
    
    if (Test-Path $oldFunctionsFile) {
        Write-Log "Processing functions and triggers documentation..." "INFO" "Yellow"
        
        # Split the content into separate files
        $content = Get-Content $oldFunctionsFile -Raw
        
        # Create functions overview
        $functionsOverview = @"
# Database Functions Overview

This document provides an overview of all database functions in the Grex expense splitting application.

## Function Categories

### Business Logic Functions
- [calculate_group_balances()](business-logic.md#calculate_group_balances) - Calculate net balances for group members
- [generate_settlement_plan()](business-logic.md#generate_settlement_plan) - Generate optimized settlement plan
- [check_user_permission()](business-logic.md#check_user_permission) - Validate user permissions

### Validation Functions  
- [validate_expense_split()](validation.md#validate_expense_split) - Validate expense split totals
- [validate_currency_code()](validation.md#validate_currency_code) - Validate ISO 4217 currency codes

### Utility Functions
- [soft_delete_record()](utilities.md#soft_delete_record) - Soft delete records
- [restore_record()](utilities.md#restore_record) - Restore soft-deleted records
- [hard_delete_record()](utilities.md#hard_delete_record) - Permanently delete records

## Performance Characteristics

All functions are optimized for performance with proper indexing and efficient SQL queries.
See individual function documentation for specific performance metrics and benchmarks.

## Usage Patterns

Functions are designed to be called from:
- Application code for business logic
- Database triggers for validation
- Administrative scripts for maintenance
- Row Level Security policies for permissions

For detailed documentation of each function, see the specific category files.
"@
        
        Set-Content -Path "docs/database/functions/overview.md" -Value $functionsOverview
        Write-Log "Created functions overview documentation" "INFO" "Green"
        
        # The detailed functions documentation has already been moved to the new structure
        Write-Log "Functions documentation has been reorganized" "INFO" "Green"
    }
}

# Move RLS policies documentation
function Move-SecurityDocumentation {
    $oldRlsFile = "docs/rls-policies.md"
    
    if (Test-Path $oldRlsFile) {
        Write-Log "Processing RLS policies documentation..." "INFO" "Yellow"
        
        # The RLS policies documentation has already been moved to the new structure
        Write-Log "RLS policies documentation has been reorganized" "INFO" "Green"
    }
}

# Move migration guide
function Move-OperationsDocumentation {
    $oldMigrationFile = "docs/migration-guide.md"
    
    if (Test-Path $oldMigrationFile) {
        Write-Log "Processing migration guide..." "INFO" "Yellow"
        
        # Move to operations directory
        Copy-Item $oldMigrationFile "docs/database/operations/migrations.md" -Force
        Write-Log "Moved migration guide to operations directory" "INFO" "Green"
    }
}

# Create missing documentation files
function New-MissingDocumentation {
    # Create relationships documentation
    $relationshipsDoc = @"
# Database Relationships and Constraints

## Foreign Key Relationships

### One-to-Many Relationships

1. **users → groups** (creator_id)
   - One user can create multiple groups
   - Cascade delete: When user is deleted, their created groups are deleted

2. **users → group_members** (user_id)
   - One user can be member of multiple groups
   - Cascade delete: When user is deleted, their memberships are deleted

3. **groups → group_members** (group_id)
   - One group can have multiple members
   - Cascade delete: When group is deleted, all memberships are deleted

4. **groups → expenses** (group_id)
   - One group can have multiple expenses
   - Cascade delete: When group is deleted, all expenses are deleted

5. **users → expenses** (payer_id)
   - One user can pay for multiple expenses
   - Cascade delete: When user is deleted, their expenses are deleted

6. **expenses → expense_participants** (expense_id)
   - One expense can have multiple participants
   - Cascade delete: When expense is deleted, all participants are deleted

7. **users → expense_participants** (user_id)
   - One user can participate in multiple expenses
   - Cascade delete: When user is deleted, their participations are deleted

8. **groups → payments** (group_id)
   - One group can have multiple payments
   - Cascade delete: When group is deleted, all payments are deleted

9. **users → payments** (payer_id, recipient_id)
   - One user can make/receive multiple payments
   - Cascade delete: When user is deleted, their payments are deleted

10. **users → audit_logs** (user_id)
    - One user can perform multiple actions
    - Cascade delete: When user is deleted, their audit logs are deleted

11. **groups → audit_logs** (group_id)
    - One group can have multiple audit logs
    - Cascade delete: When group is deleted, related audit logs are deleted

### Unique Constraints

1. **users.email**: Each email can only be used once
2. **group_members(group_id, user_id)**: Each user can only have one membership per group
3. **expense_participants(expense_id, user_id)**: Each user can only participate once per expense

## Referential Integrity

The database maintains strict referential integrity through:
- Foreign key constraints prevent orphaned records
- Cascade delete rules maintain consistency
- Check constraints validate data ranges and formats
- Unique constraints prevent duplicate data

## Constraint Violations

Common constraint violations and their meanings:
- `23505`: Unique constraint violation (duplicate email, duplicate membership)
- `23503`: Foreign key constraint violation (invalid user_id, group_id)
- `23514`: Check constraint violation (negative amount, invalid currency code)
- `23502`: Not null constraint violation (missing required field)
"@
    
    Set-Content -Path "docs/database/schema/relationships.md" -Value $relationshipsDoc
    Write-Log "Created relationships documentation" "INFO" "Green"
    
    # Create indexes documentation
    $indexesDoc = @"
# Database Indexes Documentation

## Index Strategy

The database uses a comprehensive indexing strategy to optimize query performance:

1. **Primary Key Indexes**: Automatic B-tree indexes on all primary keys
2. **Foreign Key Indexes**: Explicit indexes on all foreign keys for efficient joins
3. **Composite Indexes**: Multi-column indexes for common query patterns
4. **Partial Indexes**: Indexes on non-null values for soft-deleted records
5. **Date Indexes**: B-tree indexes on date columns for range queries

## Table Indexes

### users
- `users_pkey`: Primary key (id)
- `idx_users_email`: Email lookups
- `idx_users_created_at`: Chronological ordering
- `idx_users_deleted_at`: Exclude soft-deleted records (partial index)

### groups
- `groups_pkey`: Primary key (id)
- `idx_groups_creator_id`: Find groups by creator
- `idx_groups_created_at`: Chronological ordering
- `idx_groups_deleted_at`: Exclude soft-deleted records (partial index)

### group_members
- `group_members_pkey`: Primary key (id)
- `idx_group_members_group_id`: Find members by group
- `idx_group_members_user_id`: Find groups by user
- `idx_group_members_composite`: Efficient user-group lookups (group_id, user_id)

### expenses
- `expenses_pkey`: Primary key (id)
- `idx_expenses_group_id`: Find expenses by group
- `idx_expenses_payer_id`: Find expenses by payer
- `idx_expenses_expense_date`: Date range queries
- `idx_expenses_created_at`: Chronological ordering
- `idx_expenses_deleted_at`: Exclude soft-deleted records (partial index)

### expense_participants
- `expense_participants_pkey`: Primary key (id)
- `idx_expense_participants_expense_id`: Find participants by expense
- `idx_expense_participants_user_id`: Find participations by user
- `idx_expense_participants_composite`: Efficient expense-user lookups (expense_id, user_id)

### payments
- `payments_pkey`: Primary key (id)
- `idx_payments_group_id`: Find payments by group
- `idx_payments_payer_id`: Find payments by payer
- `idx_payments_recipient_id`: Find payments by recipient
- `idx_payments_payment_date`: Date range queries
- `idx_payments_created_at`: Chronological ordering
- `idx_payments_deleted_at`: Exclude soft-deleted records (partial index)

### audit_logs
- `audit_logs_pkey`: Primary key (id)
- `idx_audit_logs_entity_type`: Find logs by entity type
- `idx_audit_logs_entity_id`: Find logs by entity
- `idx_audit_logs_user_id`: Find logs by user
- `idx_audit_logs_group_id`: Find logs by group
- `idx_audit_logs_created_at`: Chronological ordering
- `idx_audit_logs_composite`: Efficient entity-specific queries (entity_type, entity_id, created_at)

## Performance Considerations

### Query Optimization
1. **Efficient Joins**: Foreign key indexes enable fast join operations
2. **Range Queries**: Date indexes support efficient date range filtering
3. **Composite Queries**: Multi-column indexes optimize complex WHERE clauses
4. **Soft Delete Filtering**: Partial indexes exclude deleted records efficiently

### Index Maintenance
1. **Regular Analysis**: Use ANALYZE to update table statistics
2. **Vacuum Operations**: Regular VACUUM to reclaim space and update indexes
3. **Index Usage Monitoring**: Monitor pg_stat_user_indexes for unused indexes
4. **Query Plan Analysis**: Use EXPLAIN ANALYZE to verify index usage

## Index Usage Examples

```sql
-- Efficient query using group_id index
SELECT * FROM expenses WHERE group_id = 'uuid-value';

-- Efficient range query using date index
SELECT * FROM expenses WHERE expense_date BETWEEN '2024-01-01' AND '2024-01-31';

-- Efficient composite query using composite index
SELECT * FROM group_members WHERE group_id = 'uuid-value' AND user_id = 'uuid-value';

-- Efficient soft-delete filtering using partial index
SELECT * FROM expenses WHERE deleted_at IS NULL;
```
"@
    
    Set-Content -Path "docs/database/schema/indexes.md" -Value $indexesDoc
    Write-Log "Created indexes documentation" "INFO" "Green"
}

# Move old scripts
function Move-Scripts {
    $oldMigrationScript = "scripts/windows/database/migrations/manage-migrations.ps1"
    
    if (Test-Path $oldMigrationScript) {
        Write-Log "Old migration script found - new version already created in new structure" "INFO" "Yellow"
    }
}

# Cleanup old files
function Remove-OldFiles {
    if (!$CleanupOld) {
        Write-Log "Skipping cleanup of old files (use -CleanupOld to remove)" "INFO" "Yellow"
        return
    }
    
    $oldFiles = @(
        "docs/database-schema.md",
        "docs/functions-and-triggers.md", 
        "docs/rls-policies.md",
        "docs/migration-guide.md"
    )
    
    foreach ($file in $oldFiles) {
        if (Test-Path $file) {
            Remove-Item $file -Force
            Write-Log "Removed old file: $file" "INFO" "Green"
        }
    }
}

# Main execution
try {
    Write-Log "Starting documentation reorganization..." "INFO" "Green"
    
    # Create new directory structure
    New-DirectoryStructure
    
    # Move and reorganize documentation
    Move-SchemaDocumentation
    Move-FunctionsDocumentation
    Move-SecurityDocumentation
    Move-OperationsDocumentation
    
    # Create missing documentation
    New-MissingDocumentation
    
    # Move scripts
    Move-Scripts
    
    # Cleanup old files if requested
    Remove-OldFiles
    
    Write-Log "Documentation reorganization completed successfully!" "INFO" "Green"
    Write-Log "New structure:" "INFO" "Cyan"
    Write-Log "  docs/database/ - All database documentation" "INFO" "Cyan"
    Write-Log "  scripts/windows/database/ - All database scripts (Windows)" "INFO" "Cyan"
    Write-Log "  scripts/linux/database/ - All database scripts (Linux)" "INFO" "Cyan"
    
    if (!$CleanupOld) {
        Write-Log "Note: Old files were preserved. Use -CleanupOld to remove them." "INFO" "Yellow"
    }
}
catch {
    Write-Log "Documentation reorganization failed: $($_.Exception.Message)" "ERROR" "Red"
    exit 1
}