# Export Feature

The Data Export feature enables users to extract their financial data from the application for external auditing or record-keeping.

## Overview
- **Formats Supported**: Export expense and payment histories to CSV and PDF formats.
- **Customizable Exports**: Filter by date range, user, or category before exporting.
- **Share Implementation**: Native iOS/Android share sheets to quickly send files via Email, WhatsApp, etc.

## Architecture Highlights

### Domain Layer
- **Interfaces**: Contracts for file generation capabilities (e.g., `PdfGenerator`, `CsvGenerator`).
- **Use Cases**: `GenerateGroupReportUseCase`

### Data Layer
- **File System Handling**: Manages local caching, reading, and writing to the device's temporary document directories.

### Presentation Layer
- **UI Flow**: Simple modal or bottom sheet for selecting the export parameters.
- **Loading States**: Shows progress indicators during heavy PDF generation.

## Related Features
Integrates data from **[Groups](groups.md)**, **[Expenses](expenses.md)**, and **[Payments](payments.md)**.
