-- Migration: Optimize RLS Performance Part 2
-- Description: Continue optimizing RLS policies for groups and expenses
-- Author: System
-- Date: 2025-01-25

-- Part 2: Continue fixing auth.uid() re-evaluation issues

-- Groups table admin policies
DROP POLICY IF EXISTS "groups_admin_update" ON groups;
CREATE POLICY "groups_admin_update" ON groups
    FOR UPDATE
    USING (
        EXISTS (
            SELECT 1 FROM group_members 
            WHERE group_id = groups.id 
            AND user_id = (select auth.uid()) 
            AND role = 'administrator'
        )
    )
    WITH CHECK (
        EXISTS (
            SELECT 1 FROM group_members 
            WHERE group_id = groups.id 
            AND user_id = (select auth.uid()) 
            AND role = 'administrator'
        )
    );

DROP POLICY IF EXISTS "groups_admin_delete" ON groups;
CREATE POLICY "groups_admin_delete" ON groups
    FOR UPDATE
    USING (
        EXISTS (
            SELECT 1 FROM group_members 
            WHERE group_id = groups.id 
            AND user_id = (select auth.uid()) 
            AND role = 'administrator'
        )
    )
    WITH CHECK (
        EXISTS (
            SELECT 1 FROM group_members 
            WHERE group_id = groups.id 
            AND user_id = (select auth.uid()) 
            AND role = 'administrator'
        )
    );

-- Expenses table policies optimization
DROP POLICY IF EXISTS "expenses_editor_create" ON expenses;
CREATE POLICY "expenses_editor_create" ON expenses
    FOR INSERT
    WITH CHECK (
        EXISTS (
            SELECT 1 FROM group_members 
            WHERE group_id = expenses.group_id 
            AND user_id = (select auth.uid()) 
            AND role IN ('administrator', 'editor')
        )
    );

-- Add comment
COMMENT ON SCHEMA public IS 'RLS policies optimized for performance - Part 2: groups and expenses optimization completed';