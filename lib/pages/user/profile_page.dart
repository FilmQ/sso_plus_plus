import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../session/session_providers.dart';
import '../../widgets/centered_body.dart';
import '../../widgets/info_card.dart';
import '../../widgets/key_value.dart';
import 'home/home_providers.dart';
import 'home/notification_bell.dart';

/// P-1 Profile Page (Figma node 146:50; infrastructure, D-003): the name,
/// the national ID, the phone number, the address and "Sign out".
class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  /// '0812345678' as '081 234 5678'; '023154400' as '02 315 4400'.
  static String showPhone(String p) => switch (p.length) {
        10 => '${p.substring(0, 3)} ${p.substring(3, 6)} ${p.substring(6)}',
        9 => '${p.substring(0, 2)} ${p.substring(2, 5)} ${p.substring(5)}',
        _ => p,
      };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final TextTheme text = Theme.of(context).textTheme;
    final AsyncValue<Map<String, Object?>> profile = ref.watch(profileProvider);
    final Map<String, Object?>? p = profile.value;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: const <Widget>[NotificationBell(), SizedBox(width: 4)],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        children: <Widget>[
          CenteredBody(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: 16,
              children: <Widget>[
                if (profile.isLoading) const Center(child: CircularProgressIndicator()),
                if (profile.hasError) Text('The profile cannot be shown now.', style: text.bodyMedium),
                if (p != null) ...<Widget>[
                  Text(p['full_name']! as String, style: text.headlineSmall),
                  Text('Signed in with national ID ${p['national_id']}',
                      style: text.bodyMedium?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant)),
                ],
                InfoCard(
                  icon: Icons.person,
                  title: 'Account details',
                  tonal: true,
                  children: <Widget>[
                    if (p != null) ...<Widget>[
                      KeyValue('Phone number', showPhone(p['phone_no']! as String), large: true),
                      KeyValue('Address', p['address']! as String),
                    ],
                    Align(
                      alignment: Alignment.centerLeft,
                      child: FilledButton.tonal(
                        onPressed: () => ref.read(sessionProvider.notifier).logout(),
                        child: const Text('Sign out'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
