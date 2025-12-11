-- ============================================================================
-- Migration: Create Database Triggers
-- Version: 00010
-- Description: Create database triggers for timestamp management and audit logging
-- ============================================================================

-- ============================================================================
-- Trigger Function 1: set_timestamps (for tables with both created_at and updated_at)
-- Description: Set created_at and updated_at timestamps automatically
-- Requirements: 9.1, 9.2
-- ============================================================================

CREATE OR REPLACE FUNCTION set_timestamps()
RETURNS TRIGGER AS $$
BEGIN
  IF TG_OP = 'INSERT' THEN
    -- Set both timestamps on insert
    NEW.created_at = NOW();
    NEW.updated_at = NOW();
  ELSIF TG_OP = 'UPDATE' THEN
    -- Prevent modification of created_at on updates
    NEW.created_at = OLD.created_at;
    -- Update updated_at on updates (use clock_timestamp for real-time updates)
    NEW.updated_at = clock_timestamp();
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- ============================================================================
-- Trigger Function 2: set_created_at_only (for tables with only created_at)
-- Description: Set only created_at timestamp automatically
-- Requirements: 9.1, 9.2
-- ============================================================================

CREATE OR REPLACE FUNCTION set_created_at_only()
RETURNS TRIGGER AS $$
BEGIN
  IF TG_OP = 'INSERT' THEN
    -- Set created_at on insert
    NEW.created_at = NOW();
  ELSIF TG_OP = 'UPDATE' THEN
    -- Prevent modification of created_at on updates
    NEW.created_at = OLD.created_at;
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- ============================================================================
-- Trigger Function 3: set_group_member_timestamps (for group_members table)
-- Description: Set joined_at and updated_at timestamps for group_members
-- Requirements: 9.1, 9.2
-- ============================================================================

CREATE OR REPLACE FUNCTION set_group_member_timestamps()
RETURNS TRIGGER AS $$
BEGIN
  IF TG_OP = 'INSERT' THEN
    -- Set both timestamps on insert
    NEW.joined_at = NOW();
    NEW.updated_at = NOW();
  ELSIF TG_OP = 'UPDATE' THEN
    -- Prevent modification of joined_at on updates
    NEW.joined_at = OLD.joined_at;
    -- Update updated_at on updates
    NEW.updated_at = clock_timestamp();
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Add function comments
COMMENT ON FUNCTION set_timestamps() IS 
'Trigger function to automatically set created_at and updated_at timestamps. Prevents modification of created_at on updates.';

COMMENT ON FUNCTION set_created_at_only() IS 
'Trigger function to automatically set only created_at timestamp. Prevents modification of created_at on updates.';

COMMENT ON FUNCTION set_group_member_timestamps() IS 
'Trigger function to automatically set joined_at and updated_at timestamps for group_members table.';

-- ============================================================================
-- Apply timestamp triggers to all relevant tables
-- ============================================================================

-- Drop existing timestamp triggers if they exist (for idempotency)
DROP TRIGGER IF EXISTS set_users_timestamps ON users;
DROP TRIGGER IF EXISTS set_groups_timestamps ON groups;
DROP TRIGGER IF EXISTS set_group_members_timestamps ON group_members;
DROP TRIGGER IF EXISTS set_expenses_timestamps ON expenses;
DROP TRIGGER IF EXISTS set_expense_participants_timestamps ON expense_participants;
DROP TRIGGER IF EXISTS set_payments_timestamps ON payments;

-- Apply to users table (has both created_at and updated_at)
CREATE TRIGGER set_users_timestamps
  BEFORE INSERT OR UPDATE ON users
  FOR EACH ROW EXECUTE FUNCTION set_timestamps();

-- Apply to groups table (has both created_at and updated_at)
CREATE TRIGGER set_groups_timestamps
  BEFORE INSERT OR UPDATE ON groups
  FOR EACH ROW EXECUTE FUNCTION set_timestamps();

-- Apply to group_members table (has joined_at and updated_at)
CREATE TRIGGER set_group_members_timestamps
  BEFORE INSERT OR UPDATE ON group_members
  FOR EACH ROW EXECUTE FUNCTION set_group_member_timestamps();

-- Apply to expenses table (has both created_at and updated_at)
CREATE TRIGGER set_expenses_timestamps
  BEFORE INSERT OR UPDATE ON expenses
  FOR EACH ROW EXECUTE FUNCTION set_timestamps();

-- Apply to expense_participants table (has only created_at)
CREATE TRIGGER set_expense_participants_timestamps
  BEFORE INSERT OR UPDATE ON expense_participants
  FOR EACH ROW EXECUTE FUNCTION set_created_at_only();

-- Apply to payments table (has only created_at)
CREATE TRIGGER set_payments_timestamps
  BEFORE INSERT OR UPDATE ON payments
  FOR EACH ROW EXECUTE FUNCTION set_created_at_only();

-- Note: audit_logs table already has its own specialized timestamp trigger
-- ============================================================================
-- Audit Trigger Functions
-- Description: Create audit triggers for tracking data changes
-- Requirements: 9.3, 9.4, 9.5
-- ============================================================================

-- ============================================================================
-- Audit Trigger Function 1: audit_expense_changes
-- Description: Create audit logs for expense INSERT, UPDATE, DELETE operations
-- Requirements: 9.3
-- ============================================================================

CREATE OR REPLACE FUNCTION audit_expense_changes()
RETURNS TRIGGER AS $$
DECLARE
  user_email_val TEXT;
  user_display_name_val TEXT;
  group_name_val TEXT;
BEGIN
  -- Get user context (email and display name for forensics)
  IF TG_OP = 'DELETE' THEN
    SELECT u.email, u.display_name INTO user_email_val, user_display_name_val
    FROM users u WHERE u.id = OLD.payer_id;
    
    -- If user not found (deleted), use placeholder values
    IF user_email_val IS NULL THEN
      user_email_val := 'deleted_user@unknown.com';
      user_display_name_val := 'Deleted User';
    END IF;
    
    SELECT g.name INTO group_name_val
    FROM groups g WHERE g.id = OLD.group_id;
    
    -- If group not found (deleted), use placeholder value
    IF group_name_val IS NULL THEN
      group_name_val := 'Deleted Group';
    END IF;
  ELSE
    SELECT u.email, u.display_name INTO user_email_val, user_display_name_val
    FROM users u WHERE u.id = NEW.payer_id;
    
    -- If user not found (deleted), use placeholder values
    IF user_email_val IS NULL THEN
      user_email_val := 'deleted_user@unknown.com';
      user_display_name_val := 'Deleted User';
    END IF;
    
    SELECT g.name INTO group_name_val
    FROM groups g WHERE g.id = NEW.group_id;
    
    -- If group not found (deleted), use placeholder value
    IF group_name_val IS NULL THEN
      group_name_val := 'Deleted Group';
    END IF;
  END IF;
  
  -- Handle different operations
  IF TG_OP = 'INSERT' THEN
    INSERT INTO audit_logs (
      entity_type, entity_id, action,
      user_id, user_email, user_display_name,
      group_id, group_name,
      after_state
    ) VALUES (
      'expense', NEW.id, 'create',
      NEW.payer_id, user_email_val, user_display_name_val,
      NEW.group_id, group_name_val,
      jsonb_build_object(
        'amount', NEW.amount,
        'currency', NEW.currency,
        'description', NEW.description,
        'expense_date', NEW.expense_date,
        'payer_id', NEW.payer_id,
        'group_id', NEW.group_id
      )
    );
    RETURN NEW;
    
  ELSIF TG_OP = 'UPDATE' THEN
    INSERT INTO audit_logs (
      entity_type, entity_id, action,
      user_id, user_email, user_display_name,
      group_id, group_name,
      before_state, after_state
    ) VALUES (
      'expense', NEW.id, 'update',
      NEW.payer_id, user_email_val, user_display_name_val,
      NEW.group_id, group_name_val,
      jsonb_build_object(
        'amount', OLD.amount,
        'currency', OLD.currency,
        'description', OLD.description,
        'expense_date', OLD.expense_date,
        'payer_id', OLD.payer_id,
        'group_id', OLD.group_id
      ),
      jsonb_build_object(
        'amount', NEW.amount,
        'currency', NEW.currency,
        'description', NEW.description,
        'expense_date', NEW.expense_date,
        'payer_id', NEW.payer_id,
        'group_id', NEW.group_id
      )
    );
    RETURN NEW;
    
  ELSIF TG_OP = 'DELETE' THEN
    INSERT INTO audit_logs (
      entity_type, entity_id, action,
      user_id, user_email, user_display_name,
      group_id, group_name,
      before_state
    ) VALUES (
      'expense', OLD.id, 'delete',
      CASE WHEN user_email_val = 'deleted_user@unknown.com' THEN NULL ELSE OLD.payer_id END,
      user_email_val, user_display_name_val,
      CASE WHEN group_name_val = 'Deleted Group' THEN NULL ELSE OLD.group_id END,
      group_name_val,
      jsonb_build_object(
        'amount', OLD.amount,
        'currency', OLD.currency,
        'description', OLD.description,
        'expense_date', OLD.expense_date,
        'payer_id', OLD.payer_id,
        'group_id', OLD.group_id
      )
    );
    RETURN OLD;
  END IF;
  
  RETURN NULL;
END;
$$ LANGUAGE plpgsql;

-- Add function comment
COMMENT ON FUNCTION audit_expense_changes() IS 
'Trigger function to create audit logs for all expense changes (INSERT, UPDATE, DELETE).';

-- Apply audit trigger to expenses table
CREATE TRIGGER audit_expense_changes
  AFTER INSERT OR UPDATE OR DELETE ON expenses
  FOR EACH ROW EXECUTE FUNCTION audit_expense_changes();
-- ============================================================================
-- Audit Trigger Function 2: audit_payment_changes
-- Description: Create audit logs for payment INSERT, DELETE operations
-- Requirements: 9.4
-- ============================================================================

CREATE OR REPLACE FUNCTION audit_payment_changes()
RETURNS TRIGGER AS $$
DECLARE
  payer_email_val TEXT;
  payer_display_name_val TEXT;
  recipient_email_val TEXT;
  recipient_display_name_val TEXT;
  group_name_val TEXT;
BEGIN
  -- Get user and group context (email and display name for forensics)
  IF TG_OP = 'DELETE' THEN
    -- Get payer info
    SELECT u.email, u.display_name INTO payer_email_val, payer_display_name_val
    FROM users u WHERE u.id = OLD.payer_id;
    
    -- Get recipient info
    SELECT u.email, u.display_name INTO recipient_email_val, recipient_display_name_val
    FROM users u WHERE u.id = OLD.recipient_id;
    
    -- Get group info
    SELECT g.name INTO group_name_val
    FROM groups g WHERE g.id = OLD.group_id;
    
    -- Handle deleted entities with placeholder values
    IF payer_email_val IS NULL THEN
      payer_email_val := 'deleted_user@unknown.com';
      payer_display_name_val := 'Deleted User';
    END IF;
    
    IF recipient_email_val IS NULL THEN
      recipient_email_val := 'deleted_user@unknown.com';
      recipient_display_name_val := 'Deleted User';
    END IF;
    
    IF group_name_val IS NULL THEN
      group_name_val := 'Deleted Group';
    END IF;
  ELSE
    -- Get payer info
    SELECT u.email, u.display_name INTO payer_email_val, payer_display_name_val
    FROM users u WHERE u.id = NEW.payer_id;
    
    -- Get recipient info
    SELECT u.email, u.display_name INTO recipient_email_val, recipient_display_name_val
    FROM users u WHERE u.id = NEW.recipient_id;
    
    -- Get group info
    SELECT g.name INTO group_name_val
    FROM groups g WHERE g.id = NEW.group_id;
    
    -- Handle deleted entities with placeholder values
    IF payer_email_val IS NULL THEN
      payer_email_val := 'deleted_user@unknown.com';
      payer_display_name_val := 'Deleted User';
    END IF;
    
    IF recipient_email_val IS NULL THEN
      recipient_email_val := 'deleted_user@unknown.com';
      recipient_display_name_val := 'Deleted User';
    END IF;
    
    IF group_name_val IS NULL THEN
      group_name_val := 'Deleted Group';
    END IF;
  END IF;
  
  -- Handle different operations (payments only support INSERT and DELETE)
  IF TG_OP = 'INSERT' THEN
    INSERT INTO audit_logs (
      entity_type, entity_id, action,
      user_id, user_email, user_display_name,
      group_id, group_name,
      after_state
    ) VALUES (
      'payment', NEW.id, 'create',
      NEW.payer_id, payer_email_val, payer_display_name_val,
      NEW.group_id, group_name_val,
      jsonb_build_object(
        'amount', NEW.amount,
        'currency', NEW.currency,
        'payment_date', NEW.payment_date,
        'notes', NEW.notes,
        'payer_id', NEW.payer_id,
        'recipient_id', NEW.recipient_id,
        'recipient_email', recipient_email_val,
        'recipient_display_name', recipient_display_name_val,
        'group_id', NEW.group_id
      )
    );
    RETURN NEW;
    
  ELSIF TG_OP = 'DELETE' THEN
    INSERT INTO audit_logs (
      entity_type, entity_id, action,
      user_id, user_email, user_display_name,
      group_id, group_name,
      before_state
    ) VALUES (
      'payment', OLD.id, 'delete',
      CASE WHEN payer_email_val = 'deleted_user@unknown.com' THEN NULL ELSE OLD.payer_id END,
      payer_email_val, payer_display_name_val,
      CASE WHEN group_name_val = 'Deleted Group' THEN NULL ELSE OLD.group_id END,
      group_name_val,
      jsonb_build_object(
        'amount', OLD.amount,
        'currency', OLD.currency,
        'payment_date', OLD.payment_date,
        'notes', OLD.notes,
        'payer_id', OLD.payer_id,
        'recipient_id', OLD.recipient_id,
        'recipient_email', recipient_email_val,
        'recipient_display_name', recipient_display_name_val,
        'group_id', OLD.group_id
      )
    );
    RETURN OLD;
  END IF;
  
  RETURN NULL;
END;
$$ LANGUAGE plpgsql;

-- Add function comment
COMMENT ON FUNCTION audit_payment_changes() IS 
'Trigger function to create audit logs for all payment changes (INSERT, DELETE). Payments do not support UPDATE operations.';

-- Apply audit trigger to payments table
CREATE TRIGGER audit_payment_changes
  AFTER INSERT OR DELETE ON payments
  FOR EACH ROW EXECUTE FUNCTION audit_payment_changes();
-- ============================================================================
-- Audit Trigger Function 3: audit_membership_changes
-- Description: Create audit logs for group_members INSERT, UPDATE, DELETE operations
-- Requirements: 9.5
-- ============================================================================

CREATE OR REPLACE FUNCTION audit_membership_changes()
RETURNS TRIGGER AS $$
DECLARE
  user_email_val TEXT;
  user_display_name_val TEXT;
  group_name_val TEXT;
  acting_user_id UUID;
  acting_user_email TEXT;
  acting_user_display_name TEXT;
  old_user_email TEXT;
  old_user_display_name TEXT;
BEGIN
  -- For membership changes, we need to determine who is performing the action
  -- This is tricky because the trigger doesn't know the current user context
  -- We'll use the user being added/modified as the actor for now
  -- In a real application, this would come from the application context
  
  -- Get user and group context
  IF TG_OP = 'DELETE' THEN
    -- Get member info
    SELECT u.email, u.display_name INTO user_email_val, user_display_name_val
    FROM users u WHERE u.id = OLD.user_id;
    
    -- Get group info
    SELECT g.name INTO group_name_val
    FROM groups g WHERE g.id = OLD.group_id;
    
    -- For DELETE, the acting user is unknown, so we use the member being removed
    acting_user_id := OLD.user_id;
    acting_user_email := user_email_val;
    acting_user_display_name := user_display_name_val;
    
    -- Handle deleted entities
    IF user_email_val IS NULL THEN
      user_email_val := 'deleted_user@unknown.com';
      user_display_name_val := 'Deleted User';
      acting_user_email := 'deleted_user@unknown.com';
      acting_user_display_name := 'Deleted User';
    END IF;
    
    IF group_name_val IS NULL THEN
      group_name_val := 'Deleted Group';
    END IF;
  ELSE
    -- Get member info
    SELECT u.email, u.display_name INTO user_email_val, user_display_name_val
    FROM users u WHERE u.id = NEW.user_id;
    
    -- Get group info
    SELECT g.name INTO group_name_val
    FROM groups g WHERE g.id = NEW.group_id;
    
    -- For INSERT/UPDATE, assume the user being added/modified is the actor
    acting_user_id := NEW.user_id;
    acting_user_email := user_email_val;
    acting_user_display_name := user_display_name_val;
    
    -- Handle deleted entities
    IF user_email_val IS NULL THEN
      user_email_val := 'deleted_user@unknown.com';
      user_display_name_val := 'Deleted User';
      acting_user_email := 'deleted_user@unknown.com';
      acting_user_display_name := 'Deleted User';
    END IF;
    
    IF group_name_val IS NULL THEN
      group_name_val := 'Deleted Group';
    END IF;
  END IF;
  
  -- Handle different operations
  IF TG_OP = 'INSERT' THEN
    INSERT INTO audit_logs (
      entity_type, entity_id, action,
      user_id, user_email, user_display_name,
      group_id, group_name,
      after_state
    ) VALUES (
      'group_member', NEW.id, 'create',
      acting_user_id, acting_user_email, acting_user_display_name,
      NEW.group_id, group_name_val,
      jsonb_build_object(
        'user_id', NEW.user_id,
        'user_email', user_email_val,
        'user_display_name', user_display_name_val,
        'group_id', NEW.group_id,
        'role', NEW.role,
        'joined_at', NEW.joined_at
      )
    );
    RETURN NEW;
    
  ELSIF TG_OP = 'UPDATE' THEN
    -- Get old user info for comparison
    SELECT u.email, u.display_name INTO old_user_email, old_user_display_name
    FROM users u WHERE u.id = OLD.user_id;
    
    IF old_user_email IS NULL THEN
      old_user_email := 'deleted_user@unknown.com';
      old_user_display_name := 'Deleted User';
    END IF;
    
    INSERT INTO audit_logs (
      entity_type, entity_id, action,
      user_id, user_email, user_display_name,
      group_id, group_name,
      before_state, after_state
    ) VALUES (
      'group_member', NEW.id, 'update',
      acting_user_id, acting_user_email, acting_user_display_name,
      NEW.group_id, group_name_val,
      jsonb_build_object(
        'user_id', OLD.user_id,
        'user_email', old_user_email,
        'user_display_name', old_user_display_name,
        'group_id', OLD.group_id,
        'role', OLD.role,
        'joined_at', OLD.joined_at,
        'updated_at', OLD.updated_at
      ),
      jsonb_build_object(
        'user_id', NEW.user_id,
        'user_email', user_email_val,
        'user_display_name', user_display_name_val,
        'group_id', NEW.group_id,
        'role', NEW.role,
        'joined_at', NEW.joined_at,
        'updated_at', NEW.updated_at
      )
    );
    RETURN NEW;
    
  ELSIF TG_OP = 'DELETE' THEN
    INSERT INTO audit_logs (
      entity_type, entity_id, action,
      user_id, user_email, user_display_name,
      group_id, group_name,
      before_state
    ) VALUES (
      'group_member', OLD.id, 'delete',
      CASE WHEN acting_user_email = 'deleted_user@unknown.com' THEN NULL ELSE acting_user_id END,
      acting_user_email, acting_user_display_name,
      CASE WHEN group_name_val = 'Deleted Group' THEN NULL ELSE OLD.group_id END,
      group_name_val,
      jsonb_build_object(
        'user_id', OLD.user_id,
        'user_email', user_email_val,
        'user_display_name', user_display_name_val,
        'group_id', OLD.group_id,
        'role', OLD.role,
        'joined_at', OLD.joined_at,
        'updated_at', OLD.updated_at
      )
    );
    RETURN OLD;
  END IF;
  
  RETURN NULL;
END;
$$ LANGUAGE plpgsql;

-- Add function comment
COMMENT ON FUNCTION audit_membership_changes() IS 
'Trigger function to create audit logs for all group membership changes (INSERT, UPDATE, DELETE).';

-- Apply audit trigger to group_members table
CREATE TRIGGER audit_membership_changes
  AFTER INSERT OR UPDATE OR DELETE ON group_members
  FOR EACH ROW EXECUTE FUNCTION audit_membership_changes();