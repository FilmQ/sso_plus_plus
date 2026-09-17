import 'package:flutter/material.dart';

import '../../models/claim.dart';
import '../../widgets/patient/notice_banner.dart';
import '../../widgets/shared/formats.dart';
import '../../widgets/shared/info_card.dart';
import '../../widgets/shared/section_heading.dart';

/// M4 · Claim submitted — the eligibility check runs (UC-01 → UC-02).
///
/// UC-01 invokes UC-02 on every submission. The person sees that the check
/// started, and that an officer confirms the result.
class ClaimSubmittedView extends StatelessWidget {
  const ClaimSubmittedView({super.key, required this.claim});

  final Claim claim;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colors = theme.colorScheme;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: <Widget>[
        const SizedBox(height: 8),
        Icon(Icons.check_circle, size: 48, color: colors.primary),
        const SizedBox(height: 12),
        Text(
          'Claim submitted',
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          claim.submittedAt == null
              ? 'The application registered your claim.'
              : 'Received ${Formats.dateAndTime(claim.submittedAt!)}',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: colors.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 20),
        InfoCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                'Claim number',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colors.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 2),
              Text(claim.claimNumber, style: theme.textTheme.titleMedium),
            ],
          ),
        ),
        const SizedBox(height: 8),
        const SectionHeading('What happens next'),
        InfoCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                'Section 33 eligibility check',
                style: theme.textTheme.bodyMedium,
              ),
              Text(
                'Running now against the SSO insured register.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colors.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 10),
              const ClipRRect(
                borderRadius: BorderRadius.all(Radius.circular(4)),
                child: LinearProgressIndicator(minHeight: 6),
              ),
              const SizedBox(height: 20),
              Text(
                'An officer confirms the result',
                style: theme.textTheme.bodyMedium,
              ),
              Text(
                'You are told either way in this application.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colors.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        const NoticeBanner(
          text:
              'Keep notifications on. The application tells you as soon as '
              'an officer decides.',
          icon: Icons.notifications_active_outlined,
        ),
      ],
    );
  }
}
