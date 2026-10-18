import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../shell/console_shell.dart';
import '../treatment/report_card.dart';
import 'report_providers.dart';
import 'view_status_chip.dart';

/// O6-1 Consultation Reports list (SA report figure 2-90): O6 steps 1 to 2.
class ReportListPage extends ConsumerWidget {
  const ReportListPage({super.key});

  /// O6 step 2.1: "Open" goes to the Consultation Report Page.
  static void selectReport(BuildContext context, Object? reportId) => context.go('/reports/$reportId');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<List<Map<String, Object?>>> list = ref.watch(reportListProvider);
    final List<Map<String, Object?>> rows = list.value ?? const <Map<String, Object?>>[];
    final ColorScheme colors = Theme.of(context).colorScheme;
    final TextTheme text = Theme.of(context).textTheme;
    final int notViewed = rows.where((Map<String, Object?> r) => r['view_status'] == 'Pending').length;
    return ConsolePage(
      title: 'Consultation Reports',
      subtitle: 'Reports filed by consultants',
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(reportListProvider.future),
        child: ListView(padding: const EdgeInsets.all(24), children: <Widget>[
          Container(
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
                  Icon(Icons.description, color: colors.primary),
                  Expanded(child: Text('Reports', style: text.titleMedium)),
                  Text('$notViewed not viewed', style: text.bodySmall),
                ]),
              ),
              if (list.isLoading) const Padding(padding: EdgeInsets.all(16), child: LinearProgressIndicator()),
              if (list.hasError)
                const Padding(padding: EdgeInsets.all(16), child: Text('The reports cannot be shown now.')),
              if (list.hasValue && rows.isEmpty)
                const Padding(padding: EdgeInsets.all(16), child: Text('There are no filed reports.')),
              if (rows.isNotEmpty)
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    headingRowColor: WidgetStatePropertyAll<Color>(colors.surfaceContainerLow),
                    dataRowMinHeight: 64,
                    dataRowMaxHeight: 64,
                    columns: const <DataColumn>[
                      DataColumn(label: Text('Report')),
                      DataColumn(label: Text('Claim ID')),
                      DataColumn(label: Text('User')),
                      DataColumn(label: Text('Version')),
                      DataColumn(label: Text('Signed')),
                      DataColumn(label: Text('View status')),
                      DataColumn(label: SizedBox.shrink()),
                    ],
                    rows: <DataRow>[
                      for (final Map<String, Object?> r in rows)
                        DataRow(cells: <DataCell>[
                          DataCell(Text(ReportShortcutCard.reportNo(r['report_id']), style: text.titleSmall)),
                          DataCell(Text('${r['claim_no']}')),
                          DataCell(Text('${r['user_name']}')),
                          DataCell(Text('${r['version_no']}')),
                          DataCell(Text('${r['signed_date']}')),
                          DataCell(ViewStatusChip('${r['view_status']}')),
                          DataCell(FilledButton.tonal(
                            onPressed: () => selectReport(context, r['report_id']),
                            child: const Text('Open'),
                          )),
                        ]),
                    ],
                  ),
                ),
            ]),
          ),
        ]),
      ),
    );
  }
}
