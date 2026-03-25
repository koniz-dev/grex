# Expenses Feature

The Expenses feature allows group members to record, view, and split shared costs.

## Overview
- **Expense Tracking**: Add receipts and specify who paid.
- **Split Methods**: Supports 4 split algorithms:
  - **Equal**: Split evenly among selected members.
  - **Percentage**: Split based on predefined percentages (must sum to 100%).
  - **Exact**: Assign specific dollar amounts per person.
  - **Shares**: Split based on weighting (e.g., 2 shares for user A, 1 share for user B).
- **Categorization**: Tag expenses using built-in or custom categories.

## Architecture Highlights

### Domain Layer
- **Entity**: `Expense`, `ExpenseSplit`
- **Use Cases**: `AddExpenseUseCase`, `UpdateExpenseUseCase`, `DeleteExpenseUseCase`

### Data Layer
- **Data Source**: Fetches and syncs expenses locally with Supabase.
- **Offline Support**: Queues expenses when offline and syncs upon reconnection.

### Presentation Layer
- **State Management**: BLoC pattern for the expense creation flow, managing complex forms and split calculations.
- **UI Components**: Interactive split widgets, currency input formatters, and receipt upload integrations.

## Related Features
Expenses influence the **[Balances](balances.md)** calculation engine and are associated with a **[Group](groups.md)**.
