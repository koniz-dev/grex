import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:grex/core/di/injection.dart';
import 'package:grex/core/routing/navigation_extensions.dart';
import 'package:grex/features/groups/presentation/bloc/group_bloc.dart';
import 'package:grex/features/groups/presentation/bloc/group_event.dart';
import 'package:grex/features/groups/presentation/bloc/group_state.dart';
import 'package:grex/shared/utils/currency_formatter.dart';

/// Page for creating a new expense sharing group
class CreateGroupPage extends StatelessWidget {
  /// Creates a [CreateGroupPage] instance
  const CreateGroupPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => getIt<GroupBloc>(),
      child: const CreateGroupView(),
    );
  }
}

/// View component for creating a group
class CreateGroupView extends StatefulWidget {
  /// Creates a [CreateGroupView] instance
  const CreateGroupView({super.key});

  @override
  State<CreateGroupView> createState() => _CreateGroupViewState();
}

class _CreateGroupViewState extends State<CreateGroupView> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();

  String _selectedCurrency = 'VND';
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tạo nhóm mới'),
        elevation: 0,
        backgroundColor: Theme.of(context).colorScheme.surface,
        foregroundColor: Theme.of(context).colorScheme.onSurface,
      ),
      body: BlocListener<GroupBloc, GroupState>(
        listener: (context, state) {
          if (state is GroupLoading) {
            setState(() {
              _isLoading = true;
            });
          } else {
            setState(() {
              _isLoading = false;
            });
          }

          if (state is GroupOperationSuccess) {
            // Show success message
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.green,
              ),
            );

            // Navigate back to group list
            context.goToGroups();
          } else if (state is GroupError) {
            // Show error message
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.userFriendlyMessage),
                backgroundColor: Colors.red,
                action: SnackBarAction(
                  label: 'Thử lại',
                  onPressed: _createGroup,
                ),
              ),
            );
          }
        },
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header section
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Theme.of(
                      context,
                    ).colorScheme.primaryContainer.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        Icons.group_add,
                        size: 64,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Tạo nhóm chia sẻ chi phí',
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Mời bạn bè và bắt đầu theo dõi chi phí chung',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 32),

                // Group name field
                TextFormField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: 'Tên nhóm *',
                    hintText: 'Ví dụ: Du lịch Đà Lạt, Nhóm bạn thân...',
                    prefixIcon: const Icon(Icons.group),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Theme.of(context).colorScheme.surface,
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Vui lòng nhập tên nhóm';
                    }
                    if (value.trim().length < 2) {
                      return 'Tên nhóm phải có ít nhất 2 ký tự';
                    }
                    if (value.trim().length > 50) {
                      return 'Tên nhóm không được quá 50 ký tự';
                    }
                    return null;
                  },
                  textCapitalization: TextCapitalization.words,
                  maxLength: 50,
                ),

                const SizedBox(height: 24),

                // Currency selection
                DropdownButtonFormField<String>(
                  initialValue: _selectedCurrency,
                  decoration: InputDecoration(
                    labelText: 'Tiền tệ mặc định *',
                    prefixIcon: const Icon(Icons.monetization_on),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Theme.of(context).colorScheme.surface,
                  ),
                  items: CurrencyFormatter.getSupportedCurrencies().map((
                    currency,
                  ) {
                    return DropdownMenuItem<String>(
                      value: currency,
                      child: Row(
                        children: [
                          Text(
                            CurrencyFormatter.getCurrencySymbol(currency),
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(width: 8),
                          Text(currency),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              CurrencyFormatter.getCurrencyDisplayName(
                                currency,
                              ),
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onSurfaceVariant,
                                  ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _selectedCurrency = value;
                      });
                    }
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Vui lòng chọn tiền tệ';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 24),

                // Description field (optional)
                TextFormField(
                  controller: _descriptionController,
                  decoration: InputDecoration(
                    labelText: 'Mô tả (tùy chọn)',
                    hintText: 'Mô tả ngắn về nhóm này...',
                    prefixIcon: const Icon(Icons.description),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Theme.of(context).colorScheme.surface,
                  ),
                  maxLines: 3,
                  maxLength: 200,
                  textCapitalization: TextCapitalization.sentences,
                ),

                const SizedBox(height: 32),

                // Create button
                ElevatedButton(
                  onPressed: _isLoading ? null : _createGroup,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text(
                          'Tạo nhóm',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),

                const SizedBox(height: 16),

                // Cancel button
                TextButton(
                  onPressed: _isLoading
                      ? null
                      : () => context.popOrGoToGroups(),
                  child: const Text('Hủy'),
                ),

                const SizedBox(height: 24),

                // Info section
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color:
                        Theme.of(
                          context,
                        ).colorScheme.surfaceContainerHighest.withValues(
                          alpha: 0.5,
                        ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            size: 20,
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Lưu ý',
                            style: Theme.of(context).textTheme.titleSmall
                                ?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '• Bạn sẽ trở thành quản trị viên của nhóm\n'
                        '• Có thể thay đổi tên và tiền tệ sau khi tạo\n'
                        '• Mời thành viên khác sau khi tạo nhóm thành công',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _createGroup() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final name = _nameController.text.trim();
    final description = _descriptionController.text.trim();

    context.read<GroupBloc>().add(
      GroupCreateRequested(
        name: name,
        currency: _selectedCurrency,
        description: description.isEmpty ? null : description,
      ),
    );
  }
}
