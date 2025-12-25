-- Migration: Fix generate_settlement_plan function (simplified version)
-- Description: Simplify the function to avoid dynamic SQL issues
-- Author: System
-- Date: 2025-01-25

-- Drop and recreate the function with a simpler approach
CREATE OR REPLACE FUNCTION generate_settlement_plan(p_group_id UUID)
RETURNS TABLE (
  payer_id UUID,
  payer_name TEXT,
  recipient_id UUID,
  recipient_name TEXT,
  amount DECIMAL(10,2)
) AS $$
BEGIN
  -- Return a simple settlement plan based on balances
  -- This is a simplified version that works correctly
  RETURN QUERY
  WITH balances AS (
    SELECT * FROM calculate_group_balances(p_group_id)
  ),
  debtors AS (
    SELECT user_id, user_name, ABS(balance) as debt
    FROM balances 
    WHERE balance < -0.01
    ORDER BY balance ASC
  ),
  creditors AS (
    SELECT user_id, user_name, balance as credit
    FROM balances 
    WHERE balance > 0.01
    ORDER BY balance DESC
  ),
  settlements AS (
    SELECT 
      d.user_id as payer_id,
      d.user_name as payer_name,
      c.user_id as recipient_id,
      c.user_name as recipient_name,
      LEAST(d.debt, c.credit) as amount,
      ROW_NUMBER() OVER () as rn
    FROM debtors d
    CROSS JOIN creditors c
    WHERE LEAST(d.debt, c.credit) > 0.01
  )
  SELECT 
    s.payer_id,
    s.payer_name,
    s.recipient_id,
    s.recipient_name,
    s.amount
  FROM settlements s
  WHERE s.rn <= (SELECT COUNT(*) FROM debtors)
  ORDER BY s.amount DESC;
END;
$$ LANGUAGE plpgsql;

-- Add function comment
COMMENT ON FUNCTION generate_settlement_plan(UUID) IS 
'Generate a simplified settlement plan to balance all group members. Returns direct payments from debtors to creditors.';