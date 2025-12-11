# Database Schema Overview

## Architecture

The Grex expense splitting application uses a PostgreSQL database hosted on Supabase. The schema is designed with the following principles:

- **Data Integrity**: Foreign keys, constraints, and triggers ensure consistency
- **Security**: Row Level Security (RLS) policies restrict data access based on user permissions
- **Performance**: Strategic indexes optimize common query patterns
- **Auditability**: Comprehensive audit logging tracks all changes
- **Real-time**: Publications enable instant updates across devices
- **Scalability**: Efficient schema design supports growth

## Entity Relationship Diagram

```mermaid
erDiagram
    users {
        uuid id PK
        text email UK
        text display_name
        text avatar_url
        text preferred_currency
        text preferred_language
        timestamptz created_at
        timestamptz updated_at
        timestamptz deleted_at
    }
    
    groups {
        uuid id PK
        text name
        text description
        uuid creator_id FK
        text primary_currency
        timestamptz created_at
        timestamptz updated_at
        timestamptz deleted_at
    }
    
    group_members {
        uuid id PK
        uuid group_id FK
        uuid user_id FK
        member_role role
        timestamptz joined_at
        timestamptz updated_at
    }
    
    expenses {
        uuid id PK
        uuid group_id FK
        uuid payer_id FK
        numeric amount
        text currency
        text description
        date expense_date
        split_method split_method
        text notes
        timestamptz created_at
        timestamptz updated_at
        timestamptz deleted_at
    }
    
    expense_participants {
        uuid id PK
        uuid expense_id FK
        uuid user_id FK
        numeric share_amount
        numeric share_percentage
        integer share_count
        timestamptz created_at
    }
    
    payments {
        uuid id PK
        uuid group_id FK
        uuid payer_id FK
        uuid recipient_id FK
        numeric amount
        text currency
        date payment_date
        text notes
        timestamptz created_at
        timestamptz deleted_at
    }
    
    audit_logs {
        uuid id PK
        text entity_type
        uuid entity_id
        action_type action
        uuid user_id FK
        uuid group_id FK
        jsonb before_state
        jsonb after_state
        timestamptz created_at
    }
    
    users ||--o{ groups : creates
    users ||--o{ group_members : belongs_to
    groups ||--o{ group_members : has
    groups ||--o{ expenses : contains
    groups ||--o{ payments : contains
    users ||--o{ expenses : pays
    users ||--o{ payments : sends
    users ||--o{ payments : receives
    expenses ||--o{ expense_participants : split_among
    users ||--o{ expense_participants : owes
    users ||--o{ audit_logs : performed_by
    groups ||--o{ audit_logs : relates_to
```

## Database Structure

```
PostgreSQL (Supabase)
├── Tables (7)
│   ├── users
│   ├── groups
│   ├── group_members
│   ├── expenses
│   ├── expense_participants
│   ├── payments
│   └── audit_logs
├── Enum Types (3)
│   ├── member_role
│   ├── split_method
│   └── action_type
├── Functions (6+)
│   ├── calculate_group_balances()
│   ├── validate_expense_split()
│   ├── generate_settlement_plan()
│   ├── check_user_permission()
│   ├── validate_currency_code()
│   └── soft_delete_*()
├── Triggers (4+)
│   ├── set_timestamps
│   ├── audit_expense_changes
│   ├── audit_payment_changes
│   └── audit_membership_changes
└── RLS Policies (33)
    ├── users_* (3 policies)
    ├── groups_* (4 policies)
    ├── group_members_* (4 policies)
    ├── expenses_* (4 policies)
    ├── expense_participants_* (4 policies)
    ├── payments_* (3 policies)
    └── audit_logs_* (1 policy)
```

## Core Concepts

### Multi-tenant Architecture
- **Groups** serve as the primary tenant boundary
- Complete data isolation between different groups
- Users can belong to multiple groups with different roles

### Role-based Access Control
```
administrator (Full Access)
    ↓
editor (Create/Modify)
    ↓  
viewer (Read Only)
    ↓
non-member (No Access)
```

### Data Flow
1. **User Registration**: Creates user profile
2. **Group Creation**: User creates or joins groups
3. **Expense Management**: Users add expenses and split costs
4. **Settlement**: System calculates balances and suggests payments
5. **Payment Recording**: Users record debt settlements
6. **Audit Trail**: All actions are logged for accountability

## Key Features

### Security
- **Row Level Security**: Database-level access control
- **Role-based Permissions**: Hierarchical permission system
- **Audit Logging**: Complete modification history
- **Data Isolation**: Groups cannot access each other's data

### Performance
- **Strategic Indexing**: Optimized for common query patterns
- **Efficient Functions**: Business logic executed in database
- **Query Optimization**: Designed for scalability
- **Connection Pooling**: Supabase handles connection management

### Real-time
- **WebSocket Updates**: Instant synchronization across devices
- **RLS-filtered Events**: Users only receive authorized updates
- **Collaborative Features**: Multiple users can work simultaneously

### Data Integrity
- **Foreign Key Constraints**: Maintain referential integrity
- **Check Constraints**: Validate data ranges and formats
- **Triggers**: Automatic timestamp and audit management
- **Soft Delete**: Recoverable deletion with integrity preservation

## Migration Strategy

The schema is managed through versioned migrations:
- Sequential numbering (00001, 00002, etc.)
- Atomic transactions for each migration
- Rollback capability for failed migrations
- Schema integrity verification

## Next Steps

- [Detailed Tables Documentation](tables.md)
- [Relationships and Constraints](relationships.md)
- [Index Strategy](indexes.md)
- [Functions Overview](../functions/overview.md)
- [Security Policies](../security/overview.md)