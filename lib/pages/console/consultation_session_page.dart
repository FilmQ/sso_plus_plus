import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../models/claim.dart';
import '../../models/consultation_session.dart';
import '../../models/insured_person.dart';
import '../../providers/claim_providers.dart';
import '../../providers/clinic_providers.dart';
import '../../providers/officer_providers.dart';
import '../../providers/rail_counts_provider.dart';
import '../../providers/staff_provider.dart';
import '../../providers/use_case_providers.dart';
import '../../use-cases/uc_09_conduct_consultation.dart';
import '../../widgets/console/clinical_fields_form.dart';
import '../../widgets/console/console_card.dart';
import '../../widgets/console/console_scaffolds.dart';
import '../../widgets/console/document_row.dart';
import '../../widgets/shared/async_value_view.dart';
import '../../widgets/shared/claim_status_badge.dart';
import '../../widgets/shared/detail_row.dart';
import '../../widgets/shared/empty_state.dart';
import '../../widgets/shared/formats.dart';
import '../../widgets/shared/notice_banner.dart';

/// D6 · Consultant — consultation session (UC-09).
///
/// BR-25 says that the attending consultant records the findings and that
/// nobody else does. A star marks a mandatory field.
class ConsultationSessionPage extends ConsumerStatefulWidget {
  const ConsultationSessionPage({super.key, required this.sessionId});

  final String sessionId;

  @override
  ConsumerState<ConsultationSessionPage> createState() =>
      _ConsultationSessionPageState();
}

class _ConsultationSessionPageState
    extends ConsumerState<ConsultationSessionPage> {
  final TextEditingController _findings = TextEditingController();
  final TextEditingController _diagnosis = TextEditingController();
  final TextEditingController _treatment = TextEditingController();
  final TextEditingController _fitness = TextEditingController();

  bool _loaded = false;
  bool _busy = false;
  List<String> _missing = const <String>[];

  @override
  void dispose() {
    _findings.dispose();
    _diagnosis.dispose();
    _treatment.dispose();
    _fitness.dispose();
    super.dispose();
  }

  void _fill(ConsultationSession session) {
    if (_loaded) {
      return;
    }
    _findings.text = session.findings;
    _diagnosis.text = session.diagnosis;
    _treatment.text = session.recommendedTreatment;
    _fitness.text = session.fitnessForWork;
    _loaded = true;
  }

  @override
  Widget build(BuildContext context) {
    final AsyncValue<ConsultationSession?> session = ref.watch(
      sessionProvider(widget.sessionId),
    );

    return ConsoleScreen(
      title: 'Consultation',
      subtitle: 'Consultant · record the session',
      body: AsyncValueView<ConsultationSession?>(
        value: session,
        onRetry: () => ref.invalidate(sessionProvider(widget.sessionId)),
        builder: (ConsultationSession? found) {
          if (found == null) {
            return const EmptyState(
              icon: Icons.search_off,
              title: 'This session is not known',
              message:
                  'A consultant sees only the sessions assigned to them '
                  '(BR-22).',
            );
          }
          _fill(found);

          final AsyncValue<Claim?> claim = ref.watch(
            claimProvider(found.claimNumber),
          );
          final AsyncValue<InsuredPerson?> person = ref.watch(
            personForClaimProvider(found.claimNumber),
          );

          return DetailBody(
            breadcrumb: <String>['Sessions', found.claimNumber],
            onBack: () => context.go('/clinic/sessions'),
            context_: <Widget>[
              _patient(person.value, found),
              if (claim.value != null) _injury(claim.value!),
              if (claim.value != null) _documents(claim.value!),
            ],
            action: <Widget>[
              _record(found),
              _outcomes(found),
              const NoticeBanner(
                text:
                    'Completing the session produces the report at once. A '
                    'completed consultation always produces one (BR-26).',
                icon: Icons.description_outlined,
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _patient(InsuredPerson? person, ConsultationSession session) {
    final ThemeData theme = Theme.of(context);

    return ConsoleCard(
      showDivider: false,
      children: <Widget>[
        Row(
          children: <Widget>[
            CircleAvatar(
              radius: 22,
              backgroundColor: theme.colorScheme.secondaryContainer,
              child: Text(
                person == null
                    ? '?'
                    : person.fullName
                          .split(' ')
                          .map((String p) => p.substring(0, 1))
                          .take(2)
                          .join(),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    person?.fullName ?? 'Unknown',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    person?.maskedNationalId ?? '—',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            const ClaimStatusBadge(
              label: 'Covered · Section 33',
              tone: BadgeTone.good,
              icon: Icons.verified,
            ),
          ],
        ),
        const SizedBox(height: 10),
        Text(
          'Session ${session.status.label.toLowerCase()} · '
          '${session.format.label} · ${session.room}',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _injury(Claim claim) {
    return ConsoleCard(
      title: 'Injury on the claim',
      children: <Widget>[
        FactGrid(
          perRow: 2,
          cells: <FactCell>[
            FactCell(
              label: 'Date and time',
              value: claim.injury.date == null
                  ? '—'
                  : '${Formats.shortDate(claim.injury.date!)} · '
                        '${claim.injury.time ?? ''}',
            ),
            FactCell(label: 'Cause', value: claim.injury.cause),
            FactCell(label: 'Part of body', value: claim.injury.bodyPart),
            FactCell(label: 'Employer', value: claim.injury.employer),
          ],
        ),
      ],
    );
  }

  Widget _documents(Claim claim) {
    return ConsoleCard(
      title: 'Case file',
      children: <Widget>[
        for (int i = 0; i < claim.documents.length; i++)
          DocumentRow(
            document: claim.documents[i],
            isLast: i == claim.documents.length - 1,
            onView: () {},
          ),
      ],
    );
  }

  Widget _record(ConsultationSession session) {
    final ThemeData theme = Theme.of(context);
    final bool closed = session.status == SessionStatus.completed;

    return ConsoleCard(
      title: 'Record the consultation',
      trailing: session.draftSavedAt == null
          ? null
          : ClaimStatusBadge(
              label: 'Draft saved ${Formats.time(session.draftSavedAt!)}',
            ),
      children: <Widget>[
        Text(
          'Only the attending consultant records these fields (BR-25).',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 14),
        ClinicalFieldsForm(
          findings: _findings,
          diagnosis: _diagnosis,
          recommendedTreatment: _treatment,
          fitnessForWork: _fitness,
          enabled: !closed && !_busy,
          missing: _missing,
        ),
        Text(
          'A star marks a mandatory clinical field.',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 14),
        Row(
          children: <Widget>[
            Expanded(
              child: OutlinedButton.icon(
                onPressed: closed || _busy ? null : () => _saveDraft(session),
                icon: const Icon(Icons.save_outlined),
                label: const Text('Save draft'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: FilledButton.icon(
                onPressed: closed || _busy ? null : () => _complete(session),
                icon: const Icon(Icons.check),
                label: const Text('Complete session'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _outcomes(ConsultationSession session) {
    return ConsoleCard(
      title: 'Other outcomes',
      children: <Widget>[
        InkWell(
          onTap: _busy ? null : () => _notAttended(session),
          child: const Padding(
            padding: EdgeInsets.symmetric(vertical: 4),
            child: DetailRow(
              icon: Icons.person_off_outlined,
              label: 'The patient did not attend',
              detail: 'Closes the session and returns the claim to scheduling.',
            ),
          ),
        ),
        const DetailRow(
          icon: Icons.science_outlined,
          label: 'Further investigation is necessary',
          detail:
              'Books a follow-up; the report says the findings are '
              'interim.',
        ),
        const DetailRow(
          icon: Icons.help_outline,
          label: 'The injury is unrelated to the work incident',
          detail: 'Refers the claim back to the Evaluation Officer.',
          dense: true,
        ),
      ],
    );
  }

  Future<void> _saveDraft(ConsultationSession session) async {
    setState(() => _busy = true);
    try {
      await ref
          .read(conductConsultationProvider)
          .saveDraft(
            session: session,
            findings: _findings.text,
            diagnosis: _diagnosis.text,
            recommendedTreatment: _treatment.text,
            fitnessForWork: _fitness.text,
          );
      if (!mounted) {
        return;
      }
      ref.invalidate(sessionProvider(widget.sessionId));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('The draft is kept on the session.')),
      );
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  Future<void> _complete(ConsultationSession session) async {
    setState(() => _busy = true);
    try {
      final staff = ref.read(currentStaffProvider);
      final ConsultationResult result = await ref
          .read(conductConsultationProvider)
          .complete(
            session: session,
            findings: _findings.text,
            diagnosis: _diagnosis.text,
            recommendedTreatment: _treatment.text,
            fitnessForWork: _fitness.text,
            consultantName: staff.name,
            specialty: 'Orthopaedics',
          );

      if (!mounted) {
        return;
      }
      _refresh();

      switch (result) {
        case ConsultationCompleted(report: final report):
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('The session is complete. Sign the report next.'),
            ),
          );
          context.go('/clinic/reports/${report.id}');
        case MandatoryFieldsMissing(fields: final List<String> fields):
          setState(() => _missing = fields);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'These fields are mandatory: ${fields.join(', ')}.',
              ),
            ),
          );
        case PatientDidNotAttend():
          break;
      }
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  Future<void> _notAttended(ConsultationSession session) async {
    setState(() => _busy = true);
    try {
      await ref.read(conductConsultationProvider).recordNonAttendance(session);
      if (!mounted) {
        return;
      }
      _refresh();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'The non-attendance is recorded. The claim returns to '
            'scheduling.',
          ),
        ),
      );
      context.go('/clinic/sessions');
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  void _refresh() {
    ref.invalidate(sessionProvider(widget.sessionId));
    ref.invalidate(sessionQueueProvider);
    ref.invalidate(reportQueueProvider);
    ref.invalidate(schedulingWorklistProvider);
    ref.invalidate(railCountsProvider);
  }
}
