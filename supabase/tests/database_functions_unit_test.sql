-- ============================================================================
-- Unit Tests: Database Functions
-- Description: Unit tests for all database functions
-- ============================================================================

SELECT plan(12);

-- Create test users
INSERT INTO users (email, display_name) VALUES 
  ('unit_func1@example.com', 'Unit Function User 1'),
  ('unit_func2@example.com', 'Unit Function User 2'),
  ('unit_func3@example.com', 'Unit Function User 3');

-- Create test group
INSERT INTO groups (name, creator_id) 
VALUES ('Unit Function Test Group', (SELECT id FROM users WHERE email = 'unit_func1@example.com'));

-- Add members to group with different roles
INSERT INTO group_members (group_id, user_id, role)
VALUES 
  ((SELECT id FROM groups WHERE name = 'Unit Function Test Group'), 
   (SELECT id FROM users WHERE email = 'unit_func1@example.com'), 'administrator'),
  ((SELECT id FROM groups WHERE name = 'Unit Function Test Group'), 
   (SELECT id FROM users WHERE email = 'unit_func2@example.com'), 'editor'),
  ((SELECT id FROM groups WHERE name = 'Unit Function Test Group'), 
   (SELECT id FROM users WHERE email = 'unit_func3@example.com'), 'viewer');

-- Test 1: calculate_group_balances with empty group
SELECT ok(
  (SELECT COUNT(*) FROM calculate_group_balances(
    (SELECT id FROM groups WHERE name = 'Unit Function Test Group')
  )) = 3,
  'Test 1: calculate_group_balances returns all group members'
);

-- Test 2: validate_expense_split with valid split
-- Create expense and participants
INSERT INTO expenses (group_id, payer_id, amount, currency, description)
VALUES (
  (SELECT id FROM groups WHERE name = 'Unit Function Test Group'),
  (SELECT id FROM users WHERE email = 'unit_func1@example.com'),
  100.00, 'USD', 'Unit Function Test Expense Valid'
);

INSERT INTO expense_participants (expense_id, user_id, share_amount, share_percentage)
VALUES 
  ((SELECT id FROM expenses WHERE description = 'Unit Function Test Expense Valid'),
   (SELECT id FROM users WHERE email = 'unit_func1@example.com'), 50.00, 50.00),
  ((SELECT id FROM expenses WHERE description = 'Unit Function Test Expense Valid'),
   (SELECT id FROM users WHERE email = 'unit_func2@example.com'), 50.00, 50.00);

SELECT ok(
  validate_expense_split((SELECT id FROM expenses WHERE description = 'Unit Function Test Expense Valid')),
  'Test 2: validate_expense_split returns true for valid split'
);

-- Test 3: validate_expense_split with invalid split
INSERT INTO expenses (group_id, payer_id, amount, currency, description)
VALUES (
  (SELECT id FROM groups WHERE name = 'Unit Function Test Group'),
  (SELECT id FROM users WHERE email = 'unit_func1@example.com'),
  100.00, 'USD', 'Unit Function Test Expense Invalid'
);

INSERT INTO expense_participants (expense_id, user_id, share_amount, share_percentage)
VALUES 
  ((SELECT id FROM expenses WHERE description = 'Unit Function Test Expense Invalid'),
   (SELECT id FROM users WHERE email = 'unit_func1@example.com'), 40.00, 40.00),
  ((SELECT id FROM expenses WHERE description = 'Unit Function Test Expense Invalid'),
   (SELECT id FROM users WHERE email = 'unit_func2@example.com'), 40.00, 40.00);

SELECT ok(
  NOT validate_expense_split((SELECT id FROM expenses WHERE description = 'Unit Function Test Expense Invalid')),
  'Test 3: validate_expense_split returns false for invalid split'
);

-- Test 4: generate_settlement_plan with unbalanced group (should return transactions)
SELECT ok(
  (SELECT COUNT(*) FROM generate_settlement_plan(
    (SELECT id FROM groups WHERE name = 'Unit Function Test Group')
  )) > 0,
  'Test 4: generate_settlement_plan returns transactions for unbalanced group'
);

-- Test 5: check_user_permission - administrator can admin
SELECT ok(
  check_user_permission(
    (SELECT id FROM users WHERE email = 'unit_func1@example.com'),
    (SELECT id FROM groups WHERE name = 'Unit Function Test Group'),
    'admin'
  ),
  'Test 5: Administrator has admin permission'
);

-- Test 6: check_user_permission - editor cannot admin
SELECT ok(
  NOT check_user_permission(
    (SELECT id FROM users WHERE email = 'unit_func2@example.com'),
    (SELECT id FROM groups WHERE name = 'Unit Function Test Group'),
    'admin'
  ),
  'Test 6: Editor does not have admin permission'
);

-- Test 7: check_user_permission - editor can edit
SELECT ok(
  check_user_permission(
    (SELECT id FROM users WHERE email = 'unit_func2@example.com'),
    (SELECT id FROM groups WHERE name = 'Unit Function Test Group'),
    'edit'
  ),
  'Test 7: Editor has edit permission'
);

-- Test 8: check_user_permission - viewer cannot edit
SELECT ok(
  NOT check_user_permission(
    (SELECT id FROM users WHERE email = 'unit_func3@example.com'),
    (SELECT id FROM groups WHERE name = 'Unit Function Test Group'),
    'edit'
  ),
  'Test 8: Viewer does not have edit permission'
);

-- Test 9: check_user_permission - all roles can view
SELECT ok(
  check_user_permission(
    (SELECT id FROM users WHERE email = 'unit_func3@example.com'),
    (SELECT id FROM groups WHERE name = 'Unit Function Test Group'),
    'view'
  ),
  'Test 9: Viewer has view permission'
);

-- Test 10: Error handling - nonexistent group
SELECT throws_ok(
  $$SELECT * FROM calculate_group_balances(gen_random_uuid())$$,
  NULL,
  NULL,
  'Test 10: calculate_group_balances throws error for nonexistent group'
);

-- Test 11: Error handling - nonexistent expense
SELECT throws_ok(
  $$SELECT validate_expense_split(gen_random_uuid())$$,
  NULL,
  NULL,
  'Test 11: validate_expense_split throws error for nonexistent expense'
);

-- Test 12: check_user_permission - non-member returns false
SELECT ok(
  NOT check_user_permission(
    gen_random_uuid(),
    (SELECT id FROM groups WHERE name = 'Unit Function Test Group'),
    'view'
  ),
  'Test 12: Non-member has no permissions'
);

SELECT * FROM finish();