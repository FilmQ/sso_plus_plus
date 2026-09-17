import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../models/appointment.dart';
import '../../providers/appointment_providers.dart';
import '../../widgets/shared/async_value_view.dart';
import '../../widgets/shared/claim_status_badge.dart';
import '../../widgets/shared/empty_state.dart';
import '../../widgets/shared/formats.dart';
import '../../widgets/shared/info_card.dart';

/// The Appointments destination.
///
/// It lists the consultation dates and the treatment dates together,
/// because one entity holds both.
class AppointmentsPage extends ConsumerWidget {
  const AppointmentsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ThemeData theme = Theme.of(context);
    final AsyncValue<List<Appointment>> appointments = ref.watch(
      appointmentsProvider,
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Appointments')),
      body: AsyncValueView<List<Appointment>>(
        value: appointments,
        onRetry: () => ref.invalidate(appointmentsProvider),
        builder: (List<Appointment> all) {
          if (all.isEmpty) {
            return const EmptyState(
              icon: Icons.event_busy,
              title: 'You have no appointment',
              message: 'An officer offers a date after your claim is verified.',
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            itemCount: all.length,
            separatorBuilder: (_, _) => const SizedBox(height: 10),
            itemBuilder: (BuildContext context, int index) {
              final Appointment appointment = all[index];
              return InfoCard(
                onTap: () => context.go('/appointments/${appointment.id}'),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        ClaimStatusBadge(
                          label: appointment.status.label,
                          tone: appointment.needsReply
                              ? BadgeTone.action
                              : appointment.isConfirmed
                              ? BadgeTone.good
                              : BadgeTone.neutral,
                        ),
                        const Spacer(),
                        Icon(
                          appointment.kind == AppointmentKind.treatment
                              ? Icons.medical_services_outlined
                              : Icons.event_available_outlined,
                          size: 18,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      appointment.title,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      '${Formats.longDate(appointment.start)} · '
                      '${Formats.timeRange(appointment.start, appointment.end)}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      appointment.facility,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
