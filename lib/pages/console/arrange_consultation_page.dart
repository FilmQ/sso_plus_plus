import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../models/appointment.dart';
import '../../models/claim.dart';
import '../../models/consultant.dart';
import '../../models/consultation_session.dart';
import '../../providers/claim_providers.dart';
import '../../providers/officer_providers.dart';
import '../../providers/rail_counts_provider.dart';
import '../../providers/repository_providers.dart';
import '../../providers/use_case_providers.dart';
import '../../use-cases/uc_08_arrange_consultation.dart';
import '../../widgets/console/console_card.dart';
import '../../widgets/console/console_scaffolds.dart';
import '../../widgets/console/document_row.dart';
import '../../widgets/shared/async_value_view.dart';
import '../../widgets/shared/claim_status_badge.dart';
import '../../widgets/shared/detail_row.dart';
import '../../widgets/shared/empty_state.dart';
import '../../widgets/shared/formats.dart';
import '../../widgets/shared/notice_banner.dart';

/// The consultants who may take one claim (BR-11).
final consultantsForClaimProvider =
    FutureProvider.family<List<Consultant>, String>((
      Ref ref,
      String claimNumber,
    ) async {
      final Claim? claim = await ref
          .watch(claimRepositoryProvider)
          .byNumber(claimNumber);
      if (claim == null) {
        return <Consultant>[];
      }
      return ref
          .watch(schedulingRepositoryProvider)
          .consultants(specialty: claim.injury.category?.specialty);
    });

/// D5 · Officer — arrange consultation (UC-08).
///
/// The officer hands the case to the clinical side. The consultant gets the
/// case file, and no other consultant does (BR-22).
class ArrangeConsultationPage extends ConsumerStatefulWidget {
  const ArrangeConsultationPage({super.key, required this.claimNumber});

  final String claimNumber;

  @override
  ConsumerState<ArrangeConsultationPage> createState() =>
      _ArrangeConsultationPageState();
}

class _ArrangeConsultationPageState
    extends ConsumerState<ArrangeConsultationPage> {
  SessionFormat _format = SessionFormat.inPerson;
  Consultant? _consultant;
  bool _busy = false;

  @override
  Widget build(BuildContext context) {
    final AsyncValue<Claim?> claim = ref.watch(
      claimProvider(widget.claimNumber),
    );
    final AsyncValue<Appointment?> appointment = ref.watch(
      appointmentForClaimProvider(widget.claimNumber),
    );
    final AsyncValue<List<Consultant>> consultants = ref.watch(
      consultantsForClaimProvider(widget.claimNumber),
    );
    _consultant ??= consultants.value?.firstOrNull;

    return ConsoleScreen(
      title: 'Consultations',
      subtitle: '${widget.claimNumber} · prepare the clinical handover',
      body: AsyncValueView<Claim?>(
        value: claim,
        onRetry: () => ref.invalidate(claimProvider(widget.claimNumber)),
        builder: (Claim? found) {
          if (found == null) {
            return EmptyState(
              icon: Icons.search_off,
              title: 'No claim carries the number ${widget.claimNumber}',
            );
          }

          return DetailBody(
            breadcrumb: <String>['Consultations', found.claimNumber],
            onBack: () => context.go('/officer/consultations'),
            context_: <Widget>[
              _appointmentCard(appointment.value),
              _caseFile(found),
            ],
            action: <Widget>[
              _session(),
              _release(found, appointment.value, consultants.value),
              const NoticeBanner(
                text:
                    'On release the consultant sees this claim only. The '
                    'access ends when the case closes (BR-22, BR-24).',
                icon: Icons.lock_person_outlined,
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _appointmentCard(Appointment? appointment) {
    if (appointment == null) {
      return const ConsoleCard(
        title: 'Confirmed appointment',
        children: <Widget>[Text('No appointment is on this claim.')],
      );
    }

    return ConsoleCard(
      showDivider: false,
      children: <Widget>[
        Row(
          children: <Widget>[
            Expanded(
              child: Text(
                Formats.longDate(appointment.start),
                style: Theme.of(context).textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.w600),
              ),
            ),
            ClaimStatusBadge(
              label: appointment.channel == null
                  ? 'Confirmed'
                  : 'Confirmed · in application',
              tone: BadgeTone.good,
              icon: Icons.verified,
            ),
          ],
        ),
        const SizedBox(height: 10),
        DetailRow(
          icon: Icons.person_outline,
          label: appointment.consultantName,
          detail:
              '${appointment.specialty} · '
              '${Formats.timeRange(appointment.start, appointment.end)}',
          dense: true,
        ),
      ],
    );
  }

  Widget _caseFile(Claim claim) {
    final int flagged = claim.missingDocuments.length;

    return ConsoleCard(
      title: 'Case file to release',
      trailing: flagged == 0
          ? const ClaimStatusBadge(label: 'Complete', tone: BadgeTone.good)
          : ClaimStatusBadge(
              label: '$flagged item flagged',
              tone: BadgeTone.action,
            ),
      children: <Widget>[
        DetailRow(
          icon: Icons.assignment_outlined,
          label: 'Injury details and claim history',
          detail: 'Complete',
        ),
        for (int i = 0; i < claim.documents.length; i++)
          DocumentRow(
            document: claim.documents[i],
            isLast: i == claim.documents.length - 1,
            onView: () {},
          ),
      ],
    );
  }

  Widget _session() {
    return ConsoleCard(
      title: 'Session',
      children: <Widget>[
        Text(
          'Format',
          style: Theme.of(context).textTheme.labelMedium
              ?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
        ),
        const SizedBox(height: 8),
        SegmentedButton<SessionFormat>(
          segments: const <ButtonSegment<SessionFormat>>[
            ButtonSegment<SessionFormat>(
              value: SessionFormat.inPerson,
              label: Text('In person'),
              icon: Icon(Icons.meeting_room_outlined),
            ),
            ButtonSegment<SessionFormat>(
              value: SessionFormat.tele,
              label: Text('Tele-consultation'),
              icon: Icon(Icons.videocam_outlined),
            ),
          ],
          selected: <SessionFormat>{_format},
          onSelectionChanged: (Set<SessionFormat> value) =>
              setState(() => _format = value.first),
        ),
        const SizedBox(height: 14),
        DetailRow(
          icon: Icons.place_outlined,
          label: _format == SessionFormat.inPerson
              ? 'Room 4, 2nd floor'
              : 'A link is issued to the claimant',
          detail: '30 minutes',
          dense: true,
        ),
      ],
    );
  }

  Widget _release(
    Claim claim,
    Appointment? appointment,
    List<Consultant>? consultants,
  ) {
    final ThemeData theme = Theme.of(context);
    final Consultant? chosen = _consultant;
    final bool incomplete = claim.missingDocuments.isNotEmpty;

    return ConsoleCard(
      title: 'Assigned consultant',
      children: <Widget>[
        if (chosen == null)
          const Text('No consultant matches this injury category.')
        else
          Row(
            children: <Widget>[
              CircleAvatar(
                backgroundColor: theme.colorScheme.secondaryContainer,
                child: Text(chosen.initials),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(chosen.name, style: theme.textTheme.bodyMedium),
                    Text(
                      '${chosen.specialty} · matches the injury category',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              TextButton(
                onPressed: () => _change(consultants),
                child: const Text('Change'),
              ),
            ],
          ),
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 14),
          child: Divider(height: 1),
        ),
        const DetailRow(
          icon: Icons.visibility_off_outlined,
          label: 'Access is limited to this claim',
          detail: 'A consultant sees only the claims assigned to them.',
        ),
        const DetailRow(
          icon: Icons.timer_off_outlined,
          label: 'Access ends at closure',
          detail: 'Revoked automatically when the case closes.',
          dense: true,
        ),
        const SizedBox(height: 16),
        FilledButton.icon(
          onPressed: _busy || chosen == null || appointment == null
              ? null
              : () => _arrange(claim, appointment, chosen, force: false),
          icon: const Icon(Icons.lock_open_outlined),
          label: const Text('Release file and book the session'),
        ),
        if (incomplete) ...<Widget>[
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: _busy || chosen == null || appointment == null
                ? null
                : () => _arrange(claim, appointment, chosen, force: true),
            icon: const Icon(Icons.flag_outlined),
            label: const Text('Release, and flag the missing document'),
          ),
        ],
      ],
    );
  }

  Future<void> _change(List<Consultant>? consultants) async {
    if (consultants == null || consultants.isEmpty) {
      return;
    }
    final Consultant? chosen = await showDialog<Consultant>(
      context: context,
      builder: (BuildContext context) => SimpleDialog(
        title: const Text('Assign a consultant'),
        children: <Widget>[
          for (final Consultant consultant in consultants)
            SimpleDialogOption(
              onPressed: () => Navigator.of(context).pop(consultant),
              child: ListTile(
                leading: CircleAvatar(child: Text(consultant.initials)),
                title: Text(consultant.name),
                subtitle: Text(
                  '${consultant.specialty} · ${consultant.facility}',
                ),
              ),
            ),
        ],
      ),
    );
    if (chosen != null) {
      setState(() => _consultant = chosen);
    }
  }

  Future<void> _arrange(
    Claim claim,
    Appointment appointment,
    Consultant consultant, {
    required bool force,
  }) async {
    setState(() => _busy = true);
    try {
      final ArrangeResult result = await ref
          .read(arrangeConsultationProvider)
          .arrange(
            claim: claim,
            appointment: appointment,
            consultantId: consultant.id,
            format: _format,
            room: 'Room 4, 2nd floor',
            releaseIncompleteFile: force,
          );

      if (!mounted) {
        return;
      }
      ref.invalidate(consultationWorklistProvider);
      ref.invalidate(railCountsProvider);

      switch (result) {
        case ConsultationArranged():
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('The case file is released to ${consultant.name}.'),
            ),
          );
          context.go('/officer/consultations');
        case CaseFileIncomplete(missing: final List<String> missing):
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'These documents are absent: ${missing.join(', ')}. Release '
                'with a flag, or ask the claimant for them (BR-23).',
              ),
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
