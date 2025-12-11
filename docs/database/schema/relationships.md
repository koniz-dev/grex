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
- 23505: Unique constraint violation (duplicate email, duplicate membership)
- 23503: Foreign key constraint violation (invalid user_id, group_id)
- 23514: Check constraint violation (negative amount, invalid currency code)
- 23502: Not null constraint violation (missing required field)
