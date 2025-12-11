-- ============================================================================
-- Migration: Create Payments Table
-- Version: 00007
-- Description: Create payments table for tracking payments between group members
-- ============================================================================

-- Create payments table
CREATE TABLE payments (
  -- Primary key
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  
  -- Relationships
  group_id UUID NOT NULL REFERENCES groups(id) ON DELETE CASCADE,
  payer_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  recipient_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  
  -- Payment details
  amount NUMERIC(15, 2) NOT NULL,
  currency TEXT NOT NULL,
  payment_date DATE NOT NULL DEFAULT CURRENT_DATE,
  notes TEXT,
  
  -- Timestamps
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  
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
  
  -- Payer and recipient must be different
  CONSTRAINT payer_not_recipient CHECK (payer_id != recipient_id),
  
  -- Notes validation (optional, but if provided should not be empty)
  CONSTRAINT notes_not_empty CHECK (notes IS NULL OR LENGTH(TRIM(notes)) > 0),
  CONSTRAINT notes_max_length CHECK (notes IS NULL OR LENGTH(notes) <= 1000),
  
  -- Payment date validation (not in future beyond reasonable limit)
  CONSTRAINT payment_date_reasonable CHECK (payment_date <= CURRENT_DATE + INTERVAL '1 day')
);

-- ============================================================================
-- Indexes for performance
-- ============================================================================

-- Foreign key indexes
CREATE INDEX idx_payments_group_id ON payments(group_id);
CREATE INDEX idx_payments_payer_id ON payments(payer_id);
CREATE INDEX idx_payments_recipient_id ON payments(recipient_id);

-- Date-based queries
CREATE INDEX idx_payments_payment_date ON payments(payment_date);
CREATE INDEX idx_payments_created_at ON payments(created_at);

-- Soft delete index (partial index for active payments only)
CREATE INDEX idx_payments_active ON payments(id) WHERE deleted_at IS NULL;

-- Composite indexes for common query patterns
CREATE INDEX idx_payments_group_date ON payments(group_id, payment_date) WHERE deleted_at IS NULL;
CREATE INDEX idx_payments_payer_date ON payments(payer_id, payment_date) WHERE deleted_at IS NULL;
CREATE INDEX idx_payments_recipient_date ON payments(recipient_id, payment_date) WHERE deleted_at IS NULL;

-- Amount-based queries (for reporting)
CREATE INDEX idx_payments_amount ON payments(amount) WHERE deleted_at IS NULL;

-- ============================================================================
-- Comments for documentation
-- ============================================================================

COMMENT ON TABLE payments IS 'Payments made between group members to settle expenses';
COMMENT ON COLUMN payments.id IS 'Unique identifier for the payment (UUID)';
COMMENT ON COLUMN payments.group_id IS 'Reference to the group this payment belongs to';
COMMENT ON COLUMN payments.payer_id IS 'Reference to the user who made the payment';
COMMENT ON COLUMN payments.recipient_id IS 'Reference to the user who received the payment';
COMMENT ON COLUMN payments.amount IS 'Amount of the payment (positive decimal)';
COMMENT ON COLUMN payments.currency IS 'Currency code for the payment amount (ISO 4217)';
COMMENT ON COLUMN payments.payment_date IS 'Date when the payment was made';
COMMENT ON COLUMN payments.notes IS 'Optional notes about the payment';
COMMENT ON COLUMN payments.created_at IS 'Timestamp when payment was recorded';
COMMENT ON COLUMN payments.deleted_at IS 'Timestamp when payment was soft-deleted (NULL for active payments)';

-- ============================================================================
-- Payment scenarios (for reference)
-- ============================================================================

-- Common payment scenarios:
-- 1. Settlement payments: User A pays User B to settle their balance
-- 2. Direct reimbursements: User A pays User B for a specific expense
-- 3. Advance payments: User A pays User B in advance for future expenses
-- 4. Partial settlements: User A pays part of what they owe to User B

-- Payment workflow:
-- 1. User creates payment record (payer_id = current user)
-- 2. Payment affects group balances calculation
-- 3. Payment can be deleted by payer or group administrator
-- 4. Payments do not cascade delete (they are independent records)

-- ============================================================================
-- Triggers for automatic timestamp management
-- ============================================================================

-- Create specialized timestamp trigger function for payments
CREATE OR REPLACE FUNCTION set_payments_timestamps()
RETURNS TRIGGER AS $$
BEGIN
  IF TG_OP = 'INSERT' THEN
    NEW.created_at = NOW();
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Apply timestamp trigger to payments table
-- Note: Only created_at is managed since payments typically don't get updated
CREATE TRIGGER set_payments_timestamps
  BEFORE INSERT ON payments
  FOR EACH ROW EXECUTE FUNCTION set_payments_timestamps();

-- ============================================================================
-- Verification queries (for testing)
-- ============================================================================

-- Verify table was created
-- SELECT table_name, column_name, data_type, is_nullable 
-- FROM information_schema.columns 
-- WHERE table_name = 'payments' 
-- ORDER BY ordinal_position;

-- Verify constraints
-- SELECT constraint_name, constraint_type 
-- FROM information_schema.table_constraints 
-- WHERE table_name = 'payments';

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
-- WHERE tc.constraint_type = 'FOREIGN KEY' AND tc.table_name = 'payments';

-- Verify indexes
-- SELECT indexname, indexdef 
-- FROM pg_indexes 
-- WHERE tablename = 'payments';

-- ============================================================================
-- Sample payment scenarios (for reference)
-- ============================================================================

-- Example 1: Settlement payment
-- User A owes User B $50 from shared expenses
-- INSERT INTO payments (group_id, payer_id, recipient_id, amount, currency, notes)
-- VALUES (group_uuid, userA_uuid, userB_uuid, 50.00, 'USD', 'Settlement for shared dinner expenses');

-- Example 2: Direct reimbursement
-- User B paid for User A's portion of groceries
-- INSERT INTO payments (group_id, payer_id, recipient_id, amount, currency, notes)
-- VALUES (group_uuid, userA_uuid, userB_uuid, 25.00, 'USD', 'Reimbursement for groceries');

-- Example 3: Advance payment
-- User A pays User B in advance for upcoming trip expenses
-- INSERT INTO payments (group_id, payer_id, recipient_id, amount, currency, notes)
-- VALUES (group_uuid, userA_uuid, userB_uuid, 200.00, 'USD', 'Advance payment for vacation expenses');