import 'package:flutter/material.dart';

import '../../models/appointment.dart';
import '../shared/detail_row.dart';
import '../shared/formats.dart';
import '../shared/info_card.dart';

/// The card that shows one appointment in full.
///
/// Screens M6, M7 and M9 all use it. The `kind` field of the appointment
/// makes the treatment card, so no second widget is necessary.
class AppointmentCard extends StatelessWidget {
  const AppointmentCard({
    super.key,
    required this.appointment,
    this.injurySummary,
  });

  final Appointment appointment;

  /// A short description of the injury, shown against the claim number.
  final String? injurySummary;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colors = theme.colorScheme;

    return InfoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            appointment.title,
            style: theme.textTheme.titleSmall?.copyWith(
              color: colors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            Formats.longDate(appointment.start),
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            Formats.timeRange(appointment.start, appointment.end),
            style: theme.textTheme.titleMedium,
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Divider(),
          ),
          if (appointment.consultantName.isNotEmpty)
            DetailRow(
              icon: Icons.person_outline,
              label: appointment.consultantName,
              detail: appointment.specialty,
            ),
          DetailRow(
            icon: Icons.place_outlined,
            label: appointment.facility,
            detail: appointment.room,
          ),
          DetailRow(
            icon: Icons.folder_outlined,
            label: 'Claim ${appointment.claimNumber}',
            detail: injurySummary,
            dense: true,
          ),
        ],
      ),
    );
  }
}
