import 'package:flutter/material.dart';

/// The fields that the consultant fills at the session (UC-09, step 3).
///
/// A star marks a mandatory field. `Fitness for work` carries no star: the
/// design does not mark it, and the deck does not demand it.
class ClinicalFieldsForm extends StatelessWidget {
  const ClinicalFieldsForm({
    super.key,
    required this.findings,
    required this.diagnosis,
    required this.recommendedTreatment,
    required this.fitnessForWork,
    this.enabled = true,
    this.missing = const <String>[],
  });

  final TextEditingController findings;
  final TextEditingController diagnosis;
  final TextEditingController recommendedTreatment;
  final TextEditingController fitnessForWork;
  final bool enabled;

  /// The mandatory fields that are still empty.
  final List<String> missing;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        _Field(
          label: 'Findings *',
          controller: findings,
          enabled: enabled,
          error: missing.contains('Findings'),
          lines: 3,
        ),
        _Field(
          label: 'Diagnosis *',
          controller: diagnosis,
          enabled: enabled,
          error: missing.contains('Diagnosis'),
          lines: 2,
        ),
        _Field(
          label: 'Recommended treatment *',
          controller: recommendedTreatment,
          enabled: enabled,
          error: missing.contains('Recommended treatment'),
          lines: 2,
        ),
        _Field(
          label: 'Fitness for work',
          controller: fitnessForWork,
          enabled: enabled,
          error: false,
          lines: 2,
        ),
      ],
    );
  }
}

class _Field extends StatelessWidget {
  const _Field({
    required this.label,
    required this.controller,
    required this.enabled,
    required this.error,
    required this.lines,
  });

  final String label;
  final TextEditingController controller;
  final bool enabled;
  final bool error;
  final int lines;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextField(
        controller: controller,
        enabled: enabled,
        maxLines: lines,
        decoration: InputDecoration(
          labelText: label,
          errorText: error ? 'This field is mandatory.' : null,
        ),
      ),
    );
  }
}
