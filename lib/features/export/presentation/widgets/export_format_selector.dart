import 'package:flutter/material.dart';
import 'package:grex/core/services/export_service.dart';

/// Widget for selecting export format
class ExportFormatSelector extends StatelessWidget {
  /// Creates an [ExportFormatSelector] instance
  const ExportFormatSelector({
    required this.selectedFormat,
    required this.onFormatChanged,
    super.key,
  });

  /// The currently selected export format
  final ExportFormat selectedFormat;

  /// Callback when the export format changes
  final ValueChanged<ExportFormat> onFormatChanged;

  @override
  Widget build(BuildContext context) {
    return RadioGroup<ExportFormat>(
      groupValue: selectedFormat,
      onChanged: (value) {
        if (value != null) {
          onFormatChanged(value);
        }
      },
      child: Column(
        children: ExportFormat.values.map((format) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _buildFormatOption(context, format),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildFormatOption(BuildContext context, ExportFormat format) {
    final isSelected = selectedFormat == format;

    return Card(
      elevation: isSelected ? 2 : 0,
      color: isSelected ? Theme.of(context).colorScheme.primaryContainer : null,
      child: InkWell(
        onTap: () => onFormatChanged(format),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Format icon
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: isSelected
                      ? Theme.of(
                          context,
                        ).colorScheme.primary.withValues(alpha: 0.2)
                      : Theme.of(
                          context,
                        ).colorScheme.surfaceContainerHighest.withValues(
                          alpha: 0.3,
                        ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  _getFormatIcon(format),
                  color: isSelected
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),

              const SizedBox(width: 16),

              // Format info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      format.displayName,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: isSelected
                            ? Theme.of(context).colorScheme.onPrimaryContainer
                            : null,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _getFormatDescription(format),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: isSelected
                            ? Theme.of(
                                context,
                              ).colorScheme.onPrimaryContainer.withValues(
                                alpha: 0.8,
                              )
                            : Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),

              // Selection indicator
              Radio<ExportFormat>(
                value: format,
                activeColor: Theme.of(context).colorScheme.primary,
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getFormatIcon(ExportFormat format) {
    switch (format) {
      case ExportFormat.csv:
        return Icons.table_chart;
      case ExportFormat.pdf:
        return Icons.picture_as_pdf;
    }
  }

  String _getFormatDescription(ExportFormat format) {
    switch (format) {
      case ExportFormat.csv:
        return 'Spreadsheet format, perfect for Excel or Google Sheets';
      case ExportFormat.pdf:
        return 'Formatted report, easy to read and share';
    }
  }
}
