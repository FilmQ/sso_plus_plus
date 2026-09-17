import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../models/appointment.dart';
import '../../models/consultation_report.dart';
import '../../providers/appointment_providers.dart';
import '../../providers/claim_providers.dart';
import '../../widgets/patient/notice_banner.dart';
import '../../widgets/shared/async_value_view.dart';
import '../../widgets/shared/claim_status_badge.dart';
import '../../widgets/shared/detail_row.dart';
import '../../widgets/shared/empty_state.dart';
import '../../widgets/shared/formats.dart';
import '../../widgets/shared/info_card.dart';
import '../../widgets/shared/report_section.dart';

/// M8 · Consultation report (UC-09 → UC-10).
///
/// BR-30 says that the report is written in language the patient can read.
/// BR-28 says that a signed report cannot change, so the screen says so.
class ConsultationReportPage extends ConsumerWidget {
  const ConsultationReportPage({super.key, required this.claimNumber});

  final String claimNumber;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colors = theme.colorScheme;
    final AsyncValue<ConsultationReport?> report = ref.watch(
      latestReportProvider(claimNumber),
    );
    final AsyncValue<List<Appointment>> appointments = ref.watch(
      appointmentsProvider,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Consultation report'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.canPop()
              ? context.pop()
              : context.go('/claims/$claimNumber'),
        ),
      ),
      body: AsyncValueView<ConsultationReport?>(
        value: report,
        onRetry: () => ref.invalidate(latestReportProvider(claimNumber)),
        builder: (ConsultationReport? found) {
          if (found == null) {
            return const EmptyState(
              icon: Icons.description_outlined,
              title: 'No signed report yet',
              message:
                  'The consultant signs the report after your consultation.',
            );
          }

          final Appointment? treatment = _treatmentFor(
            appointments.value,
            found,
          );

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
            children: <Widget>[
              Row(
                children: <Widget>[
                  ClaimStatusBadge(
                    label: found.versionLabel,
                    tone: found.isSigned ? BadgeTone.good : BadgeTone.neutral,
                    icon: found.isSigned ? Icons.verified : null,
                  ),
                  const Spacer(),
                  if (found.signedAt != null)
                    Text(
                      Formats.dateAndTime(found.signedAt!),
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              InfoCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    DetailRow(
                      icon: Icons.person_outline,
                      label: found.consultantName,
                      detail: '${found.specialty} · signed the report',
                      dense: true,
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      child: Divider(),
                    ),
                    ReportSection(heading: 'Findings', body: found.findings),
                    ReportSection(heading: 'Diagnosis', body: found.diagnosis),
                    ReportSection(
                      heading: 'Recommended treatment',
                      body: found.recommendedTreatment,
                      isLast: true,
                    ),
                  ],
                ),
              ),
              if (treatment != null) ...<Widget>[
                const SizedBox(height: 12),
                InfoCard(
                  tone: InfoCardTone.highlighted,
                  onTap: () => context.go('/appointments/${treatment.id}'),
                  child: DetailRow(
                    icon: Icons.medical_services_outlined,
                    label: 'Treatment booked for you',
                    detail:
                        '${Formats.shortDateWithDay(treatment.start)} · '
                        '${Formats.time(treatment.start)}',
                    dense: true,
                  ),
                ),
              ],
              const SizedBox(height: 16),
              const NoticeBanner(
                text:
                    'A signed report cannot be changed. A correction is '
                    'issued as a new version, and this one is kept.',
                icon: Icons.lock_outline,
              ),
            ],
          );
        },
      ),
    );
  }

  /// The treatment that this report produced (BR-31).
  static Appointment? _treatmentFor(
    List<Appointment>? all,
    ConsultationReport report,
  ) {
    if (all == null) {
      return null;
    }
    for (final Appointment appointment in all) {
      if (appointment.kind == AppointmentKind.treatment &&
          appointment.reportId == report.id) {
        return appointment;
      }
    }
    return null;
  }
}
