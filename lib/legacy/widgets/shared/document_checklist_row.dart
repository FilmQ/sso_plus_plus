import 'package:flutter/material.dart';

import '../../models/claim_document.dart';

/// One line of the required-document checklist (BR-03).
///
/// Screen M3 shows these rows. The officer claim detail shows them again.
class DocumentChecklistRow extends StatelessWidget {
  const DocumentChecklistRow({
    super.key,
    required this.document,
    this.isLast = false,
    this.onAttach,
  });

  final ClaimDocument document;
  final bool isLast;
  final VoidCallback? onAttach;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colors = theme.colorScheme;
    final bool attached = document.isAttached;

    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(
            attached ? Icons.check_circle : Icons.radio_button_unchecked,
            size: 20,
            color: attached ? colors.primary : colors.outline,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(document.type.label, style: theme.textTheme.bodyMedium),
                Text(
                  document.statusText,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: attached ? colors.onSurfaceVariant : colors.error,
                  ),
                ),
              ],
            ),
          ),
          if (!attached && onAttach != null)
            TextButton(onPressed: onAttach, child: const Text('Add')),
        ],
      ),
    );
  }
}
