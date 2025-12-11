# Database Functions Overview

This document provides an overview of all database functions in the Grex expense splitting application.

## Function Categories

### Business Logic Functions
- [calculate_group_balances()](business-logic.md#calculate_group_balances) - Calculate net balances for group members
- [generate_settlement_plan()](business-logic.md#generate_settlement_plan) - Generate optimized settlement plan
- [check_user_permission()](business-logic.md#check_user_permission) - Validate user permissions

### Validation Functions  
- [validate_expense_split()](validation.md#validate_expense_split) - Validate expense split totals
- [validate_currency_code()](validation.md#validate_currency_code) - Validate ISO 4217 currency codes

### Utility Functions
- [soft_delete_record()](utilities.md#soft_delete_record) - Soft delete records
- [restore_record()](utilities.md#restore_record) - Restore soft-deleted records
- [hard_delete_record()](utilities.md#hard_delete_record) - Permanently delete records

## Performance Characteristics

All functions are optimized for performance with proper indexing and efficient SQL queries.
See individual function documentation for specific performance metrics and benchmarks.

## Usage Patterns

Functions are designed to be called from:
- Application code for business logic
- Database triggers for validation
- Administrative scripts for maintenance
- Row Level Security policies for permissions

For detailed documentation of each function, see the specific category files.
