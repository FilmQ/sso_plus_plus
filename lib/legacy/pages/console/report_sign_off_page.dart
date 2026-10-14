import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../models/consultation_report.dart';
import '../../models/insured_person.dart';
import '../../providers/clinic_providers.dart';
import '../../providers/officer_providers.dart';
import '../../providers/rail_counts_provider.dart';
import '../../providers/use_case_providers.dart';
import '../../use-cases/uc_10_generate_consultation_report.dart';
import '../../widgets/console/console_card.dart';
import '../../widgets/console/console_scaffolds.dart';
import '../../widgets/console/report_preview.dart';
import '../../widgets/shared/async_value_view.dart';
import '../../widgets/shared/claim_status_badge.dart';
import '../../widgets/shared/detail_row.dart';
import '../../widgets/shared/empty_state.dart';
import '../../widgets/shared/notice_banner.dart';

/// D7 · Consultant — report sign-off (UC-10).
///
/// BR-28 says that the signature locks the version. A correction becomes a
/// new version, and this one is kept as superseded.
class ReportSignOffPage extends ConsumerStatefulWidget {
  const ReportSignOffPage({super.key, required this.reportId});

  final String reportId;

  @override
  ConsumerState<ReportSignOffPage> createState() => _ReportSignOffPageState();
}

class _ReportSignOffPageState extends ConsumerState<ReportSignOffPage> {
  bool _busy = false;

  @override
  Widget build(BuildContext context) {
    final AsyncValue<ConsultationReport?> report = ref.watch(
      reportProvider(widget.reportId),
    );

    return ConsoleScreen(
      title: 'Report',
      subtitle: 'Consultant · sign and file the consultation report',
      body: AsyncValueView<ConsultationReport?>(
        value: report,
        onRetry: () => ref.invalidate(reportProvider(widget.reportId)),
        builder: (ConsultationReport? found) {
          if (found == null) {
            return const EmptyState(
              icon: Icons.search_off,
              title: 'This report is not known',
            );
          }

          final AsyncValue<InsuredPerson?> person = ref.watch(
            personForClaimProvider(found.claimNumber),
          );

          return DetailBody(
            breadcrumb: <String>['Reports', found.claimNumber],
            onBack: () => context.go('/clinic/reports'),
            context_: <Widget>[
              ReportPreview(
                report: found,
                patientName: person.value?.fullName ?? 'Unknown',
                patientId: person.value?.maskedNationalId ?? '—',
              ),
            ],
            action: <Widget>[
              _checks(found),
              const NoticeBanner(
                text:
                    'Signing locks this version. A correction is issued as a '
                    'new version, and this one is kept (BR-28).',
                icon: Icons.lock_outline,
              ),
              const NoticeBanner(
                text:
                    'On signing, the claimant and the Evaluation Officer can '
                    'read the report in the application.',
                icon: Icons.mark_email_read_outlined,
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _checks(ConsultationReport report) {
    final List<String> outstanding = ref
        .read(generateReportProvider)
        .outstandingChecks(report);

    bool done(String label) => !outstanding.contains(label);

    return ConsoleCard(
      title: 'Before signing',
      trailing: ClaimStatusBadge(
        label: report.isSigned ? 'Signed' : 'Draft · unsigned',
        tone: report.isSigned ? BadgeTone.good : BadgeTone.neutral,
      ),
      children: <Widget>[
        _check('Findings recorded', done('Findings recorded')),
        _check('Diagnosis recorded', done('Diagnosis recorded')),
        _check(
          'Recommended treatment recorded',
          done('Recommended treatment recorded'),
        ),
        _check('Written in plain language', true, last: true),
        const SizedBox(height: 16),
        FilledButton.icon(
          onPressed: _busy || report.isSigned ? null : () => _sign(report),
          icon: const Icon(Icons.draw_outlined),
          label: Text(
            report.isSigned ? 'Already signed' : 'Sign and file the report',
          ),
        ),
        const SizedBox(height: 10),
        OutlinedButton.icon(
          onPressed: _busy ? null : () => context.go('/clinic/sessions'),
          icon: const Icon(Icons.edit_outlined),
          label: const Text('Amend the draft'),
        ),
      ],
    );
  }

  Widget _check(String label, bool done, {bool last = false}) {
    return DetailRow(
      icon: done ? Icons.check_circle : Icons.radio_button_unchecked,
      label: label,
      detail: done
          ? 'Ready'
          : 'Mandatory clinical field. Return to the session.',
      dense: last,
    );
  }

  Future<void> _sign(ConsultationReport report) async {
    setState(() => _busy = true);
    try {
      final SignResult result = await ref
          .read(generateReportProvider)
          .sign(report);

      if (!mounted) {
        return;
      }
      ref.invalidate(reportProvider(widget.reportId));
      ref.invalidate(reportQueueProvider);
      ref.invalidate(treatmentQueueProvider);
      ref.invalidate(railCountsProvider);

      switch (result) {
        case ReportSigned(report: final ConsultationReport signed):
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'The report is signed and filed. Book the treatment next.',
              ),
            ),
          );
          context.go('/clinic/treatment/${signed.id}');
        case ReportNotReady(missing: final List<String> missing):
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Still outstanding: ${missing.join(', ')}.'),
            ),
          );
      }
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }
}
