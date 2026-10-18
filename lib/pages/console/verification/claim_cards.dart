import 'package:flutter/material.dart';

import '../../../widgets/status_chip.dart';

/// A card of the console with a title row and a divider (Figma O1-2).
class ConsoleCard extends StatelessWidget {
  const ConsoleCard({super.key, required this.title, required this.children, this.trailing, this.subtitle});

  final String title;
  final String? subtitle;
  final Widget? trailing;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    final TextTheme text = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.outlineVariant),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, spacing: 12, children: <Widget>[
        Row(children: <Widget>[Expanded(child: Text(title, style: text.titleMedium)), ?trailing]),
        if (subtitle != null) Text(subtitle!, style: text.bodySmall),
        const Divider(height: 1),
        ...children,
      ]),
    );
  }
}

/// "Claim summary" (QO1.3). [status] is the claim_status of QO1.1, or the
/// new status after O2 or O3; null when it is not known.
class ClaimSummaryCard extends StatelessWidget {
  const ClaimSummaryCard({super.key, required this.summary, this.status});

  final Map<String, Object?> summary;
  final String? status;

  @override
  Widget build(BuildContext context) {
    final List<(String, String)> fields = <(String, String)>[
      ('National ID', 'national_id'),
      ('Employer on claim', 'employer_on_claim'),
      ('Date of injury', 'date_of_injury'),
      ('Place', 'injury_place'),
      ('Cause of injury', 'injury_cause'),
      ('Injury part of body', 'body_part'),
    ];
    return ConsoleCard(
      title: 'Claim summary',
      trailing: status == null ? null : ClaimStatusChip(status!),
      children: <Widget>[
        LayoutBuilder(builder: (BuildContext context, BoxConstraints box) {
          final double width = box.maxWidth >= 480 ? (box.maxWidth - 32) / 3 : box.maxWidth;
          return Wrap(spacing: 16, runSpacing: 16, children: <Widget>[
            for (final (String label, String key) in fields)
              SizedBox(width: width, child: LabelValue(label, '${summary[key] ?? '-'}')),
          ]);
        }),
      ],
    );
  }
}

/// A small label over a value (Figma O1-2 summary fields).
class LabelValue extends StatelessWidget {
  const LabelValue(this.label, this.value, {super.key});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, spacing: 2, children: <Widget>[
      Text(label, style: text.labelMedium?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant)),
      Text(value, style: text.bodyLarge),
    ]);
  }
}

/// "Documents lodged with the claim" (QO1.4): the document type, the file
/// name and the size.
class DocumentsCard extends StatelessWidget {
  const DocumentsCard({super.key, required this.documents, required this.onView});

  final List<Map<String, Object?>> documents;
  final ValueChanged<Map<String, Object?>> onView;

  static bool isImage(String fileName) => RegExp(r'\.(jpe?g|png)$', caseSensitive: false).hasMatch(fileName);

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    return ConsoleCard(
      title: 'Documents lodged with the claim',
      children: <Widget>[
        if (documents.isEmpty) const Text('No documents were sent.'),
        for (final Map<String, Object?> d in documents)
          Row(spacing: 12, children: <Widget>[
            Icon(isImage('${d['file_name']}') ? Icons.image : Icons.description, color: colors.primary),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
                Text('${d['document_type'] ?? d['file_name']}', style: Theme.of(context).textTheme.bodyLarge),
                Text('${d['file_name']} · ${d['file_size']}', style: Theme.of(context).textTheme.bodySmall),
              ]),
            ),
            TextButton.icon(onPressed: () => onView(d), icon: const Icon(Icons.visibility), label: const Text('View')),
          ]),
      ],
    );
  }
}

/// The note under the documents (Figma O1-2).
class UserIsToldNote extends StatelessWidget {
  const UserIsToldNote({super.key});

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.surfaceContainerLow, borderRadius: BorderRadius.circular(12)),
      child: Row(spacing: 12, children: <Widget>[
        Icon(Icons.notifications, size: 20, color: colors.primary),
        Expanded(
          child: Text(
            'The user sees every status change in the application and receives a message when you confirm the result.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),
      ]),
    );
  }
}
