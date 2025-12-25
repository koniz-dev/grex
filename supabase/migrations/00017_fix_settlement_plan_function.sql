-- Migration: Fix generate_settlement_plan function
-- Description: Fix the temp table issue in generate_settlement_plan function
-- Author: System
-- Date: 2025-01-25

-- Drop and recreate the function with proper temp table handling
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
  temp_table_name TEXT;
  settlements_table_name TEXT;
BEGIN
  -- Generate unique temp table names to avoid conflicts
  temp_table_name := 'temp_balances_' || replace(gen_random_uuid()::text, '-', '');
  settlements_table_name := 'temp_settlements_' || replace(gen_random_uuid()::text, '-', '');
  
  -- Create temporary table to store balances
  EXECUTE format('CREATE TEMP TABLE %I AS SELECT * FROM calculate_group_balances($1)', temp_table_name) 
  USING p_group_id;
  
  -- Create temporary table for settlement transactions
  EXECUTE format('CREATE TEMP TABLE %I (
    payer_id UUID,
    payer_name TEXT,
    recipient_id UUID,
    recipient_name TEXT,
    amount DECIMAL(10,2)
  )', settlements_table_name);
  
  -- Implement greedy algorithm for settlement
  LOOP
    -- Check if there are any balances to settle
    EXECUTE format('SELECT COUNT(*) FROM %I WHERE ABS(balance) > 0.01', temp_table_name) INTO settlement_amount;
    IF settlement_amount = 0 THEN
      EXIT;
    END IF;
    
    -- Find the largest creditor (positive balance)
    EXECUTE format('SELECT * FROM %I WHERE balance > 0.01 ORDER BY balance DESC LIMIT 1', temp_table_name) 
    INTO creditor_record;
    
    -- Find the largest debtor (negative balance)
    EXECUTE format('SELECT * FROM %I WHERE balance < -0.01 ORDER BY balance ASC LIMIT 1', temp_table_name) 
    INTO debtor_record;
    
    -- If no creditor or debtor found, break
    IF creditor_record IS NULL OR debtor_record IS NULL THEN
      EXIT;
    END IF;
    
    -- Calculate settlement amount (minimum of what creditor is owed and debtor owes)
    settlement_amount := LEAST(creditor_record.balance, ABS(debtor_record.balance));
    
    -- Add settlement transaction
    EXECUTE format('INSERT INTO %I (payer_id, payer_name, recipient_id, recipient_name, amount) VALUES ($1, $2, $3, $4, $5)', 
                   settlements_table_name)
    USING debtor_record.user_id, debtor_record.user_name, 
          creditor_record.user_id, creditor_record.user_name, 
          settlement_amount;
    
    -- Update balances
    EXECUTE format('UPDATE %I SET balance = balance - $1 WHERE user_id = $2', temp_table_name)
    USING settlement_amount, creditor_record.user_id;
    
    EXECUTE format('UPDATE %I SET balance = balance + $1 WHERE user_id = $2', temp_table_name)
    USING settlement_amount, debtor_record.user_id;
    
    -- Remove users with zero balance
    EXECUTE format('DELETE FROM %I WHERE ABS(balance) <= 0.01', temp_table_name);
  END LOOP;
  
  -- Return settlement plan
  RETURN QUERY EXECUTE format('SELECT * FROM %I ORDER BY amount DESC', settlements_table_name);
  
  -- Cleanup temp tables
  EXECUTE format('DROP TABLE IF EXISTS %I', temp_table_name);
  EXECUTE format('DROP TABLE IF EXISTS %I', settlements_table_name);
END;
$$ LANGUAGE plpgsql;

-- Add function comment
COMMENT ON FUNCTION generate_settlement_plan(UUID) IS 
'Generate a settlement plan with minimum transactions to balance all group members. Uses greedy algorithm to minimize number of payments needed. Fixed version with proper temp table handling.';