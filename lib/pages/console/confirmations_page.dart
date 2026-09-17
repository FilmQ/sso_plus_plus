import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/appointment.dart';
import '../../models/appointment_slot.dart';
import '../../models/contact_attempt.dart';
import '../../models/insured_person.dart';
import '../../providers/officer_providers.dart';
import '../../providers/rail_counts_provider.dart';
import '../../providers/repository_providers.dart';
import '../../providers/staff_provider.dart';
import '../../providers/use_case_providers.dart';
import '../../use-cases/claim_rules.dart';
import '../../use-cases/uc_06_confirm_appointment_by_phone.dart';
import '../../use-cases/uc_07_reschedule_appointment.dart';
import '../../widgets/console/call_attempt_log.dart';
import '../../widgets/console/console_card.dart';
import '../../widgets/console/console_scaffolds.dart';
import '../../widgets/console/decision_card.dart';
import '../../widgets/console/worklist_panel.dart';
import '../../widgets/shared/async_value_view.dart';
import '../../widgets/shared/claim_status_badge.dart';
import '../../widgets/shared/formats.dart';
import '../../widgets/shared/notice_banner.dart';

/// D4 · Officer — phone confirmation fallback (UC-06 → UC-07).
///
/// This screen is the measure of the improvement. The banner says how many
/// appointments the claimants confirmed by themselves.
class ConfirmationsPage extends ConsumerStatefulWidget {
  const ConfirmationsPage({super.key});

  @override
  ConsumerState<ConfirmationsPage> createState() => _ConfirmationsPageState();
}

class _ConfirmationsPageState extends ConsumerState<ConfirmationsPage> {
  String? _selectedId;
  final TextEditingController _note = TextEditingController();
  PhoneReply _reply = PhoneReply.confirmed;
  bool _busy = false;

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final AsyncValue<List<Appointment>> waiting = ref.watch(
      unconfirmedWorklistProvider,
    );

    return ConsoleScreen(
      title: 'Confirmations',
      subtitle: 'Evaluation Officer · the telephone fallback',
      searchHint: 'Search claim or phone number',
      body: AsyncValueView<List<Appointment>>(
        value: waiting,
        onRetry: () => ref.invalidate(unconfirmedWorklistProvider),
        builder: (List<Appointment> found) {
          final Appointment? selected = _selectedOf(found);

          return WorklistBody(
            panels: <Widget>[
              const NoticeBanner(
                text:
                    'Self-service is the intended path. The telephone is the '
                    'exception, and the share of calls is how the office '
                    'measures the improvement.',
                icon: Icons.insights_outlined,
              ),
              const SizedBox(height: 16),
              _table(found),
              if (selected != null) _callPanel(selected),
            ],
          );
        },
      ),
    );
  }

  Appointment? _selectedOf(List<Appointment> all) {
    for (final Appointment appointment in all) {
      if (appointment.id == _selectedId) {
        return appointment;
      }
    }
    return null;
  }

  Widget _table(List<Appointment> found) {
    final ThemeData theme = Theme.of(context);

    return WorklistPanel(
      heading: 'Past the confirmation deadline',
      chips: const <Widget>[
        Chip(label: Text('Deadline passed')),
        SizedBox(width: 8),
        Chip(label: Text('Attempts left')),
      ],
      columns: const <WorklistColumn>[
        WorklistColumn('Claim / claimant', flex: 3),
        WorklistColumn('Appointment', flex: 2),
        WorklistColumn('Deadline', flex: 2),
        WorklistColumn('Attempts', flex: 2),
        WorklistColumn('', flex: 1),
      ],
      rows: <List<Widget>>[
        for (final Appointment appointment in found)
          <Widget>[
            _ClaimantCell(claimNumber: appointment.claimNumber),
            Text(
              Formats.dayDateAndTime(appointment.start),
              style: theme.textTheme.bodyMedium,
            ),
            Text(
              Formats.dateAndTime(appointment.replyBy),
              style: theme.textTheme.bodyMedium,
            ),
            _AttemptsCell(appointmentId: appointment.id),
            Align(
              alignment: Alignment.centerRight,
              child: _ActionCell(
                appointmentId: appointment.id,
                onPressed: () => setState(() {
                  _selectedId = appointment.id;
                  _note.clear();
                  _reply = PhoneReply.confirmed;
                }),
              ),
            ),
          ],
      ],
    );
  }

  Widget _callPanel(Appointment appointment) {
    final ThemeData theme = Theme.of(context);
    final AsyncValue<List<ContactAttempt>> attempts = ref.watch(
      attemptsProvider(appointment.id),
    );
    final AsyncValue<InsuredPerson?> person = ref.watch(
      personForClaimProvider(appointment.claimNumber),
    );
    final List<ContactAttempt> made = attempts.value ?? <ContactAttempt>[];
    final bool exhausted = made.length >= ClaimRules.maxCallAttempts;

    return Padding(
      padding: const EdgeInsets.only(top: 20),
      child: ConsoleCard(
        title: 'Record the reply',
        trailing: const ClaimStatusBadge(label: 'Telephone', icon: Icons.call),
        children: <Widget>[
          Text(
            '${person.value?.fullName ?? appointment.claimNumber} · '
            '${appointment.claimNumber}',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            person.value?.telephone ?? '—',
            style: theme.textTheme.titleLarge,
          ),
          Text(
            'Attempt ${made.length + 1} of ${ClaimRules.maxCallAttempts}',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 14),
            child: Divider(height: 1),
          ),
          Text(
            'Attempt history',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 10),
          CallAttemptLog(attempts: made, allowed: ClaimRules.maxCallAttempts),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 14),
            child: Divider(height: 1),
          ),
          DecisionCard<PhoneReply>(
            heading: 'Reply as the claimant gave it',
            busy: _busy,
            selected: _reply,
            onChanged: (PhoneReply value) => setState(() => _reply = value),
            options: const <DecisionOption<PhoneReply>>[
              DecisionOption<PhoneReply>(
                value: PhoneReply.confirmed,
                label: 'Confirmed',
                detail: 'Same standing as a self-confirmation (BR-18)',
              ),
              DecisionOption<PhoneReply>(
                value: PhoneReply.anotherDate,
                label: 'Asked for another date',
                detail: 'Returns to scheduling (UC-04)',
              ),
              DecisionOption<PhoneReply>(
                value: PhoneReply.declined,
                label: 'Declined — treatment abandoned',
                detail: 'Releases the slot and closes the claim',
              ),
              DecisionOption<PhoneReply>(
                value: PhoneReply.noAnswer,
                label: 'No answer',
                detail: 'Logs the attempt; the case escalates at the limit',
              ),
            ],
            reasonController: _note,
            reasonLabel: 'Note',
            reasonHelper: 'What the claimant said, in their words',
            primaryLabel: 'Save reply',
            onPrimary: () => _save(appointment),
            dangerLabel: exhausted ? 'Escalate to reschedule' : null,
            onDanger: exhausted ? () => _escalate(appointment) : null,
          ),
          const SizedBox(height: 14),
          NoticeBanner(
            text:
                'Recorded by ${ref.watch(currentStaffProvider).name}. The '
                'record keeps this apart from a self-confirmation (BR-13).',
            icon: Icons.assignment_ind_outlined,
          ),
        ],
      ),
    );
  }

  Future<void> _save(Appointment appointment) async {
    setState(() => _busy = true);
    try {
      final PhoneResult result = await ref
          .read(confirmByPhoneProvider)
          .recordReply(
            appointment: appointment,
            reply: _reply,
            officerName: ref.read(currentStaffProvider).name,
            note: _note.text.trim(),
          );

      if (!mounted) {
        return;
      }
      _refresh(appointment.id);

      final String message = switch (result) {
        ReplyRecorded(reply: final PhoneReply reply) =>
          'Recorded: ${reply.label.toLowerCase()}.',
        AttemptLogged(attemptsLeft: final int left) =>
          'The attempt is logged. $left attempts are left.',
        EscalateToReschedule() =>
          'The permitted attempts are used. Reschedule the appointment '
              '(UC-07).',
      };
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(message)));

      if (result is ReplyRecorded) {
        setState(() => _selectedId = null);
      }
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  Future<void> _escalate(Appointment appointment) async {
    setState(() => _busy = true);
    try {
      final List<AppointmentSlot> free = await ref
          .read(rescheduleAppointmentProvider)
          .replacementSlotsFor(appointment);

      if (free.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'No free slot. The claim goes on the waiting list instead.',
              ),
            ),
          );
        }
        return;
      }

      final RescheduleResult result = await ref
          .read(rescheduleAppointmentProvider)
          .reschedule(
            appointment: appointment,
            newSlot: free.first,
            officerName: ref.read(currentStaffProvider).name,
          );

      if (!mounted) {
        return;
      }
      _refresh(appointment.id);

      final String message = switch (result) {
        Rescheduled() =>
          'A new date is set. It is provisional until the claimant confirms '
              'it (BR-21).',
        RescheduleLimitReached() =>
          'The reschedule limit is reached. The claim is suspended (BR-20).',
        RescheduleSlotTaken() => 'That slot was taken. Try again.',
      };
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(message)));
      setState(() => _selectedId = null);
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  void _refresh(String appointmentId) {
    ref.invalidate(unconfirmedWorklistProvider);
    ref.invalidate(attemptsProvider(appointmentId));
    ref.invalidate(consultationWorklistProvider);
    ref.invalidate(railCountsProvider);
  }
}

/// The claimant cell of the table.
class _ClaimantCell extends ConsumerWidget {
  const _ClaimantCell({required this.claimNumber});

  final String claimNumber;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ThemeData theme = Theme.of(context);
    final AsyncValue<InsuredPerson?> person = ref.watch(
      personForClaimProvider(claimNumber),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(claimNumber, style: theme.textTheme.bodyMedium),
        Text(
          person.value?.fullName ?? '…',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

/// The attempts cell of the table.
class _AttemptsCell extends ConsumerWidget {
  const _AttemptsCell({required this.appointmentId});

  final String appointmentId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ThemeData theme = Theme.of(context);
    final int used =
        ref.watch(attemptsProvider(appointmentId)).value?.length ?? 0;
    final bool exhausted = used >= ClaimRules.maxCallAttempts;

    final String label = '$used of ${ClaimRules.maxCallAttempts} used';

    if (exhausted) {
      return Align(
        alignment: Alignment.centerLeft,
        child: ClaimStatusBadge(label: label, tone: BadgeTone.bad),
      );
    }
    return Text(label, style: theme.textTheme.bodyMedium);
  }
}

/// The button at the end of a row: call, or escalate at the limit.
class _ActionCell extends ConsumerWidget {
  const _ActionCell({required this.appointmentId, required this.onPressed});

  final String appointmentId;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final int used =
        ref.watch(attemptsProvider(appointmentId)).value?.length ?? 0;
    return FilledButton.tonal(
      onPressed: onPressed,
      child: Text(used >= ClaimRules.maxCallAttempts ? 'Reschedule' : 'Call'),
    );
  }
}

/// The calls made against one appointment.
final attemptsProvider = FutureProvider.family<List<ContactAttempt>, String>((
  Ref ref,
  String appointmentId,
) async {
  return ref.watch(schedulingRepositoryProvider).attemptsFor(appointmentId);
});
