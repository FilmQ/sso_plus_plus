import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../session/session_providers.dart';
import '../../../widgets/centered_body.dart';
import '../../../widgets/info_card.dart';
import '../../../widgets/key_value.dart';
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
        title: const Text('Home'),
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
        Text('สวัสดี คุณ$firstName', style: text.headlineSmall),
        if (home.hasError) Text('The claim cannot be shown now. Pull down to try again.', style: text.bodyMedium),
        if (home.isLoading) const Center(child: CircularProgressIndicator()),
        if (claim != null) ...<Widget>[
          Text('Claim ${claim['claim_no']} · ${claim['injury']}',
              style: text.bodyMedium?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant)),
          ClaimProgressCard(claim: claim),
          if (claim['appointment_time'] != null)
            InfoCard(
              icon: Icons.event,
              title: 'Next appointment',
              tonal: true,
              children: <Widget>[
                KeyValue('Date', claim['appointment_time']! as String, large: true),
                KeyValue('Consultant', '${claim['consultant_name']} · ${claim['office_location']}'),
              ],
            ),
        ],
      ],
    );
  }
}
