-- ============================================================================
-- Migration: Create Groups Table
-- Version: 00003
-- Description: Create groups table with constraints, indexes, and foreign keys
-- ============================================================================

-- Create groups table
CREATE TABLE groups (
  -- Primary key
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  
  -- Group information
  name TEXT NOT NULL,
  description TEXT,
  
  -- Ownership and settings
  creator_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  primary_currency TEXT NOT NULL DEFAULT 'USD',
  
  -- Timestamps
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  
  -- Soft delete support
  deleted_at TIMESTAMPTZ,
  
  -- ========================================================================
  -- Constraints
  -- ========================================================================
  
  -- Group name validation
  CONSTRAINT name_not_empty CHECK (
    LENGTH(TRIM(BOTH E' \t\n\r' FROM name)) > 0
  ),
  CONSTRAINT name_max_length CHECK (
    LENGTH(name) <= 100
  ),
  
  -- Currency code validation (ISO 4217 - 3 letter codes)
  CONSTRAINT currency_code_length CHECK (
    LENGTH(primary_currency) = 3
  ),
  CONSTRAINT currency_code_format CHECK (
    primary_currency ~ '^[A-Z]{3}$'
  ),
  
  -- Description validation (optional, but if provided should not be empty)
  CONSTRAINT description_not_empty CHECK (
    description IS NULL OR LENGTH(TRIM(description)) > 0
  ),
  CONSTRAINT description_max_length CHECK (
    description IS NULL OR LENGTH(description) <= 500
  )
);

-- ============================================================================
-- Indexes for performance
-- ============================================================================

-- Foreign key index
CREATE INDEX idx_groups_creator_id ON groups(creator_id);

-- Timestamp indexes
CREATE INDEX idx_groups_created_at ON groups(created_at);

-- Soft delete index (partial index for active groups only)
CREATE INDEX idx_groups_active ON groups(id) WHERE deleted_at IS NULL;

-- Composite index for active groups by creation date
CREATE INDEX idx_groups_active_created ON groups(created_at, id) WHERE deleted_at IS NULL;

-- Search index for group names (for autocomplete/search functionality)
CREATE INDEX idx_groups_name_search ON groups USING gin(to_tsvector('english', name)) WHERE deleted_at IS NULL;

-- ============================================================================
-- Comments for documentation
-- ============================================================================

COMMENT ON TABLE groups IS 'Groups for organizing shared expenses among multiple users';
COMMENT ON COLUMN groups.id IS 'Unique identifier for the group (UUID)';
COMMENT ON COLUMN groups.name IS 'Display name of the group (required, max 100 chars)';
COMMENT ON COLUMN groups.description IS 'Optional description of the group purpose';
COMMENT ON COLUMN groups.creator_id IS 'User who created the group (foreign key to users.id)';
COMMENT ON COLUMN groups.primary_currency IS 'Default currency for expenses in this group (ISO 4217 code)';
COMMENT ON COLUMN groups.created_at IS 'Timestamp when group was created';
COMMENT ON COLUMN groups.updated_at IS 'Timestamp when group was last updated';
COMMENT ON COLUMN groups.deleted_at IS 'Timestamp when group was soft-deleted (NULL for active groups)';

-- ============================================================================
-- Sample data scenarios (for reference)
-- ============================================================================

-- Example groups:
-- - "Roommates" (shared apartment expenses)
-- - "Vacation 2024" (trip expenses)
-- - "Office Lunch" (workplace meal sharing)
-- - "Family Expenses" (household costs)

-- ============================================================================
-- Verification queries (for testing)
-- ============================================================================

-- Verify table was created
-- SELECT table_name, column_name, data_type, is_nullable 
-- FROM information_schema.columns 
-- WHERE table_name = 'groups' 
-- ORDER BY ordinal_position;

-- Verify constraints
-- SELECT constraint_name, constraint_type 
-- FROM information_schema.table_constraints 
-- WHERE table_name = 'groups';

-- Verify foreign keys
-- SELECT 
--   tc.constraint_name,
--   tc.table_name,
--   kcu.column_name,
--   ccu.table_name AS foreign_table_name,
--   ccu.column_name AS foreign_column_name
-- FROM information_schema.table_constraints AS tc
-- JOIN information_schema.key_column_usage AS kcu
--   ON tc.constraint_name = kcu.constraint_name
-- JOIN information_schema.constraint_column_usage AS ccu
--   ON ccu.constraint_name = tc.constraint_name
-- WHERE tc.constraint_type = 'FOREIGN KEY' AND tc.table_name = 'groups';

-- ============================================================================
-- Triggers for automatic timestamp management
-- ============================================================================

-- Create timestamp trigger function if it doesn't exist
CREATE OR REPLACE FUNCTION set_timestamps()
RETURNS TRIGGER AS $$
BEGIN
  IF TG_OP = 'INSERT' THEN
    NEW.created_at = NOW();
    NEW.updated_at = NOW();
  ELSIF TG_OP = 'UPDATE' THEN
    NEW.updated_at = NOW();
    -- Prevent modification of created_at
    NEW.created_at = OLD.created_at;
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Apply timestamp trigger to groups table
CREATE TRIGGER set_groups_timestamps
  BEFORE INSERT OR UPDATE ON groups
  FOR EACH ROW EXECUTE FUNCTION set_timestamps();

-- Verify indexes
-- SELECT indexname, indexdef 
-- FROM pg_indexes 
-- WHERE tablename = 'groups';