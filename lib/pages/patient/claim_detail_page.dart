import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../models/claim.dart';
import '../../models/claim_status.dart';
import '../../providers/claim_providers.dart';
import '../../widgets/shared/async_value_view.dart';
import '../../widgets/shared/empty_state.dart';
import 'claim_status_view.dart';
import 'claim_submitted_view.dart';
import 'rejection_view.dart';

/// The claim screen. The state of the claim selects which view it shows.
///
/// M4 and M5 of the design are the same screen at two stages, so one route
/// serves both. The URL stays `/claims/<number>` in every state.
class ClaimDetailPage extends ConsumerWidget {
  const ClaimDetailPage({super.key, required this.claimNumber});

  final String claimNumber;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<Claim?> claim = ref.watch(claimProvider(claimNumber));

    return Scaffold(
      appBar: AppBar(
        title: Text(_titleFor(claim.value?.status)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () =>
              context.canPop() ? context.pop() : context.go('/claims'),
        ),
      ),
      body: AsyncValueView<Claim?>(
        value: claim,
        onRetry: () => ref.invalidate(claimProvider(claimNumber)),
        builder: (Claim? found) {
          if (found == null) {
            return EmptyState(
              icon: Icons.search_off,
              title: 'No claim carries the number $claimNumber',
              message: 'Check the number, or open the claim from your list.',
            );
          }

          return switch (found.status) {
            ClaimStatus.submitted || ClaimStatus.awaitingVerification =>
              ClaimSubmittedView(claim: found),
            ClaimStatus.rejected => RejectionView(claim: found),
            _ => ClaimStatusView(claim: found),
          };
        },
      ),
    );
  }

  static String _titleFor(ClaimStatus? status) => switch (status) {
    ClaimStatus.submitted || ClaimStatus.awaitingVerification => 'Claim status',
    ClaimStatus.rejected => 'Decision',
    _ => 'Claim',
  };
}
