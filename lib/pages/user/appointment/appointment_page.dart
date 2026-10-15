import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../api/api_exception.dart';
import '../../../api/appointment_api.dart';
import '../../../widgets/centered_body.dart';
import '../../../widgets/date_text.dart';
import '../../../widgets/status_chip.dart';
import '../notifications/notification_providers.dart';
import 'appointment_cards.dart';
import 'cancel_dialog.dart';
import 'reminder_dialog.dart';
import 'request_date_dialog.dart';

/// U3-2 Appointment Page (SA report figure 2-24), with the results U3-5 (Date
/// changed) and U3-7 (Appointment cancelled). U3.1, U3.2 and U3.3.
class AppointmentPage extends ConsumerStatefulWidget {
  const AppointmentPage({super.key, required this.claimId, this.notificationId});

  final int claimId;

  /// The message that opened the page, for Q3.7 (D-034). Null from the Home page.
  final int? notificationId;

  @override
  ConsumerState<AppointmentPage> createState() => _AppointmentPageState();
}

class _AppointmentPageState extends ConsumerState<AppointmentPage> {
  Map<String, Object?>? _appointment;
  String? _error;
  bool _busy = false;

  AppointmentApi get _api => ref.read(appointmentApiProvider);

  @override
  void initState() {
    super.initState();
    open();
  }

  /// U3.1 step 3 (Q3.2).
  Future<void> open() async {
    try {
      final Map<String, Object?> a = await _api.getAppointment(widget.claimId);
      if (mounted) setState(() => _appointment = a);
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    }
  }

  /// Runs one change, shows a 409 or other error as a message, and reloads the
  /// values that the change can alter on the other pages.
  Future<bool> _change(Future<Map<String, Object?>> Function() call) async {
    setState(() => _busy = true);
    try {
      final Map<String, Object?> a = await call();
      if (mounted) setState(() => _appointment = a);
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

  /// U3.1 steps 4.1 to 6: Q3.3, Q3.7, then the reminder pop-up (U3-3).
  Future<void> clickConfirmAppointment() async {
    if (!await _change(() => _api.confirmAppointment(widget.claimId, widget.notificationId)) || !mounted) return;
    await showReminderDialog(context, _appointment!['appointment_date']! as String);
  }

  /// U3.2: the pop-up (U3-4), then Q3.5 and Q3.7. "Cancel" (Alternate Case 1)
  /// goes back to the page without a change.
  Future<void> clickRequestAnotherDate() async {
    final (DateTime, String)? choice = await showRequestDateDialog(
      context,
      consultantName: _appointment!['consultant_name']! as String,
      loadSlots: (String date) => _api.getFreeSlots(widget.claimId, date),
    );
    if (choice == null) return; // backToAppointmentPage()
    final (DateTime date, String time) = choice;
    if (await _change(() => _api.reschedule(widget.claimId, DateText.iso(date), time, widget.notificationId))) {
      _snack('เวลานัดหมายถูกเปลี่ยนเป็น ${DateText.long(date)} : $time'); // U3-5
    }
  }

  /// U3.3: the warning (U3-6), then Q3.6 and Q3.7. "Go Back" (Alternate Case 1)
  /// goes back to the page without a change.
  Future<void> clickCannotAttend() async {
    if (!await showCancelWarning(context)) return;
    if (await _change(() => _api.cancelAppointment(widget.claimId, widget.notificationId))) {
      _snack('เวลานัดหมายถูกยกเลิกแล้ว'); // U3-7
    }
  }

  @override
  Widget build(BuildContext context) {
    final Map<String, Object?>? a = _appointment;
    return Scaffold(
      appBar: AppBar(
        leading: BackButton(onPressed: () => context.canPop() ? context.pop() : context.go('/notifications')),
        title: const Text('Appointment'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
        children: <Widget>[
          CenteredBody(
            child: a == null
                ? Padding(
                    padding: const EdgeInsets.all(24),
                    child: Center(child: _error == null ? const CircularProgressIndicator() : Text(_error!)),
                  )
                : _body(a),
          ),
        ],
      ),
    );
  }

  Widget _body(Map<String, Object?> a) {
    final String status = a['appointment_status']! as String;
    final ColorScheme colors = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 12,
      children: <Widget>[
        Row(children: <Widget>[
          Expanded(child: Text('Status', style: Theme.of(context).textTheme.titleSmall)),
          Flexible(flex: 3, child: AppointmentStatusChip(status)),
        ]),
        AppointmentCards(appointment: a),
        const SizedBox(height: 12),
        // Pending: all three options (U3.1 step 3). Confirmed: the state
        // machine still allows another date or a cancel (R-023).
        if (status == 'Pending')
          FilledButton.icon(
            onPressed: _busy ? null : clickConfirmAppointment,
            icon: const Icon(Icons.check),
            label: const Text('Confirm Appointment'),
          ),
        if (status == 'Pending' || status == 'Confirmed') ...<Widget>[
          OutlinedButton.icon(
            onPressed: _busy ? null : clickRequestAnotherDate,
            icon: const Icon(Icons.edit_calendar),
            label: const Text('Request Another Date'),
          ),
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(foregroundColor: colors.error, side: BorderSide(color: colors.error)),
            onPressed: _busy ? null : clickCannotAttend,
            icon: const Icon(Icons.event_busy),
            label: const Text('I cannot attend'),
          ),
        ],
      ],
    );
  }
}
