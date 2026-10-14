import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../models/eligibility.dart';
import '../../providers/officer_providers.dart';
import '../../widgets/console/console_scaffolds.dart';
import '../../widgets/console/kpi_tile.dart';
import '../../widgets/console/worklist_panel.dart';
import '../../widgets/shared/async_value_view.dart';
import '../../widgets/shared/claim_status_badge.dart';
import '../../widgets/shared/formats.dart';

/// D1 · Officer — verification worklist (UC-02).
///
/// The officer sees every claim that waits for a Section 33 decision, with
/// the answer the register already gave.
class VerificationWorklistPage extends ConsumerWidget {
  const VerificationWorklistPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ThemeData theme = Theme.of(context);
    final AsyncValue<List<VerificationRow>> rows = ref.watch(
      verificationRowsProvider,
    );
    final AsyncValue<VerificationCounts> counts = ref.watch(
      verificationCountsProvider,
    );

    final VerificationCounts figures =
        counts.value ??
        const VerificationCounts(
          awaiting: 0,
          needsReview: 0,
          registerDown: 0,
          verifiedThisWeek: 0,
        );

    return ConsoleScreen(
      title: 'Verification',
      subtitle: 'Evaluation Officer · claims awaiting a Section 33 decision',
      searchHint: 'Search claim number or name',
      body: AsyncValueView<List<VerificationRow>>(
        value: rows,
        onRetry: () => ref.invalidate(verificationRowsProvider),
        builder: (List<VerificationRow> found) {
          return WorklistBody(
            kpis: <Widget>[
              KpiTile(
                label: 'Awaiting verification',
                value: figures.awaiting,
                icon: Icons.hourglass_empty,
              ),
              KpiTile(
                label: 'Needs review',
                value: figures.needsReview,
                icon: Icons.warning_amber_outlined,
                tone: KpiTone.warning,
              ),
              KpiTile(
                label: 'Register unavailable',
                value: figures.registerDown,
                icon: Icons.error_outline,
                tone: KpiTone.alert,
              ),
              KpiTile(
                label: 'Verified this week',
                value: figures.verifiedThisWeek,
                icon: Icons.check_circle_outline,
                tone: KpiTone.good,
              ),
            ],
            panels: <Widget>[
              WorklistPanel(
                heading: 'Claims awaiting verification',
                footer:
                    'Showing ${found.length} of ${found.length} · sorted by '
                    'oldest submission',
                columns: const <WorklistColumn>[
                  WorklistColumn('Claim / claimant', flex: 4),
                  WorklistColumn('Injury date'),
                  WorklistColumn('Submitted'),
                  WorklistColumn('Docs', flex: 1),
                  WorklistColumn('Register result', flex: 2),
                  WorklistColumn('Status', flex: 2),
                  WorklistColumn('', flex: 2),
                ],
                rows: <List<Widget>>[
                  for (final VerificationRow row in found)
                    <Widget>[
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            row.claim.claimNumber,
                            style: theme.textTheme.bodyMedium,
                          ),
                          Text(
                            row.claimantLine,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        row.claim.injury.date == null
                            ? '—'
                            : Formats.shortDate(row.claim.injury.date!),
                        style: theme.textTheme.bodyMedium,
                      ),
                      Text(
                        row.claim.submittedAt == null
                            ? '—'
                            : Formats.dateAndTime(row.claim.submittedAt!),
                        style: theme.textTheme.bodyMedium,
                      ),
                      Text(
                        row.documentCount,
                        style: theme.textTheme.bodyMedium,
                      ),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: _resultBadge(row),
                      ),
                      Text(
                        row.statusLine,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      Align(
                        alignment: Alignment.centerRight,
                        child: FilledButton.tonal(
                          onPressed: () => context.go(
                            '/officer/verification/${row.claim.claimNumber}',
                          ),
                          child: const Text('Open'),
                        ),
                      ),
                    ],
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  static Widget _resultBadge(VerificationRow row) {
    if (!row.record.available) {
      return const ClaimStatusBadge(
        label: 'Register down',
        tone: BadgeTone.bad,
        icon: Icons.cloud_off,
      );
    }
    return switch (row.automatic) {
      EligibilityResult.covered => const ClaimStatusBadge(
        label: 'Covered',
        tone: BadgeTone.good,
        icon: Icons.verified,
      ),
      EligibilityResult.needsReview => const ClaimStatusBadge(
        label: 'Needs review',
        tone: BadgeTone.action,
        icon: Icons.warning_amber_outlined,
      ),
      EligibilityResult.notCovered => const ClaimStatusBadge(
        label: 'Not covered',
        tone: BadgeTone.bad,
        icon: Icons.cancel_outlined,
      ),
    };
  }
}
