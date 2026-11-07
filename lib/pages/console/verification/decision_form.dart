import 'package:flutter/material.dart';

import '../../../l10n/tr.dart';

/// The officer's choice in the right panel of O1-2 (O2 and O3 step 3).
class Decision {
  String? result; // 'Covered' (Confirm) or 'Not covered'
  String? reasonCode;
  final TextEditingController message = TextEditingController();
  final TextEditingController overrideReason = TextEditingController();

  bool get ready => result == 'Covered' || (result == 'Not covered' && reasonCode != null);

  void dispose() {
    message.dispose();
    overrideReason.dispose();
  }
}

/// "Officer decision" (Figma O2-1, O3-1): Confirm or Not Covered, the
/// rejection reason (QO1.6) and the message for Not Covered, the override
/// reason (QO2.1 and QO3.1 need it when the decision differs from the
/// automatic result; R-037), and "Confirm Result". [errors] are the 422 field
/// errors.
class DecisionForm extends StatelessWidget {
  const DecisionForm({
    super.key,
    required this.decision,
    required this.reasons,
    required this.errors,
    required this.busy,
    required this.onChanged,
    required this.onConfirmResult,
  });

  final Decision decision;
  final List<Map<String, Object?>> reasons;
  final Map<String, Object?> errors;
  final bool busy;
  final VoidCallback onChanged;
  final VoidCallback onConfirmResult;

  /// The code and the name of a QO1.6 row. The name is Thai data, with English in English mode.
  static String reasonLabel(BuildContext context, Map<String, Object?> r) =>
      '${r['reason_code']} · ${context.tr('${r['name_th']}')}';

  @override
  Widget build(BuildContext context) {
    final bool notCovered = decision.result == 'Not covered';
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, spacing: 12, children: <Widget>[
      Text(context.tr('Officer decision'), style: Theme.of(context).textTheme.titleSmall),
      RadioGroup<String>(
        groupValue: decision.result,
        onChanged: (String? v) {
          decision.result = v;
          onChanged();
        },
        child: Column(spacing: 12, children: <Widget>[
          _option(context, 'Covered', 'Confirm', 'Covered under Section 33, the claim moves to scheduling'),
          _option(context, 'Not covered', 'Not Covered', 'The claim is rejected and the user is told why'),
        ]),
      ),
      if (notCovered) ...<Widget>[
        // A new language makes a new menu, so the field shows the label in that language.
        KeyedSubtree(
          key: ValueKey<Locale>(Localizations.localeOf(context)),
          child: DropdownMenu<String>(
            key: const Key('rejection_reason'),
            expandedInsets: EdgeInsets.zero,
            label: Text(context.tr('Rejection reason')),
            hintText: context.tr('Choose a reason'),
            initialSelection: decision.reasonCode,
            errorText: context.trMaybe(errors['reason_code'] as String?),
            dropdownMenuEntries: <DropdownMenuEntry<String>>[
              for (final Map<String, Object?> r in reasons)
                DropdownMenuEntry<String>(value: '${r['reason_code']}', label: reasonLabel(context, r)),
            ],
            onSelected: (String? code) {
              decision.reasonCode = code;
              onChanged();
            },
          ),
        ),
        TextField(
          controller: decision.message,
          minLines: 3,
          maxLines: 5,
          maxLength: 1000,
          decoration: InputDecoration(
            labelText: context.tr('Message to the user'),
            border: const OutlineInputBorder(),
            errorText: context.trMaybe(errors['officer_message'] as String?),
          ),
        ),
      ],
      TextField(
        controller: decision.overrideReason,
        maxLength: 255,
        decoration: InputDecoration(
          labelText: context.tr('Override reason (required if your decision differs)'),
          hintText: context.tr('Why your decision differs from the automatic result'),
          border: const OutlineInputBorder(),
          errorText: context.trMaybe(errors['override_reason'] as String?),
        ),
      ),
      FilledButton.icon(
        onPressed: decision.ready && !busy ? onConfirmResult : null,
        icon: const Icon(Icons.check),
        label: Text(context.tr('Confirm Result')),
      ),
    ]);
  }

  /// One choice as an outlined card; the chosen card is filled.
  Widget _option(BuildContext context, String value, String title, String subtitle) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    final bool chosen = decision.result == value;
    return Material(
      color: chosen ? colors.secondaryContainer : colors.surfaceContainerLowest,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: chosen ? colors.primary : colors.outlineVariant),
      ),
      clipBehavior: Clip.antiAlias,
      child: RadioListTile<String>(value: value, title: Text(context.tr(title)), subtitle: Text(context.tr(subtitle))),
    );
  }
}
