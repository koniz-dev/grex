import 'package:flutter/material.dart';
import 'package:grex/shared/extensions/context_extensions.dart';

/// A widget that displays a list of password requirements and updates
/// their state (met or not met) in real-time as the user types.
class PasswordRequirementIndicator extends StatefulWidget {
  /// Creates a [PasswordRequirementIndicator].
  const PasswordRequirementIndicator({
    required this.controller,
    required this.focusNode,
    super.key,
  });

  /// The controller of the password text field to listen to.
  final TextEditingController controller;
  
  /// The focus node of the password text field to determine visibility.
  final FocusNode focusNode;

  @override
  State<PasswordRequirementIndicator> createState() =>
      _PasswordRequirementIndicatorState();
}

class _PasswordRequirementIndicatorState
    extends State<PasswordRequirementIndicator> {
  bool _hasLength = false;
  bool _hasUppercase = false;
  bool _hasNumber = false;
  bool _hasSpecial = false;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_validatePassword);
    widget.focusNode.addListener(_onFocusChanged);
    _validatePassword();
  }

  void _onFocusChanged() {
    setState(() {}); // Trigger rebuild to show/hide based on focus
  }

  @override
  void didUpdateWidget(covariant PasswordRequirementIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_validatePassword);
      widget.controller.addListener(_validatePassword);
      _validatePassword();
    }
    if (oldWidget.focusNode != widget.focusNode) {
      oldWidget.focusNode.removeListener(_onFocusChanged);
      widget.focusNode.addListener(_onFocusChanged);
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_validatePassword);
    widget.focusNode.removeListener(_onFocusChanged);
    super.dispose();
  }

  void _validatePassword() {
    final password = widget.controller.text;
    final hasLength = password.length >= 8;
    final hasUppercase = password.contains(RegExp('[A-Z]'));
    final hasNumber = password.contains(RegExp('[0-9]'));
    // Matches any character that is not alphanumeric and not a whitespace
    final hasSpecial = password.contains(RegExp(r'[^a-zA-Z0-9\s]'));

    if (_hasLength != hasLength ||
        _hasUppercase != hasUppercase ||
        _hasNumber != hasNumber ||
        _hasSpecial != hasSpecial) {
      setState(() {
        _hasLength = hasLength;
        _hasUppercase = hasUppercase;
        _hasNumber = hasNumber;
        _hasSpecial = hasSpecial;
      });
    }
  }

  Widget _buildRequirementRow(String text, bool isMet) {
    final color = isMet ? const Color(0xFF10B981) : const Color(0xFFA1A1AA);
    final icon = isMet ? Icons.check_circle : Icons.circle_outlined;

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 8),
          Text(
            text,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              fontWeight: FontWeight.normal,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    
    final isAllMet = _hasLength && _hasUppercase && _hasNumber && _hasSpecial;
    // Show if focused, or if user typed something but hasn't met all conditions
    final isVisible = widget.focusNode.hasFocus ||
        (widget.controller.text.isNotEmpty && !isAllMet);

    return AnimatedSize(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOut,
      child: !isVisible
          ? const SizedBox.shrink()
          : Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildRequirementRow(l10n.pwdReqLength, _hasLength),
                  _buildRequirementRow(l10n.pwdReqUppercase, _hasUppercase),
                  _buildRequirementRow(l10n.pwdReqNumber, _hasNumber),
                  _buildRequirementRow(l10n.pwdReqSpecial, _hasSpecial),
                ],
              ),
            ),
    );
  }
}
