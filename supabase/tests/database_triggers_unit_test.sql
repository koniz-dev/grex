-- ============================================================================
-- Unit Tests: Database Triggers
-- Description: Unit tests for all database triggers
-- ============================================================================

SELECT plan(15);

-- Create test users
INSERT INTO users (email, display_name) VALUES 
  ('trigger_unit1@example.com', 'Trigger Unit User 1'),
  ('trigger_unit2@example.com', 'Trigger Unit User 2');

-- Create test group
INSERT INTO groups (name, creator_id) 
VALUES ('Trigger Unit Test Group', (SELECT id FROM users WHERE email = 'trigger_unit1@example.com'));

-- Test 1: User timestamp trigger on INSERT
INSERT INTO users (email, display_name) VALUES ('timestamp_test@example.com', 'Timestamp Test User');

SELECT ok(
  (SELECT created_at FROM users WHERE email = 'timestamp_test@example.com') IS NOT NULL,
  'Test 1: User created_at set on INSERT'
);

SELECT ok(
  (SELECT updated_at FROM users WHERE email = 'timestamp_test@example.com') IS NOT NULL,
  'Test 2: User updated_at set on INSERT'
);

-- Test 3: User timestamp trigger on UPDATE
UPDATE users SET display_name = 'Updated Timestamp Test User' WHERE email = 'timestamp_test@example.com';

SELECT ok(
  (SELECT updated_at > created_at FROM users WHERE email = 'timestamp_test@example.com'),
  'Test 3: User updated_at changes on UPDATE'
);

-- Test 4: Group timestamp trigger
INSERT INTO groups (name, creator_id) VALUES 
  ('Timestamp Test Group', (SELECT id FROM users WHERE email = 'trigger_unit1@example.com'));

SELECT ok(
  (SELECT created_at FROM groups WHERE name = 'Timestamp Test Group') IS NOT NULL AND
  (SELECT updated_at FROM groups WHERE name = 'Timestamp Test Group') IS NOT NULL,
  'Test 4: Group timestamps set on INSERT'
);

-- Test 5: Group member timestamp trigger (joined_at and updated_at)
INSERT INTO group_members (group_id, user_id, role) VALUES
  ((SELECT id FROM groups WHERE name = 'Timestamp Test Group'),
   (SELECT id FROM users WHERE email = 'trigger_unit2@example.com'),
   'editor');

SELECT ok(
  (SELECT joined_at FROM group_members 
   WHERE group_id = (SELECT id FROM groups WHERE name = 'Timestamp Test Group')
     AND user_id = (SELECT id FROM users WHERE email = 'trigger_unit2@example.com')) IS NOT NULL,
  'Test 5: Group member joined_at set on INSERT'
);

-- Test 6: Expense timestamp trigger
INSERT INTO expenses (group_id, payer_id, amount, currency, description) VALUES
  ((SELECT id FROM groups WHERE name = 'Timestamp Test Group'),
   (SELECT id FROM users WHERE email = 'trigger_unit1@example.com'),
   100.00, 'USD', 'Unit Test Expense');

SELECT ok(
  (SELECT created_at FROM expenses WHERE description = 'Unit Test Expense') IS NOT NULL AND
  (SELECT updated_at FROM expenses WHERE description = 'Unit Test Expense') IS NOT NULL,
  'Test 6: Expense timestamps set on INSERT'
);

-- Test 7: Expense participant timestamp trigger
INSERT INTO expense_participants (expense_id, user_id, share_amount, share_percentage) VALUES
  ((SELECT id FROM expenses WHERE description = 'Unit Test Expense'),
   (SELECT id FROM users WHERE email = 'trigger_unit1@example.com'),
   100.00, 100.00);

SELECT ok(
  (SELECT created_at FROM expense_participants 
   WHERE expense_id = (SELECT id FROM expenses WHERE description = 'Unit Test Expense')) IS NOT NULL,
  'Test 7: Expense participant created_at set on INSERT'
);

-- Test 8: Payment timestamp trigger
INSERT INTO payments (group_id, payer_id, recipient_id, amount, currency, notes) VALUES
  ((SELECT id FROM groups WHERE name = 'Timestamp Test Group'),
   (SELECT id FROM users WHERE email = 'trigger_unit1@example.com'),
   (SELECT id FROM users WHERE email = 'trigger_unit2@example.com'),
   50.00, 'USD', 'Unit test payment');

SELECT ok(
  (SELECT created_at FROM payments WHERE notes = 'Unit test payment') IS NOT NULL,
  'Test 8: Payment created_at set on INSERT'
);

-- Test 9: Expense audit trigger on INSERT
SELECT ok(
  (SELECT COUNT(*) FROM audit_logs 
   WHERE entity_type = 'expense' 
     AND action = 'create'
     AND after_state->>'description' = 'Unit Test Expense') = 1,
  'Test 9: Expense INSERT creates audit log'
);

-- Test 10: Expense audit trigger on UPDATE
UPDATE expenses SET description = 'Updated Unit Test Expense' WHERE description = 'Unit Test Expense';

SELECT ok(
  (SELECT COUNT(*) FROM audit_logs 
   WHERE entity_type = 'expense' 
     AND action = 'update'
     AND before_state->>'description' = 'Unit Test Expense'
     AND after_state->>'description' = 'Updated Unit Test Expense') = 1,
  'Test 10: Expense UPDATE creates audit log'
);

-- Test 11: Payment audit trigger on INSERT
SELECT ok(
  (SELECT COUNT(*) FROM audit_logs 
   WHERE entity_type = 'payment' 
     AND action = 'create'
     AND after_state->>'notes' = 'Unit test payment') = 1,
  'Test 11: Payment INSERT creates audit log'
);

-- Test 12: Group member audit trigger on INSERT
SELECT ok(
  (SELECT COUNT(*) FROM audit_logs 
   WHERE entity_type = 'group_member' 
     AND action = 'create'
     AND after_state->>'role' = 'editor') >= 1,
  'Test 12: Group member INSERT creates audit log'
);

-- Test 13: Group member audit trigger on UPDATE
UPDATE group_members SET role = 'administrator' 
WHERE group_id = (SELECT id FROM groups WHERE name = 'Timestamp Test Group')
  AND user_id = (SELECT id FROM users WHERE email = 'trigger_unit2@example.com');

SELECT ok(
  (SELECT COUNT(*) FROM audit_logs 
   WHERE entity_type = 'group_member' 
     AND action = 'update'
     AND before_state->>'role' = 'editor'
     AND after_state->>'role' = 'administrator'
     AND after_state->>'user_email' = 'trigger_unit2@example.com') >= 1,
  'Test 13: Group member UPDATE creates audit log'
);

-- Test 14: Audit log immutability (should fail to update)
SELECT throws_ok(
  $$UPDATE audit_logs SET user_email = 'hacker@evil.com' WHERE entity_type = 'expense' LIMIT 1$$,
  NULL,
  NULL,
  'Test 14: Audit logs are immutable (UPDATE should fail)'
);

-- Test 15: Audit log immutability (should fail to delete)
SELECT throws_ok(
  $$DELETE FROM audit_logs WHERE entity_type = 'expense' LIMIT 1$$,
  NULL,
  NULL,
  'Test 15: Audit logs are immutable (DELETE should fail)'
);

SELECT * FROM finish();