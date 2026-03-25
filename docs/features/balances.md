# Balances Feature

The Balances feature is the core calculation engine of the Expense Sharing app, generating real-time settlement plans.

## Overview
- **Real-Time Calculation**: Aggregates all expenses and payments to determine who owes whom.
- **Settlement Optimization**: Reduces the number of internal group transactions required to settle up (minimizing graph edges).
- **Group Summaries**: Individual balances (e.g., "You owe $10", "You are owed $50").

## Architecture Highlights

### Domain Layer
- **Entity**: `BalanceSummary`, `Debt`
- **Use Cases**: `CalculateBalancesUseCase`, `OptimizeDebtsUseCase`
- **Logic**: The graph optimization algorithm lives entirely in the Domain layer, making it fully testable without external dependencies.

### Data Layer
- Usually relies on the data provided by `ExpensesRepository` and `PaymentsRepository` rather than storing state directly, functioning as an aggregation layer.

### Presentation Layer
- **State Management**: Consumes data streams and presents them via BLoC/Riverpod.
- **UI Components**: Visually distinct positive (green) and negative (red) balance indicators, debt breakdown charts.

## Related Features
Calculations derive from both **[Expenses](expenses.md)** and **[Payments](payments.md)**.
