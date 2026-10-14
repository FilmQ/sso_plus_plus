import 'package:flutter/material.dart';

import '../../models/appointment_slot.dart';
import '../../models/consultant.dart';
import '../shared/formats.dart';

/// The free slots of one consultant, as a row of choices.
///
/// Screens D3 and D8 share this widget. UC-04 and UC-11 both need it.
class SlotPicker extends StatelessWidget {
  const SlotPicker({
    super.key,
    required this.consultant,
    required this.slots,
    required this.selected,
    required this.onSelect,
    this.showConsultant = true,
  });

  final Consultant? consultant;
  final List<AppointmentSlot> slots;
  final AppointmentSlot? selected;
  final ValueChanged<AppointmentSlot> onSelect;
  final bool showConsultant;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colors = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          if (showConsultant && consultant != null) ...<Widget>[
            CircleAvatar(
              radius: 18,
              backgroundColor: colors.secondaryContainer,
              child: Text(
                consultant!.initials,
                style: theme.textTheme.labelLarge?.copyWith(
                  color: colors.onSecondaryContainer,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(width: 12),
            SizedBox(
              width: 190,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(consultant!.name, style: theme.textTheme.bodyMedium),
                  Text(
                    '${consultant!.specialty} · ${consultant!.area}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: <Widget>[
                if (slots.isEmpty)
                  Text(
                    'No free slot in this period.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                for (final AppointmentSlot slot in slots)
                  _SlotChip(
                    slot: slot,
                    selected: selected?.id == slot.id,
                    onTap: () => onSelect(slot),
                    long: !showConsultant,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SlotChip extends StatelessWidget {
  const _SlotChip({
    required this.slot,
    required this.selected,
    required this.onTap,
    required this.long,
  });

  final AppointmentSlot slot;
  final bool selected;
  final VoidCallback onTap;

  /// True to show the date as well as the time.
  final bool long;

  @override
  Widget build(BuildContext context) {
    final String label = long
        ? '${Formats.shortDateWithDay(slot.start)} · '
              '${Formats.time(slot.start)}'
        : '${_weekday(slot.start)} ${Formats.time(slot.start)}';

    return ChoiceChip(
      selected: selected,
      onSelected: (_) => onTap(),
      label: Text(label),
    );
  }

  static String _weekday(DateTime date) =>
      Formats.shortDateWithDay(date).split(' ').first;
}
