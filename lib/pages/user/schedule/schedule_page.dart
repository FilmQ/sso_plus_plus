import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../widgets/centered_body.dart';
import '../notifications/notification_providers.dart';
import 'schedule_cards.dart';
import 'schedule_providers.dart';

/// U5-1 Schedule Page · Appointments and U6-1 Schedule Page · Treatments
/// (SA report figures 2-49 and 2-52). U5 (QU5.1) and U6 (Q6.1).
class SchedulePage extends ConsumerStatefulWidget {
  const SchedulePage({super.key});

  @override
  ConsumerState<SchedulePage> createState() => _SchedulePageState();
}

class _SchedulePageState extends ConsumerState<SchedulePage> {
  String activeTab = 'Appointments';

  /// U4: a treatment card opens the Confirm Treatment page.
  Future<void> _openTreatment(Map<String, Object?> row) async {
    await context.push('/treatment/${row['treatment_id']}');
    refreshUserData(ref);
  }

  @override
  Widget build(BuildContext context) {
    final bool appointments = activeTab == 'Appointments';
    final AsyncValue<List<Map<String, Object?>>> rows =
        ref.watch(appointments ? appointmentScheduleProvider : treatmentScheduleProvider);
    final List<Map<String, Object?>> items = rows.value ?? const <Map<String, Object?>>[];
    return Scaffold(
      appBar: AppBar(title: const Text('Schedule')),
      body: RefreshIndicator(
        onRefresh: () async {
          refreshUserData(ref);
          await ref.read((appointments ? appointmentScheduleProvider : treatmentScheduleProvider).future);
        },
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          children: <Widget>[
            CenteredBody(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                spacing: 12,
                children: <Widget>[
                  SegmentedButton<String>(
                    segments: const <ButtonSegment<String>>[
                      ButtonSegment<String>(value: 'Appointments', label: Text('Appointments')),
                      ButtonSegment<String>(value: 'Treatments', label: Text('Treatments')),
                    ],
                    selected: <String>{activeTab},
                    onSelectionChanged: (Set<String> s) => setState(() => activeTab = s.single),
                  ),
                  Text('Upcoming', style: Theme.of(context).textTheme.titleSmall),
                  if (rows.isLoading) const Center(child: CircularProgressIndicator()),
                  if (rows.hasError) const Text('The schedule cannot be shown now. Pull down to try again.'),
                  if (rows.hasValue && items.isEmpty)
                    Text(appointments ? 'You have no upcoming appointments.' : 'You have no upcoming treatments.'),
                  for (final Map<String, Object?> row in items)
                    appointments
                        ? AppointmentScheduleCard(row: row)
                        : TreatmentScheduleCard(row: row, onTap: () => _openTreatment(row)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
