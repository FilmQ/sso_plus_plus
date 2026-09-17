import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../models/claim.dart';
import '../../models/rejection_notice.dart';
import '../../providers/claim_providers.dart';
import '../../providers/notice_providers.dart';
import '../../providers/use_case_providers.dart';
import '../../use-cases/uc_03_reject_application.dart';
import '../../widgets/patient/action_bar.dart';
import '../../widgets/shared/claim_status_badge.dart';
import '../../widgets/shared/detail_row.dart';
import '../../widgets/shared/formats.dart';
import '../../widgets/shared/info_card.dart';
import '../../widgets/shared/notice_banner.dart';
import '../../widgets/shared/section_heading.dart';

/// M5 · Rejection notice (UC-03).
///
/// The person reads why the claim failed, the record it was decided from,
/// and the two routes forward: appeal, or resubmit with new evidence.
class RejectionView extends ConsumerWidget {
  const RejectionView({super.key, required this.claim});

  final Claim claim;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colors = theme.colorScheme;
    final RejectionNotice? notice = claim.rejection;

    if (notice == null) {
      return const Center(child: Text('This claim carries no decision.'));
    }

    final int daysLeft = ref
        .read(rejectApplicationProvider)
        .daysLeftToAppeal(claim);

    return Column(
      children: <Widget>[
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            children: <Widget>[
              Row(
                children: <Widget>[
                  const ClaimStatusBadge(
                    label: 'Not covered',
                    tone: BadgeTone.bad,
                  ),
                  const Spacer(),
                  Text(
                    claim.claimNumber,
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                'Your claim is not covered',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Decided ${Formats.shortDate(notice.decidedAt)}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colors.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 20),
              InfoCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      'Reason',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    DetailRow(
                      icon: Icons.tag,
                      label: 'Code ${notice.reasonCode}',
                      detail: notice.reasonText,
                    ),
                    DetailRow(
                      icon: Icons.fact_check_outlined,
                      label: 'Checked against',
                      detail: notice.checkedAgainst,
                      dense: true,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              const SectionHeading('What you can do'),
              InfoCard(
                padding: EdgeInsets.zero,
                child: Column(
                  children: <Widget>[
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: DetailRow(
                        icon: Icons.gavel_outlined,
                        label: 'Appeal this decision',
                        detail:
                            'Within ${notice.appealDays} days of the '
                            'decision. $daysLeft days are left.',
                        dense: true,
                      ),
                    ),
                    const Divider(height: 1),
                    const Padding(
                      padding: EdgeInsets.all(16),
                      child: DetailRow(
                        icon: Icons.note_add_outlined,
                        label: 'Resubmit with new evidence',
                        detail: 'This starts a new claim linked to this one.',
                        dense: true,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              const NoticeBanner(
                text:
                    'Your claim and its documents stay on record. A refused '
                    'claim is kept, so it can be appealed and audited.',
              ),
            ],
          ),
        ),
        ActionBar(
          secondaryLabel: 'Resubmit',
          primaryLabel: 'Appeal',
          onSecondary: () => _resubmit(context, ref),
          onPrimary: () => _appeal(context, ref),
        ),
      ],
    );
  }

  Future<void> _appeal(BuildContext context, WidgetRef ref) async {
    final RejectionResponse result = await ref
        .read(rejectApplicationProvider)
        .appeal(claim);
    if (!context.mounted) {
      return;
    }
    _refresh(ref);

    switch (result) {
      case AppealStarted():
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Your appeal is with an officer for review.'),
          ),
        );
        context.go('/claims');
      case AppealPeriodOver(closedOn: final DateTime closedOn):
        _sayPeriodOver(context, closedOn);
      case ResubmissionStarted():
        break;
    }
  }

  Future<void> _resubmit(BuildContext context, WidgetRef ref) async {
    final RejectionResponse result = await ref
        .read(rejectApplicationProvider)
        .resubmit(claim);
    if (!context.mounted) {
      return;
    }
    _refresh(ref);

    switch (result) {
      case ResubmissionStarted(newClaim: final Claim fresh):
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Claim ${fresh.claimNumber} is a draft. It refers back to '
              '${claim.claimNumber}.',
            ),
          ),
        );
        context.go('/new-claim');
      case AppealPeriodOver(closedOn: final DateTime closedOn):
        _sayPeriodOver(context, closedOn);
      case AppealStarted():
        break;
    }
  }

  void _refresh(WidgetRef ref) {
    ref.invalidate(claimsProvider);
    ref.invalidate(claimProvider(claim.claimNumber));
    ref.invalidate(noticesProvider);
    ref.invalidate(unreadNoticeCountProvider);
  }

  static void _sayPeriodOver(BuildContext context, DateTime closedOn) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'The appeal period closed on ${Formats.shortDate(closedOn)}.',
        ),
      ),
    );
  }
}
