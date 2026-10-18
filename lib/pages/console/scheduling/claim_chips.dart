import 'package:flutter/material.dart';

import '../verification/claim_cards.dart';

/// "Claims ready to schedule" (Figma O4-1, QO4.1) or "Claims with a filed
/// report" (Figma O5.1-1, QO5.1): one chip for each claim.
class ClaimChips extends StatelessWidget {
  const ClaimChips({
    super.key,
    this.title = 'Claims ready to schedule',
    this.empty = 'There are no claims to schedule.',
    required this.claims,
    required this.selectedId,
    required this.loading,
    required this.onSelect,
  });

  final String title;
  final String empty;
  final List<Map<String, Object?>> claims;
  final int? selectedId;
  final bool loading;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    return ConsoleCard(
      title: title,
      trailing: Text('${claims.length} claims', style: Theme.of(context).textTheme.bodySmall),
      children: <Widget>[
        if (loading) const Center(child: CircularProgressIndicator()),
        if (!loading && claims.isEmpty) Text(empty),
        Wrap(spacing: 8, runSpacing: 8, children: <Widget>[
          for (final Map<String, Object?> c in claims)
            ChoiceChip(
              label: Text('${c['claim_no']} · ${c['user_name']}'),
              selected: c['claim_id'] == selectedId,
              onSelected: (_) => onSelect(c['claim_id']! as int),
            ),
        ]),
      ],
    );
  }
}
