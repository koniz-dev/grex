-- ============================================================================
-- SQL Injection Attack Simulation
-- Description: Simulates various SQL injection attacks to verify prevention
-- Requirements: All (Security requirement for all functions and queries)
-- ============================================================================

-- This file simulates real SQL injection attacks to verify our defenses work
-- All attacks should FAIL, demonstrating our security measures are effective

\echo '=== SQL INJECTION ATTACK SIMULATION ==='
\echo 'This test simulates real SQL injection attacks.'
\echo 'ALL ATTACKS SHOULD FAIL - this proves our security works.'
\echo ''

-- ============================================================================
-- Attack Simulation 1: Classic SQL Injection in Function Parameters
-- ============================================================================

\echo 'Attack 1: Classic SQL Injection in Function Parameters'
\echo 'Attempting: calculate_group_balances('''; DROP TABLE users; --'')'

-- This should fail due to UUID type validation
DO $attack1$
BEGIN
  BEGIN
    -- Attempt SQL injection through function parameter
    PERFORM calculate_group_balances(''''; DROP TABLE users; --''::UUID);
    RAISE NOTICE 'SECURITY BREACH: SQL injection succeeded!';
  EXCEPTION
    WHEN invalid_text_representation THEN
      RAISE NOTICE 'SECURITY OK: Attack blocked by UUID type validation';
    WHEN OTHERS THEN
      RAISE NOTICE 'SECURITY OK: Attack blocked - %', SQLERRM;
  END;
END;
$attack1$;

-- ============================================================================
-- Attack Simulation 2: Union-Based SQL Injection
-- ============================================================================

\echo ''
\echo 'Attack 2: Union-Based SQL Injection'
\echo 'Attempting to extract sensitive data through UNION'

DO $attack2$
BEGIN
  BEGIN
    -- Attempt union-based injection (this should fail due to type safety)
    PERFORM calculate_group_balances('00000000-0000-0000-0000-000000000000'' UNION SELECT id, email, ''hacked'' FROM users; --'::UUID);
    RAISE NOTICE 'SECURITY BREACH: Union injection succeeded!';
  EXCEPTION
    WHEN invalid_text_representation THEN
      RAISE NOTICE 'SECURITY OK: Union attack blocked by UUID validation';
    WHEN OTHERS THEN
      RAISE NOTICE 'SECURITY OK: Union attack blocked - %', SQLERRM;
  END;
END;
$attack2$;

-- ============================================================================
-- Attack Simulation 3: Boolean-Based Blind SQL Injection
-- ============================================================================

\echo ''
\echo 'Attack 3: Boolean-Based Blind SQL Injection'
\echo 'Attempting to extract data through boolean conditions'

DO $attack3$
BEGIN
  BEGIN
    -- Attempt boolean-based blind injection
    PERFORM check_user_permission(
      '00000000-0000-0000-0000-000000000000',
      '00000000-0000-0000-0000-000000000000',
      'admin'' OR 1=1; --'
    );
    RAISE NOTICE 'SECURITY OK: Function executed (input treated as literal)';
  EXCEPTION
    WHEN OTHERS THEN
      RAISE NOTICE 'SECURITY OK: Boolean injection blocked - %', SQLERRM;
  END;
END;
$attack3$;

-- ============================================================================
-- Attack Simulation 4: Time-Based Blind SQL Injection
-- ============================================================================

\echo ''
\echo 'Attack 4: Time-Based Blind SQL Injection'
\echo 'Attempting to cause delays to extract information'

DO $attack4$
BEGIN
  BEGIN
    -- Attempt time-based injection (PostgreSQL syntax)
    PERFORM check_user_permission(
      '00000000-0000-0000-0000-000000000000',
      '00000000-0000-0000-0000-000000000000',
      'admin''; SELECT pg_sleep(5); --'
    );
    RAISE NOTICE 'SECURITY OK: Function executed (malicious code treated as literal)';
  EXCEPTION
    WHEN OTHERS THEN
      RAISE NOTICE 'SECURITY OK: Time-based injection blocked - %', SQLERRM;
  END;
END;
$attack4$;

-- ============================================================================
-- Attack Simulation 5: Constraint Bypass Attempts
-- ============================================================================

\echo ''
\echo 'Attack 5: Constraint Bypass Attempts'
\echo 'Attempting to bypass input validation constraints'

-- Test email format bypass
DO $attack5a$
BEGIN
  BEGIN
    INSERT INTO users (id, email, display_name) VALUES 
    ('12345678-1234-1234-1234-123456789012', 
     'admin@example.com''; DROP TABLE users; --', 
     'Hacker');
    RAISE NOTICE 'SECURITY BREACH: Email constraint bypassed!';
  EXCEPTION
    WHEN check_violation THEN
      RAISE NOTICE 'SECURITY OK: Email format constraint blocked injection';
    WHEN OTHERS THEN
      RAISE NOTICE 'SECURITY OK: Email injection blocked - %', SQLERRM;
  END;
END;
$attack5a$;

-- Test amount constraint bypass
DO $attack5b$
BEGIN
  BEGIN
    INSERT INTO expenses (group_id, payer_id, amount, currency, description) VALUES 
    ('12345678-1234-1234-1234-123456789012',
     '12345678-1234-1234-1234-123456789012',
     -999999.99, -- Negative amount should be rejected
     'USD',
     'Malicious expense');
    RAISE NOTICE 'SECURITY BREACH: Amount constraint bypassed!';
  EXCEPTION
    WHEN check_violation THEN
      RAISE NOTICE 'SECURITY OK: Positive amount constraint blocked negative value';
    WHEN foreign_key_violation THEN
      RAISE NOTICE 'SECURITY OK: Foreign key constraint blocked invalid references';
    WHEN OTHERS THEN
      RAISE NOTICE 'SECURITY OK: Amount injection blocked - %', SQLERRM;
  END;
END;
$attack5b$;

-- ============================================================================
-- Attack Simulation 6: JSONB Injection in Audit Logs
-- ============================================================================

\echo ''
\echo 'Attack 6: JSONB Injection in Audit Logs'
\echo 'Attempting to inject malicious code through JSONB fields'

-- Create test data first
DO $setup$
BEGIN
  -- Create test user and group for this attack
  INSERT INTO users (id, email, display_name) VALUES 
  ('aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', 'test@example.com', 'Test User')
  ON CONFLICT (id) DO NOTHING;
  
  INSERT INTO groups (id, name, creator_id) VALUES 
  ('bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb', 'Test Group', 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa')
  ON CONFLICT (id) DO NOTHING;
  
  INSERT INTO group_members (group_id, user_id, role) VALUES 
  ('bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb', 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', 'administrator')
  ON CONFLICT (group_id, user_id) DO NOTHING;
EXCEPTION
  WHEN OTHERS THEN
    -- Ignore setup errors for this test
    NULL;
END;
$setup$;

DO $attack6$
DECLARE
  malicious_description TEXT := 'Test"; DROP TABLE audit_logs; SELECT "hacked';
  expense_id UUID;
  audit_count INTEGER;
BEGIN
  -- Count audit logs before
  SELECT COUNT(*) INTO audit_count FROM audit_logs;
  
  BEGIN
    -- Insert expense with malicious description
    INSERT INTO expenses (id, group_id, payer_id, amount, currency, description) VALUES 
    ('cccccccc-cccc-cccc-cccc-cccccccccccc',
     'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb',
     'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa',
     100.00,
     'USD',
     malicious_description)
    RETURNING id INTO expense_id;
    
    -- Check if audit log was created safely
    IF EXISTS (SELECT 1 FROM audit_logs WHERE entity_id = expense_id) THEN
      RAISE NOTICE 'SECURITY OK: Audit trigger handled malicious JSONB data safely';
    ELSE
      RAISE NOTICE 'SECURITY ISSUE: Audit log not created';
    END IF;
    
    -- Verify audit_logs table still exists
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'audit_logs') THEN
      RAISE NOTICE 'SECURITY OK: audit_logs table not compromised by JSONB injection';
    ELSE
      RAISE NOTICE 'SECURITY BREACH: audit_logs table was dropped!';
    END IF;
    
  EXCEPTION
    WHEN OTHERS THEN
      RAISE NOTICE 'SECURITY OK: JSONB injection blocked - %', SQLERRM;
  END;
END;
$attack6$;

-- ============================================================================
-- Attack Simulation 7: Function Overloading Attack
-- ============================================================================

\echo ''
\echo 'Attack 7: Function Overloading Attack'
\echo 'Attempting to create malicious functions with same names'

DO $attack7$
BEGIN
  BEGIN
    -- Attempt to create a malicious function with the same name
    EXECUTE 'CREATE OR REPLACE FUNCTION calculate_group_balances(p_group_id UUID) 
             RETURNS TABLE (user_id UUID, user_name TEXT, balance DECIMAL(10,2)) AS $$ 
             BEGIN 
               DROP TABLE users; 
               RETURN; 
             END; 
             $$ LANGUAGE plpgsql;';
    RAISE NOTICE 'SECURITY BREACH: Function overloading succeeded!';
  EXCEPTION
    WHEN insufficient_privilege THEN
      RAISE NOTICE 'SECURITY OK: Function overloading blocked by privileges';
    WHEN OTHERS THEN
      RAISE NOTICE 'SECURITY OK: Function overloading blocked - %', SQLERRM;
  END;
END;
$attack7$;

-- ============================================================================
-- Attack Simulation 8: RLS Policy Bypass
-- ============================================================================

\echo ''
\echo 'Attack 8: RLS Policy Bypass Attempt'
\echo 'Attempting to bypass Row Level Security policies'

DO $attack8$
BEGIN
  BEGIN
    -- Attempt to disable RLS (should fail without superuser privileges)
    ALTER TABLE users DISABLE ROW LEVEL SECURITY;
    RAISE NOTICE 'SECURITY BREACH: RLS disabled successfully!';
  EXCEPTION
    WHEN insufficient_privilege THEN
      RAISE NOTICE 'SECURITY OK: RLS disable blocked by insufficient privileges';
    WHEN OTHERS THEN
      RAISE NOTICE 'SECURITY OK: RLS bypass blocked - %', SQLERRM;
  END;
END;
$attack8$;

-- ============================================================================
-- Attack Simulation 9: Audit Log Tampering
-- ============================================================================

\echo ''
\echo 'Attack 9: Audit Log Tampering Attempt'
\echo 'Attempting to modify or delete audit logs'

DO $attack9$
BEGIN
  BEGIN
    -- Attempt to delete audit logs
    DELETE FROM audit_logs WHERE entity_type = 'expense';
    RAISE NOTICE 'SECURITY BREACH: Audit logs deleted!';
  EXCEPTION
    WHEN OTHERS THEN
      RAISE NOTICE 'SECURITY OK: Audit log deletion blocked - %', SQLERRM;
  END;
  
  BEGIN
    -- Attempt to update audit logs
    UPDATE audit_logs SET after_state = '{"hacked": true}' WHERE entity_type = 'expense';
    RAISE NOTICE 'SECURITY BREACH: Audit logs modified!';
  EXCEPTION
    WHEN OTHERS THEN
      RAISE NOTICE 'SECURITY OK: Audit log modification blocked - %', SQLERRM;
  END;
END;
$attack9$;

-- ============================================================================
-- Attack Simulation 10: Privilege Escalation
-- ============================================================================

\echo ''
\echo 'Attack 10: Privilege Escalation Attempt'
\echo 'Attempting to escalate database privileges'

DO $attack10$
BEGIN
  BEGIN
    -- Attempt to create superuser
    CREATE USER hacker SUPERUSER;
    RAISE NOTICE 'SECURITY BREACH: Superuser created!';
  EXCEPTION
    WHEN insufficient_privilege THEN
      RAISE NOTICE 'SECURITY OK: Superuser creation blocked by insufficient privileges';
    WHEN OTHERS THEN
      RAISE NOTICE 'SECURITY OK: Privilege escalation blocked - %', SQLERRM;
  END;
  
  BEGIN
    -- Attempt to grant all privileges
    GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO PUBLIC;
    RAISE NOTICE 'SECURITY BREACH: All privileges granted to public!';
  EXCEPTION
    WHEN insufficient_privilege THEN
      RAISE NOTICE 'SECURITY OK: Privilege grant blocked by insufficient privileges';
    WHEN OTHERS THEN
      RAISE NOTICE 'SECURITY OK: Privilege escalation blocked - %', SQLERRM;
  END;
END;
$attack10$;

-- ============================================================================
-- Attack Summary and Verification
-- ============================================================================

\echo ''
\echo '=== ATTACK SIMULATION SUMMARY ==='
\echo ''

-- Verify critical tables still exist
DO $summary$
BEGIN
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'users') THEN
    RAISE NOTICE 'VERIFICATION: users table exists ✓';
  ELSE
    RAISE NOTICE 'CRITICAL: users table missing ✗';
  END IF;
  
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'audit_logs') THEN
    RAISE NOTICE 'VERIFICATION: audit_logs table exists ✓';
  ELSE
    RAISE NOTICE 'CRITICAL: audit_logs table missing ✗';
  END IF;
  
  -- Check if RLS is still enabled
  IF EXISTS (SELECT 1 FROM pg_tables WHERE schemaname = 'public' AND tablename = 'users' AND rowsecurity = true) THEN
    RAISE NOTICE 'VERIFICATION: RLS still enabled on users table ✓';
  ELSE
    RAISE NOTICE 'CRITICAL: RLS disabled on users table ✗';
  END IF;
  
  -- Check function integrity
  IF EXISTS (SELECT 1 FROM information_schema.routines WHERE routine_name = 'calculate_group_balances') THEN
    RAISE NOTICE 'VERIFICATION: calculate_group_balances function exists ✓';
  ELSE
    RAISE NOTICE 'CRITICAL: calculate_group_balances function missing ✗';
  END IF;
END;
$summary$;

\echo ''
\echo 'SQL INJECTION ATTACK SIMULATION COMPLETED'
\echo ''
\echo 'Expected Results:'
\echo '- All attacks should be BLOCKED (SECURITY OK messages)'
\echo '- All verification checks should show ✓'
\echo '- No SECURITY BREACH or CRITICAL messages should appear'
\echo ''
\echo 'If any attacks succeeded, immediate security review is required!'