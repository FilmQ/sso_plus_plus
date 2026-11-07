import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../l10n/tr.dart';
import '../../../session/session_providers.dart';
import '../../../widgets/centered_body.dart';
import '../../../widgets/info_card.dart';
import '../../../widgets/key_value.dart';
import '../treatment/open_treatment.dart';
import 'claim_progress_card.dart';
import 'home_providers.dart';
import 'notification_bell.dart';

/// U2-1 Home page (SA report figure 2-17): the claim card (Q2.4) and the
/// bell icon of U2 (Q2.1 to Q2.3, in [NotificationBell]).
class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: Text(context.tr('Home')),
        actions: const <Widget>[NotificationBell(), SizedBox(width: 4)],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(unreadCountProvider);
          ref.invalidate(homeClaimProvider);
          await ref.read(homeClaimProvider.future);
        },
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          children: const <Widget>[CenteredBody(child: _HomeBody())],
        ),
      ),
    );
  }
}

class _HomeBody extends ConsumerWidget {
  const _HomeBody();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final TextTheme text = Theme.of(context).textTheme;
    final AsyncValue<Map<String, Object?>?> home = ref.watch(homeClaimProvider);
    final Map<String, Object?>? claim = home.value;
    final String firstName = (claim?['first_name'] as String?) ?? ref.watch(sessionProvider).value?.firstName ?? '';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 16,
      children: <Widget>[
        Text(context.tr('Hello, {name}', {'name': firstName}), style: text.headlineSmall),
        if (home.hasError) Text(context.tr('The claim cannot be shown now. Pull down to try again.'), style: text.bodyMedium),
        if (home.isLoading) const Center(child: CircularProgressIndicator()),
        if (claim != null) ...<Widget>[
          Text(context.tr('Claim {no} · {injury}', {'no': claim['claim_no'], 'injury': claim['injury']}),
              style: text.bodyMedium?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant)),
          ClaimProgressCard(claim: claim),
          // After U4.3 a past Confirmed appointment is still in Q2.4 (D-064).
          if (claim['appointment_time'] != null && claim['claim_status'] != 'Withdrawn')
            InfoCard(
              icon: Icons.event,
              title: 'Next appointment',
              tonal: true,
              children: <Widget>[
                KeyValue('Date', claim['appointment_time']! as String, large: true),
                KeyValue('Consultant', '${claim['consultant_name']} · ${context.tr('${claim['office_location']}')}'),
                Align(
                  alignment: Alignment.centerLeft,
                  child: FilledButton.tonal(
                    onPressed: () => context.push('/appointment/${claim['claim_id']}'),
                    child: Text(context.tr('View appointment')),
                  ),
                ),
              ],
            ),
          // U4: a Pending treatment waits for the user's answer (D-045).
          if (claim['treatment_status'] == 'Pending')
            Align(
              alignment: Alignment.centerLeft,
              child: FilledButton.tonal(
                onPressed: () => openTreatmentOfClaim(context, ref, claim['claim_id']! as int),
                child: Text(context.tr('View treatment')),
              ),
            ),
        ],
      ],
    );
  }
}
