import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../models/appointment.dart';
import '../../models/claim.dart';
import '../../models/claim_progress.dart';
import '../../models/claim_status.dart';
import '../../models/consultation_report.dart';
import '../../providers/appointment_providers.dart';
import '../../providers/claim_providers.dart';
import '../../widgets/shared/claim_status_badge.dart';
import '../../widgets/shared/detail_row.dart';
import '../../widgets/shared/formats.dart';
import '../../widgets/shared/info_card.dart';
import '../../widgets/shared/progress_stepper.dart';
import '../../widgets/shared/section_heading.dart';

/// The claim screen for every stage that has no screen of its own.
///
/// It shows where the claim has reached and the way to the appointment, the
/// report and the treatment.
class ClaimStatusView extends ConsumerWidget {
  const ClaimStatusView({super.key, required this.claim});

  final Claim claim;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colors = theme.colorScheme;
    final AsyncValue<List<Appointment>> appointments = ref.watch(
      appointmentsProvider,
    );
    final AsyncValue<ConsultationReport?> report = ref.watch(
      latestReportProvider(claim.claimNumber),
    );

    final List<Appointment> mine =
        appointments.value
            ?.where((Appointment a) => a.claimNumber == claim.claimNumber)
            .toList() ??
        <Appointment>[];

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: <Widget>[
        Row(
          children: <Widget>[
            ClaimStatusBadge(
              label: claim.status.label,
              tone: _toneFor(claim.status),
            ),
            const Spacer(),
            Text(
              claim.claimNumber,
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
                icon: Icons.healing_outlined,
                label: claim.injury.bodyPart.isEmpty
                    ? 'Injury'
                    : claim.injury.bodyPart,
                detail: claim.injury.cause,
              ),
              DetailRow(
                icon: Icons.event_outlined,
                label: claim.injury.date == null
                    ? 'Date not set'
                    : Formats.shortDate(claim.injury.date!),
                detail: claim.injury.place,
              ),
              DetailRow(
                icon: Icons.business_outlined,
                label: claim.injury.employer,
                detail: 'Employer on the claim',
                dense: true,
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        const SectionHeading('Claim progress'),
        InfoCard(child: ProgressStepper(steps: _stepsFor(claim))),
        if (mine.isNotEmpty) ...<Widget>[
          const SizedBox(height: 8),
          const SectionHeading('Appointments'),
          for (final Appointment appointment in mine)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: InfoCard(
                onTap: () => context.go('/appointments/${appointment.id}'),
                child: DetailRow(
                  icon: appointment.kind == AppointmentKind.treatment
                      ? Icons.medical_services_outlined
                      : Icons.event_available_outlined,
                  label:
                      '${appointment.title} · '
                      '${Formats.shortDateWithDay(appointment.start)}',
                  detail: appointment.status.label,
                  dense: true,
                ),
              ),
            ),
        ],
        if (report.value != null) ...<Widget>[
          const SizedBox(height: 8),
          const SectionHeading('Consultation report'),
          InfoCard(
            onTap: () => context.go('/claims/${claim.claimNumber}/report'),
            child: DetailRow(
              icon: Icons.description_outlined,
              label: 'Report ${report.value!.versionLabel}',
              detail: report.value!.signedAt == null
                  ? 'Not signed yet'
                  : 'Signed ${Formats.dateAndTime(report.value!.signedAt!)}',
              dense: true,
            ),
          ),
        ],
      ],
    );
  }

  static BadgeTone _toneFor(ClaimStatus status) => switch (status) {
    ClaimStatus.verifiedNotCovered || ClaimStatus.rejected => BadgeTone.bad,
    ClaimStatus.appointmentProposed => BadgeTone.action,
    ClaimStatus.verifiedCovered ||
    ClaimStatus.appointmentConfirmed ||
    ClaimStatus.reportSigned ||
    ClaimStatus.treatmentScheduled => BadgeTone.good,
    _ => BadgeTone.neutral,
  };

  static List<ProgressStep> _stepsFor(Claim claim) {
    final Map<ProgressStage, String> details = <ProgressStage, String>{};
    if (claim.submittedAt != null) {
      details[ProgressStage.submitted] = Formats.dateAndTime(
        claim.submittedAt!,
      );
    }
    final verification = claim.verification;
    if (verification != null) {
      details[ProgressStage.verified] =
          '${verification.result.label} · '
          '${Formats.dateAndTime(verification.decidedAt)}';
    }
    return ClaimProgress.stepsFor(claim, details: details);
  }
}
