-- Migration: Fix search_path for all functions
-- Description: Set search_path for all functions to prevent security vulnerabilities
-- Author: System
-- Date: 2025-01-25

-- Fix search_path for all functions by adding SET search_path = public
-- This prevents SQL injection attacks through search_path manipulation

-- Soft delete functions (with parameter names)
ALTER FUNCTION soft_delete_user(user_id_param UUID) SET search_path = public;
ALTER FUNCTION restore_user(user_id_param UUID) SET search_path = public;
ALTER FUNCTION hard_delete_user(user_id_param UUID) SET search_path = public;
ALTER FUNCTION soft_delete_group(group_id_param UUID) SET search_path = public;
ALTER FUNCTION restore_group(group_id_param UUID) SET search_path = public;
ALTER FUNCTION hard_delete_group(group_id_param UUID) SET search_path = public;
ALTER FUNCTION soft_delete_expense(expense_id_param UUID) SET search_path = public;
ALTER FUNCTION restore_expense(expense_id_param UUID) SET search_path = public;
ALTER FUNCTION hard_delete_expense(expense_id_param UUID) SET search_path = public;
ALTER FUNCTION soft_delete_payment(payment_id_param UUID) SET search_path = public;
ALTER FUNCTION restore_payment(payment_id_param UUID) SET search_path = public;
ALTER FUNCTION hard_delete_payment(payment_id_param UUID) SET search_path = public;

-- Get active functions
ALTER FUNCTION get_active_users() SET search_path = public;
ALTER FUNCTION get_active_groups() SET search_path = public;
ALTER FUNCTION get_active_expenses(group_id_param UUID) SET search_path = public;
ALTER FUNCTION get_active_payments(group_id_param UUID) SET search_path = public;

-- Migration management functions
ALTER FUNCTION record_migration(p_migration_name TEXT, p_version TEXT, p_description TEXT, p_execution_time_ms INTEGER, p_checksum TEXT, p_success BOOLEAN, p_error_message TEXT) SET search_path = public;
ALTER FUNCTION is_migration_applied(p_migration_name TEXT) SET search_path = public;
ALTER FUNCTION get_migration_status() SET search_path = public;
ALTER FUNCTION validate_migration_order(p_version TEXT) SET search_path = public;
ALTER FUNCTION verify_schema_integrity() SET search_path = public;
ALTER FUNCTION rollback_last_migration() SET search_path = public;

-- Business logic functions
ALTER FUNCTION calculate_group_balances(p_group_id UUID) SET search_path = public;
ALTER FUNCTION validate_expense_split(p_expense_id UUID) SET search_path = public;
ALTER FUNCTION generate_settlement_plan(p_group_id UUID) SET search_path = public;
ALTER FUNCTION check_user_permission(p_user_id UUID, p_group_id UUID, p_required_role TEXT) SET search_path = public;

-- Currency functions
ALTER FUNCTION validate_currency_code(currency_code TEXT) SET search_path = public;
ALTER FUNCTION get_currency_decimal_places(currency_code TEXT) SET search_path = public;
ALTER FUNCTION format_currency_amount(amount DECIMAL, currency_code TEXT) SET search_path = public;

-- Trigger functions (no parameters)
ALTER FUNCTION set_timestamps() SET search_path = public;
ALTER FUNCTION set_created_at_only() SET search_path = public;
ALTER FUNCTION set_group_member_timestamps() SET search_path = public;
ALTER FUNCTION set_group_members_timestamps() SET search_path = public;
ALTER FUNCTION set_expense_participants_timestamps() SET search_path = public;
ALTER FUNCTION set_payments_timestamps() SET search_path = public;
ALTER FUNCTION set_audit_logs_timestamps() SET search_path = public;
ALTER FUNCTION audit_expense_changes() SET search_path = public;
ALTER FUNCTION audit_payment_changes() SET search_path = public;
ALTER FUNCTION audit_membership_changes() SET search_path = public;

-- Add comment explaining the security fix
COMMENT ON SCHEMA public IS 'All functions have been secured with fixed search_path to prevent SQL injection attacks through search_path manipulation.';