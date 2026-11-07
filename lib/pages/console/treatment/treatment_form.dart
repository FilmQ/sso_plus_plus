import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/tr.dart';
import '../scheduling/availability_card.dart';
import '../verification/claim_cards.dart';
import 'treatment_providers.dart';

/// "Treatment to book" (Figma O5.1-1, O5.1 steps 2.1 and 3): the type, the
/// duration and the facility, then "Available Times" (QO5.2) by day.
class TreatmentForm extends StatelessWidget {
  const TreatmentForm({
    super.key,
    required this.type,
    required this.duration,
    required this.facility,
    required this.slots,
    required this.selected,
    required this.onType,
    required this.onDuration,
    required this.onFacility,
    required this.onSelect,
  });

  final String? type;
  final int? duration;
  final String? facility;

  /// The QO5.2 rows, or null before the three fields are chosen.
  final AsyncValue<List<Map<String, Object?>>>? slots;
  final Map<String, Object?>? selected;
  final ValueChanged<String?> onType;
  final ValueChanged<int?> onDuration;
  final ValueChanged<String?> onFacility;
  final ValueChanged<Map<String, Object?>> onSelect;

  @override
  Widget build(BuildContext context) {
    return ConsoleCard(
      title: 'Treatment to book',
      children: <Widget>[
        Wrap(spacing: 12, runSpacing: 12, children: <Widget>[
          _menu<String>(context, const Key('treatment_type'), 'Treatment type', type, TreatmentOptions.types,
              (String t) => context.tr(t), onType),
          _menu<int>(context, const Key('duration'), 'Duration', duration, TreatmentOptions.durations,
              (int m) => context.tr('{n} minutes', <String, Object?>{'n': m}), onDuration),
          _menu<String>(context, const Key('facility'), 'Facility', facility, TreatmentOptions.facilities,
              (String f) => context.tr(f), onFacility, width: 300),
        ]),
        Text(context.tr('Available Times'), style: Theme.of(context).textTheme.titleSmall),
        _times(context),
        const SlotLegend(busy: 'Busy or does not fit before 12:00 or 17:00, not clickable'),
      ],
    );
  }

  Widget _menu<T>(BuildContext context, Key key, String label, T? value, List<T> options, String Function(T) text,
          ValueChanged<T?> onChanged, {double width = 190}) =>
      // A new language makes a new menu, so the field shows the label in that language.
      KeyedSubtree(
        key: ValueKey<(Key, Locale)>((key, Localizations.localeOf(context))),
        child: DropdownMenu<T>(
          key: key,
          width: width,
          label: Text(context.tr(label)),
          initialSelection: value,
          dropdownMenuEntries: <DropdownMenuEntry<T>>[
            for (final T o in options) DropdownMenuEntry<T>(value: o, label: text(o)),
          ],
          onSelected: onChanged,
        ),
      );

  Widget _times(BuildContext context) {
    final AsyncValue<List<Map<String, Object?>>>? s = slots;
    if (s == null) return Text(context.tr('Choose a treatment type, duration and facility first.'));
    return s.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (Object e, _) => Text(context.tr('The times cannot be shown now.')),
      data: (List<Map<String, Object?>> rows) {
        if (rows.isEmpty) return Text(context.tr('There are no times in the next days.'));
        final List<String> days =
            <String>{for (final Map<String, Object?> r in rows) '${r['slot_at']}'.substring(0, 10)}.toList();
        return Column(crossAxisAlignment: CrossAxisAlignment.stretch, spacing: 12, children: <Widget>[
          for (final String day in days)
            Wrap(spacing: 8, runSpacing: 8, children: <Widget>[
              for (final Map<String, Object?> r in rows.where((r) => '${r['slot_at']}'.startsWith(day)))
                _slot(context, r),
            ]),
        ]);
      },
    );
  }

  Widget _slot(BuildContext context, Map<String, Object?> r) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    final Key key = ValueKey<String>('time:${r['slot_at']}');
    final Text label = Text(context.tr('${r['slot_button']}'));
    return switch (r['slot_state']) {
      'mine' => FilledButton(
          key: key,
          style: FilledButton.styleFrom(
              disabledBackgroundColor: colors.primary, disabledForegroundColor: colors.onPrimary),
          onPressed: null,
          child: label),
      'free' when selected?['slot_at'] == r['slot_at'] => OutlinedButton.icon(
          key: key,
          style: OutlinedButton.styleFrom(
              backgroundColor: colors.secondaryContainer, side: BorderSide(color: colors.primary, width: 2)),
          onPressed: () => onSelect(r),
          icon: const Icon(Icons.check),
          label: label),
      'free' => OutlinedButton(key: key, onPressed: () => onSelect(r), child: label),
      _ => FilledButton.tonal(key: key, onPressed: null, child: label),
    };
  }
}
