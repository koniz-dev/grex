-- ============================================================================
-- Migration: Fix RLS Infinite Recursion
-- Version: 00022
-- Description: Fix infinite recursion in users and group_members RLS policies
-- Solution: Use SECURITY DEFINER functions to bypass RLS in policy checks
-- Reference: https://github.com/orgs/supabase/discussions/3328
-- ============================================================================

-- ============================================================================
-- Create helper functions with SECURITY DEFINER
-- These functions bypass RLS when called from policies
-- ============================================================================

-- Function to check if user is member of a specific group
CREATE OR REPLACE FUNCTION auth_is_group_member(_user_id uuid, _group_id uuid)
RETURNS boolean
LANGUAGE sql
SECURITY DEFINER
STABLE
SET search_path = public
AS $$
  SELECT EXISTS (
    SELECT 1
    FROM group_members
    WHERE user_id = _user_id
      AND group_id = _group_id
  );
$$;

-- Function to get all group IDs for a user
CREATE OR REPLACE FUNCTION auth_get_user_groups(_user_id uuid)
RETURNS SETOF uuid
LANGUAGE sql
SECURITY DEFINER
STABLE
SET search_path = public
AS $$
  SELECT group_id
  FROM group_members
  WHERE user_id = _user_id;
$$;

-- Function to get all user IDs that share a group with given user
CREATE OR REPLACE FUNCTION auth_get_shared_group_users(_user_id uuid)
RETURNS SETOF uuid
LANGUAGE sql
SECURITY DEFINER
STABLE
SET search_path = public
AS $$
  SELECT DISTINCT gm2.user_id
  FROM group_members gm1
  JOIN group_members gm2 ON gm1.group_id = gm2.group_id
  WHERE gm1.user_id = _user_id;
$$;

-- ============================================================================
-- Fix group_members table policies
-- ============================================================================

-- Drop existing SELECT policies
DROP POLICY IF EXISTS "group_members_view_own_groups" ON group_members;
DROP POLICY IF EXISTS "group_members_select_policy" ON group_members;
DROP POLICY IF EXISTS "group_members_select" ON group_members;
DROP POLICY IF EXISTS "group_members_select_own" ON group_members;
DROP POLICY IF EXISTS "group_members_select_same_group" ON group_members;

-- New SELECT policy using SECURITY DEFINER function
CREATE POLICY "group_members_select" ON group_members
  FOR SELECT
  USING (auth_is_group_member(auth.uid(), group_id));

-- ============================================================================
-- Fix users table policies
-- ============================================================================

-- Drop ALL existing SELECT policies on users (from all previous migrations)
DROP POLICY IF EXISTS "users_view_own_profile" ON users;
DROP POLICY IF EXISTS "users_view_group_members" ON users;
DROP POLICY IF EXISTS "users_select_policy" ON users;
DROP POLICY IF EXISTS "users_select" ON users;
DROP POLICY IF EXISTS "users_select_own" ON users;
DROP POLICY IF EXISTS "users_select_group_members" ON users;

-- New SELECT policy using SECURITY DEFINER function
-- User can ALWAYS view their own profile, OR view profiles of group members
CREATE POLICY "users_select" ON users
  FOR SELECT
  USING (
    id = auth.uid()
    OR
    id IN (SELECT auth_get_shared_group_users(auth.uid()))
  );

-- ============================================================================
-- Grant execute permissions
-- ============================================================================

GRANT EXECUTE ON FUNCTION auth_is_group_member TO authenticated;
GRANT EXECUTE ON FUNCTION auth_is_group_member TO anon;
GRANT EXECUTE ON FUNCTION auth_get_user_groups TO authenticated;
GRANT EXECUTE ON FUNCTION auth_get_user_groups TO anon;
GRANT EXECUTE ON FUNCTION auth_get_shared_group_users TO authenticated;
GRANT EXECUTE ON FUNCTION auth_get_shared_group_users TO anon;

-- ============================================================================
-- Comments
-- ============================================================================

COMMENT ON FUNCTION auth_is_group_member IS 
'Check if user is member of a group (SECURITY DEFINER to bypass RLS)';

COMMENT ON FUNCTION auth_get_user_groups IS 
'Get all group IDs for a user (SECURITY DEFINER to bypass RLS)';

COMMENT ON FUNCTION auth_get_shared_group_users IS 
'Get all user IDs that share a group with given user (SECURITY DEFINER to bypass RLS)';

COMMENT ON POLICY "group_members_select" ON group_members IS 
'Allow users to view memberships in groups they belong to';

COMMENT ON POLICY "users_select" ON users IS 
'Allow users to view own profile and profiles of group members';
