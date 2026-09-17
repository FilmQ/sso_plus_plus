import 'package:flutter/material.dart';

/// One field of the injury form on screen M2.
///
/// The design puts the label above the value and an explanation below the
/// box. The explanation is optional.
class FormTextField extends StatelessWidget {
  const FormTextField({
    super.key,
    required this.label,
    required this.controller,
    this.helper,
    this.hint,
    this.readOnly = false,
    this.onTap,
    this.errorText,
    this.maxLines = 1,
  });

  final String label;
  final TextEditingController controller;

  /// The sentence below the box, for example "From your Section 33 record".
  final String? helper;

  final String? hint;
  final bool readOnly;
  final VoidCallback? onTap;
  final String? errorText;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          TextField(
            controller: controller,
            readOnly: readOnly,
            onTap: onTap,
            maxLines: maxLines,
            decoration: InputDecoration(
              labelText: label,
              hintText: hint,
              errorText: errorText,
              suffixIcon: readOnly && onTap != null
                  ? const Icon(Icons.arrow_drop_down)
                  : null,
            ),
          ),
          if (helper != null && errorText == null)
            Padding(
              padding: const EdgeInsets.only(top: 6, left: 4),
              child: Text(
                helper!,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
