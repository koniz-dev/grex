# Row Level Security (RLS) Policies

## Overview

Row Level Security (RLS) policies enforce data access control at the database level, ensuring users can only access data they have permission to view and modify. The RLS implementation follows a **group-based access control** model with role-based permissions.

## Security Model

### Group-Based Access Control

1. **Group Membership**: Users must be members of a group to access its data
2. **Role-Based Permissions**: Different roles have different permission levels
3. **Data Isolation**: Complete isolation between different groups
4. **Automatic Enforcement**: Policies apply to all queries automatically

### Role Hierarchy

```
administrator (Full Access)
    ↓
editor (Create/Modify)
    ↓  
viewer (Read Only)
    ↓
non-member (No Access)
```

### Policy Types

1. **SELECT Policies**: Control what data users can view
2. **INSERT Policies**: Control what data users can create
3. **UPDATE Policies**: Control what data users can modify
4. **DELETE Policies**: Control what data users can remove

## Users Table Policies

### users_select_own
**Purpose**: Users can view their own profile information.
**Rule**: `auth.uid() = id`

```sql
CREATE POLICY users_select_own ON users
  FOR SELECT
  USING (auth.uid() = id);
```

### users_update_own
**Purpose**: Users can update their own profile information.
**Rule**: `auth.uid() = id`

```sql
CREATE POLICY users_update_own ON users
  FOR UPDATE
  USING (auth.uid() = id);
```

### users_select_group_members
**Purpose**: Users can view profiles of other members in their groups.
**Rule**: User ID exists in groups where current user is also a member

```sql
CREATE POLICY users_select_group_members ON users
  FOR SELECT
  USING (
    id IN (
      SELECT gm.user_id
      FROM group_members gm
      WHERE gm.group_id IN (
        SELECT group_id
        FROM group_members
        WHERE user_id = auth.uid()
      )
    )
  );
```

## Groups Table Policies

### groups_select_member
**Purpose**: Users can view groups they are members of.
**Rule**: Group ID exists in user's memberships

```sql
CREATE POLICY groups_select_member ON groups
  FOR SELECT
  USING (
    id IN (
      SELECT group_id
      FROM group_members
      WHERE user_id = auth.uid()
    )
  );
```

### groups_insert_own
**Purpose**: Users can create new groups.
**Rule**: `auth.uid() = creator_id`

```sql
CREATE POLICY groups_insert_own ON groups
  FOR INSERT
  WITH CHECK (auth.uid() = creator_id);
```

### groups_update_admin
**Purpose**: Only administrators can update group information.
**Rule**: User has administrator role in the group

```sql
CREATE POLICY groups_update_admin ON groups
  FOR UPDATE
  USING (
    check_user_permission(auth.uid(), id, 'administrator')
  );
```

### groups_delete_admin
**Purpose**: Only administrators can delete groups.
**Rule**: User has administrator role in the group

```sql
CREATE POLICY groups_delete_admin ON groups
  FOR DELETE
  USING (
    check_user_permission(auth.uid(), id, 'administrator')
  );
```

## Group Members Table Policies

### group_members_select_member
**Purpose**: Users can view membership information for groups they belong to.

```sql
CREATE POLICY group_members_select_member ON group_members
  FOR SELECT
  USING (
    group_id IN (
      SELECT group_id
      FROM group_members
      WHERE user_id = auth.uid()
    )
  );
```

### group_members_insert_admin
**Purpose**: Only administrators can add new members to groups.

```sql
CREATE POLICY group_members_insert_admin ON group_members
  FOR INSERT
  WITH CHECK (
    check_user_permission(auth.uid(), group_id, 'administrator')
  );
```

### group_members_update_admin
**Purpose**: Only administrators can change member roles.

```sql
CREATE POLICY group_members_update_admin ON group_members
  FOR UPDATE
  USING (
    check_user_permission(auth.uid(), group_id, 'administrator')
  );
```

### group_members_delete_admin
**Purpose**: Only administrators can remove members from groups.

```sql
CREATE POLICY group_members_delete_admin ON group_members
  FOR DELETE
  USING (
    check_user_permission(auth.uid(), group_id, 'administrator')
  );
```

## Expenses Table Policies

### expenses_select_member
**Purpose**: Users can view expenses from groups they are members of.

```sql
CREATE POLICY expenses_select_member ON expenses
  FOR SELECT
  USING (
    group_id IN (
      SELECT group_id
      FROM group_members
      WHERE user_id = auth.uid()
    )
  );
```

### expenses_insert_editor
**Purpose**: Editors and administrators can create expenses.

```sql
CREATE POLICY expenses_insert_editor ON expenses
  FOR INSERT
  WITH CHECK (
    check_user_permission(auth.uid(), group_id, 'editor')
  );
```

### expenses_update_editor
**Purpose**: Users can update their own expenses (if editor+), administrators can update any expense.

```sql
CREATE POLICY expenses_update_editor ON expenses
  FOR UPDATE
  USING (
    (payer_id = auth.uid() AND check_user_permission(auth.uid(), group_id, 'editor'))
    OR check_user_permission(auth.uid(), group_id, 'administrator')
  );
```

### expenses_delete_admin
**Purpose**: Only administrators can delete expenses.

```sql
CREATE POLICY expenses_delete_admin ON expenses
  FOR DELETE
  USING (
    check_user_permission(auth.uid(), group_id, 'administrator')
  );
```

## Expense Participants Table Policies

### expense_participants_select_member
**Purpose**: Users can view participants of expenses from their groups.

```sql
CREATE POLICY expense_participants_select_member ON expense_participants
  FOR SELECT
  USING (
    expense_id IN (
      SELECT id
      FROM expenses
      WHERE group_id IN (
        SELECT group_id
        FROM group_members
        WHERE user_id = auth.uid()
      )
    )
  );
```

### expense_participants_insert_editor
**Purpose**: Users can add participants to expenses they can edit.

```sql
CREATE POLICY expense_participants_insert_editor ON expense_participants
  FOR INSERT
  WITH CHECK (
    expense_id IN (
      SELECT id
      FROM expenses e
      WHERE (e.payer_id = auth.uid() AND check_user_permission(auth.uid(), e.group_id, 'editor'))
         OR check_user_permission(auth.uid(), e.group_id, 'administrator')
    )
  );
```

### expense_participants_update_editor
**Purpose**: Users can update participants for expenses they can edit.

```sql
CREATE POLICY expense_participants_update_editor ON expense_participants
  FOR UPDATE
  USING (
    expense_id IN (
      SELECT id
      FROM expenses e
      WHERE (e.payer_id = auth.uid() AND check_user_permission(auth.uid(), e.group_id, 'editor'))
         OR check_user_permission(auth.uid(), e.group_id, 'administrator')
    )
  );
```

### expense_participants_delete_editor
**Purpose**: Users can remove participants from expenses they can edit.

```sql
CREATE POLICY expense_participants_delete_editor ON expense_participants
  FOR DELETE
  USING (
    expense_id IN (
      SELECT id
      FROM expenses e
      WHERE (e.payer_id = auth.uid() AND check_user_permission(auth.uid(), e.group_id, 'editor'))
         OR check_user_permission(auth.uid(), e.group_id, 'administrator')
    )
  );
```

## Payments Table Policies

### payments_select_member
**Purpose**: Users can view payments from groups they are members of.

```sql
CREATE POLICY payments_select_member ON payments
  FOR SELECT
  USING (
    group_id IN (
      SELECT group_id
      FROM group_members
      WHERE user_id = auth.uid()
    )
  );
```

### payments_insert_editor
**Purpose**: Editors can create payments, but only as the payer.

```sql
CREATE POLICY payments_insert_editor ON payments
  FOR INSERT
  WITH CHECK (
    check_user_permission(auth.uid(), group_id, 'editor')
    AND payer_id = auth.uid()
  );
```

### payments_delete_own_or_admin
**Purpose**: Users can delete their own payments, administrators can delete any payment.

```sql
CREATE POLICY payments_delete_own_or_admin ON payments
  FOR DELETE
  USING (
    payer_id = auth.uid()
    OR check_user_permission(auth.uid(), group_id, 'administrator')
  );
```

## Audit Logs Table Policies

### audit_logs_select_admin
**Purpose**: Only administrators can view audit logs for their groups.

```sql
CREATE POLICY audit_logs_select_admin ON audit_logs
  FOR SELECT
  USING (
    group_id IN (
      SELECT group_id
      FROM group_members
      WHERE user_id = auth.uid()
        AND role = 'administrator'
    )
  );
```

### Audit Logs Modification Prevention
Audit logs are created only by triggers and cannot be modified by users:
- No INSERT, UPDATE, or DELETE policies are created
- Only database triggers can create audit logs
- Complete immutability ensures audit integrity

## Policy Testing Examples

### Testing Group Isolation

```sql
-- Setup: Create two groups with different members
-- Group A: Alice (admin), Bob (editor)
-- Group B: Charlie (admin), David (editor)

-- Test 1: Alice should only see Group A data
SET SESSION AUTHORIZATION alice;
SELECT * FROM groups;  -- Should return only Group A

-- Test 2: Bob should not see Group B expenses
SET SESSION AUTHORIZATION bob;
SELECT * FROM expenses WHERE group_id = 'group-b-id';  -- Should return empty

-- Test 3: Charlie cannot modify Group A
SET SESSION AUTHORIZATION charlie;
UPDATE groups SET name = 'Hacked' WHERE id = 'group-a-id';  -- Should fail
```

### Testing Role Permissions

```sql
-- Setup: Alice (admin), Bob (editor), Charlie (viewer) in same group

-- Test 1: Only Alice can add members
SET SESSION AUTHORIZATION alice;
INSERT INTO group_members (group_id, user_id, role) 
VALUES ('group-id', 'new-user-id', 'editor');  -- Should succeed

SET SESSION AUTHORIZATION bob;
INSERT INTO group_members (group_id, user_id, role) 
VALUES ('group-id', 'another-user-id', 'editor');  -- Should fail

-- Test 2: Bob can create expenses, Charlie cannot
SET SESSION AUTHORIZATION bob;
INSERT INTO expenses (group_id, payer_id, amount, currency, description)
VALUES ('group-id', 'bob-id', 50.00, 'USD', 'Lunch');  -- Should succeed

SET SESSION AUTHORIZATION charlie;
INSERT INTO expenses (group_id, payer_id, amount, currency, description)
VALUES ('group-id', 'charlie-id', 30.00, 'USD', 'Coffee');  -- Should fail
```

## Performance Considerations

### Policy Optimization

1. **Index Usage**: All policies leverage existing indexes for efficient filtering
2. **Subquery Optimization**: PostgreSQL optimizes subqueries in policy conditions
3. **Function Caching**: `check_user_permission()` results can be cached within transactions
4. **Minimal Overhead**: Well-designed policies add minimal query overhead

### Query Plan Analysis

```sql
-- Analyze policy impact on query performance
EXPLAIN (ANALYZE, BUFFERS) 
SELECT * FROM expenses WHERE group_id = 'some-group-id';

-- Check if policies use indexes effectively
-- Look for "Index Scan" rather than "Seq Scan" in query plans
```

## Security Best Practices

### Policy Design Principles

1. **Principle of Least Privilege**: Grant minimum necessary permissions
2. **Defense in Depth**: Multiple layers of security (RLS + application logic)
3. **Fail Secure**: Policies deny access by default
4. **Audit Everything**: Comprehensive logging of all data access

### Common Security Pitfalls

1. **Overly Permissive Policies**: Avoid policies that grant too much access
2. **Logic Errors**: Test policies thoroughly with different user scenarios
3. **Performance vs Security**: Don't sacrifice security for performance
4. **Policy Gaps**: Ensure all tables have appropriate policies

## Troubleshooting

### Common Issues

1. **Empty Result Sets**: User might not be a group member
2. **Permission Denied**: User might lack required role
3. **Policy Conflicts**: Multiple policies might create conflicts
4. **Performance Issues**: Complex policies might slow queries

### Debugging Techniques

```sql
-- Check user's group memberships
SELECT g.name, gm.role 
FROM groups g
JOIN group_members gm ON g.id = gm.group_id
WHERE gm.user_id = auth.uid();

-- Test policy conditions manually
SELECT check_user_permission(auth.uid(), 'group-id', 'editor');

-- Disable RLS temporarily for debugging (admin only)
ALTER TABLE expenses DISABLE ROW LEVEL SECURITY;
-- Remember to re-enable: ALTER TABLE expenses ENABLE ROW LEVEL SECURITY;
```

This comprehensive RLS implementation ensures robust data security while maintaining good performance and usability.