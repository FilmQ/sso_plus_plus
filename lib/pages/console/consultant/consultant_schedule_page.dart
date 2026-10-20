import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../api/consultant_api.dart';
import '../../../widgets/person_avatar.dart';
import '../shell/console_shell.dart';
import 'consultant_providers.dart';
import 'recent_changes_card.dart';

/// C1-1 Schedule Page (SA report figure 2-95): C1 View Appointment Schedule,
/// the "Recent changes" card (QC1.2) and the Confirmed appointments of the
/// consultant from today on (QC1.1).
class ConsultantSchedulePage extends ConsumerWidget {
  const ConsultantSchedulePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<ConsultantSchedule> list = ref.watch(consultantScheduleProvider);
    final List<Map<String, Object?>> rows = list.value?.appointments ?? const <Map<String, Object?>>[];
    final ColorScheme colors = Theme.of(context).colorScheme;
    final TextTheme text = Theme.of(context).textTheme;
    return ConsolePage(
      title: 'Schedule Page',
      subtitle: 'Confirmed appointments from today and recent changes from users',
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(consultantScheduleProvider.future),
        child: ListView(padding: const EdgeInsets.all(24), children: <Widget>[
          RecentChangesCard(
            messages: list.value?.recentChanges ?? const <Map<String, Object?>>[],
            loading: list.isLoading,
          ),
          const SizedBox(height: 16),
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
                  Icon(Icons.calendar_month, color: colors.primary),
                  Expanded(child: Text('Upcoming appointments', style: text.titleMedium)),
                  Text('${rows.length} confirmed', style: text.bodySmall),
                ]),
              ),
              if (list.isLoading) const Padding(padding: EdgeInsets.all(16), child: LinearProgressIndicator()),
              if (list.hasError)
                const Padding(padding: EdgeInsets.all(16), child: Text('The appointments cannot be shown now.')),
              if (list.hasValue && rows.isEmpty)
                const Padding(padding: EdgeInsets.all(16), child: Text('You have no confirmed appointments.')),
              if (rows.isNotEmpty)
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    headingRowColor: WidgetStatePropertyAll<Color>(colors.surfaceContainerLow),
                    dataRowMinHeight: 64,
                    dataRowMaxHeight: 64,
                    columns: const <DataColumn>[
                      DataColumn(label: Text('User')),
                      DataColumn(label: Text('Appointment date')),
                      DataColumn(label: Text('Claim ID')),
                      DataColumn(label: Text('Injury')),
                      DataColumn(label: Text('Injury date')),
                    ],
                    rows: <DataRow>[
                      for (final Map<String, Object?> r in rows)
                        DataRow(cells: <DataCell>[
                          DataCell(Row(spacing: 12, children: <Widget>[
                            PersonAvatar('${r['user_name']}'),
                            Text('${r['user_name']}'),
                          ])),
                          DataCell(Text('${r['appointment_date']}', style: text.titleSmall)),
                          DataCell(Text('${r['claim_no']}')),
                          DataCell(Text('${r['injury']}')),
                          DataCell(Text('${r['injury_date']}')),
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
