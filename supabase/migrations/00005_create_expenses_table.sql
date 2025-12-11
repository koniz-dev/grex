-- ============================================================================
-- Migration: Create Expenses Table
-- Version: 00005
-- Description: Create expenses table with constraints, indexes, and foreign keys
-- ============================================================================

-- Create expenses table
CREATE TABLE expenses (
  -- Primary key
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  
  -- Relationships
  group_id UUID NOT NULL REFERENCES groups(id) ON DELETE CASCADE,
  payer_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  
  -- Expense details
  amount NUMERIC(15, 2) NOT NULL,
  currency TEXT NOT NULL,
  description TEXT NOT NULL,
  expense_date DATE NOT NULL DEFAULT CURRENT_DATE,
  split_method split_method NOT NULL DEFAULT 'equal',
  notes TEXT,
  
  -- Timestamps
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  
  -- Soft delete support
  deleted_at TIMESTAMPTZ,
  
  -- ========================================================================
  -- Constraints
  -- ========================================================================
  
  -- Amount must be positive
  CONSTRAINT amount_positive CHECK (amount > 0),
  
  -- Currency code validation (ISO 4217 - 3 letter codes)
  CONSTRAINT currency_code_length CHECK (LENGTH(currency) = 3),
  CONSTRAINT currency_code_format CHECK (currency ~ '^[A-Z]{3}$'),
  
  -- Description validation
  CONSTRAINT description_not_empty CHECK (LENGTH(TRIM(description)) > 0),
  CONSTRAINT description_max_length CHECK (LENGTH(description) <= 500),
  
  -- Notes validation (optional, but if provided should not be empty)
  CONSTRAINT notes_not_empty CHECK (notes IS NULL OR LENGTH(TRIM(notes)) > 0),
  CONSTRAINT notes_max_length CHECK (notes IS NULL OR LENGTH(notes) <= 1000),
  
  -- Expense date validation (not in future beyond reasonable limit)
  CONSTRAINT expense_date_reasonable CHECK (expense_date <= CURRENT_DATE + INTERVAL '1 day')
);

-- ============================================================================
-- Indexes for performance
-- ============================================================================

-- Foreign key indexes
CREATE INDEX idx_expenses_group_id ON expenses(group_id);
CREATE INDEX idx_expenses_payer_id ON expenses(payer_id);

-- Date-based queries
CREATE INDEX idx_expenses_expense_date ON expenses(expense_date);
CREATE INDEX idx_expenses_created_at ON expenses(created_at);

-- Soft delete index (partial index for active expenses only)
CREATE INDEX idx_expenses_active ON expenses(id) WHERE deleted_at IS NULL;

-- Composite indexes for common query patterns
CREATE INDEX idx_expenses_group_date ON expenses(group_id, expense_date) WHERE deleted_at IS NULL;
CREATE INDEX idx_expenses_payer_date ON expenses(payer_id, expense_date) WHERE deleted_at IS NULL;

-- Amount-based queries (for reporting)
CREATE INDEX idx_expenses_amount ON expenses(amount) WHERE deleted_at IS NULL;

-- Split method queries
CREATE INDEX idx_expenses_split_method ON expenses(split_method);

-- Full-text search on description
CREATE INDEX idx_expenses_description_search ON expenses USING gin(to_tsvector('english', description)) WHERE deleted_at IS NULL;

-- ============================================================================
-- Comments for documentation
-- ============================================================================

COMMENT ON TABLE expenses IS 'Expenses recorded within groups for splitting among members';
COMMENT ON COLUMN expenses.id IS 'Unique identifier for the expense (UUID)';
COMMENT ON COLUMN expenses.group_id IS 'Reference to the group this expense belongs to';
COMMENT ON COLUMN expenses.payer_id IS 'Reference to the user who paid for this expense';
COMMENT ON COLUMN expenses.amount IS 'Total amount of the expense (positive decimal)';
COMMENT ON COLUMN expenses.currency IS 'Currency code for the expense amount (ISO 4217)';
COMMENT ON COLUMN expenses.description IS 'Description of what the expense was for';
COMMENT ON COLUMN expenses.expense_date IS 'Date when the expense occurred';
COMMENT ON COLUMN expenses.split_method IS 'Method used to split this expense among participants';
COMMENT ON COLUMN expenses.notes IS 'Optional additional notes about the expense';
COMMENT ON COLUMN expenses.created_at IS 'Timestamp when expense was recorded';
COMMENT ON COLUMN expenses.updated_at IS 'Timestamp when expense was last updated';
COMMENT ON COLUMN expenses.deleted_at IS 'Timestamp when expense was soft-deleted (NULL for active expenses)';

-- ============================================================================
-- Expense splitting methods (for reference)
-- ============================================================================

-- equal: Split equally among all participants
--   - Each participant pays: amount / participant_count
--   - Example: $100 / 4 people = $25 each

-- percentage: Split by specified percentages
--   - Percentages must sum to 100%
--   - Example: Person A: 50%, Person B: 30%, Person C: 20%

-- exact: Split by exact amounts
--   - Exact amounts must sum to total expense amount
--   - Example: Person A: $60, Person B: $25, Person C: $15

-- shares: Split by shares/ratios
--   - Proportional to share counts
--   - Example: Person A: 2 shares, Person B: 1 share, Person C: 1 share
--   - Person A pays: (2/4) * $100 = $50, others pay $25 each

-- ============================================================================
-- Triggers for automatic timestamp management
-- ============================================================================

-- Apply timestamp trigger to expenses table
CREATE TRIGGER set_expenses_timestamps
  BEFORE INSERT OR UPDATE ON expenses
  FOR EACH ROW EXECUTE FUNCTION set_timestamps();

-- ============================================================================
-- Verification queries (for testing)
-- ============================================================================

-- Verify table was created
-- SELECT table_name, column_name, data_type, is_nullable 
-- FROM information_schema.columns 
-- WHERE table_name = 'expenses' 
-- ORDER BY ordinal_position;

-- Verify constraints
-- SELECT constraint_name, constraint_type 
-- FROM information_schema.table_constraints 
-- WHERE table_name = 'expenses';

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
-- WHERE tc.constraint_type = 'FOREIGN KEY' AND tc.table_name = 'expenses';

-- Verify indexes
-- SELECT indexname, indexdef 
-- FROM pg_indexes 
-- WHERE tablename = 'expenses';

-- ============================================================================
-- Sample expense scenarios (for reference)
-- ============================================================================

-- Common expense types:
-- - Meals: "Dinner at Restaurant ABC", "Groceries for the week"
-- - Transportation: "Uber to airport", "Gas for road trip"
-- - Accommodation: "Hotel for 3 nights", "Airbnb rental"
-- - Utilities: "Electricity bill", "Internet service"
-- - Entertainment: "Movie tickets", "Concert tickets"
-- - Shopping: "Household supplies", "Gift for birthday party"