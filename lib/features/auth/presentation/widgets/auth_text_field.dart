import 'package:flutter/material.dart';

/// Custom text field for authentication forms.
///
/// Styled according to design specs with proper colors, spacing, and error
/// states. The label is rendered via [InputDecoration.label] (a descendant of
/// the inner [TextFormField]) so widget tests can locate the field using
/// `find.widgetWithText(TextFormField, label)`.
class AuthTextField extends StatefulWidget {
  /// Creates an [AuthTextField].
  ///
  /// The [label] and [placeholder] parameters are required.
  const AuthTextField({
    required this.label,
    required this.placeholder,
    super.key,
    this.fieldKey,
    this.visibilityToggleKey,
    this.controller,
    this.focusNode,
    this.validator,
    this.obscureText = false,
    this.showVisibilityToggle = false,
    this.keyboardType,
    this.textInputAction,
    this.onChanged,
    this.onFieldSubmitted,
    this.hasError = false,
    this.enabled = true,
    this.readOnly = false,
  });

  /// The label text displayed above the input field.
  final String label;

  /// The placeholder text shown when the field is empty.
  final String placeholder;

  /// Optional key applied to the inner [TextFormField] for widget tests.
  final Key? fieldKey;

  /// Optional key applied to the visibility toggle button.
  final Key? visibilityToggleKey;

  /// The controller for the text field.
  final TextEditingController? controller;

  /// Optional focus node for the text field.
  final FocusNode? focusNode;

  /// The validator function for form validation.
  final String? Function(String?)? validator;

  /// Whether to obscure the text (for passwords).
  final bool obscureText;

  /// Whether to show the visibility toggle (only effective when
  /// [obscureText] is true).
  final bool showVisibilityToggle;

  /// The keyboard type to use for the input.
  final TextInputType? keyboardType;

  /// The text input action for the keyboard.
  final TextInputAction? textInputAction;

  /// Callback when the text changes.
  final void Function(String)? onChanged;

  /// Callback when the field is submitted.
  final void Function(String)? onFieldSubmitted;

  /// Whether the field has an error state.
  final bool hasError;

  /// Whether the field is enabled for input.
  final bool enabled;

  /// Whether the field is read-only.
  final bool readOnly;

  @override
  State<AuthTextField> createState() => _AuthTextFieldState();
}

class _AuthTextFieldState extends State<AuthTextField> {
  late bool _obscure;

  @override
  void initState() {
    super.initState();
    _obscure = widget.obscureText;
  }

  @override
  void didUpdateWidget(covariant AuthTextField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.obscureText != widget.obscureText) {
      _obscure = widget.obscureText;
    }
  }

  @override
  Widget build(BuildContext context) {
    final showToggle = widget.obscureText && widget.showVisibilityToggle;
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          widget.label,
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          key: widget.fieldKey,
          controller: widget.controller,
          focusNode: widget.focusNode,
          validator: widget.validator,
          obscureText: _obscure,
          keyboardType: widget.keyboardType,
          textInputAction: widget.textInputAction,
          onChanged: widget.onChanged,
          onFieldSubmitted: widget.onFieldSubmitted,
          enabled: widget.enabled,
          readOnly: widget.readOnly,
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 14,
            fontWeight: FontWeight.normal,
            color: colorScheme.onSurface,
          ),
          decoration: InputDecoration(
            hintText: widget.placeholder,
            hintStyle: TextStyle(
              fontFamily: 'Inter',
              fontSize: 14,
              fontWeight: FontWeight.normal,
              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
            ),
            filled: true,
            fillColor: colorScheme.surfaceContainerHighest,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
            suffixIcon: showToggle
                ? IconButton(
                    key: widget.visibilityToggleKey,
                    icon: Icon(
                      _obscure ? Icons.visibility_off : Icons.visibility,
                      color: colorScheme.onSurfaceVariant,
                      size: 20,
                    ),
                    onPressed: () => setState(() => _obscure = !_obscure),
                  )
                : null,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(
                color: colorScheme.error,
                width: 2,
              ),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(
                color: colorScheme.error,
                width: 2,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
