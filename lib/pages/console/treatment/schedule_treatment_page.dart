import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../api/api_exception.dart';
import '../../../widgets/date_text.dart';
import '../scheduling/claim_chips.dart';
import '../shell/console_shell.dart';
import 'booking_summary.dart';
import 'report_card.dart';
import 'treatment_dialogs.dart';
import 'treatment_form.dart';
import 'treatment_providers.dart';

/// O5.1-1 Treatment page (SA report figures 2-79 to 2-86): O5.1 Book
/// Treatment and O5.2 No Treatment Required.
class ScheduleTreatmentPage extends ConsumerStatefulWidget {
  const ScheduleTreatmentPage({super.key});

  @override
  ConsumerState<ScheduleTreatmentPage> createState() => _ScheduleTreatmentPageState();
}

class _ScheduleTreatmentPageState extends ConsumerState<ScheduleTreatmentPage> {
  int? claimId;
  String? type;
  int? duration;
  String? facility;
  Map<String, Object?>? selectedSlot;
  bool _busy = false;

  /// The QO5.2 key of the chosen facility and duration: tomorrow and the next
  /// days.
  String? get _timesKey {
    if (type == null || duration == null || facility == null) return null;
    final DateTime now = DateTime.now();
    final DateTime from = DateTime(now.year, now.month, now.day + 1);
    final DateTime to = DateTime(now.year, now.month, now.day + TreatmentOptions.days);
    return '$facility|$duration|${DateText.iso(from)}|${DateText.iso(to)}';
  }

  void _reset() => setState(() => (claimId = null, type = null, duration = null, facility = null, selectedSlot = null));

  void _refresh() {
    ref.invalidate(claimsForTreatmentProvider);
    final String? key = _timesKey;
    if (key != null) ref.invalidate(availableTimesProvider(key));
  }

  /// O5.1 steps 3 to 6: the confirmation card (O5.1-2), QO5.3 and QN.1, then
  /// "Treatment Booked" (O5.1-3).
  Future<void> bookSlot(Map<String, Object?> claim) async {
    final DateTime start = BookingSummary.startOf(selectedSlot!);
    final String user = _fullName(claim);
    final bool? ok = await showTreatmentConfirmDialog(
      context,
      title: 'Do you confirm to book this treatment at $facility : ${DateText.long(start)} - ${DateText.time(start)}',
      text: '$type, $duration minutes, for $user (${claim['claim_no']}).',
    );
    if (ok != true || !mounted) return; // Alternate Case 1 [Cancel]
    await _run(() async {
      final Map<String, Object?> r = await ref.read(officerTreatmentApiProvider).bookTreatment(
        claim['claim_id']! as int,
        <String, Object?>{
          'report_id': claim['report_id'],
          'treatment_type': type,
          'duration_minutes': duration,
          'facility_name': facility,
          'date': DateText.iso(start),
          'time': DateText.time(start),
        },
      );
      if (!mounted) return;
      await showTreatmentResultDialog(context,
          icon: Icons.event_available,
          title: 'Treatment Booked',
          text: '$type on ${r['treatment_date']} at $facility is booked. $user has been notified and can accept or '
              'ask for another date.');
    });
  }

  /// O5.2 steps 3 to 6: the confirmation card (O5.2-1), QO5.4 and QN.4, then
  /// "No Treatment Required" (O5.2-2).
  Future<void> clickNoTreatmentRequired(Map<String, Object?> claim) async {
    final String user = _fullName(claim);
    final bool? ok = await showTreatmentConfirmDialog(
      context,
      title: 'Do you confirm that no treatment require for user $user',
      text: 'Claim ${claim['claim_no']} will be closed with the status No treatment required.',
    );
    if (ok != true || !mounted) return; // Alternate Case 1 [Cancel]
    await _run(() async {
      await ref.read(officerTreatmentApiProvider).closeWithoutTreatment(claim['claim_id']! as int);
      if (!mounted) return;
      await showTreatmentResultDialog(context,
          icon: Icons.task_alt,
          title: 'No Treatment Required',
          text: 'Claim ${claim['claim_no']} is closed. $user has been notified that no treatment is required.');
    });
  }

  /// The title and name of the user (QO5.1 title_name and user_name).
  static String _fullName(Map<String, Object?> claim) =>
      <Object?>[claim['title_name'], claim['user_name']].whereType<Object>().join(' ');

  /// Runs a change; a refused change shows the server message. Then the
  /// lists are loaded again and the form starts again.
  Future<void> _run(Future<void> Function() change) async {
    setState(() => _busy = true);
    try {
      await change();
      _refresh();
      _reset();
    } on ApiException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(consoleSnackBar(e.message));
      _refresh();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final AsyncValue<List<Map<String, Object?>>> claims = ref.watch(claimsForTreatmentProvider);
    final List<Map<String, Object?>> rows = claims.value ?? const <Map<String, Object?>>[];
    final Map<String, Object?>? claim =
        rows.where((Map<String, Object?> c) => c['claim_id'] == claimId).firstOrNull ?? rows.firstOrNull;
    final String? key = _timesKey;
    final Widget left = Column(crossAxisAlignment: CrossAxisAlignment.stretch, spacing: 16, children: <Widget>[
      ClaimChips(
        title: 'Claims with a filed report',
        empty: 'There are no claims with a filed report.',
        claims: rows,
        selectedId: claim?['claim_id'] as int?,
        loading: claims.isLoading,
        onSelect: (int id) => setState(() => (claimId = id, selectedSlot = null)),
      ),
      if (claim != null) ReportShortcutCard(claim: claim, onView: () => context.go('/reports/${claim['report_id']}')),
      TreatmentForm(
        type: type,
        duration: duration,
        facility: facility,
        slots: key == null ? null : ref.watch(availableTimesProvider(key)),
        selected: selectedSlot,
        onType: (String? v) => setState(() => type = v),
        onDuration: (int? v) => setState(() => (duration = v, selectedSlot = null)),
        onFacility: (String? v) => setState(() => (facility = v, selectedSlot = null)),
        onSelect: (Map<String, Object?> s) => setState(() => selectedSlot = s),
      ),
    ]);
    final Widget right = BookingSummary(
      claim: claim,
      type: type,
      duration: duration,
      facility: facility,
      slot: selectedSlot,
      busy: _busy,
      onBook: () => bookSlot(claim!),
      onNoTreatment: () => clickNoTreatmentRequired(claim!),
    );
    return ConsolePage(
      title: claim == null ? 'Treatment' : 'Treatment · ${claim['claim_no']}',
      subtitle: claim == null
          ? 'There are no claims with a filed report'
          : '${claim['user_name']} · report signed ${claim['signed_date']}',
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
