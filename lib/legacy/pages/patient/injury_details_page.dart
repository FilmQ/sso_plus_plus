import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../models/injury_details.dart';
import '../../providers/new_claim_provider.dart';
import '../../widgets/patient/action_bar.dart';
import '../../widgets/patient/form_text_field.dart';
import '../../widgets/patient/step_progress_header.dart';
import '../../widgets/shared/formats.dart';

/// M2 · Submit claim — injury details (UC-01, steps 1 and 2).
///
/// The application checks each field as the person enters it, and marks
/// anything that is absent (flow 2a).
class InjuryDetailsPage extends ConsumerStatefulWidget {
  const InjuryDetailsPage({super.key});

  @override
  ConsumerState<InjuryDetailsPage> createState() => _InjuryDetailsPageState();
}

class _InjuryDetailsPageState extends ConsumerState<InjuryDetailsPage> {
  late final TextEditingController _date;
  late final TextEditingController _time;
  late final TextEditingController _place;
  late final TextEditingController _cause;
  late final TextEditingController _employer;

  DateTime? _injuryDate;
  BodyPartOption? _bodyPart;

  /// True after the person selects Next once. Only then does the form mark
  /// the fields that are absent.
  bool _showErrors = false;

  @override
  void initState() {
    super.initState();
    final NewClaimState draft = ref.read(newClaimProvider);
    _injuryDate = draft.injury.date;
    _date = TextEditingController(
      text: _injuryDate == null ? '' : Formats.slashDate(_injuryDate!),
    );
    _time = TextEditingController(text: draft.injury.time ?? '');
    _place = TextEditingController(text: draft.injury.place);
    _cause = TextEditingController(text: draft.injury.cause);
    _employer = TextEditingController(text: draft.injury.employer);
    for (final BodyPartOption option in bodyPartOptions) {
      if (option.label == draft.injury.bodyPart) {
        _bodyPart = option;
      }
    }
  }

  @override
  void dispose() {
    _date.dispose();
    _time.dispose();
    _place.dispose();
    _cause.dispose();
    _employer.dispose();
    super.dispose();
  }

  InjuryDetails get _current => InjuryDetails(
    date: _injuryDate,
    time: _time.text.trim(),
    place: _place.text.trim(),
    cause: _cause.text.trim(),
    bodyPart: _bodyPart?.label ?? '',
    employer: _employer.text.trim(),
    category: _bodyPart?.category,
  );

  String? _errorFor(String field, String value) {
    if (!_showErrors || value.isNotEmpty) {
      return null;
    }
    return '$field is required.';
  }

  Future<void> _pickDate() async {
    final DateTime now = DateTime(2026, 9, 14);
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _injuryDate ?? now,
      firstDate: DateTime(now.year - 2),
      lastDate: now,
      helpText: 'Date of injury',
    );
    if (picked != null) {
      setState(() {
        _injuryDate = picked;
        _date.text = Formats.slashDate(picked);
      });
    }
  }

  Future<void> _pickTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 9, minute: 0),
      helpText: 'Time of injury',
    );
    if (picked != null) {
      setState(() {
        _time.text =
            '${picked.hour.toString().padLeft(2, '0')}:'
            '${picked.minute.toString().padLeft(2, '0')}';
      });
    }
  }

  void _saveDraft() {
    ref.read(newClaimProvider.notifier).setInjury(_current);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('The application saved your draft.')),
    );
  }

  void _next() {
    final InjuryDetails injury = _current;
    ref.read(newClaimProvider.notifier).setInjury(injury);

    if (!injury.isComplete) {
      setState(() => _showErrors = true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Complete these fields first: ${injury.missingFields.join(', ')}.',
          ),
        ),
      );
      return;
    }
    context.go('/new-claim/documents');
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('New injury claim'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          tooltip: 'Leave the form',
          onPressed: () => context.go('/home'),
        ),
      ),
      body: SafeArea(
        top: false,
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: <Widget>[
            const StepProgressHeader(
              step: 1,
              totalSteps: 3,
              title: 'Injury details',
            ),
            const SizedBox(height: 20),
            FormTextField(
              label: 'Date of injury',
              controller: _date,
              readOnly: true,
              onTap: _pickDate,
              hint: 'Select the date',
              errorText: _showErrors && _injuryDate == null
                  ? 'Date of injury is required.'
                  : null,
            ),
            FormTextField(
              label: 'Time of injury',
              controller: _time,
              readOnly: true,
              onTap: _pickTime,
              hint: 'Select the time',
              errorText: _errorFor('Time of injury', _time.text.trim()),
            ),
            FormTextField(
              label: 'Place of injury',
              controller: _place,
              hint: 'Warehouse B, loading bay 3',
              errorText: _errorFor('Place of injury', _place.text.trim()),
            ),
            FormTextField(
              label: 'Cause of injury',
              controller: _cause,
              hint: 'Struck by a falling pallet',
              maxLines: 2,
              errorText: _errorFor('Cause of injury', _cause.text.trim()),
            ),
            DropdownButtonFormField<BodyPartOption>(
              initialValue: _bodyPart,
              decoration: InputDecoration(
                labelText: 'Part of body affected',
                errorText: _showErrors && _bodyPart == null
                    ? 'Part of body affected is required.'
                    : null,
              ),
              items: <DropdownMenuItem<BodyPartOption>>[
                for (final BodyPartOption option in bodyPartOptions)
                  DropdownMenuItem<BodyPartOption>(
                    value: option,
                    child: Text(option.label),
                  ),
              ],
              onChanged: (BodyPartOption? value) =>
                  setState(() => _bodyPart = value),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 6, left: 4, bottom: 16),
              child: Text(
                'Required. The consultant is matched to this part of the '
                'body.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            FormTextField(
              label: 'Employer',
              controller: _employer,
              helper: 'From your Section 33 record. Correct it if it changed.',
              errorText: _errorFor('Employer', _employer.text.trim()),
            ),
          ],
        ),
      ),
      bottomNavigationBar: ActionBar(
        secondaryLabel: 'Save draft',
        primaryLabel: 'Next',
        onSecondary: _saveDraft,
        onPrimary: _next,
      ),
    );
  }
}
