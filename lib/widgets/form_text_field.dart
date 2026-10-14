import 'package:flutter/material.dart';

/// An outlined Material 3 text field with a help line and an error line
/// (U1-2, U1-3). When the error is set, the field shows the error icon.
class FormTextField extends StatefulWidget {
  const FormTextField({
    super.key,
    required this.label,
    this.controller,
    this.helper,
    this.error,
    this.prefixIcon,
    this.suffixIcon,
    this.secret = false,
    this.keyboardType,
    this.maxLines = 1,
    this.readOnly = false,
    this.onTap,
    this.onChanged,
  });

  final String label;
  final TextEditingController? controller;
  final String? helper;
  final String? error;
  final IconData? prefixIcon;
  final IconData? suffixIcon;

  /// A password field with a show/hide button.
  final bool secret;
  final TextInputType? keyboardType;
  final int maxLines;
  final bool readOnly;
  final VoidCallback? onTap;
  final ValueChanged<String>? onChanged;

  @override
  State<FormTextField> createState() => _FormTextFieldState();
}

class _FormTextFieldState extends State<FormTextField> {
  bool _hidden = true;

  @override
  Widget build(BuildContext context) {
    final Widget? suffix = widget.secret
        ? IconButton(
            tooltip: _hidden ? 'Show password' : 'Hide password',
            icon: Icon(_hidden ? Icons.visibility_off : Icons.visibility),
            onPressed: () => setState(() => _hidden = !_hidden),
          )
        : widget.error != null
            ? Icon(Icons.error, color: Theme.of(context).colorScheme.error)
            : widget.suffixIcon == null
                ? null
                : Icon(widget.suffixIcon);
    return TextField(
      controller: widget.controller,
      obscureText: widget.secret && _hidden,
      keyboardType: widget.keyboardType,
      maxLines: widget.secret ? 1 : widget.maxLines,
      minLines: 1,
      readOnly: widget.readOnly,
      onTap: widget.onTap,
      onChanged: widget.onChanged,
      decoration: InputDecoration(
        labelText: widget.label,
        helperText: widget.helper,
        helperMaxLines: 2,
        errorText: widget.error,
        errorMaxLines: 2,
        prefixIcon: widget.prefixIcon == null ? null : Icon(widget.prefixIcon),
        suffixIcon: suffix,
      ),
    );
  }
}
