-- ============================================================================
-- Migration: Auto Create User Profile on Auth Signup
-- Version: 00023
-- Description: Create trigger to automatically create user profile when
--              a new user signs up via Supabase Auth
-- This is the standard Supabase pattern for handling user profiles
-- ============================================================================

-- Function to handle new user signup
-- This runs with SECURITY DEFINER so it bypasses RLS
CREATE OR REPLACE FUNCTION handle_new_user()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  INSERT INTO public.users (id, email, display_name, preferred_currency, preferred_language)
  VALUES (
    NEW.id,
    NEW.email,
    COALESCE(NEW.raw_user_meta_data->>'display_name', split_part(NEW.email, '@', 1)),
    COALESCE(NEW.raw_user_meta_data->>'preferred_currency', 'VND'),
    COALESCE(NEW.raw_user_meta_data->>'preferred_language', 'vi')
  );
  RETURN NEW;
END;
$$;

-- Create trigger on auth.users table
-- This fires AFTER INSERT so the auth user exists when we create the profile
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW
  EXECUTE FUNCTION handle_new_user();

-- ============================================================================
-- Comments
-- ============================================================================

COMMENT ON FUNCTION handle_new_user IS 
'Automatically creates a user profile in public.users when a new user signs up via Supabase Auth. Uses SECURITY DEFINER to bypass RLS.';
