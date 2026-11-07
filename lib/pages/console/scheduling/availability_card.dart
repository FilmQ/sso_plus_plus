import 'package:flutter/material.dart';

import '../../../l10n/tr.dart';
import '../../../widgets/person_avatar.dart';
import '../verification/claim_cards.dart';
import 'scheduling_providers.dart';

/// "Consultant availability" (Figma O4-1): a row of hour buttons for each
/// consultant of QO4.2. White: free; grey: busy, not clickable; purple:
/// scheduled by this officer and pending; with a check: selected.
class AvailabilityCard extends StatelessWidget {
  const AvailabilityCard({super.key, required this.slots, required this.selected, required this.onSelect});

  final List<Map<String, Object?>> slots;
  final Map<String, Object?>? selected;
  final ValueChanged<Map<String, Object?>> onSelect;

  @override
  Widget build(BuildContext context) {
    final List<int> consultants = <int>{for (final Map<String, Object?> s in slots) s.consultantId}.toList();
    return ConsoleCard(
      title: 'Consultant availability',
      children: <Widget>[
        if (consultants.isEmpty) Text(context.tr('There are no consultants.')),
        for (final int id in consultants) _consultant(context, slots.where((s) => s.consultantId == id).toList()),
      ],
    );
  }

  Widget _consultant(BuildContext context, List<Map<String, Object?>> rows) {
    final TextTheme text = Theme.of(context).textTheme;
    final String name = '${rows.first['consultant_name']}';
    return Column(crossAxisAlignment: CrossAxisAlignment.start, spacing: 12, children: <Widget>[
      Row(spacing: 12, children: <Widget>[
        PersonAvatar(name),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
            Text(name, style: text.titleSmall),
            Text(context.tr('${rows.first['office_location']}'), style: text.bodySmall),
          ]),
        ),
      ]),
      Wrap(spacing: 8, runSpacing: 8, children: <Widget>[for (final Map<String, Object?> s in rows) _slot(context, s)]),
      const SizedBox(height: 4),
    ]);
  }

  Widget _slot(BuildContext context, Map<String, Object?> s) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    final String label = context.tr('${s['slot_button']}');
    final Map<String, Object?>? sel = selected;
    final bool chosen = sel != null && sel['consultant_id'] == s['consultant_id'] && sel['slot_at'] == s['slot_at'];
    return switch (s.state) {
      'mine' => FilledButton(
          key: ValueKey<String>('slot:${s.consultantId}:${s.slotTime}'),
          style: FilledButton.styleFrom(
              disabledBackgroundColor: colors.primary, disabledForegroundColor: colors.onPrimary),
          onPressed: null,
          child: Text(label)),
      'free' when chosen => OutlinedButton.icon(
          key: ValueKey<String>('slot:${s.consultantId}:${s.slotTime}'),
          style: OutlinedButton.styleFrom(
              backgroundColor: colors.secondaryContainer, side: BorderSide(color: colors.primary, width: 2)),
          onPressed: () => onSelect(s),
          icon: const Icon(Icons.check),
          label: Text(label)),
      'free' => OutlinedButton(
          key: ValueKey<String>('slot:${s.consultantId}:${s.slotTime}'),
          onPressed: () => onSelect(s),
          child: Text(label)),
      _ => FilledButton.tonal(
          key: ValueKey<String>('slot:${s.consultantId}:${s.slotTime}'), onPressed: null, child: Text(label)),
    };
  }
}

/// The colour legend under the date (Figma O4-1).
class SlotLegend extends StatelessWidget {
  const SlotLegend({super.key, this.busy = 'Busy, not clickable'});

  /// The text of the grey hours (O5.1-1 adds the 12:00 and 17:00 limits).
  final String busy;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    Widget item(Color fill, Color border, String label) =>
        Row(mainAxisSize: MainAxisSize.min, spacing: 6, children: <Widget>[
          Container(
            width: 16,
            height: 16,
            decoration: BoxDecoration(
                color: fill, border: Border.all(color: border), borderRadius: BorderRadius.circular(4)),
          ),
          Flexible(child: Text(context.tr(label), style: Theme.of(context).textTheme.bodySmall)),
        ]);
    return Wrap(spacing: 16, runSpacing: 8, children: <Widget>[
      item(colors.surfaceContainerLowest, colors.outline, 'Free'),
      item(colors.surfaceContainerHighest, colors.surfaceContainerHighest, busy),
      item(colors.primary, colors.primary, 'Scheduled by you, pending'),
      item(colors.secondaryContainer, colors.primary, 'Selected'),
    ]);
  }
}
