import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../models/claim.dart';
import '../../models/claim_status.dart';
import '../../providers/claim_providers.dart';
import '../../widgets/shared/async_value_view.dart';
import '../../widgets/shared/claim_status_badge.dart';
import '../../widgets/shared/empty_state.dart';
import '../../widgets/shared/formats.dart';
import '../../widgets/shared/info_card.dart';

/// The Claims destination. It lists every claim of the person.
class ClaimsPage extends ConsumerWidget {
  const ClaimsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ThemeData theme = Theme.of(context);
    final AsyncValue<List<Claim>> claims = ref.watch(claimsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Your claims')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.go('/new-claim'),
        icon: const Icon(Icons.add),
        label: const Text('New claim'),
      ),
      body: AsyncValueView<List<Claim>>(
        value: claims,
        onRetry: () => ref.invalidate(claimsProvider),
        builder: (List<Claim> all) {
          if (all.isEmpty) {
            return const EmptyState(
              icon: Icons.folder_open,
              title: 'You have no claim yet',
              message: 'Select New claim to report a work injury.',
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
            itemCount: all.length,
            separatorBuilder: (_, _) => const SizedBox(height: 10),
            itemBuilder: (BuildContext context, int index) {
              final Claim claim = all[index];
              return InfoCard(
                onTap: () => context.go('/claims/${claim.claimNumber}'),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        ClaimStatusBadge(
                          label: claim.status.label,
                          tone: _toneFor(claim.status),
                        ),
                        const Spacer(),
                        Text(
                          claim.claimNumber,
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      claim.injury.bodyPart.isEmpty
                          ? 'Injury claim'
                          : claim.injury.bodyPart,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      claim.injury.cause,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      claim.submittedAt == null
                          ? 'Not sent yet'
                          : 'Sent ${Formats.dateAndTime(claim.submittedAt!)}',
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

  static BadgeTone _toneFor(ClaimStatus status) => switch (status) {
    ClaimStatus.verifiedNotCovered || ClaimStatus.rejected => BadgeTone.bad,
    ClaimStatus.appointmentProposed => BadgeTone.action,
    ClaimStatus.verifiedCovered ||
    ClaimStatus.appointmentConfirmed ||
    ClaimStatus.reportSigned ||
    ClaimStatus.treatmentScheduled => BadgeTone.good,
    _ => BadgeTone.neutral,
  };
}
