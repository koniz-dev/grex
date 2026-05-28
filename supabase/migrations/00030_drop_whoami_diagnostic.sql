-- ============================================================================
-- Migration: Drop diagnostic whoami() function
-- Version: 00030
-- Description: 00028 added whoami() to debug an RLS rejection where the
--              JWT context looked correct but groups INSERT still failed.
--              The bug was sidestepped by routing creation through the
--              SECURITY DEFINER `create_group_with_owner` RPC (migration
--              00029), so the diagnostic helper is no longer needed and
--              shouldn't ship to production.
-- ============================================================================

DROP FUNCTION IF EXISTS public.whoami();
