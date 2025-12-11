# Business Workflow Examples

This document provides examples of complete business workflows implemented through database operations in the Grex expense splitting application.

## User Registration and Onboarding

### 1. New User Registration
```sql
-- Step 1: Create user profile
INSERT INTO users (email, display_name, preferred_currency, preferred_language)
VALUES ('alice@example.com', 'Alice Smith', 'USD', 'en')
RETURNING id;

-- Step 2: Verify user was created successfully
SELECT id, email, display_name, created_at 
FROM users 
WHERE email = 'alice@example.com';
```

### 2. User Profile Update
```sql
-- Update user preferences
UPDATE users 
SET display_name = 'Alice Johnson',
    preferred_currency = 'EUR',
    avatar_url = 'https://example.com/avatars/alice.jpg'
WHERE id = 'user-uuid'
  AND deleted_at IS NULL;

-- Verify update (updated_at should be newer)
SELECT display_name, preferred_currency, avatar_url, updated_at
FROM users 
WHERE id = 'user-uuid';
```

## Group Management Workflows

### 1. Create New Group
```sql
BEGIN;

-- Step 1: Create the group
INSERT INTO groups (name, description, creator_id, primary_currency)
VALUES ('Trip to Paris', 'Expenses for our Paris vacation', 'creator-uuid', 'EUR')
RETURNING id;

-- Step 2: Add creator as administrator
INSERT INTO group_members (group_id, user_id, role)
VALUES ('group-uuid', 'creator-uuid', 'administrator');

-- Step 3: Verify group creation
SELECT g.name, g.description, gm.role
FROM groups g
JOIN group_members gm ON g.id = gm.group_id
WHERE g.id = 'group-uuid' AND gm.user_id = 'creator-uuid';

COMMIT;
```

### 2. Invite Users to Group
```sql
BEGIN;

-- Step 1: Check if user has permission to add members
SELECT check_user_permission('admin-uuid', 'group-uuid', 'administrator');

-- Step 2: Add new member (if permission check passed)
INSERT INTO group_members (group_id, user_id, role)
VALUES ('group-uuid', 'new-member-uuid', 'editor');

-- Step 3: Verify member was added
SELECT u.display_name, gm.role, gm.joined_at
FROM group_members gm
JOIN users u ON gm.user_id = u.id
WHERE gm.group_id = 'group-uuid'
ORDER BY gm.joined_at;

COMMIT;
```

### 3. Change Member Role
```sql
BEGIN;

-- Step 1: Verify current user has admin permissions
SELECT check_user_permission('admin-uuid', 'group-uuid', 'administrator');

-- Step 2: Update member role
UPDATE group_members 
SET role = 'administrator'
WHERE group_id = 'group-uuid' 
  AND user_id = 'member-uuid';

-- Step 3: Verify role change
SELECT u.display_name, gm.role, gm.updated_at
FROM group_members gm
JOIN users u ON gm.user_id = u.id
WHERE gm.group_id = 'group-uuid' AND gm.user_id = 'member-uuid';

COMMIT;
```

## Expense Management Workflows

### 1. Create Expense with Equal Split
```sql
BEGIN;

-- Step 1: Create the expense
INSERT INTO expenses (group_id, payer_id, amount, currency, description, expense_date, split_method)
VALUES ('group-uuid', 'payer-uuid', 120.00, 'EUR', 'Dinner at Le Bistro', '2024-01-15', 'equal')
RETURNING id;

-- Step 2: Add participants (equal split among 3 people = 40.00 each)
INSERT INTO expense_participants (expense_id, user_id, share_amount)
VALUES 
    ('expense-uuid', 'user1-uuid', 40.00),
    ('expense-uuid', 'user2-uuid', 40.00),
    ('expense-uuid', 'user3-uuid', 40.00);

-- Step 3: Validate the split
SELECT validate_expense_split('expense-uuid');

-- Step 4: Verify expense creation
SELECT 
    e.description,
    e.amount,
    e.currency,
    payer.display_name as payer,
    COUNT(ep.user_id) as participant_count,
    SUM(ep.share_amount) as total_shares
FROM expenses e
JOIN users payer ON e.payer_id = payer.id
JOIN expense_participants ep ON e.id = ep.expense_id
WHERE e.id = 'expense-uuid'
GROUP BY e.id, e.description, e.amount, e.currency, payer.display_name;

COMMIT;
```

### 2. Create Expense with Custom Split
```sql
BEGIN;

-- Step 1: Create the expense
INSERT INTO expenses (group_id, payer_id, amount, currency, description, split_method)
VALUES ('group-uuid', 'payer-uuid', 100.00, 'USD', 'Groceries', 'exact')
RETURNING id;

-- Step 2: Add participants with custom amounts
INSERT INTO expense_participants (expense_id, user_id, share_amount)
VALUES 
    ('expense-uuid', 'user1-uuid', 45.00),  -- User1 owes $45
    ('expense-uuid', 'user2-uuid', 30.00),  -- User2 owes $30
    ('expense-uuid', 'user3-uuid', 25.00);  -- User3 owes $25

-- Step 3: Validate the split (should sum to $100)
SELECT validate_expense_split('expense-uuid');

COMMIT;
```

### 3. Update Expense
```sql
BEGIN;

-- Step 1: Check if user can update this expense
SELECT 
    e.payer_id = 'current-user-uuid' as is_payer,
    check_user_permission('current-user-uuid', e.group_id, 'administrator') as is_admin
FROM expenses e
WHERE e.id = 'expense-uuid';

-- Step 2: Update expense details (if authorized)
UPDATE expenses 
SET amount = 130.00,
    description = 'Dinner at Le Bistro (with wine)'
WHERE id = 'expense-uuid';

-- Step 3: Update participant shares proportionally
UPDATE expense_participants 
SET share_amount = share_amount * (130.00 / 120.00)  -- Scale by new amount
WHERE expense_id = 'expense-uuid';

-- Step 4: Validate updated split
SELECT validate_expense_split('expense-uuid');

COMMIT;
```

### 4. Delete Expense
```sql
BEGIN;

-- Step 1: Check if user has permission to delete
SELECT check_user_permission('current-user-uuid', 'group-uuid', 'administrator');

-- Step 2: Soft delete the expense (participants will be cascade deleted)
UPDATE expenses 
SET deleted_at = NOW()
WHERE id = 'expense-uuid';

-- Step 3: Verify deletion
SELECT id, description, deleted_at
FROM expenses 
WHERE id = 'expense-uuid';

COMMIT;
```

## Payment Recording Workflows

### 1. Record Simple Payment
```sql
BEGIN;

-- Step 1: Record the payment
INSERT INTO payments (group_id, payer_id, recipient_id, amount, currency, payment_date, notes)
VALUES ('group-uuid', 'payer-uuid', 'recipient-uuid', 50.00, 'USD', CURRENT_DATE, 'Settling dinner expense');

-- Step 2: Verify payment was recorded
SELECT 
    p.amount,
    p.currency,
    payer.display_name as payer,
    recipient.display_name as recipient,
    p.payment_date,
    p.notes
FROM payments p
JOIN users payer ON p.payer_id = payer.id
JOIN users recipient ON p.recipient_id = recipient.id
WHERE p.id = 'payment-uuid';

COMMIT;
```

### 2. Settle All Debts Using Settlement Plan
```sql
BEGIN;

-- Step 1: Get current balances
SELECT * FROM calculate_group_balances('group-uuid');

-- Step 2: Generate settlement plan
SELECT * FROM generate_settlement_plan('group-uuid');

-- Step 3: Record settlement payments (based on plan)
INSERT INTO payments (group_id, payer_id, recipient_id, amount, currency, notes)
VALUES 
    ('group-uuid', 'debtor1-uuid', 'creditor1-uuid', 25.50, 'USD', 'Settlement payment'),
    ('group-uuid', 'debtor2-uuid', 'creditor1-uuid', 15.75, 'USD', 'Settlement payment');

-- Step 4: Verify balances are now settled
SELECT * FROM calculate_group_balances('group-uuid');

COMMIT;
```

## Balance Calculation Workflows

### 1. Get Current Group Balances
```sql
-- Get all member balances
SELECT 
    user_name,
    balance,
    CASE 
        WHEN balance > 0 THEN 'Owed money'
        WHEN balance < 0 THEN 'Owes money'
        ELSE 'Settled'
    END as status
FROM calculate_group_balances('group-uuid')
ORDER BY balance DESC;
```

### 2. Check if Group is Settled
```sql
-- Check if all balances are zero (group is settled)
SELECT 
    COUNT(*) as total_members,
    COUNT(*) FILTER (WHERE ABS(balance) < 0.01) as settled_members,
    COUNT(*) FILTER (WHERE ABS(balance) < 0.01) = COUNT(*) as is_fully_settled
FROM calculate_group_balances('group-uuid');
```

### 3. Get Settlement Recommendations
```sql
-- Get recommended payments to settle all debts
SELECT 
    payer_name || ' should pay ' || recipient_name || ': ' || 
    amount || ' ' || 'USD' as recommendation
FROM generate_settlement_plan('group-uuid')
ORDER BY amount DESC;
```

## Audit and Reporting Workflows

### 1. Generate Expense Report
```sql
-- Monthly expense report for a group
SELECT 
    DATE_TRUNC('month', e.expense_date) as month,
    COUNT(*) as expense_count,
    SUM(e.amount) as total_amount,
    AVG(e.amount) as average_amount,
    STRING_AGG(DISTINCT u.display_name, ', ') as contributors
FROM expenses e
JOIN users u ON e.payer_id = u.id
WHERE e.group_id = 'group-uuid'
  AND e.deleted_at IS NULL
  AND e.expense_date >= DATE_TRUNC('year', CURRENT_DATE)
GROUP BY DATE_TRUNC('month', e.expense_date)
ORDER BY month DESC;
```

### 2. User Activity Summary
```sql
-- Get user's activity summary in a group
SELECT 
    'Expenses Paid' as activity_type,
    COUNT(*) as count,
    SUM(amount) as total_amount
FROM expenses 
WHERE group_id = 'group-uuid' 
  AND payer_id = 'user-uuid' 
  AND deleted_at IS NULL

UNION ALL

SELECT 
    'Payments Made' as activity_type,
    COUNT(*) as count,
    SUM(amount) as total_amount
FROM payments 
WHERE group_id = 'group-uuid' 
  AND payer_id = 'user-uuid' 
  AND deleted_at IS NULL

UNION ALL

SELECT 
    'Payments Received' as activity_type,
    COUNT(*) as count,
    SUM(amount) as total_amount
FROM payments 
WHERE group_id = 'group-uuid' 
  AND recipient_id = 'user-uuid' 
  AND deleted_at IS NULL;
```

### 3. Audit Trail Review
```sql
-- Get recent audit trail for a group (admin only)
SELECT 
    al.created_at,
    al.action,
    al.entity_type,
    u.display_name as performed_by,
    CASE 
        WHEN al.entity_type = 'expense' THEN 
            COALESCE(al.after_state->>'description', al.before_state->>'description')
        WHEN al.entity_type = 'payment' THEN 
            'Amount: ' || COALESCE(al.after_state->>'amount', al.before_state->>'amount')
        ELSE 'N/A'
    END as details
FROM audit_logs al
JOIN users u ON al.user_id = u.id
WHERE al.group_id = 'group-uuid'
  AND al.created_at >= CURRENT_DATE - INTERVAL '30 days'
ORDER BY al.created_at DESC
LIMIT 50;
```

## Data Cleanup Workflows

### 1. Soft Delete Cleanup
```sql
-- Find old soft-deleted records (older than 90 days)
SELECT 
    'expenses' as table_name,
    COUNT(*) as soft_deleted_count
FROM expenses 
WHERE deleted_at IS NOT NULL 
  AND deleted_at < CURRENT_DATE - INTERVAL '90 days'

UNION ALL

SELECT 
    'payments' as table_name,
    COUNT(*) as soft_deleted_count
FROM payments 
WHERE deleted_at IS NOT NULL 
  AND deleted_at < CURRENT_DATE - INTERVAL '90 days';
```

### 2. Archive Old Groups
```sql
-- Find inactive groups (no activity in 6 months)
SELECT 
    g.id,
    g.name,
    g.created_at,
    MAX(GREATEST(
        COALESCE(MAX(e.created_at), '1900-01-01'::timestamptz),
        COALESCE(MAX(p.created_at), '1900-01-01'::timestamptz)
    )) as last_activity
FROM groups g
LEFT JOIN expenses e ON g.id = e.group_id AND e.deleted_at IS NULL
LEFT JOIN payments p ON g.id = p.group_id AND p.deleted_at IS NULL
WHERE g.deleted_at IS NULL
GROUP BY g.id, g.name, g.created_at
HAVING MAX(GREATEST(
    COALESCE(MAX(e.created_at), '1900-01-01'::timestamptz),
    COALESCE(MAX(p.created_at), '1900-01-01'::timestamptz)
)) < CURRENT_DATE - INTERVAL '6 months'
ORDER BY last_activity;
```

## Error Handling Examples

### 1. Handle Constraint Violations
```sql
-- Example of handling unique constraint violation
DO $
BEGIN
    INSERT INTO group_members (group_id, user_id, role)
    VALUES ('group-uuid', 'user-uuid', 'editor');
EXCEPTION 
    WHEN unique_violation THEN
        -- User is already a member, update their role instead
        UPDATE group_members 
        SET role = 'editor', updated_at = NOW()
        WHERE group_id = 'group-uuid' AND user_id = 'user-uuid';
        
        RAISE NOTICE 'User was already a member, role updated';
END;
$;
```

### 2. Validate Business Rules
```sql
-- Example of validating business rules before operations
DO $
DECLARE
    member_count INTEGER;
    user_role member_role;
BEGIN
    -- Check if group has enough members before removing one
    SELECT COUNT(*) INTO member_count
    FROM group_members 
    WHERE group_id = 'group-uuid';
    
    -- Check user's current role
    SELECT role INTO user_role
    FROM group_members 
    WHERE group_id = 'group-uuid' AND user_id = 'user-to-remove-uuid';
    
    -- Don't allow removing the last administrator
    IF user_role = 'administrator' THEN
        SELECT COUNT(*) INTO member_count
        FROM group_members 
        WHERE group_id = 'group-uuid' AND role = 'administrator';
        
        IF member_count <= 1 THEN
            RAISE EXCEPTION 'Cannot remove the last administrator from the group';
        END IF;
    END IF;
    
    -- Proceed with removal
    DELETE FROM group_members 
    WHERE group_id = 'group-uuid' AND user_id = 'user-to-remove-uuid';
    
    RAISE NOTICE 'User removed successfully';
END;
$;
```

These workflows demonstrate how the database schema supports complex business operations while maintaining data integrity and security through constraints, triggers, and RLS policies.