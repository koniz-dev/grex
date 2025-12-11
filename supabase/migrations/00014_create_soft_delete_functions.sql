-- Migration: Create Soft Delete Helper Functions
-- Description: Implement soft delete functionality with helper functions for all tables
-- Requirements: 15.1, 15.3, 15.4

-- Create function to soft delete a user
CREATE OR REPLACE FUNCTION soft_delete_user(user_id_param UUID)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    -- Update the user's deleted_at timestamp
    UPDATE users 
    SET deleted_at = NOW()
    WHERE id = user_id_param AND deleted_at IS NULL;
    
    -- Return true if a row was updated
    RETURN FOUND;
END;
$$;

-- Create function to restore a soft-deleted user
CREATE OR REPLACE FUNCTION restore_user(user_id_param UUID)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    -- Clear the deleted_at timestamp
    UPDATE users 
    SET deleted_at = NULL
    WHERE id = user_id_param AND deleted_at IS NOT NULL;
    
    -- Return true if a row was updated
    RETURN FOUND;
END;
$$;

-- Create function to hard delete a soft-deleted user
CREATE OR REPLACE FUNCTION hard_delete_user(user_id_param UUID)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    -- Permanently delete the user (only if already soft-deleted)
    DELETE FROM users 
    WHERE id = user_id_param AND deleted_at IS NOT NULL;
    
    -- Return true if a row was deleted
    RETURN FOUND;
END;
$$;

-- Create function to soft delete a group
CREATE OR REPLACE FUNCTION soft_delete_group(group_id_param UUID)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    -- Update the group's deleted_at timestamp
    UPDATE groups 
    SET deleted_at = NOW()
    WHERE id = group_id_param AND deleted_at IS NULL;
    
    -- Return true if a row was updated
    RETURN FOUND;
END;
$$;

-- Create function to restore a soft-deleted group
CREATE OR REPLACE FUNCTION restore_group(group_id_param UUID)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    -- Clear the deleted_at timestamp
    UPDATE groups 
    SET deleted_at = NULL
    WHERE id = group_id_param AND deleted_at IS NOT NULL;
    
    -- Return true if a row was updated
    RETURN FOUND;
END;
$$;

-- Create function to hard delete a soft-deleted group
CREATE OR REPLACE FUNCTION hard_delete_group(group_id_param UUID)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    -- Permanently delete the group (only if already soft-deleted)
    DELETE FROM groups 
    WHERE id = group_id_param AND deleted_at IS NOT NULL;
    
    -- Return true if a row was deleted
    RETURN FOUND;
END;
$$;

-- Create function to soft delete an expense
CREATE OR REPLACE FUNCTION soft_delete_expense(expense_id_param UUID)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    -- Update the expense's deleted_at timestamp
    UPDATE expenses 
    SET deleted_at = NOW()
    WHERE id = expense_id_param AND deleted_at IS NULL;
    
    -- Return true if a row was updated
    RETURN FOUND;
END;
$$;

-- Create function to restore a soft-deleted expense
CREATE OR REPLACE FUNCTION restore_expense(expense_id_param UUID)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    -- Clear the deleted_at timestamp
    UPDATE expenses 
    SET deleted_at = NULL
    WHERE id = expense_id_param AND deleted_at IS NOT NULL;
    
    -- Return true if a row was updated
    RETURN FOUND;
END;
$$;

-- Create function to hard delete a soft-deleted expense
CREATE OR REPLACE FUNCTION hard_delete_expense(expense_id_param UUID)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    -- Permanently delete the expense (only if already soft-deleted)
    DELETE FROM expenses 
    WHERE id = expense_id_param AND deleted_at IS NOT NULL;
    
    -- Return true if a row was deleted
    RETURN FOUND;
END;
$$;

-- Create function to soft delete a payment
CREATE OR REPLACE FUNCTION soft_delete_payment(payment_id_param UUID)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    -- Update the payment's deleted_at timestamp
    UPDATE payments 
    SET deleted_at = NOW()
    WHERE id = payment_id_param AND deleted_at IS NULL;
    
    -- Return true if a row was updated
    RETURN FOUND;
END;
$$;

-- Create function to restore a soft-deleted payment
CREATE OR REPLACE FUNCTION restore_payment(payment_id_param UUID)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    -- Clear the deleted_at timestamp
    UPDATE payments 
    SET deleted_at = NULL
    WHERE id = payment_id_param AND deleted_at IS NOT NULL;
    
    -- Return true if a row was updated
    RETURN FOUND;
END;
$$;

-- Create function to hard delete a soft-deleted payment
CREATE OR REPLACE FUNCTION hard_delete_payment(payment_id_param UUID)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    -- Permanently delete the payment (only if already soft-deleted)
    DELETE FROM payments 
    WHERE id = payment_id_param AND deleted_at IS NOT NULL;
    
    -- Return true if a row was deleted
    RETURN FOUND;
END;
$$;

-- Create generic function to get active records (excluding soft-deleted)
CREATE OR REPLACE FUNCTION get_active_users()
RETURNS TABLE(
    id UUID,
    email TEXT,
    display_name TEXT,
    avatar_url TEXT,
    preferred_currency TEXT,
    preferred_language TEXT,
    created_at TIMESTAMPTZ,
    updated_at TIMESTAMPTZ
)
LANGUAGE sql
STABLE
AS $$
    SELECT id, email, display_name, avatar_url, preferred_currency, preferred_language, created_at, updated_at
    FROM users 
    WHERE deleted_at IS NULL;
$$;

-- Create function to get active groups
CREATE OR REPLACE FUNCTION get_active_groups()
RETURNS TABLE(
    id UUID,
    name TEXT,
    description TEXT,
    creator_id UUID,
    primary_currency TEXT,
    created_at TIMESTAMPTZ,
    updated_at TIMESTAMPTZ
)
LANGUAGE sql
STABLE
AS $$
    SELECT id, name, description, creator_id, primary_currency, created_at, updated_at
    FROM groups 
    WHERE deleted_at IS NULL;
$$;

-- Create function to get active expenses for a group
CREATE OR REPLACE FUNCTION get_active_expenses(group_id_param UUID)
RETURNS TABLE(
    id UUID,
    group_id UUID,
    payer_id UUID,
    description TEXT,
    amount NUMERIC(15,2),
    currency TEXT,
    expense_date DATE,
    split_method split_method,
    created_at TIMESTAMPTZ,
    updated_at TIMESTAMPTZ
)
LANGUAGE sql
STABLE
AS $$
    SELECT id, group_id, payer_id, description, amount, currency, expense_date, split_method, created_at, updated_at
    FROM expenses 
    WHERE group_id = group_id_param AND deleted_at IS NULL;
$$;

-- Create function to get active payments for a group
CREATE OR REPLACE FUNCTION get_active_payments(group_id_param UUID)
RETURNS TABLE(
    id UUID,
    group_id UUID,
    payer_id UUID,
    recipient_id UUID,
    amount NUMERIC(15,2),
    currency TEXT,
    payment_date DATE,
    created_at TIMESTAMPTZ
)
LANGUAGE sql
STABLE
AS $$
    SELECT id, group_id, payer_id, recipient_id, amount, currency, payment_date, created_at
    FROM payments 
    WHERE group_id = group_id_param AND deleted_at IS NULL;
$$;

-- Add comments for documentation
COMMENT ON FUNCTION soft_delete_user(UUID) IS 'Soft deletes a user by setting deleted_at timestamp';
COMMENT ON FUNCTION restore_user(UUID) IS 'Restores a soft-deleted user by clearing deleted_at timestamp';
COMMENT ON FUNCTION hard_delete_user(UUID) IS 'Permanently deletes a soft-deleted user';
COMMENT ON FUNCTION soft_delete_group(UUID) IS 'Soft deletes a group by setting deleted_at timestamp';
COMMENT ON FUNCTION restore_group(UUID) IS 'Restores a soft-deleted group by clearing deleted_at timestamp';
COMMENT ON FUNCTION hard_delete_group(UUID) IS 'Permanently deletes a soft-deleted group';
COMMENT ON FUNCTION soft_delete_expense(UUID) IS 'Soft deletes an expense by setting deleted_at timestamp';
COMMENT ON FUNCTION restore_expense(UUID) IS 'Restores a soft-deleted expense by clearing deleted_at timestamp';
COMMENT ON FUNCTION hard_delete_expense(UUID) IS 'Permanently deletes a soft-deleted expense';
COMMENT ON FUNCTION soft_delete_payment(UUID) IS 'Soft deletes a payment by setting deleted_at timestamp';
COMMENT ON FUNCTION restore_payment(UUID) IS 'Restores a soft-deleted payment by clearing deleted_at timestamp';
COMMENT ON FUNCTION hard_delete_payment(UUID) IS 'Permanently deletes a soft-deleted payment';
COMMENT ON FUNCTION get_active_users() IS 'Returns all users that are not soft-deleted';
COMMENT ON FUNCTION get_active_groups() IS 'Returns all groups that are not soft-deleted';
COMMENT ON FUNCTION get_active_expenses(UUID) IS 'Returns all expenses for a group that are not soft-deleted';
COMMENT ON FUNCTION get_active_payments(UUID) IS 'Returns all payments for a group that are not soft-deleted';