import 'dart:async';

import '../controller/treatment_controller.dart';

/// U4.3 Reject (SA report 2.18, class AutoCancelJob): QU4.3 cancels each
/// Pending treatment on or before today and tells its user.
///
/// The job runs once when the server starts, then every day at 00:05
/// Asia/Bangkok (D-043). QU4.3 changes only Pending rows, so an extra run
/// does no harm.
class AutoCancelJob {
  AutoCancelJob(this.controller, {this.log = print});

  /// Gives a controller without a session for each run.
  final TreatmentController Function() controller;
  final void Function(String) log;

  /// Minute 5 of hour 0, every day (Asia/Bangkok).
  final String cronExpression = '5 0 * * *';
  DateTime? lastRunAt;
  Timer? _timer;

  /// U4.3 step 2: the deadline is reached. Gives the number of cancelled treatments.
  Future<int> onDeadlineReached() async {
    final cancelled = await controller().cancelUnacceptedTreatments();
    lastRunAt = DateTime.now();
    log('AutoCancelJob: QU4.3 cancelled $cancelled treatment(s)');
    return cancelled;
  }

  void start() {
    unawaited(_run());
  }

  void stop() => _timer?.cancel();

  Future<void> _run() async {
    try {
      await onDeadlineReached();
    } catch (e) {
      log('AutoCancelJob: QU4.3 failed: $e');
    }
    _timer = Timer(nextRunDelay(DateTime.now().toUtc()), _run);
  }

  /// The time from [nowUtc] to the next 00:05 in Bangkok (UTC+7, no summer time).
  static Duration nextRunDelay(DateTime nowUtc) {
    final bangkok = nowUtc.add(const Duration(hours: 7));
    var next = DateTime.utc(bangkok.year, bangkok.month, bangkok.day, 0, 5);
    if (!next.isAfter(bangkok)) next = next.add(const Duration(days: 1));
    return next.difference(bangkok);
  }
}
