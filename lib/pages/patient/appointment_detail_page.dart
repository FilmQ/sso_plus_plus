import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../models/appointment.dart';
import '../../providers/appointment_providers.dart';
import '../../providers/claim_providers.dart';
import '../../providers/notice_providers.dart';
import '../../providers/use_case_providers.dart';
import '../../use-cases/uc_05_confirm_appointment.dart';
import '../../widgets/patient/action_stack.dart';
import '../../widgets/patient/appointment_card.dart';
import '../../widgets/patient/notice_banner.dart';
import '../../widgets/shared/async_value_view.dart';
import '../../widgets/shared/claim_status_badge.dart';
import '../../widgets/shared/detail_row.dart';
import '../../widgets/shared/empty_state.dart';
import '../../widgets/shared/formats.dart';
import '../../widgets/shared/info_card.dart';
import '../../widgets/shared/section_heading.dart';

/// M6, M7 and M9 · the appointment screen (UC-05, and UC-11 for treatment).
///
/// One screen serves all three frames of the design. The state of the
/// appointment and its kind select what it shows.
class AppointmentDetailPage extends ConsumerStatefulWidget {
  const AppointmentDetailPage({super.key, required this.appointmentId});

  final String appointmentId;

  @override
  ConsumerState<AppointmentDetailPage> createState() =>
      _AppointmentDetailPageState();
}

class _AppointmentDetailPageState extends ConsumerState<AppointmentDetailPage> {
  bool _busy = false;

  @override
  Widget build(BuildContext context) {
    final AsyncValue<Appointment?> appointment = ref.watch(
      appointmentProvider(widget.appointmentId),
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(
          appointment.value?.kind == AppointmentKind.treatment
              ? 'Treatment'
              : 'Appointment',
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () =>
              context.canPop() ? context.pop() : context.go('/appointments'),
        ),
      ),
      body: AsyncValueView<Appointment?>(
        value: appointment,
        onRetry: () =>
            ref.invalidate(appointmentProvider(widget.appointmentId)),
        builder: (Appointment? found) {
          if (found == null) {
            return const EmptyState(
              icon: Icons.event_busy,
              title: 'This appointment is not known',
            );
          }
          return _Body(
            appointment: found,
            injurySummary: ref
                .watch(claimProvider(found.claimNumber))
                .value
                ?.injury
                .cause,
            busy: _busy,
            onConfirm: () => _confirm(found),
            onAnotherDate: () => _requestAnotherDate(found),
            onCannotAttend: () => _decline(found),
          );
        },
      ),
    );
  }

  void _refresh() {
    ref.invalidate(appointmentProvider(widget.appointmentId));
    ref.invalidate(appointmentsProvider);
    ref.invalidate(appointmentAwaitingReplyProvider);
    ref.invalidate(claimsProvider);
    ref.invalidate(noticesProvider);
    ref.invalidate(unreadNoticeCountProvider);
  }

  Future<void> _run(Future<ConfirmResult> Function() action) async {
    setState(() => _busy = true);
    try {
      final ConfirmResult result = await action();
      if (!mounted) {
        return;
      }
      _refresh();
      _report(result);
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  Future<void> _confirm(Appointment appointment) =>
      _run(() => ref.read(confirmAppointmentProvider).confirm(appointment));

  Future<void> _requestAnotherDate(Appointment appointment) => _run(
    () => ref.read(confirmAppointmentProvider).requestAnotherDate(appointment),
  );

  Future<void> _decline(Appointment appointment) async {
    final String? reason = await showDialog<String>(
      context: context,
      builder: (BuildContext context) => const _DeclineDialog(),
    );
    if (reason == null || !mounted) {
      return;
    }
    await _run(
      () => ref.read(confirmAppointmentProvider).decline(appointment, reason),
    );
  }

  void _report(ConfirmResult result) {
    final String message = switch (result) {
      AppointmentConfirmed() =>
        'The appointment is confirmed. A reminder follows before the date.',
      AnotherDateRequested() =>
        'An officer will offer another date. The slot returns to the pool.',
      AppointmentDeclined() => 'The application recorded that you refused.',
      ConfirmationWindowClosed() =>
        'The reply period closed. An officer will telephone you.',
    };
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }
}

class _Body extends StatelessWidget {
  const _Body({
    required this.appointment,
    required this.injurySummary,
    required this.busy,
    required this.onConfirm,
    required this.onAnotherDate,
    required this.onCannotAttend,
  });

  final Appointment appointment;

  /// A short description of the injury, shown against the claim number.
  final String? injurySummary;

  final bool busy;
  final VoidCallback onConfirm;
  final VoidCallback onAnotherDate;
  final VoidCallback onCannotAttend;

  bool get _isTreatment => appointment.kind == AppointmentKind.treatment;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colors = theme.colorScheme;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
      children: <Widget>[
        Row(
          children: <Widget>[
            ClaimStatusBadge(
              label: _isTreatment && appointment.needsReply
                  ? 'Treatment scheduled'
                  : appointment.status.label,
              tone: appointment.needsReply
                  ? BadgeTone.action
                  : appointment.isConfirmed
                  ? BadgeTone.good
                  : BadgeTone.neutral,
            ),
            const Spacer(),
            Text(
              appointment.claimNumber,
              style: theme.textTheme.labelMedium?.copyWith(
                color: colors.onSurfaceVariant,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        AppointmentCard(appointment: appointment, injurySummary: injurySummary),
        const SizedBox(height: 16),

        if (appointment.needsReply) ...<Widget>[
          NoticeBanner(
            text: _isTreatment
                ? 'This date was written into your application when the '
                      'consultant booked it. Nobody typed it again.'
                : 'Reply by '
                      '${Formats.shortDateWithDay(appointment.replyBy)}.',
            tone: BannerTone.warning,
            icon: Icons.schedule,
          ),
          const SizedBox(height: 16),
          ActionStack(
            busy: busy,
            primaryLabel: _isTreatment
                ? 'Confirm attendance'
                : 'Confirm this appointment',
            onPrimary: onConfirm,
            secondaryLabel: 'Request another date',
            onSecondary: onAnotherDate,
            tertiaryLabel: _isTreatment ? null : 'I cannot attend',
            onTertiary: _isTreatment ? null : onCannotAttend,
            caption:
                'If you do not reply, an officer telephones you and records '
                'your answer.',
          ),
        ],

        if (appointment.isConfirmed) ...<Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _sayLater(context, 'Add to calendar'),
                  icon: const Icon(Icons.calendar_month_outlined),
                  label: const Text('Add to calendar'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _sayLater(context, 'Directions'),
                  icon: const Icon(Icons.directions_outlined),
                  label: const Text('Directions'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (appointment.channel != null)
            NoticeBanner(
              text:
                  '${appointment.channel!.label}'
                  '${appointment.confirmedAt == null ? '' : ' · '
                            '${Formats.dateAndTime(appointment.confirmedAt!)}'}',
              icon: Icons.verified_outlined,
            ),
          const SizedBox(height: 8),
          const SectionHeading('Before you go'),
          const InfoCard(
            child: Column(
              children: <Widget>[
                DetailRow(
                  icon: Icons.badge_outlined,
                  label: 'National ID card',
                  detail: 'Bring the original, not a copy.',
                ),
                DetailRow(
                  icon: Icons.description_outlined,
                  label: 'Medical certificate',
                  detail: 'Already attached to your claim.',
                  dense: true,
                ),
              ],
            ),
          ),
        ],

        if (_isTreatment) ...<Widget>[
          const SizedBox(height: 8),
          const SectionHeading('After this session'),
          const InfoCard(
            child: Column(
              children: <Widget>[
                DetailRow(
                  icon: Icons.event_repeat_outlined,
                  label: 'Review at three weeks',
                  detail: 'Booked after this session.',
                ),
                DetailRow(
                  icon: Icons.payments_outlined,
                  label: 'Covered by the Social Security Office',
                  detail: 'Nothing to pay at the facility.',
                  dense: true,
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  static void _sayLater(BuildContext context, String what) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('$what arrives in a later phase.')));
  }
}

/// Flow 2b: the person states that they will not attend.
class _DeclineDialog extends StatefulWidget {
  const _DeclineDialog();

  @override
  State<_DeclineDialog> createState() => _DeclineDialogState();
}

class _DeclineDialogState extends State<_DeclineDialog> {
  final TextEditingController _reason = TextEditingController();

  @override
  void dispose() {
    _reason.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('You cannot attend'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          const Text(
            'Tell the officer why. The application records your reason with '
            'the refusal.',
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _reason,
            autofocus: true,
            decoration: const InputDecoration(labelText: 'Reason'),
          ),
        ],
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(
            _reason.text.trim().isEmpty
                ? 'No reason given'
                : _reason.text.trim(),
          ),
          child: const Text('Send'),
        ),
      ],
    );
  }
}
