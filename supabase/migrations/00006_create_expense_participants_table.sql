-- ============================================================================
-- Migration: Create Expense Participants Table
-- Version: 00006
-- Description: Create expense_participants table for tracking how expenses are split among users
-- ============================================================================

-- Create expense_participants table
CREATE TABLE expense_participants (
  -- Primary key
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  
  -- Relationships
  expense_id UUID NOT NULL REFERENCES expenses(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  
  -- Share information (different methods of splitting)
  share_amount NUMERIC(15, 2) NOT NULL,
  share_percentage NUMERIC(5, 2),
  share_count INTEGER,
  
  -- Timestamps
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  
  -- ========================================================================
  -- Constraints
  -- ========================================================================
  
  -- Share amount must be positive
  CONSTRAINT share_amount_positive CHECK (share_amount > 0),
  
  -- Share percentage must be between 0 and 100 (if provided)
  CONSTRAINT share_percentage_range CHECK (
    share_percentage IS NULL OR (share_percentage >= 0 AND share_percentage <= 100)
  ),
  
  -- Share count must be positive (if provided)
  CONSTRAINT share_count_positive CHECK (
    share_count IS NULL OR share_count > 0
  ),
  
  -- Ensure unique participation per user per expense
  CONSTRAINT unique_expense_user UNIQUE (expense_id, user_id)
);

-- ============================================================================
-- Indexes for performance
-- ============================================================================

-- Foreign key indexes
CREATE INDEX idx_expense_participants_expense_id ON expense_participants(expense_id);
CREATE INDEX idx_expense_participants_user_id ON expense_participants(user_id);

-- Composite index for efficient lookups
CREATE INDEX idx_expense_participants_composite ON expense_participants(expense_id, user_id);

-- Index for share amount queries (finding largest/smallest shares)
CREATE INDEX idx_expense_participants_share_amount ON expense_participants(share_amount);

-- Timestamp index
CREATE INDEX idx_expense_participants_created_at ON expense_participants(created_at);

-- ============================================================================
-- Comments for documentation
-- ============================================================================

COMMENT ON TABLE expense_participants IS 'Tracks how expenses are split among group members with different splitting methods';
COMMENT ON COLUMN expense_participants.id IS 'Unique identifier for the participation record (UUID)';
COMMENT ON COLUMN expense_participants.expense_id IS 'Reference to the expense being split (foreign key to expenses.id)';
COMMENT ON COLUMN expense_participants.user_id IS 'Reference to the participating user (foreign key to users.id)';
COMMENT ON COLUMN expense_participants.share_amount IS 'Actual amount this user owes for this expense (always required)';
COMMENT ON COLUMN expense_participants.share_percentage IS 'Percentage of expense for percentage-based splits (optional)';
COMMENT ON COLUMN expense_participants.share_count IS 'Number of shares for share-based splits (optional)';
COMMENT ON COLUMN expense_participants.created_at IS 'Timestamp when participation was created';

-- ============================================================================
-- Split method explanations (for reference)
-- ============================================================================

-- Different ways expenses can be split:

-- 1. EQUAL SPLIT:
--    - share_amount = expense.amount / number_of_participants
--    - share_percentage = NULL
--    - share_count = NULL

-- 2. PERCENTAGE SPLIT:
--    - share_amount = expense.amount * (share_percentage / 100)
--    - share_percentage = user-defined percentage (must sum to 100% across all participants)
--    - share_count = NULL

-- 3. EXACT SPLIT:
--    - share_amount = user-defined exact amount (must sum to expense.amount)
--    - share_percentage = NULL
--    - share_count = NULL

-- 4. SHARES SPLIT:
--    - share_amount = expense.amount * (share_count / total_shares)
--    - share_percentage = NULL
--    - share_count = user-defined number of shares

-- ============================================================================
-- Triggers for automatic timestamp management
-- ============================================================================

-- Create specialized timestamp trigger function for expense_participants
CREATE OR REPLACE FUNCTION set_expense_participants_timestamps()
RETURNS TRIGGER AS $$
BEGIN
  IF TG_OP = 'INSERT' THEN
    NEW.created_at = NOW();
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Apply timestamp trigger to expense_participants table
-- Note: Only created_at is managed since participants typically don't get updated
CREATE TRIGGER set_expense_participants_timestamps
  BEFORE INSERT ON expense_participants
  FOR EACH ROW EXECUTE FUNCTION set_expense_participants_timestamps();

-- ============================================================================
-- Verification queries (for testing)
-- ============================================================================

-- Verify table was created
-- SELECT table_name, column_name, data_type, is_nullable 
-- FROM information_schema.columns 
-- WHERE table_name = 'expense_participants' 
-- ORDER BY ordinal_position;

-- Verify constraints
-- SELECT constraint_name, constraint_type 
-- FROM information_schema.table_constraints 
-- WHERE table_name = 'expense_participants';

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
-- WHERE tc.constraint_type = 'FOREIGN KEY' AND tc.table_name = 'expense_participants';

-- Verify indexes
-- SELECT indexname, indexdef 
-- FROM pg_indexes 
-- WHERE tablename = 'expense_participants';

-- ============================================================================
-- Sample usage scenarios (for reference)
-- ============================================================================

-- Example 1: Equal split of $100 among 4 people
-- INSERT INTO expense_participants (expense_id, user_id, share_amount)
-- VALUES 
--   (expense_uuid, user1_uuid, 25.00),
--   (expense_uuid, user2_uuid, 25.00),
--   (expense_uuid, user3_uuid, 25.00),
--   (expense_uuid, user4_uuid, 25.00);

-- Example 2: Percentage split (60%, 40%)
-- INSERT INTO expense_participants (expense_id, user_id, share_amount, share_percentage)
-- VALUES 
--   (expense_uuid, user1_uuid, 60.00, 60.00),
--   (expense_uuid, user2_uuid, 40.00, 40.00);

-- Example 3: Share-based split (2 shares vs 1 share)
-- INSERT INTO expense_participants (expense_id, user_id, share_amount, share_count)
-- VALUES 
--   (expense_uuid, user1_uuid, 66.67, 2),
--   (expense_uuid, user2_uuid, 33.33, 1);