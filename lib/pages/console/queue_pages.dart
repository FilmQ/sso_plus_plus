import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../models/claim.dart';
import '../../models/consultation_report.dart';
import '../../models/consultation_session.dart';
import '../../providers/clinic_providers.dart';
import '../../providers/officer_providers.dart';
import '../../widgets/console/console_scaffolds.dart';
import '../../widgets/console/worklist_panel.dart';
import '../../widgets/shared/async_value_view.dart';
import '../../widgets/shared/formats.dart';

/// The landing screens of five rail destinations.
///
/// The design draws the detail of each of these (D3, D5, D6, D7 and D8). A
/// list has to come first, because the rail opens a destination and not a
/// single case. Each list uses the same panel as D1 and D4.

/// One row of a queue.
class _Row {
  const _Row({
    required this.title,
    required this.detail,
    required this.trailing,
    required this.route,
  });

  final String title;
  final String detail;
  final String trailing;
  final String route;
}

class _QueueScreen extends StatelessWidget {
  const _QueueScreen({
    required this.title,
    required this.subtitle,
    required this.heading,
    required this.trailingColumn,
    required this.rows,
  });

  final String title;
  final String subtitle;
  final String heading;
  final String trailingColumn;
  final List<_Row> rows;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return ConsoleScreen(
      title: title,
      subtitle: subtitle,
      body: WorklistBody(
        panels: <Widget>[
          WorklistPanel(
            heading: heading,
            footer: '${rows.length} in this queue',
            columns: <WorklistColumn>[
              const WorklistColumn('Case', flex: 4),
              WorklistColumn(trailingColumn, flex: 3),
              const WorklistColumn('', flex: 1),
            ],
            rows: <List<Widget>>[
              for (final _Row row in rows)
                <Widget>[
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(row.title, style: theme.textTheme.bodyMedium),
                      Text(
                        row.detail,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                  Text(row.trailing, style: theme.textTheme.bodyMedium),
                  Align(
                    alignment: Alignment.centerRight,
                    child: FilledButton.tonal(
                      onPressed: () => context.go(row.route),
                      child: const Text('Open'),
                    ),
                  ),
                ],
            ],
          ),
        ],
      ),
    );
  }
}

/// The claims that are covered and need a date (opens D3).
class SchedulingQueuePage extends ConsumerWidget {
  const SchedulingQueuePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<List<Claim>> claims = ref.watch(
      schedulingWorklistProvider,
    );

    return AsyncValueView<List<Claim>>(
      value: claims,
      onRetry: () => ref.invalidate(schedulingWorklistProvider),
      builder: (List<Claim> found) => _QueueScreen(
        title: 'Scheduling',
        subtitle: 'Evaluation Officer · covered claims that need a date',
        heading: 'Claims awaiting an appointment',
        trailingColumn: 'Verified',
        rows: <_Row>[
          for (final Claim claim in found)
            _Row(
              title: claim.claimNumber,
              detail: '${claim.injury.bodyPart} · ${claim.injury.employer}',
              trailing: claim.verification == null
                  ? '—'
                  : Formats.shortDate(claim.verification!.decidedAt),
              route: '/officer/scheduling/${claim.claimNumber}',
            ),
        ],
      ),
    );
  }
}

/// The confirmed appointments that need a session (opens D5).
class ConsultationsQueuePage extends ConsumerWidget {
  const ConsultationsQueuePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<List<Claim>> claims = ref.watch(
      consultationWorklistProvider,
    );

    return AsyncValueView<List<Claim>>(
      value: claims,
      onRetry: () => ref.invalidate(consultationWorklistProvider),
      builder: (List<Claim> found) => _QueueScreen(
        title: 'Consultations',
        subtitle: 'Evaluation Officer · confirmed dates to hand over',
        heading: 'Appointments to prepare',
        trailingColumn: 'Injury',
        rows: <_Row>[
          for (final Claim claim in found)
            _Row(
              title: claim.claimNumber,
              detail: claim.injury.employer,
              trailing: claim.injury.bodyPart,
              route: '/officer/consultations/${claim.claimNumber}',
            ),
        ],
      ),
    );
  }
}

/// The sessions of the consultant who is signed in (opens D6).
class SessionsQueuePage extends ConsumerWidget {
  const SessionsQueuePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<List<ConsultationSession>> sessions = ref.watch(
      sessionQueueProvider,
    );

    return AsyncValueView<List<ConsultationSession>>(
      value: sessions,
      onRetry: () => ref.invalidate(sessionQueueProvider),
      builder: (List<ConsultationSession> found) => _QueueScreen(
        title: 'Sessions',
        subtitle: 'Consultant · your prepared consultations',
        heading: 'Sessions assigned to you',
        trailingColumn: 'State',
        rows: <_Row>[
          for (final ConsultationSession session in found)
            _Row(
              title: session.claimNumber,
              detail: '${session.format.label} · ${session.room}',
              trailing: session.status.label,
              route: '/clinic/sessions/${session.id}',
            ),
        ],
      ),
    );
  }
}

/// The reports that wait for a signature (opens D7).
class ReportsQueuePage extends ConsumerWidget {
  const ReportsQueuePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<List<ConsultationReport>> reports = ref.watch(
      reportQueueProvider,
    );

    return AsyncValueView<List<ConsultationReport>>(
      value: reports,
      onRetry: () => ref.invalidate(reportQueueProvider),
      builder: (List<ConsultationReport> found) => _QueueScreen(
        title: 'Reports',
        subtitle: 'Consultant · drafts that wait for your signature',
        heading: 'Unsigned reports',
        trailingColumn: 'Consultation',
        rows: <_Row>[
          for (final ConsultationReport report in found)
            _Row(
              title: report.claimNumber,
              detail: report.versionLabel,
              trailing: report.consultedOn == null
                  ? '—'
                  : Formats.shortDate(report.consultedOn!),
              route: '/clinic/reports/${report.id}',
            ),
        ],
      ),
    );
  }
}

/// The signed reports that need a treatment date (opens D8).
class TreatmentQueuePage extends ConsumerWidget {
  const TreatmentQueuePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<List<ConsultationReport>> reports = ref.watch(
      treatmentQueueProvider,
    );

    return AsyncValueView<List<ConsultationReport>>(
      value: reports,
      onRetry: () => ref.invalidate(treatmentQueueProvider),
      builder: (List<ConsultationReport> found) => _QueueScreen(
        title: 'Treatment',
        subtitle: 'Consultant · signed reports that need a date',
        heading: 'Treatment to book',
        trailingColumn: 'Signed',
        rows: <_Row>[
          for (final ConsultationReport report in found)
            _Row(
              title: report.claimNumber,
              detail: report.recommendedTreatment,
              trailing: report.signedAt == null
                  ? '—'
                  : Formats.shortDate(report.signedAt!),
              route: '/clinic/treatment/${report.id}',
            ),
        ],
      ),
    );
  }
}
