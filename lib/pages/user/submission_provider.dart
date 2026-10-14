import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The claim data of the last U1 submission, for U1-5. Null before a submission.
final NotifierProvider<SubmissionNotifier, Map<String, Object?>?> submissionProvider =
    NotifierProvider<SubmissionNotifier, Map<String, Object?>?>(SubmissionNotifier.new);

class SubmissionNotifier extends Notifier<Map<String, Object?>?> {
  @override
  Map<String, Object?>? build() => null;

  void set(Map<String, Object?>? claim) => state = claim;
}
