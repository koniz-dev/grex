-- ============================================================================
-- Migration: Create Database Functions
-- Version: 00009
-- Description: Create database functions for balance calculations and validations
-- ============================================================================

-- ============================================================================
-- Function 1: calculate_group_balances
-- Description: Calculate net balances for all group members
-- Requirements: 10.1
-- ============================================================================

CREATE OR REPLACE FUNCTION calculate_group_balances(p_group_id UUID)
RETURNS TABLE (
  user_id UUID,
  user_name TEXT,
  balance DECIMAL(10,2)
) AS $$
DECLARE
  group_currency TEXT;
BEGIN
  -- Get the group's primary currency
  SELECT primary_currency INTO group_currency
  FROM groups 
  WHERE id = p_group_id AND deleted_at IS NULL;
  
  IF NOT FOUND THEN
    RAISE EXCEPTION 'Group not found or has been deleted';
  END IF;

  -- Calculate balances using CTEs for clarity and performance
  RETURN QUERY
  WITH expense_totals AS (
    -- Total amount each user paid for expenses
    SELECT 
      e.payer_id as user_id,
      COALESCE(SUM(e.amount), 0) as total_paid
    FROM expenses e
    WHERE e.group_id = p_group_id 
      AND e.deleted_at IS NULL
      AND e.currency = group_currency
    GROUP BY e.payer_id
  ),
  participant_totals AS (
    -- Total amount each user owes from expense participation
    SELECT 
      ep.user_id,
      COALESCE(SUM(ep.share_amount), 0) as total_owed
    FROM expense_participants ep
    JOIN expenses e ON ep.expense_id = e.id
    WHERE e.group_id = p_group_id 
      AND e.deleted_at IS NULL
      AND e.currency = group_currency
    GROUP BY ep.user_id
  ),
  payments_sent AS (
    -- Total amount each user sent in payments
    SELECT 
      p.payer_id as user_id,
      COALESCE(SUM(p.amount), 0) as total_sent
    FROM payments p
    WHERE p.group_id = p_group_id 
      AND p.deleted_at IS NULL
      AND p.currency = group_currency
    GROUP BY p.payer_id
  ),
  payments_received AS (
    -- Total amount each user received in payments
    SELECT 
      p.recipient_id as user_id,
      COALESCE(SUM(p.amount), 0) as total_received
    FROM payments p
    WHERE p.group_id = p_group_id 
      AND p.deleted_at IS NULL
      AND p.currency = group_currency
    GROUP BY p.recipient_id
  ),
  all_members AS (
    -- Get all group members (active only)
    SELECT 
      gm.user_id,
      u.display_name as user_name
    FROM group_members gm
    JOIN users u ON gm.user_id = u.id
    WHERE gm.group_id = p_group_id 
      AND u.deleted_at IS NULL
  )
  SELECT 
    am.user_id,
    am.user_name,
    -- Balance = Amount paid + Amount received - Amount owed - Amount sent
    COALESCE(et.total_paid, 0) + COALESCE(pr.total_received, 0) - 
    COALESCE(pt.total_owed, 0) - COALESCE(ps.total_sent, 0) as balance
  FROM all_members am
  LEFT JOIN expense_totals et ON am.user_id = et.user_id
  LEFT JOIN participant_totals pt ON am.user_id = pt.user_id
  LEFT JOIN payments_sent ps ON am.user_id = ps.user_id
  LEFT JOIN payments_received pr ON am.user_id = pr.user_id
  ORDER BY am.user_name;
END;
$$ LANGUAGE plpgsql;

-- Add function comment
COMMENT ON FUNCTION calculate_group_balances(UUID) IS 
'Calculate net balances for all members of a group. Returns user_id, user_name, and balance. Positive balance means user is owed money, negative means user owes money.';

-- ============================================================================
-- Function 2: validate_expense_split
-- Description: Verify split amounts sum to expense total
-- Requirements: 10.2
-- ============================================================================

CREATE OR REPLACE FUNCTION validate_expense_split(p_expense_id UUID)
RETURNS BOOLEAN AS $$
DECLARE
  expense_amount DECIMAL(10,2);
  split_total DECIMAL(10,2);
  tolerance DECIMAL(10,2) := 0.01; -- Allow small rounding errors
BEGIN
  -- Get the expense amount
  SELECT amount INTO expense_amount
  FROM expenses 
  WHERE id = p_expense_id AND deleted_at IS NULL;
  
  IF NOT FOUND THEN
    RAISE EXCEPTION 'Expense not found or has been deleted';
  END IF;

  -- Calculate total of all participant shares
  SELECT COALESCE(SUM(share_amount), 0) INTO split_total
  FROM expense_participants
  WHERE expense_id = p_expense_id;

  -- Check if totals match within tolerance
  RETURN ABS(expense_amount - split_total) < tolerance;
END;
$$ LANGUAGE plpgsql;

-- Add function comment
COMMENT ON FUNCTION validate_expense_split(UUID) IS 
'Validate that the sum of expense participant shares equals the expense amount within a small tolerance (0.01) for rounding errors.';

-- ============================================================================
-- Verification queries (for testing)
-- ============================================================================

-- Verify functions were created
-- SELECT routine_name, routine_type, data_type 
-- FROM information_schema.routines 
-- WHERE routine_schema = 'public' 
--   AND routine_name IN ('calculate_group_balances', 'validate_expense_split');

-- Test calculate_group_balances function
-- SELECT * FROM calculate_group_balances('some-group-uuid');

-- Test validate_expense_split function  
-- SELECT validate_expense_split('some-expense-uuid');
-- ============================================================================
-- Function 3: generate_settlement_plan
-- Description: Calculate minimum transactions for settlement
-- Requirements: 10.3
-- ============================================================================

CREATE OR REPLACE FUNCTION generate_settlement_plan(p_group_id UUID)
RETURNS TABLE (
  payer_id UUID,
  payer_name TEXT,
  recipient_id UUID,
  recipient_name TEXT,
  amount DECIMAL(10,2)
) AS $$
DECLARE
  balance_record RECORD;
  creditor_record RECORD;
  debtor_record RECORD;
  settlement_amount DECIMAL(10,2);
BEGIN
  -- Create temporary table to store balances
  CREATE TEMP TABLE temp_balances AS
  SELECT * FROM calculate_group_balances(p_group_id);
  
  -- Create temporary table for settlement transactions
  CREATE TEMP TABLE temp_settlements (
    payer_id UUID,
    payer_name TEXT,
    recipient_id UUID,
    recipient_name TEXT,
    amount DECIMAL(10,2)
  );
  
  -- Implement greedy algorithm for settlement
  WHILE EXISTS (SELECT 1 FROM temp_balances WHERE ABS(balance) > 0.01) LOOP
    -- Find the largest creditor (positive balance)
    SELECT * INTO creditor_record 
    FROM temp_balances 
    WHERE balance > 0.01 
    ORDER BY balance DESC 
    LIMIT 1;
    
    -- Find the largest debtor (negative balance)
    SELECT * INTO debtor_record 
    FROM temp_balances 
    WHERE balance < -0.01 
    ORDER BY balance ASC 
    LIMIT 1;
    
    -- If no creditor or debtor found, break
    IF NOT FOUND OR creditor_record IS NULL OR debtor_record IS NULL THEN
      EXIT;
    END IF;
    
    -- Calculate settlement amount (minimum of what creditor is owed and debtor owes)
    settlement_amount := LEAST(creditor_record.balance, ABS(debtor_record.balance));
    
    -- Add settlement transaction
    INSERT INTO temp_settlements (payer_id, payer_name, recipient_id, recipient_name, amount)
    VALUES (debtor_record.user_id, debtor_record.user_name, 
            creditor_record.user_id, creditor_record.user_name, 
            settlement_amount);
    
    -- Update balances
    UPDATE temp_balances 
    SET balance = balance - settlement_amount 
    WHERE user_id = creditor_record.user_id;
    
    UPDATE temp_balances 
    SET balance = balance + settlement_amount 
    WHERE user_id = debtor_record.user_id;
    
    -- Remove users with zero balance
    DELETE FROM temp_balances WHERE ABS(balance) <= 0.01;
  END LOOP;
  
  -- Return settlement plan
  RETURN QUERY SELECT * FROM temp_settlements ORDER BY amount DESC;
  
  -- Cleanup
  DROP TABLE temp_balances;
  DROP TABLE temp_settlements;
END;
$$ LANGUAGE plpgsql;

-- Add function comment
COMMENT ON FUNCTION generate_settlement_plan(UUID) IS 
'Generate a settlement plan with minimum transactions to balance all group members. Uses greedy algorithm to minimize number of payments needed.';

-- ============================================================================
-- Function 4: check_user_permission
-- Description: Validate user permissions based on role
-- Requirements: 10.4
-- ============================================================================

CREATE OR REPLACE FUNCTION check_user_permission(
  p_user_id UUID,
  p_group_id UUID,
  p_required_permission TEXT
)
RETURNS BOOLEAN AS $$
DECLARE
  user_role member_role;
BEGIN
  -- Get user's role in the group
  SELECT role INTO user_role
  FROM group_members
  WHERE user_id = p_user_id AND group_id = p_group_id;
  
  IF NOT FOUND THEN
    -- User is not a member of the group
    RETURN FALSE;
  END IF;
  
  -- Check permissions based on role hierarchy
  -- administrator > editor > viewer
  CASE p_required_permission
    WHEN 'view' THEN
      -- All roles can view
      RETURN TRUE;
    WHEN 'edit' THEN
      -- Editor and administrator can edit
      RETURN user_role IN ('editor', 'administrator');
    WHEN 'admin' THEN
      -- Only administrator can perform admin actions
      RETURN user_role = 'administrator';
    ELSE
      -- Unknown permission
      RETURN FALSE;
  END CASE;
END;
$$ LANGUAGE plpgsql;

-- Add function comment
COMMENT ON FUNCTION check_user_permission(UUID, UUID, TEXT) IS 
'Check if a user has the required permission in a group based on their role. Permissions: view, edit, admin. Role hierarchy: administrator > editor > viewer.';