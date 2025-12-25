import 'package:flutter/material.dart';
import 'package:grex/core/services/export_service.dart';

/// Dialog showing export progress with cancellation option
class ExportProgressDialog extends StatelessWidget {
  /// Creates an [ExportProgressDialog] instance
  const ExportProgressDialog({
    required this.format,
    required this.progress,
    super.key,
    this.onCancel,
  });

  /// The export format being generated
  final ExportFormat format;

  /// The current export progress (0.0 to 1.0)
  final double progress;

  /// Optional callback to cancel the export process
  final VoidCallback? onCancel;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          Icon(
            Icons.download,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(width: 12),
          const Text('Exporting Data'),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Generating ${format.displayName} export...',
            style: Theme.of(context).textTheme.bodyMedium,
          ),

          const SizedBox(height: 20),

          // Progress indicator
          LinearProgressIndicator(
            value: progress,
            backgroundColor: Theme.of(
              context,
            ).colorScheme.surfaceContainerHighest,
            valueColor: AlwaysStoppedAnimation<Color>(
              Theme.of(context).colorScheme.primary,
            ),
          ),

          const SizedBox(height: 12),

          // Progress text
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _getProgressText(progress),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              Text(
                '${(progress * 100).toInt()}%',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Status message
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(
                context,
              ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _getStatusMessage(progress),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        if (onCancel != null)
          TextButton(
            onPressed: onCancel,
            child: const Text('Cancel'),
          ),
      ],
    );
  }

  String _getProgressText(double progress) {
    if (progress < 0.2) {
      return 'Preparing data...';
    } else if (progress < 0.4) {
      return 'Processing members...';
    } else if (progress < 0.6) {
      return 'Processing expenses...';
    } else if (progress < 0.8) {
      return 'Processing payments...';
    } else if (progress < 1.0) {
      return 'Finalizing export...';
    } else {
      return 'Complete!';
    }
  }

  String _getStatusMessage(double progress) {
    if (progress < 0.2) {
      return 'Gathering group information and member data';
    } else if (progress < 0.4) {
      return 'Collecting member details and roles';
    } else if (progress < 0.6) {
      return 'Compiling expense records and calculations';
    } else if (progress < 0.8) {
      return 'Processing payment history and balances';
    } else if (progress < 1.0) {
      return 'Creating ${format.displayName} file and preparing for sharing';
    } else {
      return 'Export completed successfully!';
    }
  }
}
