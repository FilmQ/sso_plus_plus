import 'package:flutter/material.dart';

import '../verification/claim_cards.dart';

/// "Claims ready to schedule" (Figma O4-1, QO4.1), "Claims with a filed
/// report" (Figma O5.1-1, QO5.1) or "Consultations waiting for a report"
/// (Figma C2.1-1, QC2.1): one chip for each row.
class ClaimChips extends StatelessWidget {
  const ClaimChips({
    super.key,
    this.title = 'Claims ready to schedule',
    this.empty = 'There are no claims to schedule.',
    this.idKey = 'claim_id',
    this.labelOf,
    this.countLabel = 'claims',
    required this.claims,
    required this.selectedId,
    required this.loading,
    required this.onSelect,
  });

  final String title;
  final String empty;

  /// The key of the row ID: claim_id, or appointment_id for C2.1.
  final String idKey;

  /// The chip text; by default 'claim_no · user_name'.
  final String Function(Map<String, Object?> row)? labelOf;

  /// The word after the number in the title row, for example 'claims'.
  final String countLabel;
  final List<Map<String, Object?>> claims;
  final int? selectedId;
  final bool loading;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    return ConsoleCard(
      title: title,
      trailing: Text('${claims.length} $countLabel', style: Theme.of(context).textTheme.bodySmall),
      children: <Widget>[
        if (loading) const Center(child: CircularProgressIndicator()),
        if (!loading && claims.isEmpty) Text(empty),
        Wrap(spacing: 8, runSpacing: 8, children: <Widget>[
          for (final Map<String, Object?> c in claims)
            ChoiceChip(
              label: Text(labelOf?.call(c) ?? '${c['claim_no']} · ${c['user_name']}'),
              selected: c[idKey] == selectedId,
              onSelected: (_) => onSelect(c[idKey]! as int),
            ),
        ]),
      ],
    );
  }
}
