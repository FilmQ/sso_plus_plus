import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../api/api_exception.dart';
import '../../../widgets/date_text.dart';
import '../../../widgets/picker_field.dart';
import '../shell/console_shell.dart';
import 'availability_card.dart';
import 'claim_chips.dart';
import 'offer_dialogs.dart';
import 'offer_panel.dart';
import 'scheduling_providers.dart';

/// O4-1 Scheduling page (SA report figures 2-73 to 2-75): O4 Schedule
/// Appointment.
class ScheduleAppointmentPage extends ConsumerStatefulWidget {
  const ScheduleAppointmentPage({super.key});

  @override
  ConsumerState<ScheduleAppointmentPage> createState() => _ScheduleAppointmentPageState();
}

class _ScheduleAppointmentPageState extends ConsumerState<ScheduleAppointmentPage> {
  int? claimId;
  DateTime slotDate = _nextWeekday(DateTime.now());
  Map<String, Object?>? selectedSlot;
  bool _busy = false;

  /// The first weekday after [today]: the first date the page offers.
  static DateTime _nextWeekday(DateTime today) {
    DateTime d = DateTime(today.year, today.month, today.day + 1);
    while (d.weekday > DateTime.friday) {
      d = DateTime(d.year, d.month, d.day + 1);
    }
    return d;
  }

  /// O4 step 2.1: a new date shows the availability of that date (QO4.2).
  Future<void> selectDate() async {
    final DateTime now = DateTime.now();
    final DateTime? d = await showDatePicker(
      context: context,
      initialDate: slotDate,
      firstDate: DateTime(now.year, now.month, now.day + 1),
      lastDate: DateTime(now.year + 1, now.month, now.day),
      selectableDayPredicate: (DateTime d) => d.weekday <= DateTime.friday, // weekdays only (QO4.2)
    );
    if (d != null) setState(() => (slotDate = d, selectedSlot = null));
  }

  /// O4 steps 3 to 6: the confirmation card (O4-2), QO4.3 and QN.3, then
  /// "Appointment Scheduled" (O4-3).
  Future<void> offerSlot(Map<String, Object?> claim) async {
    final Map<String, Object?> s = selectedSlot!;
    final String dateText = '${s['slot_date_text']}'.substring('${s['slot_date_text']}'.indexOf(' ') + 1);
    final bool? ok = await showOfferConfirmDialog(
      context,
      date: dateText,
      time: '${s['slot_time_range']}',
      details: 'With ${s['consultant_name']} for ${claim['user_name']} (${claim['claim_no']}), '
          '${s['office_location']}.',
    );
    if (ok != true || !mounted) return; // Alternate Case 1 [Cancel]
    setState(() => _busy = true);
    try {
      final Map<String, Object?> r = await ref
          .read(schedulingApiProvider)
          .offerAppointment(claim['claim_id']! as int, s.consultantId, s.slotDate, s.slotTime);
      if (!mounted) return;
      await showAppointmentScheduledDialog(
        context,
        'The appointment on ${r['appointment_date']} is reserved. ${claim['user_name']} and '
        '${s['consultant_name']} have been notified. The user must confirm it by ${r['confirm_by']}.',
      );
      setState(() => (selectedSlot = null, claimId = null));
    } on ApiException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(consoleSnackBar(e.message));
    } finally {
      ref.invalidate(claimsToScheduleProvider);
      ref.invalidate(availabilityProvider(DateText.iso(slotDate)));
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final AsyncValue<List<Map<String, Object?>>> claims = ref.watch(claimsToScheduleProvider);
    final List<Map<String, Object?>> rows = claims.value ?? const <Map<String, Object?>>[];
    final Map<String, Object?>? claim =
        rows.where((Map<String, Object?> c) => c['claim_id'] == claimId).firstOrNull ?? rows.firstOrNull;
    final AsyncValue<List<Map<String, Object?>>> slots = ref.watch(availabilityProvider(DateText.iso(slotDate)));
    final Widget left = Column(crossAxisAlignment: CrossAxisAlignment.stretch, spacing: 16, children: <Widget>[
      ClaimChips(
        claims: rows,
        selectedId: claim?['claim_id'] as int?,
        loading: claims.isLoading,
        onSelect: (int id) => setState(() => claimId = id),
      ),
      Wrap(spacing: 16, runSpacing: 12, crossAxisAlignment: WrapCrossAlignment.center, children: <Widget>[
        SizedBox(
          width: 300,
          child: PickerField(
            label: 'Appointment date',
            icon: Icons.calendar_month,
            value: DateText.withDay(slotDate),
            onTap: selectDate,
          ),
        ),
        const SlotLegend(),
      ]),
      slots.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (Object e, _) => Text(e is ApiException ? e.message : 'The availability cannot be shown now.'),
        data: (List<Map<String, Object?>> list) => AvailabilityCard(
          slots: list,
          selected: selectedSlot,
          onSelect: (Map<String, Object?> s) => setState(() => selectedSlot = s),
        ),
      ),
    ]);
    final Widget right = OfferPanel(slot: selectedSlot, claim: claim, busy: _busy, onOffer: () => offerSlot(claim!));
    return ConsolePage(
      title: 'Scheduling',
      subtitle: claim == null
          ? 'There are no claims to schedule'
          : '${claim['claim_no']} · ${claim['user_name']} · verified ${claim['verified_date'] ?? '-'}',
      body: LayoutBuilder(builder: (BuildContext context, BoxConstraints box) {
        final bool wide = box.maxWidth >= 1000;
        return ListView(padding: const EdgeInsets.all(24), children: <Widget>[
          if (wide)
            Row(crossAxisAlignment: CrossAxisAlignment.start, spacing: 24, children: <Widget>[
              Expanded(flex: 7, child: left),
              Expanded(flex: 4, child: right),
            ])
          else
            Column(crossAxisAlignment: CrossAxisAlignment.stretch, spacing: 16, children: <Widget>[left, right]),
        ]);
      }),
    );
  }
}
