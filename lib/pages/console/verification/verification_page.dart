import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../l10n/tr.dart';
import '../shell/console_shell.dart';
import 'claims_table.dart';
import 'verification_providers.dart';

/// O1-1 Verification Page (SA report figure 2-55): the counts by status
/// (QO1.2) and the claims to verify (QO1.1). O1 steps 1 to 3.
class VerificationPage extends ConsumerWidget {
  const VerificationPage({super.key});

  /// O1 step 3: "Open" goes to the Eligibility Decision Page.
  static void clickOpen(BuildContext context, int claimId) => context.go('/verification/$claimId');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<Map<String, Object?>> page = ref.watch(verificationListProvider);
    final Map<String, Object?> counts = (page.value?['counts'] as Map<String, Object?>?) ?? const <String, Object?>{};
    final List<Map<String, Object?>> claims =
        ((page.value?['claims'] as List<Object?>?) ?? const <Object?>[]).cast<Map<String, Object?>>();
    return ConsolePage(
      title: 'Verification',
      subtitle: 'Claims waiting for an eligibility decision',
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(verificationListProvider.future),
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: <Widget>[
            Wrap(spacing: 16, runSpacing: 16, children: <Widget>[
              _CountCard(Icons.hourglass_top, 'Awaiting verification', counts['awaiting_verification']),
              _CountCard(Icons.rate_review, 'Reviews needed', counts['reviews_needed']),
              _CountCard(Icons.cloud_off, 'Register unavailable', counts['register_unavailable']),
            ]),
            const SizedBox(height: 16),
            if (page.hasError) Text(context.tr('The claims cannot be shown now. Pull down to try again.')),
            if (page.isLoading) const Center(child: CircularProgressIndicator()),
            if (page.hasValue) ClaimsTable(claims: claims, onOpen: (int id) => clickOpen(context, id)),
          ],
        ),
      ),
    );
  }
}

/// One count of QO1.2 (Figma O1-1, top row).
class _CountCard extends StatelessWidget {
  const _CountCard(this.icon, this.label, this.count);

  final IconData icon;
  final String label;
  final Object? count;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    return Container(
      width: 360,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.outlineVariant),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, spacing: 4, children: <Widget>[
        Row(spacing: 8, children: <Widget>[
          Icon(icon, size: 20, color: colors.primary),
          Flexible(child: Text(context.tr(label), style: Theme.of(context).textTheme.titleSmall)),
        ]),
        Text('${count ?? '-'}', style: Theme.of(context).textTheme.displaySmall),
      ]),
    );
  }
}
