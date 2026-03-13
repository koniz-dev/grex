import 'package:flutter/material.dart';

/// Custom text field for authentication forms
///
/// Styled according to design specs with proper colors, spacing, and error
/// states.
class AuthTextField extends StatelessWidget {
  /// Creates an [AuthTextField].
  ///
  /// The [label] and [placeholder] parameters are required.
  const AuthTextField({
    required this.label,
    required this.placeholder,
    super.key,
    this.controller,
    this.validator,
    this.obscureText = false,
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

  /// The controller for the text field.
  final TextEditingController? controller;

  /// The validator function for form validation.
  final String? Function(String?)? validator;

  /// Whether to obscure the text (for passwords).
  final bool obscureText;

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
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Label
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 6),
        // Input field
        TextFormField(
          controller: controller,
          validator: validator,
          obscureText: obscureText,
          keyboardType: keyboardType,
          textInputAction: textInputAction,
          onChanged: onChanged,
          onFieldSubmitted: onFieldSubmitted,
          enabled: enabled,
          readOnly: readOnly,
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 14,
            fontWeight: FontWeight.normal,
            color: Colors.black,
          ),
          decoration: InputDecoration(
            hintText: placeholder,
            hintStyle: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 14,
              fontWeight: FontWeight.normal,
              color: Color(0xFFA1A1AA),
            ),
            filled: true,
            fillColor: const Color(0xFFF4F4F5),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
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
              borderSide: const BorderSide(
                color: Color(0xFFDC2626),
                width: 2,
              ),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(
                color: Color(0xFFDC2626),
                width: 2,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
