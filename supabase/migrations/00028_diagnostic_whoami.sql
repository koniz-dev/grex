-- ============================================================================
-- Migration: Diagnostic whoami() function
-- Version: 00028
-- Description: Returns the auth.uid() and current_role as PostgREST sees
--              them for the calling JWT. Used to debug RLS rejections where
--              the Flutter side looks correct but the policy still fails.
--              Remove after diagnosis is complete.
-- ============================================================================

CREATE OR REPLACE FUNCTION public.whoami()
RETURNS TABLE (
  uid uuid,
  role text,
  email text,
  jwt_role text
)
LANGUAGE sql
STABLE
SECURITY INVOKER
AS $$
  SELECT
    auth.uid() AS uid,
    current_setting('role', true) AS role,
    current_setting('request.jwt.claim.email', true) AS email,
    current_setting('request.jwt.claim.role', true) AS jwt_role;
$$;

GRANT EXECUTE ON FUNCTION public.whoami() TO authenticated;
GRANT EXECUTE ON FUNCTION public.whoami() TO anon;
