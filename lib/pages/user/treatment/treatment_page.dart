import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../api/api_exception.dart';
import '../../../api/treatment_api.dart';
import '../../../widgets/centered_body.dart';
import '../../../widgets/status_chip.dart';
import '../notifications/notification_providers.dart';
import '../schedule/schedule_providers.dart';
import 'accepted_dialog.dart';
import 'available_dates_dialog.dart';
import 'treatment_cards.dart';
import 'treatment_text.dart';

/// U4-1 Confirm Treatment page (SA report figure 2-38), with the results U4-2
/// (Treatment accepted) and U4-4 (New treatment date saved). U4.1 and U4.2.
/// A new date counts as accepting, so after U4.2 the page has no buttons.
class TreatmentPage extends ConsumerStatefulWidget {
  const TreatmentPage({super.key, required this.treatmentId});

  final int treatmentId;

  @override
  ConsumerState<TreatmentPage> createState() => _TreatmentPageState();
}

class _TreatmentPageState extends ConsumerState<TreatmentPage> {
  Map<String, Object?>? _treatment;
  String? _error;
  bool _busy = false;

  TreatmentApi get _api => ref.read(treatmentApiProvider);

  @override
  void initState() {
    super.initState();
    open();
  }

  /// U4.1 steps 1 to 2: the page data (QU4.4).
  Future<void> open() async {
    try {
      final Map<String, Object?> t = await _api.getTreatment(widget.treatmentId);
      if (mounted) setState(() => _treatment = t);
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    }
  }

  /// Runs one change, shows an error as a message, and reloads the values that
  /// the change can alter on the other pages.
  Future<bool> _change(Future<Map<String, Object?>> Function() call) async {
    setState(() => _busy = true);
    try {
      final Map<String, Object?> t = await call();
      if (mounted) setState(() => _treatment = t);
      refreshUserData(ref);
      return true;
    } on ApiException catch (e) {
      _snack(e.message);
      if (e.status == 409) await open();
      return false;
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _snack(String text) {
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  /// U4.1: QU4.1, then the pop-up (U4-2).
  Future<void> clickAccept() async {
    if (!await _change(() => _api.acceptTreatment(widget.treatmentId)) || !mounted) return;
    await showAcceptedDialog(context, _treatment!);
  }

  /// U4.2: getAvailableDates (QU4.5, U4-3), select a date, saveDate (QU4.2),
  /// then the new date (U4-4). "Cancel" goes back without a change.
  Future<void> clickRequestAnotherDate() async {
    final String time = TreatmentText.time(_treatment!['treatment_date']! as String);
    final Map<String, Object?>? chosen = await showAvailableDates(
      context,
      time: time,
      loadDates: () => _api.getAvailableDates(widget.treatmentId),
    );
    if (chosen == null) return;
    await saveDate(chosen, time);
  }

  /// U4.2 step 4 (QU4.2), then the U4-4 snackbar.
  Future<void> saveDate(Map<String, Object?> chosen, String time) async {
    if (await _change(() => _api.changeDate(widget.treatmentId, chosen['slot_date']! as String))) {
      _snack(TreatmentText.dateChanged(chosen['date_label']! as String, time));
    }
  }

  @override
  Widget build(BuildContext context) {
    final Map<String, Object?>? t = _treatment;
    return Scaffold(
      appBar: AppBar(
        leading: BackButton(onPressed: () => context.canPop() ? context.pop() : context.go('/schedule')),
        title: const Text('Confirm Treatment'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
        children: <Widget>[
          CenteredBody(
            child: t == null
                ? Padding(
                    padding: const EdgeInsets.all(24),
                    child: Center(child: _error == null ? const CircularProgressIndicator() : Text(_error!)),
                  )
                : _body(t),
          ),
        ],
      ),
    );
  }

  Widget _body(Map<String, Object?> t) {
    final bool pending = t['treatment_status'] == 'Pending';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 12,
      children: <Widget>[
        Row(children: <Widget>[
          Expanded(child: Text('Status', style: Theme.of(context).textTheme.titleSmall)),
          Flexible(flex: 3, child: TreatmentStatusChip(t['treatment_status']! as String)),
        ]),
        TreatmentCards(treatment: t),
        // QU4.1 and QU4.2 change only a Pending treatment (05-states.md).
        if (pending) ...<Widget>[
          const AnswerBeforeNote(),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: _busy ? null : clickAccept,
            icon: const Icon(Icons.check),
            label: const Text('Accept'),
          ),
          OutlinedButton.icon(
            onPressed: _busy ? null : clickRequestAnotherDate,
            icon: const Icon(Icons.edit_calendar),
            label: const Text('Request Another Date'),
          ),
        ],
      ],
    );
  }
}
