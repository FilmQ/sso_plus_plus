import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../models/appointment_slot.dart';
import '../../models/claim.dart';
import '../../providers/claim_providers.dart';
import '../../providers/officer_providers.dart';
import '../../providers/rail_counts_provider.dart';
import '../../providers/repository_providers.dart';
import '../../providers/staff_provider.dart';
import '../../providers/use_case_providers.dart';
import '../../use-cases/uc_04_schedule_appointment.dart';
import '../../widgets/console/console_card.dart';
import '../../widgets/console/console_scaffolds.dart';
import '../../widgets/console/slot_picker.dart';
import '../../widgets/shared/async_value_view.dart';
import '../../widgets/shared/claim_status_badge.dart';
import '../../widgets/shared/detail_row.dart';
import '../../widgets/shared/empty_state.dart';
import '../../widgets/shared/formats.dart';
import '../../widgets/shared/notice_banner.dart';

/// D3 · Officer — schedule appointment (UC-04).
///
/// The officer sees live availability for the specialty that the injury
/// needs, and offers one slot to the claimant.
class ScheduleAppointmentPage extends ConsumerStatefulWidget {
  const ScheduleAppointmentPage({super.key, required this.claimNumber});

  final String claimNumber;

  @override
  ConsumerState<ScheduleAppointmentPage> createState() =>
      _ScheduleAppointmentPageState();
}

class _ScheduleAppointmentPageState
    extends ConsumerState<ScheduleAppointmentPage> {
  AppointmentSlot? _selected;
  bool _busy = false;

  @override
  Widget build(BuildContext context) {
    final AsyncValue<Claim?> claim = ref.watch(
      claimProvider(widget.claimNumber),
    );
    final AsyncValue<List<ConsultantSlots>> availability = ref.watch(
      slotsForClaimProvider(widget.claimNumber),
    );

    return ConsoleScreen(
      title: 'Scheduling',
      subtitle: '${widget.claimNumber} · offer a consultation date',
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
            breadcrumb: <String>['Scheduling', found.claimNumber],
            onBack: () => context.go('/officer/scheduling'),
            context_: <Widget>[
              _claimContext(found),
              _availability(availability),
            ],
            action: <Widget>[
              _offer(found),
              const NoticeBanner(
                text:
                    'Offering the date starts the confirmation window. If '
                    'the claimant does not reply, an officer telephones them '
                    '(UC-06).',
                icon: Icons.schedule,
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _claimContext(Claim claim) {
    final ThemeData theme = Theme.of(context);
    final DateTime target = ref
        .read(scheduleAppointmentProvider)
        .serviceTargetEndsOn(claim);
    final int daysLeft = target.difference(ref.read(clockProvider)()).inDays;

    return ConsoleCard(
      showDivider: false,
      children: <Widget>[
        Row(
          children: <Widget>[
            Expanded(
              child: Text(
                '${claim.injury.bodyPart} · '
                '${claim.injury.category?.label.toLowerCase() ?? 'injury'}',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const ClaimStatusBadge(
              label: 'Covered · Section 33',
              tone: BadgeTone.good,
              icon: Icons.verified,
            ),
            const SizedBox(width: 8),
            ClaimStatusBadge(
              label: 'Service target: $daysLeft days',
              tone: daysLeft < 3 ? BadgeTone.action : BadgeTone.neutral,
            ),
          ],
        ),
        const SizedBox(height: 10),
        Text(
          'Consultant specialty must match the injury category: '
          '${claim.injury.category?.specialty ?? 'any'} (BR-11).',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _availability(AsyncValue<List<ConsultantSlots>> availability) {
    return ConsoleCard(
      title: 'Consultant availability',
      children: <Widget>[
        AsyncValueView<List<ConsultantSlots>>(
          value: availability,
          builder: (List<ConsultantSlots> groups) {
            if (groups.isEmpty) {
              return const EmptyState(
                icon: Icons.event_busy,
                title: 'No consultant matches this injury',
              );
            }
            return Column(
              children: <Widget>[
                for (int i = 0; i < groups.length; i++) ...<Widget>[
                  SlotPicker(
                    consultant: groups[i].consultant,
                    slots: groups[i].slots,
                    selected: _selected,
                    onSelect: (AppointmentSlot slot) =>
                        setState(() => _selected = slot),
                  ),
                  if (i < groups.length - 1)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: Divider(height: 1),
                    ),
                ],
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _offer(Claim claim) {
    final AppointmentSlot? slot = _selected;

    return ConsoleCard(
      title: 'Appointment to offer',
      children: <Widget>[
        if (slot == null)
          const EmptyState(
            icon: Icons.touch_app_outlined,
            title: 'Select a slot',
            message: 'Choose a free slot from the availability panel.',
          )
        else ...<Widget>[
          DetailRow(
            icon: Icons.event_outlined,
            label: Formats.longDate(slot.start),
            detail: Formats.timeRange(slot.start, slot.end),
          ),
          DetailRow(
            icon: Icons.place_outlined,
            label: slot.facility,
            detail: slot.room,
            dense: true,
          ),
          const SizedBox(height: 14),
          const NoticeBanner(
            text:
                'The slot is held against this claim only, until the '
                'claimant answers (BR-12).',
            icon: Icons.lock_clock_outlined,
          ),
          const SizedBox(height: 14),
          FilledButton.icon(
            onPressed: _busy ? null : () => _offerSlot(claim, slot),
            icon: const Icon(Icons.send_outlined),
            label: const Text('Offer to the claimant'),
          ),
        ],
        const SizedBox(height: 10),
        OutlinedButton.icon(
          onPressed: _busy ? null : () => _waitingList(claim),
          icon: const Icon(Icons.pending_actions_outlined),
          label: const Text('Add to waiting list'),
        ),
      ],
    );
  }

  Future<void> _offerSlot(Claim claim, AppointmentSlot slot) async {
    setState(() => _busy = true);
    try {
      final ScheduleResult result = await ref
          .read(scheduleAppointmentProvider)
          .offer(
            claim: claim,
            slot: slot,
            officerName: ref.read(currentStaffProvider).name,
          );

      if (!mounted) {
        return;
      }
      _refresh();

      switch (result) {
        case AppointmentOffered():
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'The date is in the application of the claimant now.',
              ),
            ),
          );
          context.go('/officer/scheduling');
        case SlotNoLongerFree():
          setState(() => _selected = null);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Another claim took that slot. The list is refreshed.',
              ),
            ),
          );
        case PlacedOnWaitingList():
          break;
      }
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  Future<void> _waitingList(Claim claim) async {
    await ref.read(scheduleAppointmentProvider).addToWaitingList(claim);
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'The claim is on the waiting list. An alert follows when a '
          'matching slot is released.',
        ),
      ),
    );
  }

  void _refresh() {
    ref.invalidate(slotsForClaimProvider(widget.claimNumber));
    ref.invalidate(schedulingWorklistProvider);
    ref.invalidate(unconfirmedWorklistProvider);
    ref.invalidate(railCountsProvider);
    ref.invalidate(claimProvider(widget.claimNumber));
  }
}
