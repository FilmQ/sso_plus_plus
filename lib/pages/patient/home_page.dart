import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../models/appointment.dart';
import '../../models/claim.dart';
import '../../models/claim_progress.dart';
import '../../models/claim_status.dart';
import '../../providers/appointment_providers.dart';
import '../../providers/claim_providers.dart';
import '../../providers/person_provider.dart';
import '../../widgets/patient/notice_banner.dart';
import '../../widgets/shared/async_value_view.dart';
import '../../widgets/shared/claim_status_badge.dart';
import '../../widgets/shared/detail_row.dart';
import '../../widgets/shared/empty_state.dart';
import '../../widgets/shared/formats.dart';
import '../../widgets/shared/info_card.dart';
import '../../widgets/shared/progress_stepper.dart';
import '../../widgets/shared/section_heading.dart';

/// M1 · Home — the claim tracker.
///
/// It answers two questions: what must the person do now, and where has the
/// claim reached.
class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ThemeData theme = Theme.of(context);
    final person = ref.watch(currentPersonProvider);
    final AsyncValue<List<Claim>> claims = ref.watch(claimsProvider);
    final AsyncValue<Appointment?> next = ref.watch(
      appointmentAwaitingReplyProvider,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('SST Claims'),
        actions: <Widget>[
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            tooltip: 'Inbox',
            onPressed: () => context.go('/inbox'),
          ),
          IconButton(
            icon: const Icon(Icons.account_circle_outlined),
            tooltip: 'Account',
            onPressed: () => _showAccount(context, person.fullName),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.go('/new-claim'),
        icon: const Icon(Icons.add),
        label: const Text('New claim'),
      ),
      body: AsyncValueView<List<Claim>>(
        value: claims,
        onRetry: () => ref.invalidate(claimsProvider),
        builder: (List<Claim> all) {
          final Claim? active = _activeClaim(all);

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
            children: <Widget>[
              Text(
                person.fullName,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                'Insured under Section 33 · ${person.maskedNationalId}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 16),
              next.maybeWhen(
                data: (Appointment? appointment) => appointment == null
                    ? const SizedBox.shrink()
                    : _NextStepCard(appointment: appointment),
                orElse: () => const SizedBox.shrink(),
              ),
              if (active == null)
                const EmptyState(
                  icon: Icons.folder_open,
                  title: 'You have no claim yet',
                  message: 'Select New claim to report a work injury.',
                )
              else ...<Widget>[
                const SectionHeading('Claim progress'),
                InfoCard(
                  onTap: () => context.go('/claims/${active.claimNumber}'),
                  child: ProgressStepper(steps: _stepsFor(active)),
                ),
              ],
            ],
          );
        },
      ),
    );
  }

  /// The claim that the person is most likely to ask about.
  ///
  /// A claim that is not closed comes first. If every claim is closed, the
  /// newest one answers.
  static Claim? _activeClaim(List<Claim> all) {
    if (all.isEmpty) {
      return null;
    }
    for (final Claim claim in all) {
      if (claim.status != ClaimStatus.closed &&
          claim.status != ClaimStatus.rejected) {
        return claim;
      }
    }
    return all.first;
  }

  static List<ProgressStep> _stepsFor(Claim claim) {
    final Map<ProgressStage, String> details = <ProgressStage, String>{};

    if (claim.submittedAt != null) {
      details[ProgressStage.submitted] = Formats.dateAndTime(
        claim.submittedAt!,
      );
    }
    final verification = claim.verification;
    if (verification != null) {
      details[ProgressStage.verified] =
          '${verification.result.label} · '
          '${Formats.dateAndTime(verification.decidedAt)}';
    }
    if (claim.status == ClaimStatus.appointmentProposed) {
      details[ProgressStage.appointment] = 'Awaiting your confirmation';
    }

    return ClaimProgress.stepsFor(claim, details: details);
  }

  static void _showAccount(BuildContext context, String name) {
    showDialog<void>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: const Text('Account'),
        content: Text(
          'You are signed in as $name.\n\n'
          'This demonstration has one account. The officer and the '
          'consultant use the web console instead.',
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}

/// The card that carries the next action of the person.
class _NextStepCard extends StatelessWidget {
  const _NextStepCard({required this.appointment});

  final Appointment appointment;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final bool isTreatment = appointment.kind == AppointmentKind.treatment;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InfoCard(
        tone: InfoCardTone.highlighted,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                const ClaimStatusBadge(
                  label: 'Action needed',
                  tone: BadgeTone.action,
                  icon: Icons.error_outline,
                ),
                const Spacer(),
                Text(
                  appointment.claimNumber,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              isTreatment
                  ? 'Confirm your treatment date'
                  : 'Confirm your appointment',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 10),
            DetailRow(
              icon: Icons.event_outlined,
              label: Formats.dayDateAndTime(appointment.start),
            ),
            DetailRow(
              icon: Icons.place_outlined,
              label: '${appointment.facility} · ${appointment.room}',
              dense: true,
            ),
            const SizedBox(height: 12),
            NoticeBanner(
              text:
                  'Reply by ${Formats.shortDateWithDay(appointment.replyBy)}. '
                  'If you do not, an officer will telephone you.',
            ),
            const SizedBox(height: 12),
            Row(
              children: <Widget>[
                FilledButton.icon(
                  onPressed: () =>
                      context.go('/appointments/${appointment.id}'),
                  icon: const Icon(Icons.check),
                  label: const Text('Confirm'),
                ),
                const SizedBox(width: 8),
                TextButton(
                  onPressed: () =>
                      context.go('/appointments/${appointment.id}'),
                  child: const Text('Another date'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
