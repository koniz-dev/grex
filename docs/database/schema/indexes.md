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
- users_pkey: Primary key (id)
- idx_users_email: Email lookups
- idx_users_created_at: Chronological ordering
- idx_users_deleted_at: Exclude soft-deleted records (partial index)

### groups
- groups_pkey: Primary key (id)
- idx_groups_creator_id: Find groups by creator
- idx_groups_created_at: Chronological ordering
- idx_groups_deleted_at: Exclude soft-deleted records (partial index)

### group_members
- group_members_pkey: Primary key (id)
- idx_group_members_group_id: Find members by group
- idx_group_members_user_id: Find groups by user
- idx_group_members_composite: Efficient user-group lookups (group_id, user_id)

### expenses
- expenses_pkey: Primary key (id)
- idx_expenses_group_id: Find expenses by group
- idx_expenses_payer_id: Find expenses by payer
- idx_expenses_expense_date: Date range queries
- idx_expenses_created_at: Chronological ordering
- idx_expenses_deleted_at: Exclude soft-deleted records (partial index)

### expense_participants
- expense_participants_pkey: Primary key (id)
- idx_expense_participants_expense_id: Find participants by expense
- idx_expense_participants_user_id: Find participations by user
- idx_expense_participants_composite: Efficient expense-user lookups (expense_id, user_id)

### payments
- payments_pkey: Primary key (id)
- idx_payments_group_id: Find payments by group
- idx_payments_payer_id: Find payments by payer
- idx_payments_recipient_id: Find payments by recipient
- idx_payments_payment_date: Date range queries
- idx_payments_created_at: Chronological ordering
- idx_payments_deleted_at: Exclude soft-deleted records (partial index)

### audit_logs
- udit_logs_pkey: Primary key (id)
- idx_audit_logs_entity_type: Find logs by entity type
- idx_audit_logs_entity_id: Find logs by entity
- idx_audit_logs_user_id: Find logs by user
- idx_audit_logs_group_id: Find logs by group
- idx_audit_logs_created_at: Chronological ordering
- idx_audit_logs_composite: Efficient entity-specific queries (entity_type, entity_id, created_at)

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

`sql
-- Efficient query using group_id index
SELECT * FROM expenses WHERE group_id = 'uuid-value';

-- Efficient range query using date index
SELECT * FROM expenses WHERE expense_date BETWEEN '2024-01-01' AND '2024-01-31';

-- Efficient composite query using composite index
SELECT * FROM group_members WHERE group_id = 'uuid-value' AND user_id = 'uuid-value';

-- Efficient soft-delete filtering using partial index
SELECT * FROM expenses WHERE deleted_at IS NULL;
`
