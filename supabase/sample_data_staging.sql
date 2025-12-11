-- Sample Data for Staging Environment Testing
-- This file contains sample data to verify the staging deployment works correctly

BEGIN;

-- Insert test users with various configurations
INSERT INTO users (id, email, display_name, preferred_currency, preferred_language) VALUES
    ('550e8400-e29b-41d4-a716-446655440001', 'alice.staging@example.com', 'Alice Johnson (Staging)', 'USD', 'en'),
    ('550e8400-e29b-41d4-a716-446655440002', 'bob.staging@example.com', 'Bob Smith (Staging)', 'USD', 'en'),
    ('550e8400-e29b-41d4-a716-446655440003', 'charlie.staging@example.com', 'Charlie Brown (Staging)', 'EUR', 'en'),
    ('550e8400-e29b-41d4-a716-446655440004', 'diana.staging@example.com', 'Diana Prince (Staging)', 'GBP', 'en');

-- Insert test groups
INSERT INTO groups (id, name, description, creator_id, primary_currency) VALUES
    ('660e8400-e29b-41d4-a716-446655440001', 'Staging Test Group 1', 'Primary test group for staging validation', '550e8400-e29b-41d4-a716-446655440001', 'USD'),
    ('660e8400-e29b-41d4-a716-446655440002', 'Staging Test Group 2', 'Secondary test group for multi-group scenarios', '550e8400-e29b-41d4-a716-446655440002', 'EUR');

-- Insert group memberships with different roles
INSERT INTO group_members (group_id, user_id, role) VALUES
    -- Group 1 memberships
    ('660e8400-e29b-41d4-a716-446655440001', '550e8400-e29b-41d4-a716-446655440001', 'administrator'),
    ('660e8400-e29b-41d4-a716-446655440001', '550e8400-e29b-41d4-a716-446655440002', 'editor'),
    ('660e8400-e29b-41d4-a716-446655440001', '550e8400-e29b-41d4-a716-446655440003', 'viewer'),
    -- Group 2 memberships
    ('660e8400-e29b-41d4-a716-446655440002', '550e8400-e29b-41d4-a716-446655440002', 'administrator'),
    ('660e8400-e29b-41d4-a716-446655440002', '550e8400-e29b-41d4-a716-446655440004', 'editor');

-- Insert test expenses with different split methods
INSERT INTO expenses (id, group_id, payer_id, amount, currency, description, split_method, notes) VALUES
    ('770e8400-e29b-41d4-a716-446655440001', '660e8400-e29b-41d4-a716-446655440001', '550e8400-e29b-41d4-a716-446655440001', 120.00, 'USD', 'Staging Test Dinner', 'equal', 'Equal split test'),
    ('770e8400-e29b-41d4-a716-446655440002', '660e8400-e29b-41d4-a716-446655440001', '550e8400-e29b-41d4-a716-446655440002', 75.50, 'USD', 'Staging Test Groceries', 'percentage', 'Percentage split test'),
    ('770e8400-e29b-41d4-a716-446655440003', '660e8400-e29b-41d4-a716-446655440002', '550e8400-e29b-41d4-a716-446655440004', 200.00, 'EUR', 'Staging Test Hotel', 'exact', 'Exact amount split test');

-- Insert expense participants with different split configurations
INSERT INTO expense_participants (expense_id, user_id, share_amount, share_percentage) VALUES
    -- Equal split expense (120.00 / 3 = 40.00 each)
    ('770e8400-e29b-41d4-a716-446655440001', '550e8400-e29b-41d4-a716-446655440001', 40.00, NULL),
    ('770e8400-e29b-41d4-a716-446655440001', '550e8400-e29b-41d4-a716-446655440002', 40.00, NULL),
    ('770e8400-e29b-41d4-a716-446655440001', '550e8400-e29b-41d4-a716-446655440003', 40.00, NULL),
    -- Percentage split expense (75.50 total)
    ('770e8400-e29b-41d4-a716-446655440002', '550e8400-e29b-41d4-a716-446655440001', 37.75, 50.00),
    ('770e8400-e29b-41d4-a716-446655440002', '550e8400-e29b-41d4-a716-446655440002', 22.65, 30.00),
    ('770e8400-e29b-41d4-a716-446655440002', '550e8400-e29b-41d4-a716-446655440003', 15.10, 20.00),
    -- Exact split expense (200.00 total)
    ('770e8400-e29b-41d4-a716-446655440003', '550e8400-e29b-41d4-a716-446655440002', 100.00, NULL),
    ('770e8400-e29b-41d4-a716-446655440003', '550e8400-e29b-41d4-a716-446655440004', 100.00, NULL);

-- Insert test payments
INSERT INTO payments (id, group_id, payer_id, recipient_id, amount, currency, notes) VALUES
    ('880e8400-e29b-41d4-a716-446655440001', '660e8400-e29b-41d4-a716-446655440001', '550e8400-e29b-41d4-a716-446655440002', 20.00, 'USD', 'Staging test payment 1'),
    ('880e8400-e29b-41d4-a716-446655440002', '660e8400-e29b-41d4-a716-446655440001', '550e8400-e29b-41d4-a716-446655440003', 15.00, 'USD', 'Staging test payment 2');

-- Verify data integrity and functions
DO $$
DECLARE
    balance_count INTEGER;
    split_valid BOOLEAN;
    admin_permission BOOLEAN;
    settlement_count INTEGER;
BEGIN
    -- Test balance calculation function
    SELECT COUNT(*) INTO balance_count 
    FROM calculate_group_balances('660e8400-e29b-41d4-a716-446655440001');
    
    IF balance_count != 3 THEN
        RAISE EXCEPTION 'Balance calculation failed: expected 3 users, got %', balance_count;
    END IF;
    
    -- Test expense split validation
    SELECT validate_expense_split('770e8400-e29b-41d4-a716-446655440001') INTO split_valid;
    
    IF NOT split_valid THEN
        RAISE EXCEPTION 'Expense split validation failed for equal split expense';
    END IF;
    
    -- Test permission checking
    SELECT check_user_permission('550e8400-e29b-41d4-a716-446655440001', '660e8400-e29b-41d4-a716-446655440001', 'administrator') INTO admin_permission;
    
    IF NOT admin_permission THEN
        RAISE EXCEPTION 'Permission check failed: user should have administrator permission';
    END IF;
    
    -- Test settlement plan generation
    SELECT COUNT(*) INTO settlement_count 
    FROM generate_settlement_plan('660e8400-e29b-41d4-a716-446655440001');
    
    -- Settlement count may vary based on balances, just ensure function executes
    
    RAISE NOTICE 'All function tests passed successfully';
END $$;

-- Test audit logging by performing some operations
UPDATE users SET display_name = 'Alice Johnson (Updated)' WHERE id = '550e8400-e29b-41d4-a716-446655440001';
UPDATE expenses SET notes = 'Updated notes for staging test' WHERE id = '770e8400-e29b-41d4-a716-446655440001';

-- Verify audit logs were created
DO $$
DECLARE
    audit_count INTEGER;
BEGIN
    SELECT COUNT(*) INTO audit_count FROM audit_logs WHERE entity_type IN ('user', 'expense');
    
    IF audit_count < 2 THEN
        RAISE EXCEPTION 'Audit logging failed: expected at least 2 audit entries, got %', audit_count;
    END IF;
    
    RAISE NOTICE 'Audit logging test passed: % audit entries created', audit_count;
END $$;

-- Test RLS policies by setting a user context (simulated)
-- Note: In real testing, this would be done with actual user sessions

-- Clean up test data (optional - comment out if you want to keep data for manual testing)
/*
DELETE FROM payments WHERE group_id IN ('660e8400-e29b-41d4-a716-446655440001', '660e8400-e29b-41d4-a716-446655440002');
DELETE FROM expense_participants WHERE expense_id IN ('770e8400-e29b-41d4-a716-446655440001', '770e8400-e29b-41d4-a716-446655440002', '770e8400-e29b-41d4-a716-446655440003');
DELETE FROM expenses WHERE group_id IN ('660e8400-e29b-41d4-a716-446655440001', '660e8400-e29b-41d4-a716-446655440002');
DELETE FROM group_members WHERE group_id IN ('660e8400-e29b-41d4-a716-446655440001', '660e8400-e29b-41d4-a716-446655440002');
DELETE FROM groups WHERE id IN ('660e8400-e29b-41d4-a716-446655440001', '660e8400-e29b-41d4-a716-446655440002');
DELETE FROM users WHERE id IN ('550e8400-e29b-41d4-a716-446655440001', '550e8400-e29b-41d4-a716-446655440002', '550e8400-e29b-41d4-a716-446655440003', '550e8400-e29b-41d4-a716-446655440004');
*/

COMMIT;

-- Final verification message
SELECT 'Staging sample data deployment completed successfully!' as status;