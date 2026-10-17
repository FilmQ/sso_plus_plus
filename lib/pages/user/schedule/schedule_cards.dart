import 'package:flutter/material.dart';

import '../../../widgets/person_avatar.dart';
import '../../../widgets/side_key_value.dart';
import '../../../widgets/status_chip.dart';

/// A card of the Schedule Page: the header, the date line and the claim lines.
class _ScheduleCard extends StatelessWidget {
  const _ScheduleCard({required this.row, required this.header, required this.date, this.chip, this.banner, this.onTap});

  final Map<String, Object?> row;
  final Widget header;
  final String date;
  final Widget? chip;
  final Widget? banner;
  final VoidCallback? onTap;

  String _s(String key) => (row[key] as String?) ?? '';

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    return Card.outlined(
      margin: EdgeInsets.zero,
      color: colors.surfaceContainerLowest,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            ?banner,
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                spacing: 12,
                children: <Widget>[
                  header,
                  Row(spacing: 8, children: <Widget>[
                    Icon(Icons.calendar_month, color: colors.primary),
                    Expanded(child: Text(date, style: Theme.of(context).textTheme.titleMedium)),
                    ?chip,
                  ]),
                  const Divider(height: 1),
                  SideKeyValue('Claim ID', _s('claim_no'), labelWidth: 88),
                  SideKeyValue('Injury', _s('injury'), labelWidth: 88),
                  SideKeyValue('Injury date', _s('injury_date'), labelWidth: 88),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// U5-1: one QU5.1 row. QU5.1 has no status and no claim_id, so the card has
/// no chip and does not open the Appointment Page (R-032).
class AppointmentScheduleCard extends StatelessWidget {
  const AppointmentScheduleCard({super.key, required this.row});

  final Map<String, Object?> row;

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    final String name = (row['consultant_name'] as String?) ?? '';
    return _ScheduleCard(
      row: row,
      date: (row['appointment_date'] as String?) ?? '',
      header: Row(spacing: 12, children: <Widget>[
        PersonAvatar(name),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
            Text(name, style: text.titleSmall),
            Text((row['office_location'] as String?) ?? '',
                style: text.bodySmall?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant)),
          ]),
        ),
      ]),
    );
  }
}

/// U6-1: one Q6.1 row. The schema has no picture or address of the facility,
/// so the card shows an icon and the treatment type (R-033).
class TreatmentScheduleCard extends StatelessWidget {
  const TreatmentScheduleCard({super.key, required this.row, this.onTap});

  final Map<String, Object?> row;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    final TextTheme text = Theme.of(context).textTheme;
    return _ScheduleCard(
      row: row,
      onTap: onTap,
      date: (row['treatment_date'] as String?) ?? '',
      chip: TreatmentStatusChip((row['treatment_status'] as String?) ?? '', short: true),
      banner: Container(
        height: 96,
        color: colors.primaryContainer,
        child: Icon(Icons.local_hospital, size: 40, color: colors.onPrimaryContainer),
      ),
      header: Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
        Text((row['facility_name'] as String?) ?? '', style: text.titleSmall),
        Text((row['treatment_type'] as String?) ?? '', style: text.bodySmall?.copyWith(color: colors.onSurfaceVariant)),
      ]),
    );
  }
}
