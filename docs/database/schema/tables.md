# Database Tables Documentation

## Enum Types

### member_role
Defines the role hierarchy within groups:
- `administrator`: Full permissions (create, read, update, delete)
- `editor`: Can create and modify expenses/payments
- `viewer`: Read-only access

### split_method
Defines how expenses are split among participants:
- `equal`: Split equally among all participants
- `percentage`: Split by specified percentages
- `exact`: Split by exact amounts
- `shares`: Split by share counts

### action_type
Defines types of actions for audit logging:
- `create`: Record creation
- `update`: Record modification
- `delete`: Record deletion

## Core Tables

### users
Stores user profiles and authentication information.

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| id | UUID | PRIMARY KEY, DEFAULT gen_random_uuid() | Unique user identifier |
| email | TEXT | NOT NULL, UNIQUE | User's email address |
| display_name | TEXT | NOT NULL | User's display name |
| avatar_url | TEXT | | URL to user's avatar image |
| preferred_currency | TEXT | NOT NULL, DEFAULT 'USD' | User's preferred currency (ISO 4217) |
| preferred_language | TEXT | NOT NULL, DEFAULT 'en' | User's preferred language (ISO 639-1) |
| created_at | TIMESTAMPTZ | NOT NULL, DEFAULT NOW() | Record creation timestamp |
| updated_at | TIMESTAMPTZ | NOT NULL, DEFAULT NOW() | Last update timestamp |
| deleted_at | TIMESTAMPTZ | | Soft delete timestamp |

**Constraints:**
- `email_format`: Email must match valid email pattern
- `currency_code_length`: Currency code must be exactly 3 characters
- `language_code_length`: Language code must be exactly 2 characters

**Indexes:**
- `idx_users_email`: Fast email lookups
- `idx_users_created_at`: Chronological ordering
- `idx_users_deleted_at`: Exclude soft-deleted records

### groups
Stores group information and settings.

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| id | UUID | PRIMARY KEY, DEFAULT gen_random_uuid() | Unique group identifier |
| name | TEXT | NOT NULL | Group name |
| description | TEXT | | Group description |
| creator_id | UUID | NOT NULL, REFERENCES users(id) ON DELETE CASCADE | Group creator |
| primary_currency | TEXT | NOT NULL, DEFAULT 'USD' | Group's primary currency |
| created_at | TIMESTAMPTZ | NOT NULL, DEFAULT NOW() | Record creation timestamp |
| updated_at | TIMESTAMPTZ | NOT NULL, DEFAULT NOW() | Last update timestamp |
| deleted_at | TIMESTAMPTZ | | Soft delete timestamp |

**Constraints:**
- `name_not_empty`: Name cannot be empty or whitespace only
- `name_max_length`: Name cannot exceed 100 characters
- `currency_code_length`: Currency code must be exactly 3 characters

**Indexes:**
- `idx_groups_creator_id`: Find groups by creator
- `idx_groups_created_at`: Chronological ordering
- `idx_groups_deleted_at`: Exclude soft-deleted records

### group_members
Tracks group membership and roles.

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| id | UUID | PRIMARY KEY, DEFAULT gen_random_uuid() | Unique membership identifier |
| group_id | UUID | NOT NULL, REFERENCES groups(id) ON DELETE CASCADE | Group reference |
| user_id | UUID | NOT NULL, REFERENCES users(id) ON DELETE CASCADE | User reference |
| role | member_role | NOT NULL, DEFAULT 'editor' | User's role in the group |
| joined_at | TIMESTAMPTZ | NOT NULL, DEFAULT NOW() | When user joined |
| updated_at | TIMESTAMPTZ | NOT NULL, DEFAULT NOW() | Last role update |

**Constraints:**
- `unique_group_user`: One membership per user per group

**Indexes:**
- `idx_group_members_group_id`: Find members by group
- `idx_group_members_user_id`: Find groups by user
- `idx_group_members_composite`: Efficient user-group lookups

### expenses
Stores expense transactions and split information.

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| id | UUID | PRIMARY KEY, DEFAULT gen_random_uuid() | Unique expense identifier |
| group_id | UUID | NOT NULL, REFERENCES groups(id) ON DELETE CASCADE | Group reference |
| payer_id | UUID | NOT NULL, REFERENCES users(id) ON DELETE CASCADE | Who paid the expense |
| amount | NUMERIC(15,2) | NOT NULL | Expense amount |
| currency | TEXT | NOT NULL | Currency code (ISO 4217) |
| description | TEXT | NOT NULL | Expense description |
| expense_date | DATE | NOT NULL, DEFAULT CURRENT_DATE | When expense occurred |
| split_method | split_method | NOT NULL, DEFAULT 'equal' | How expense is split |
| notes | TEXT | | Additional notes |
| created_at | TIMESTAMPTZ | NOT NULL, DEFAULT NOW() | Record creation timestamp |
| updated_at | TIMESTAMPTZ | NOT NULL, DEFAULT NOW() | Last update timestamp |
| deleted_at | TIMESTAMPTZ | | Soft delete timestamp |

**Constraints:**
- `amount_positive`: Amount must be greater than 0
- `currency_code_length`: Currency code must be exactly 3 characters
- `description_not_empty`: Description cannot be empty

**Indexes:**
- `idx_expenses_group_id`: Find expenses by group
- `idx_expenses_payer_id`: Find expenses by payer
- `idx_expenses_expense_date`: Date range queries
- `idx_expenses_created_at`: Chronological ordering
- `idx_expenses_deleted_at`: Exclude soft-deleted records

### expense_participants
Tracks who participates in each expense and their share.

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| id | UUID | PRIMARY KEY, DEFAULT gen_random_uuid() | Unique participant identifier |
| expense_id | UUID | NOT NULL, REFERENCES expenses(id) ON DELETE CASCADE | Expense reference |
| user_id | UUID | NOT NULL, REFERENCES users(id) ON DELETE CASCADE | Participant user |
| share_amount | NUMERIC(15,2) | NOT NULL | Amount this user owes |
| share_percentage | NUMERIC(5,2) | | Percentage of total (for percentage splits) |
| share_count | INTEGER | | Share count (for share-based splits) |
| created_at | TIMESTAMPTZ | NOT NULL, DEFAULT NOW() | Record creation timestamp |

**Constraints:**
- `share_amount_positive`: Share amount must be greater than 0
- `share_percentage_range`: Percentage must be between 0 and 100
- `share_count_positive`: Share count must be greater than 0
- `unique_expense_user`: One participation per user per expense

**Indexes:**
- `idx_expense_participants_expense_id`: Find participants by expense
- `idx_expense_participants_user_id`: Find participations by user
- `idx_expense_participants_composite`: Efficient expense-user lookups

### payments
Records debt settlements between users.

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| id | UUID | PRIMARY KEY, DEFAULT gen_random_uuid() | Unique payment identifier |
| group_id | UUID | NOT NULL, REFERENCES groups(id) ON DELETE CASCADE | Group reference |
| payer_id | UUID | NOT NULL, REFERENCES users(id) ON DELETE CASCADE | Who made the payment |
| recipient_id | UUID | NOT NULL, REFERENCES users(id) ON DELETE CASCADE | Who received the payment |
| amount | NUMERIC(15,2) | NOT NULL | Payment amount |
| currency | TEXT | NOT NULL | Currency code (ISO 4217) |
| payment_date | DATE | NOT NULL, DEFAULT CURRENT_DATE | When payment was made |
| notes | TEXT | | Additional notes |
| created_at | TIMESTAMPTZ | NOT NULL, DEFAULT NOW() | Record creation timestamp |
| deleted_at | TIMESTAMPTZ | | Soft delete timestamp |

**Constraints:**
- `amount_positive`: Amount must be greater than 0
- `currency_code_length`: Currency code must be exactly 3 characters
- `payer_not_recipient`: Payer and recipient must be different

**Indexes:**
- `idx_payments_group_id`: Find payments by group
- `idx_payments_payer_id`: Find payments by payer
- `idx_payments_recipient_id`: Find payments by recipient
- `idx_payments_payment_date`: Date range queries
- `idx_payments_created_at`: Chronological ordering
- `idx_payments_deleted_at`: Exclude soft-deleted records

### audit_logs
Tracks all data modifications for accountability.

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| id | UUID | PRIMARY KEY, DEFAULT gen_random_uuid() | Unique log identifier |
| entity_type | TEXT | NOT NULL | Type of entity modified |
| entity_id | UUID | NOT NULL | ID of modified entity |
| action | action_type | NOT NULL | Type of action performed |
| user_id | UUID | NOT NULL, REFERENCES users(id) ON DELETE CASCADE | Who performed the action |
| group_id | UUID | REFERENCES groups(id) ON DELETE CASCADE | Related group (if applicable) |
| before_state | JSONB | | Entity state before modification |
| after_state | JSONB | | Entity state after modification |
| created_at | TIMESTAMPTZ | NOT NULL, DEFAULT NOW() | When action occurred |

**Constraints:**
- `entity_type_not_empty`: Entity type cannot be empty

**Indexes:**
- `idx_audit_logs_entity_type`: Find logs by entity type
- `idx_audit_logs_entity_id`: Find logs by entity
- `idx_audit_logs_user_id`: Find logs by user
- `idx_audit_logs_group_id`: Find logs by group
- `idx_audit_logs_created_at`: Chronological ordering
- `idx_audit_logs_composite`: Efficient entity-specific queries

**Special Rules:**
- `audit_logs_no_update`: Prevents UPDATE operations
- `audit_logs_no_delete`: Prevents DELETE operations

## Data Types

### UUID
All primary keys use UUID (Universally Unique Identifier) for:
- Global uniqueness across distributed systems
- Security (non-sequential, unpredictable)
- Scalability (no central ID generation)

### NUMERIC(15,2)
Used for all monetary amounts:
- 15 total digits (supports up to 999 trillion)
- 2 decimal places for currency precision
- Exact decimal arithmetic (no floating-point errors)

### TIMESTAMPTZ
Used for all timestamps:
- Timezone-aware timestamps
- Automatic timezone conversion
- Consistent ordering across timezones

### JSONB
Used for audit log states:
- Binary JSON format for efficient storage
- Supports indexing and querying
- Flexible schema for different entity types

### TEXT
Used for all string fields:
- Variable length with no arbitrary limit
- UTF-8 encoding support
- Efficient storage for short and long strings

## Soft Delete Implementation

Soft delete is implemented using `deleted_at` timestamps:
- NULL value indicates active record
- Non-NULL value indicates soft-deleted record
- Partial indexes exclude soft-deleted records from queries
- Referential integrity is maintained for soft-deleted records
- Helper functions provide soft delete, restore, and hard delete operations

## Performance Considerations

### Indexing Strategy

1. **Primary Key Indexes**: Automatic B-tree indexes on all primary keys
2. **Foreign Key Indexes**: Explicit indexes on all foreign keys for efficient joins
3. **Composite Indexes**: Multi-column indexes for common query patterns
4. **Partial Indexes**: Indexes on non-null values for soft-deleted records
5. **Date Indexes**: B-tree indexes on date columns for range queries

### Query Optimization

1. **Efficient Joins**: Foreign key indexes enable fast join operations
2. **Range Queries**: Date indexes support efficient date range filtering
3. **Composite Queries**: Multi-column indexes optimize complex WHERE clauses
4. **Soft Delete Filtering**: Partial indexes exclude deleted records efficiently

### Storage Optimization

1. **JSONB Compression**: Automatic compression for audit log data
2. **UUID Storage**: Efficient 16-byte storage for UUIDs
3. **NUMERIC Precision**: Exact decimal storage without waste
4. **Text Compression**: Automatic compression for long text fields