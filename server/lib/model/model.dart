/// Base class of all models (SA report 2.18, class Model).
abstract class Model {
  /// Field name to error message. The page shows each message under its field.
  final Map<String, String> fieldErrors = {};

  /// The report's `errors: List<String>`.
  List<String> get errors => fieldErrors.values.toList();

  bool isValid() => fieldErrors.isEmpty;
}

/// The input did not pass the checks (Alternate Case [Validation Failed]).
class ValidationFailedException implements Exception {
  const ValidationFailedException(this.fieldErrors, {this.alreadyRegistered = false});

  final Map<String, String> fieldErrors;

  /// True when the national ID is already in InsuredPerson (Q1.2, screen U1-4).
  final bool alreadyRegistered;

  @override
  String toString() => 'ValidationFailedException($fieldErrors)';
}
