-- ============================================================================
-- Migration: Create Users Table
-- Version: 00002
-- Description: Create users table with constraints, indexes, and validation
-- ============================================================================

-- Create users table
CREATE TABLE users (
  -- Primary key
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  
  -- Authentication and profile
  email TEXT NOT NULL UNIQUE,
  display_name TEXT NOT NULL,
  avatar_url TEXT,
  
  -- Preferences
  preferred_currency TEXT NOT NULL DEFAULT 'USD',
  preferred_language TEXT NOT NULL DEFAULT 'en',
  
  -- Timestamps
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  
  -- Soft delete support
  deleted_at TIMESTAMPTZ,
  
  -- ========================================================================
  -- Constraints
  -- ========================================================================
  
  -- Email format validation (RFC 5322 compliant)
  CONSTRAINT email_format CHECK (
    email ~* '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$'
  ),
  
  -- Display name validation
  CONSTRAINT display_name_not_empty CHECK (
    LENGTH(TRIM(display_name)) > 0
  ),
  CONSTRAINT display_name_max_length CHECK (
    LENGTH(display_name) <= 100
  ),
  
  -- Currency code validation (ISO 4217 - 3 letter codes)
  CONSTRAINT currency_code_length CHECK (
    LENGTH(preferred_currency) = 3
  ),
  CONSTRAINT currency_code_format CHECK (
    preferred_currency ~ '^[A-Z]{3}$'
  ),
  
  -- Language code validation (ISO 639-1 - 2 letter codes)
  CONSTRAINT language_code_length CHECK (
    LENGTH(preferred_language) = 2
  ),
  CONSTRAINT language_code_format CHECK (
    preferred_language ~ '^[a-z]{2}$'
  ),
  
  -- Avatar URL validation (optional, but if provided must be valid URL)
  CONSTRAINT avatar_url_format CHECK (
    avatar_url IS NULL OR 
    avatar_url ~* '^https?://[^\s/$.?#].[^\s]*$'
  )
);

-- ============================================================================
-- Indexes for performance
-- ============================================================================

-- Primary lookup indexes
CREATE INDEX idx_users_email ON users(email);
CREATE INDEX idx_users_created_at ON users(created_at);

-- Soft delete index (partial index for active users only)
CREATE INDEX idx_users_active ON users(id) WHERE deleted_at IS NULL;

-- Composite index for active users by creation date
CREATE INDEX idx_users_active_created ON users(created_at, id) WHERE deleted_at IS NULL;

-- ============================================================================
-- Comments for documentation
-- ============================================================================

COMMENT ON TABLE users IS 'User accounts and profiles for the expense splitting application';
COMMENT ON COLUMN users.id IS 'Unique identifier for the user (UUID)';
COMMENT ON COLUMN users.email IS 'User email address (unique, used for authentication)';
COMMENT ON COLUMN users.display_name IS 'User display name shown in the application';
COMMENT ON COLUMN users.avatar_url IS 'Optional URL to user avatar image';
COMMENT ON COLUMN users.preferred_currency IS 'Default currency for user (ISO 4217 code)';
COMMENT ON COLUMN users.preferred_language IS 'Default language for user interface (ISO 639-1 code)';
COMMENT ON COLUMN users.created_at IS 'Timestamp when user account was created';
COMMENT ON COLUMN users.updated_at IS 'Timestamp when user account was last updated';
COMMENT ON COLUMN users.deleted_at IS 'Timestamp when user was soft-deleted (NULL for active users)';

-- ============================================================================
-- Sample supported currencies (for reference)
-- ============================================================================

-- Common currencies that should be supported:
-- USD (US Dollar), EUR (Euro), GBP (British Pound), JPY (Japanese Yen)
-- VND (Vietnamese Dong), CNY (Chinese Yuan), KRW (Korean Won)
-- AUD (Australian Dollar), CAD (Canadian Dollar), CHF (Swiss Franc)

-- ============================================================================
-- Sample supported languages (for reference)
-- ============================================================================

-- Common languages that should be supported:
-- en (English), vi (Vietnamese), zh (Chinese), ja (Japanese)
-- ko (Korean), fr (French), de (German), es (Spanish)

-- ============================================================================
-- Verification queries (for testing)
-- ============================================================================

-- Verify table was created
-- SELECT table_name, column_name, data_type, is_nullable 
-- FROM information_schema.columns 
-- WHERE table_name = 'users' 
-- ORDER BY ordinal_position;

-- Verify constraints
-- SELECT constraint_name, constraint_type 
-- FROM information_schema.table_constraints 
-- WHERE table_name = 'users';

-- Verify indexes
-- SELECT indexname, indexdef 
-- FROM pg_indexes 
-- WHERE tablename = 'users';