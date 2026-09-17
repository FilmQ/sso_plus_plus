/// The business rules that more than one use case obeys.
///
/// The deck names these rules but gives no numbers for some of them. Open
/// point 2 of IMPLEMENTATION.md records that. The numbers below are the
/// choice of this project. The screens show them, so a reader always sees
/// the same figure that the code uses.
abstract final class ClaimRules {
  /// BR-14: the confirmation window closes this long before the slot.
  static const Duration confirmationWindow = Duration(days: 2);

  /// BR-17: the officer may call this many times before the case escalates.
  static const int maxCallAttempts = 3;

  /// BR-20: the office may move a date this many times before it escalates.
  static const int maxReschedules = 2;

  /// BR-09: the person has this many days to appeal a refusal.
  static const int appealDays = 30;

  /// BR-10: an appointment must be offered within this period after the
  /// eligibility is verified.
  static const Duration serviceTarget = Duration(days: 14);

  /// The last moment at which an answer to an appointment is accepted.
  ///
  /// BR-15 says that silence is not a confirmation, so this moment matters.
  static DateTime replyDeadlineFor(DateTime slotStart) =>
      slotStart.subtract(confirmationWindow);

  /// True if [now] is after the reply deadline of [slotStart].
  static bool windowIsClosed(DateTime slotStart, DateTime now) =>
      now.isAfter(replyDeadlineFor(slotStart));
}
