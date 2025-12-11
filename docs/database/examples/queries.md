# Common Database Queries

This document provides examples of common database queries used in the Grex expense splitting application.

## User Management Queries

### Get User Profile
```sql
-- Get user profile with preferences
SELECT 
    id,
    email,
    display_name,
    avatar_url,
    preferred_currency,
    preferred_language,
    created_at
FROM users 
WHERE id = $1 AND deleted_at IS NULL;
```

### Get User's Groups
```sql
-- Get all groups where user is a member
SELECT 
    g.id,
    g.name,
    g.description,
    g.primary_currency,
    gm.role,
    gm.joined_at
FROM groups g
JOIN group_members gm ON g.id = gm.group_id
WHERE gm.user_id = $1 
  AND g.deleted_at IS NULL
ORDER BY gm.joined_at DESC;
```

## Group Management Queries

### Get Group Members
```sql
-- Get all members of a group with their roles
SELECT 
    u.id,
    u.display_name,
    u.email,
    u.avatar_url,
    gm.role,
    gm.joined_at
FROM users u
JOIN group_members gm ON u.id = gm.user_id
WHERE gm.group_id = $1
  AND u.deleted_at IS NULL
ORDER BY gm.role, u.display_name;
```

### Get Group Statistics
```sql
-- Get group statistics (members, expenses, total amount)
SELECT 
    g.name,
    COUNT(DISTINCT gm.user_id) as member_count,
    COUNT(DISTINCT e.id) as expense_count,
    COALESCE(SUM(e.amount), 0) as total_expenses,
    g.primary_currency
FROM groups g
LEFT JOIN group_members gm ON g.id = gm.group_id
LEFT JOIN expenses e ON g.id = e.group_id AND e.deleted_at IS NULL
WHERE g.id = $1 AND g.deleted_at IS NULL
GROUP BY g.id, g.name, g.primary_currency;
```

## Expense Management Queries

### Get Group Expenses
```sql
-- Get all expenses for a group with payer information
SELECT 
    e.id,
    e.amount,
    e.currency,
    e.description,
    e.expense_date,
    e.split_method,
    e.notes,
    u.display_name as payer_name,
    u.avatar_url as payer_avatar,
    e.created_at
FROM expenses e
JOIN users u ON e.payer_id = u.id
WHERE e.group_id = $1 
  AND e.deleted_at IS NULL
ORDER BY e.expense_date DESC, e.created_at DESC;
```

### Get Expense Details with Participants
```sql
-- Get expense details including all participants
SELECT 
    e.id,
    e.amount,
    e.currency,
    e.description,
    e.expense_date,
    e.split_method,
    e.notes,
    payer.display_name as payer_name,
    json_agg(
        json_build_object(
            'user_id', participant.id,
            'user_name', participant.display_name,
            'share_amount', ep.share_amount,
            'share_percentage', ep.share_percentage,
            'share_count', ep.share_count
        ) ORDER BY participant.display_name
    ) as participants
FROM expenses e
JOIN users payer ON e.payer_id = payer.id
JOIN expense_participants ep ON e.id = ep.expense_id
JOIN users participant ON ep.user_id = participant.id
WHERE e.id = $1 AND e.deleted_at IS NULL
GROUP BY e.id, e.amount, e.currency, e.description, e.expense_date, 
         e.split_method, e.notes, payer.display_name;
```

### Get User's Expense Participations
```sql
-- Get all expenses where user is a participant
SELECT 
    e.id,
    e.amount,
    e.currency,
    e.description,
    e.expense_date,
    payer.display_name as payer_name,
    ep.share_amount,
    g.name as group_name
FROM expenses e
JOIN expense_participants ep ON e.id = ep.expense_id
JOIN users payer ON e.payer_id = payer.id
JOIN groups g ON e.group_id = g.id
WHERE ep.user_id = $1 
  AND e.deleted_at IS NULL
ORDER BY e.expense_date DESC;
```

## Payment Management Queries

### Get Group Payments
```sql
-- Get all payments in a group
SELECT 
    p.id,
    p.amount,
    p.currency,
    p.payment_date,
    p.notes,
    payer.display_name as payer_name,
    recipient.display_name as recipient_name,
    p.created_at
FROM payments p
JOIN users payer ON p.payer_id = payer.id
JOIN users recipient ON p.recipient_id = recipient.id
WHERE p.group_id = $1 
  AND p.deleted_at IS NULL
ORDER BY p.payment_date DESC, p.created_at DESC;
```

### Get User's Payment History
```sql
-- Get payments made or received by user
SELECT 
    p.id,
    p.amount,
    p.currency,
    p.payment_date,
    p.notes,
    CASE 
        WHEN p.payer_id = $1 THEN 'sent'
        ELSE 'received'
    END as payment_type,
    CASE 
        WHEN p.payer_id = $1 THEN recipient.display_name
        ELSE payer.display_name
    END as other_party,
    g.name as group_name
FROM payments p
JOIN users payer ON p.payer_id = payer.id
JOIN users recipient ON p.recipient_id = recipient.id
JOIN groups g ON p.group_id = g.id
WHERE (p.payer_id = $1 OR p.recipient_id = $1)
  AND p.deleted_at IS NULL
ORDER BY p.payment_date DESC;
```

## Balance and Settlement Queries

### Get Group Balances
```sql
-- Get current balances for all group members
SELECT * FROM calculate_group_balances($1);
```

### Get Settlement Plan
```sql
-- Get optimized settlement plan for group
SELECT * FROM generate_settlement_plan($1);
```

### Get User Balance in Group
```sql
-- Get specific user's balance in a group
SELECT 
    user_id,
    user_name,
    balance
FROM calculate_group_balances($1)
WHERE user_id = $2;
```

## Audit and Reporting Queries

### Get Recent Activity
```sql
-- Get recent activity in a group (for administrators)
SELECT 
    al.action,
    al.entity_type,
    al.created_at,
    u.display_name as user_name,
    CASE 
        WHEN al.entity_type = 'expense' THEN 
            (al.after_state->>'description')
        WHEN al.entity_type = 'payment' THEN 
            'Payment: ' || (al.after_state->>'amount') || ' ' || (al.after_state->>'currency')
        WHEN al.entity_type = 'group_member' THEN 
            'Role: ' || (al.after_state->>'role')
        ELSE al.entity_type
    END as description
FROM audit_logs al
JOIN users u ON al.user_id = u.id
WHERE al.group_id = $1
ORDER BY al.created_at DESC
LIMIT 50;
```

### Get Expense Summary by Date Range
```sql
-- Get expense summary for a date range
SELECT 
    DATE_TRUNC('month', e.expense_date) as month,
    COUNT(*) as expense_count,
    SUM(e.amount) as total_amount,
    e.currency,
    AVG(e.amount) as average_amount
FROM expenses e
WHERE e.group_id = $1 
  AND e.expense_date BETWEEN $2 AND $3
  AND e.deleted_at IS NULL
GROUP BY DATE_TRUNC('month', e.expense_date), e.currency
ORDER BY month DESC;
```

### Get Top Spenders
```sql
-- Get top spenders in a group
SELECT 
    u.display_name,
    COUNT(e.id) as expense_count,
    SUM(e.amount) as total_paid,
    AVG(e.amount) as average_expense
FROM users u
JOIN expenses e ON u.id = e.payer_id
WHERE e.group_id = $1 
  AND e.deleted_at IS NULL
  AND e.expense_date >= $2  -- Date filter
GROUP BY u.id, u.display_name
ORDER BY total_paid DESC
LIMIT 10;
```

## Search and Filter Queries

### Search Expenses by Description
```sql
-- Search expenses by description (case-insensitive)
SELECT 
    e.id,
    e.amount,
    e.currency,
    e.description,
    e.expense_date,
    u.display_name as payer_name
FROM expenses e
JOIN users u ON e.payer_id = u.id
WHERE e.group_id = $1 
  AND e.deleted_at IS NULL
  AND LOWER(e.description) LIKE LOWER('%' || $2 || '%')
ORDER BY e.expense_date DESC;
```

### Filter Expenses by Date Range and Amount
```sql
-- Filter expenses by multiple criteria
SELECT 
    e.id,
    e.amount,
    e.currency,
    e.description,
    e.expense_date,
    u.display_name as payer_name
FROM expenses e
JOIN users u ON e.payer_id = u.id
WHERE e.group_id = $1 
  AND e.deleted_at IS NULL
  AND e.expense_date BETWEEN $2 AND $3
  AND e.amount BETWEEN $4 AND $5
  AND ($6 IS NULL OR e.payer_id = $6)  -- Optional payer filter
ORDER BY e.expense_date DESC;
```

## Performance Optimization Examples

### Using Indexes Effectively
```sql
-- Efficient query using composite index
EXPLAIN ANALYZE
SELECT * FROM group_members 
WHERE group_id = $1 AND user_id = $2;

-- Efficient date range query using index
EXPLAIN ANALYZE
SELECT * FROM expenses 
WHERE expense_date BETWEEN '2024-01-01' AND '2024-01-31'
  AND deleted_at IS NULL;
```

### Avoiding N+1 Queries
```sql
-- Bad: Multiple queries (N+1 problem)
-- SELECT * FROM expenses WHERE group_id = $1;
-- For each expense: SELECT * FROM expense_participants WHERE expense_id = $expense_id;

-- Good: Single query with JOIN
SELECT 
    e.*,
    json_agg(
        json_build_object(
            'user_id', ep.user_id,
            'share_amount', ep.share_amount
        )
    ) as participants
FROM expenses e
LEFT JOIN expense_participants ep ON e.id = ep.expense_id
WHERE e.group_id = $1 AND e.deleted_at IS NULL
GROUP BY e.id;
```

## Data Validation Queries

### Check Data Integrity
```sql
-- Verify expense splits sum correctly
SELECT 
    e.id,
    e.amount,
    SUM(ep.share_amount) as total_shares,
    ABS(e.amount - SUM(ep.share_amount)) as difference
FROM expenses e
JOIN expense_participants ep ON e.id = ep.expense_id
WHERE e.group_id = $1 AND e.deleted_at IS NULL
GROUP BY e.id, e.amount
HAVING ABS(e.amount - SUM(ep.share_amount)) > 0.01;
```

### Find Orphaned Records
```sql
-- Find expense participants without valid expenses
SELECT ep.* 
FROM expense_participants ep
LEFT JOIN expenses e ON ep.expense_id = e.id
WHERE e.id IS NULL OR e.deleted_at IS NOT NULL;
```

## Query Performance Tips

1. **Use Indexes**: Always check that your queries use appropriate indexes
2. **Limit Results**: Use LIMIT for pagination and large result sets
3. **Avoid SELECT ***: Select only needed columns
4. **Use Prepared Statements**: Parameterized queries for security and performance
5. **Analyze Query Plans**: Use EXPLAIN ANALYZE to understand query execution
6. **Consider Materialized Views**: For complex aggregations used frequently

## Security Considerations

1. **Always Use Parameters**: Never concatenate user input into SQL strings
2. **Respect RLS Policies**: All queries automatically respect Row Level Security
3. **Validate Input**: Validate all parameters before executing queries
4. **Audit Sensitive Operations**: Log all data modifications through triggers