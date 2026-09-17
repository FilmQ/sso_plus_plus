/// Supplies the current time to a use case.
///
/// Every use case takes a clock instead of a call to `DateTime.now()`. The
/// demo needs this. UC-05 becomes UC-06 when a deadline passes, and no
/// person can wait for a real deadline during a demonstration.
typedef Clock = DateTime Function();

/// The clock of the device. Use this one in a real deployment.
DateTime systemClock() => DateTime.now();
