import 'package:flutter/material.dart';

import '../../../widgets/status_chip.dart';

/// "Claims to verify" (Figma O1-1): one QO1.1 row a line, with "Open" on the
/// right. On a narrow screen the table scrolls to the side.
class ClaimsTable extends StatelessWidget {
  const ClaimsTable({super.key, required this.claims, required this.onOpen});

  final List<Map<String, Object?>> claims;
  final ValueChanged<int> onOpen;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    final TextTheme text = Theme.of(context).textTheme;
    String s(Map<String, Object?> row, String key) => '${row[key] ?? ''}';
    return Container(
      decoration: BoxDecoration(
        color: colors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.outlineVariant),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: <Widget>[
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(spacing: 8, children: <Widget>[
            Icon(Icons.fact_check, color: colors.primary),
            Expanded(child: Text('Claims to verify', style: text.titleMedium)),
            Text('Showing ${claims.length} of ${claims.length}', style: text.bodySmall),
          ]),
        ),
        if (claims.isEmpty)
          const Padding(padding: EdgeInsets.fromLTRB(16, 0, 16, 16), child: Text('There are no claims to verify.'))
        else
          LayoutBuilder(
            builder: (BuildContext context, BoxConstraints box) => SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: ConstrainedBox(
                constraints: BoxConstraints(minWidth: box.maxWidth),
                child: DataTable(
                  // The default spacing (56) cuts off "Open" at 1440 x 900 (D-065).
                  columnSpacing: 32,
                  headingRowColor: WidgetStatePropertyAll<Color>(colors.surfaceContainerLow),
                  dataRowMinHeight: 64,
                  dataRowMaxHeight: 64,
                  columns: const <DataColumn>[
                    DataColumn(label: Text('Claim ID')),
                    DataColumn(label: Text('Claimant')),
                    DataColumn(label: Text('Injury')),
                    DataColumn(label: Text('Submitted')),
                    DataColumn(label: Text('Documents')),
                    DataColumn(label: Text('Status')),
                    // numeric: the cell content goes to the right.
                    DataColumn(label: SizedBox.shrink(), numeric: true),
                  ],
                  rows: <DataRow>[
                    for (final Map<String, Object?> row in claims)
                      DataRow(cells: <DataCell>[
                        DataCell(Text(s(row, 'claim_no'), style: text.titleSmall)),
                        DataCell(Text(s(row, 'claimant_name'))),
                        DataCell(Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(s(row, 'injury')),
                            Text(s(row, 'injury_date'), style: text.bodySmall),
                          ],
                        )),
                        DataCell(Text(s(row, 'submitted_date'))),
                        DataCell(Text('${s(row, 'documents_sent')} files')),
                        DataCell(ClaimStatusChip(s(row, 'verification_status'))),
                        DataCell(FilledButton.tonal(
                          onPressed: () => onOpen(row['claim_id']! as int),
                          child: const Text('Open'),
                        )),
                      ]),
                  ],
                ),
              ),
            ),
          ),
      ]),
    );
  }
}
