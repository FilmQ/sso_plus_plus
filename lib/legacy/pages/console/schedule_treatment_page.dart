import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../models/appointment_slot.dart';
import '../../models/consultation_report.dart';
import '../../providers/clinic_providers.dart';
import '../../providers/rail_counts_provider.dart';
import '../../providers/repository_providers.dart';
import '../../providers/use_case_providers.dart';
import '../../use-cases/uc_11_schedule_treatment.dart';
import '../../widgets/console/console_card.dart';
import '../../widgets/console/console_scaffolds.dart';
import '../../widgets/console/slot_picker.dart';
import '../../widgets/shared/async_value_view.dart';
import '../../widgets/shared/detail_row.dart';
import '../../widgets/shared/empty_state.dart';
import '../../widgets/shared/formats.dart';
import '../../widgets/shared/notice_banner.dart';

/// The free treatment slots (D8).
final treatmentSlotsProvider = FutureProvider<List<AppointmentSlot>>((
  Ref ref,
) async {
  return ref.watch(schedulingRepositoryProvider).freeSlots(treatment: true);
});

/// D8 · Consultant — schedule treatment (UC-11).
///
/// BR-32 says that the date reaches the application of the claimant at the
/// moment of the booking. Nobody types it again.
class ScheduleTreatmentPage extends ConsumerStatefulWidget {
  const ScheduleTreatmentPage({super.key, required this.reportId});

  final String reportId;

  @override
  ConsumerState<ScheduleTreatmentPage> createState() =>
      _ScheduleTreatmentPageState();
}

class _ScheduleTreatmentPageState extends ConsumerState<ScheduleTreatmentPage> {
  AppointmentSlot? _selected;
  bool _busy = false;

  @override
  Widget build(BuildContext context) {
    final AsyncValue<ConsultationReport?> report = ref.watch(
      reportProvider(widget.reportId),
    );
    final AsyncValue<List<AppointmentSlot>> slots = ref.watch(
      treatmentSlotsProvider,
    );

    return ConsoleScreen(
      title: 'Treatment',
      subtitle: 'Consultant · book from the signed report',
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

          return DetailBody(
            breadcrumb: <String>['Treatment', found.claimNumber],
            onBack: () => context.go('/clinic/treatment'),
            context_: <Widget>[
              _recommendation(found),
              _booking(slots),
              const NoticeBanner(
                text:
                    'If no slot falls inside the period the treatment needs, '
                    'flag the case to the Evaluation Officer instead of '
                    'booking it late.',
                icon: Icons.report_problem_outlined,
              ),
            ],
            action: <Widget>[
              _summary(found),
              const NoticeBanner(
                text:
                    'The date is written into the application of the '
                    'claimant at the moment you book it (BR-32).',
                icon: Icons.bolt_outlined,
              ),
              const NoticeBanner(
                text:
                    'If the claimant cannot attend, the confirmation cycle '
                    'of UC-05 applies to this date as well.',
                icon: Icons.sync_outlined,
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _recommendation(ConsultationReport report) {
    final ThemeData theme = Theme.of(context);

    return ConsoleCard(
      title: 'Recommended in the report',
      trailing: TextButton(
        onPressed: () => context.go('/clinic/reports/${report.id}'),
        child: Text('View report v${report.version}'),
      ),
      children: <Widget>[
        Text(
          '“${report.recommendedTreatment}”',
          style: theme.textTheme.bodyLarge,
        ),
        const SizedBox(height: 10),
        Text(
          'Treatment must be traceable to a signed report (BR-31).',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _booking(AsyncValue<List<AppointmentSlot>> slots) {
    return ConsoleCard(
      title: 'Treatment to book',
      children: <Widget>[
        FactGrid(
          perRow: 2,
          cells: const <FactCell>[
            FactCell(
              label: 'Treatment type',
              value: 'Cast immobilisation and review',
            ),
            FactCell(label: 'Duration', value: '60 minutes'),
          ],
        ),
        const SizedBox(height: 14),
        const FactCell(
          label: 'Facility',
          value: 'Bangkok Rehabilitation Centre',
        ),
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 14),
          child: Divider(height: 1),
        ),
        AsyncValueView<List<AppointmentSlot>>(
          value: slots,
          builder: (List<AppointmentSlot> free) {
            if (free.isEmpty) {
              return const EmptyState(
                icon: Icons.event_busy,
                title: 'No free treatment slot',
              );
            }
            return SlotPicker(
              consultant: null,
              showConsultant: false,
              slots: free,
              selected: _selected,
              onSelect: (AppointmentSlot slot) =>
                  setState(() => _selected = slot),
            );
          },
        ),
      ],
    );
  }

  Widget _summary(ConsultationReport report) {
    final AppointmentSlot? slot = _selected;

    return ConsoleCard(
      title: 'Booking summary',
      children: <Widget>[
        if (slot == null)
          const EmptyState(
            icon: Icons.touch_app_outlined,
            title: 'Select a slot',
            message: 'Choose a free treatment slot on the left.',
          )
        else ...<Widget>[
          const DetailRow(
            icon: Icons.medical_services_outlined,
            label: 'Cast immobilisation and review',
            detail: 'First session · 60 minutes',
          ),
          DetailRow(
            icon: Icons.event_outlined,
            label: Formats.longDate(slot.start),
            detail:
                '${Formats.time(slot.start)} – '
                '${Formats.time(slot.start.add(const Duration(hours: 1)))}',
          ),
          DetailRow(
            icon: Icons.place_outlined,
            label: slot.facility,
            detail: slot.room,
          ),
          DetailRow(
            icon: Icons.link,
            label: 'Linked to report v${report.version}',
            detail: report.signedAt == null
                ? 'Not signed'
                : 'Signed ${Formats.dateAndTime(report.signedAt!)}',
            dense: true,
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: _busy ? null : () => _book(report, slot),
            icon: const Icon(Icons.event_available_outlined),
            label: const Text('Book treatment'),
          ),
        ],
        const SizedBox(height: 10),
        OutlinedButton.icon(
          onPressed: _busy ? null : () => _noTreatment(report),
          icon: const Icon(Icons.do_not_disturb_on_outlined),
          label: const Text('No treatment required'),
        ),
      ],
    );
  }

  Future<void> _book(ConsultationReport report, AppointmentSlot slot) async {
    setState(() => _busy = true);
    try {
      final TreatmentResult result = await ref
          .read(scheduleTreatmentProvider)
          .book(
            report: report,
            slot: slot,
            treatmentType: 'Cast immobilisation and review',
          );

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

  Future<void> _noTreatment(ConsultationReport report) async {
    setState(() => _busy = true);
    try {
      final TreatmentResult result = await ref
          .read(scheduleTreatmentProvider)
          .recordNoTreatment(report);
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

  void _report(TreatmentResult result) {
    final String message = switch (result) {
      TreatmentBooked() =>
        'The treatment date is in the application of the claimant now.',
      NoTreatmentRequired() =>
        'The claim is closed as complete, with the report as its outcome.',
      ReportNotSigned() =>
        'A treatment must come from a signed report (BR-31).',
      ClaimNotOpen() => 'The claim is not open, so nothing can be booked.',
      TreatmentSlotTaken() => 'That slot was taken. Choose another.',
    };
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));

    if (result is TreatmentBooked || result is NoTreatmentRequired) {
      context.go('/clinic/treatment');
    }
  }

  void _refresh() {
    ref.invalidate(treatmentSlotsProvider);
    ref.invalidate(treatmentQueueProvider);
    ref.invalidate(reportProvider(widget.reportId));
    ref.invalidate(railCountsProvider);
  }
}
