-- ============================================================================
-- Migration: create_group_with_owner RPC
-- Version: 00029
-- Description: Single-call atomic group creation. The Flutter client kept
--              hitting RLS rejections doing two sequential INSERTs (groups
--              then group_members) under the JWT context; whoami() confirmed
--              auth.uid() returned the correct UUID and role=authenticated
--              yet the groups INSERT still failed with
--              "new row violates row-level security policy". Wrapping both
--              inserts in a SECURITY DEFINER RPC sidesteps the issue and is
--              the canonical Supabase pattern for "create entity + own first
--              membership" flows. The function still validates auth.uid()
--              itself so anonymous callers can't create rows.
-- ============================================================================

CREATE OR REPLACE FUNCTION public.create_group_with_owner(
  p_name TEXT,
  p_currency TEXT,
  p_description TEXT DEFAULT NULL,
  p_owner_display_name TEXT DEFAULT 'Administrator'
)
RETURNS uuid
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  uid uuid := auth.uid();
  new_group_id uuid;
BEGIN
  IF uid IS NULL THEN
    RAISE EXCEPTION 'Not authenticated' USING ERRCODE = '42501';
  END IF;

  INSERT INTO groups (name, currency, creator_id, description)
  VALUES (p_name, upper(p_currency), uid, p_description)
  RETURNING id INTO new_group_id;

  INSERT INTO group_members (group_id, user_id, display_name, role)
  VALUES (new_group_id, uid, p_owner_display_name, 'administrator');

  RETURN new_group_id;
END;
$$;

GRANT EXECUTE ON FUNCTION public.create_group_with_owner(
  TEXT, TEXT, TEXT, TEXT
) TO authenticated;

COMMENT ON FUNCTION public.create_group_with_owner(
  TEXT, TEXT, TEXT, TEXT
) IS
'Atomic group creation: inserts a groups row with the caller as creator and a group_members row as administrator. SECURITY DEFINER bypasses RLS for both writes; the function still requires a non-null auth.uid() so the caller must be authenticated.';
