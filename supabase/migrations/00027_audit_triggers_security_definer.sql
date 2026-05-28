-- ============================================================================
-- Migration: SECURITY DEFINER for audit trigger functions
-- Version: 00027
-- Description: 00010 defines audit_expense_changes / audit_payment_changes /
--              audit_membership_changes as plain SECURITY INVOKER functions,
--              so trigger-driven INSERTs into audit_logs run with the
--              caller's RLS context. 00011 set
--              `audit_logs_no_manual_insert WITH CHECK (false)` to block
--              direct client inserts — which also blocks the triggers,
--              causing operations like creating a group ("INSERT into
--              group_members fires audit_membership_changes") to fail with
--              "Access denied".
--
-- Promote the audit functions to SECURITY DEFINER so the INSERT runs as the
-- function owner (postgres) and bypasses the audit_logs RLS check. The
-- search_path is pinned to public to avoid trojan-schema attacks per the
-- standard Supabase SECURITY DEFINER pattern.
-- ============================================================================

ALTER FUNCTION audit_expense_changes()
  SECURITY DEFINER
  SET search_path = public;

ALTER FUNCTION audit_payment_changes()
  SECURITY DEFINER
  SET search_path = public;

ALTER FUNCTION audit_membership_changes()
  SECURITY DEFINER
  SET search_path = public;

COMMENT ON FUNCTION audit_expense_changes() IS
'Audit trigger for expenses. SECURITY DEFINER so trigger-driven INSERT INTO audit_logs bypasses the no-manual-insert RLS policy.';
COMMENT ON FUNCTION audit_payment_changes() IS
'Audit trigger for payments. SECURITY DEFINER so trigger-driven INSERT INTO audit_logs bypasses the no-manual-insert RLS policy.';
COMMENT ON FUNCTION audit_membership_changes() IS
'Audit trigger for group memberships. SECURITY DEFINER so trigger-driven INSERT INTO audit_logs bypasses the no-manual-insert RLS policy.';
