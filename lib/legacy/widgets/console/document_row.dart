import 'package:flutter/material.dart';

import '../../models/claim_document.dart';

/// One document of the case file, with a way to open it.
///
/// Screens D2, D5 and D6 show these rows. A document that is absent is
/// marked, because BR-23 lets a session open only with a complete file or
/// with an explicit flag.
class DocumentRow extends StatelessWidget {
  const DocumentRow({
    super.key,
    required this.document,
    this.note,
    this.onView,
    this.isLast = false,
  });

  final ClaimDocument document;

  /// A remark about the file, for example `Page 2 unreadable`.
  final String? note;

  final VoidCallback? onView;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colors = theme.colorScheme;
    final bool attached = document.isAttached;
    final bool flagged = note != null;

    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 14),
      child: Row(
        children: <Widget>[
          Icon(
            !attached
                ? Icons.error_outline
                : flagged
                ? Icons.warning_amber_outlined
                : Icons.check_circle,
            size: 20,
            color: !attached
                ? colors.error
                : flagged
                ? colors.tertiary
                : colors.primary,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(document.type.label, style: theme.textTheme.bodyMedium),
                Text(
                  note ?? document.statusText,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: attached && !flagged
                        ? colors.onSurfaceVariant
                        : colors.error,
                  ),
                ),
              ],
            ),
          ),
          if (attached)
            TextButton.icon(
              onPressed: onView,
              icon: const Icon(Icons.visibility_outlined, size: 18),
              label: const Text('View'),
            ),
        ],
      ),
    );
  }
}
