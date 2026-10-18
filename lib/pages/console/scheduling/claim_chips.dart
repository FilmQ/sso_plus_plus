import 'package:flutter/material.dart';

import '../verification/claim_cards.dart';

/// "Claims ready to schedule" (Figma O4-1): one chip for each QO4.1 row.
class ClaimChips extends StatelessWidget {
  const ClaimChips({
    super.key,
    required this.claims,
    required this.selectedId,
    required this.loading,
    required this.onSelect,
  });

  final List<Map<String, Object?>> claims;
  final int? selectedId;
  final bool loading;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    return ConsoleCard(
      title: 'Claims ready to schedule',
      trailing: Text('${claims.length} claims', style: Theme.of(context).textTheme.bodySmall),
      children: <Widget>[
        if (loading) const Center(child: CircularProgressIndicator()),
        if (!loading && claims.isEmpty) const Text('There are no claims to schedule.'),
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
