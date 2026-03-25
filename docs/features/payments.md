# Payments Feature

The Payments feature tracks reimbursements and direct settlements between users inside a group.

## Overview
- **Record Payments**: Allows users to mark debts as paid (e.g., "Alice paid Bob $20").
- **Payment History**: A ledger of all P2P transactions to audit balance changes over time.
- **Approval Workflow (Optional)**: Can optionally require the payee to confirm receipt before the balance updates.

## Architecture Highlights

### Domain Layer
- **Entity**: `Payment`, `PaymentStatus`
- **Use Cases**: `RecordPaymentUseCase`, `GetPaymentHistoryUseCase`

### Data Layer
- **Repositories**: `PaymentsRepositoryImpl` which syncs data securely and maps backend models to Domain entities.

### Presentation Layer
- **State Management**: Managed via BLoC for processing payment transactions and maintaining UI responsiveness.
- **UI Components**: Payment confirmation dialogues, transaction list views.

## Related Features
Payments are integral to updating the **[Balances](balances.md)**.
