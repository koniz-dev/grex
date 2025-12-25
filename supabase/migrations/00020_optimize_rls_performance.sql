-- Migration: Optimize RLS Performance
-- Description: Fix auth.uid() re-evaluation and multiple permissive policies
-- Author: System
-- Date: 2025-01-25

-- This migration optimizes RLS policies for better performance
-- 1. Replace auth.uid() with (select auth.uid()) to avoid re-evaluation
-- 2. Consolidate multiple permissive policies where possible

-- Note: This is a complex migration that will be done in parts
-- Part 1: Fix auth.uid() re-evaluation issues

-- Users table policies optimization
DROP POLICY IF EXISTS "users_insert_own_profile" ON users;
CREATE POLICY "users_insert_own_profile" ON users
    FOR INSERT
    WITH CHECK (id = (select auth.uid()));

DROP POLICY IF EXISTS "users_update_own_profile" ON users;
CREATE POLICY "users_update_own_profile" ON users
    FOR UPDATE
    USING (id = (select auth.uid()))
    WITH CHECK (id = (select auth.uid()));

DROP POLICY IF EXISTS "users_view_own_profile" ON users;
CREATE POLICY "users_view_own_profile" ON users
    FOR SELECT
    USING (id = (select auth.uid()));

DROP POLICY IF EXISTS "users_view_group_members" ON users;
CREATE POLICY "users_view_group_members" ON users
    FOR SELECT
    USING (
        id IN (
            SELECT DISTINCT u.id 
            FROM users u
            JOIN group_members gm1 ON u.id = gm1.user_id
            JOIN group_members gm2 ON gm1.group_id = gm2.group_id
            WHERE gm2.user_id = (select auth.uid())
        )
    );

-- Groups table policies optimization
DROP POLICY IF EXISTS "groups_create_own_groups" ON groups;
CREATE POLICY "groups_create_own_groups" ON groups
    FOR INSERT
    WITH CHECK (creator_id = (select auth.uid()));

DROP POLICY IF EXISTS "groups_view_member_groups" ON groups;
CREATE POLICY "groups_view_member_groups" ON groups
    FOR SELECT
    USING (
        id IN (
            SELECT group_id 
            FROM group_members 
            WHERE user_id = (select auth.uid())
        )
    );

-- Add comment
COMMENT ON SCHEMA public IS 'RLS policies optimized for performance - Part 1: auth.uid() optimization completed';