import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../session/session_providers.dart';
import '../../session/user_session.dart';
import '../../widgets/centered_body.dart';

/// Profile: the name of the signed-in user and "Sign out". Figma has the
/// destination but no frame for it (D-024).
class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final UserSession? session = ref.watch(sessionProvider).value;
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: <Widget>[
          CenteredBody(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                ListTile(
                  leading: const CircleAvatar(child: Icon(Icons.person)),
                  title: Text(session?.displayName ?? ''),
                  subtitle: const Text('Insured person'),
                ),
                const SizedBox(height: 24),
                OutlinedButton.icon(
                  onPressed: () => ref.read(sessionProvider.notifier).logout(),
                  icon: const Icon(Icons.logout),
                  label: const Text('Sign out'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
