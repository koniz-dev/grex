import 'package:flutter/material.dart';

/// Search bar widget for filtering expenses
class ExpenseSearchBar extends StatelessWidget {
  /// Creates an [ExpenseSearchBar] instance
  const ExpenseSearchBar({
    required this.controller,
    required this.onChanged,
    super.key,
    this.hintText = 'Search...',
    this.onClear,
    this.onFilterTap,
    this.hasActiveFilters = false,
  });

  /// The text editing controller for the search field
  final TextEditingController controller;

  /// Callback when the search text changes
  final ValueChanged<String> onChanged;

  /// The hint text to display in the search field
  final String hintText;

  /// Callback when the search is cleared
  final VoidCallback? onClear;

  /// Callback when the filter button is tapped
  final VoidCallback? onFilterTap;

  /// Whether any filters are currently active
  final bool hasActiveFilters;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              onChanged: onChanged,
              decoration: InputDecoration(
                hintText: hintText,
                prefixIcon: const Icon(Icons.search),
                suffixIcon: controller.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          controller.clear();
                          onChanged('');
                          onClear?.call();
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Theme.of(context).colorScheme.surface,
              ),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: Icon(
              Icons.filter_list,
              color: hasActiveFilters
                  ? Theme.of(context).colorScheme.primary
                  : null,
            ),
            onPressed: onFilterTap,
          ),
        ],
      ),
    );
  }
}
