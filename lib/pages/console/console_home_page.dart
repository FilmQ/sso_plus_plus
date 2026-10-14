import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../session/session_providers.dart';
import '../../session/user_session.dart';
import '../../widgets/pending_page.dart';

/// The first page after sign-in on the console. The officer pages (O1 to O6)
/// and the consultant pages (C1, C2) come in later sessions.
class ConsoleHomePage extends ConsumerWidget {
  const ConsoleHomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final UserSession? session = ref.watch(sessionProvider).value;
    final bool officer = session?.isOfficer ?? false;
    return Scaffold(
      appBar: AppBar(
        title: Text(officer ? 'Evaluation Officer' : 'Consultant'),
        actions: <Widget>[
          Center(child: Text(session?.displayName ?? '')),
          const SizedBox(width: 8),
          IconButton(
            tooltip: 'Sign out',
            icon: const Icon(Icons.logout),
            onPressed: () => ref.read(sessionProvider.notifier).logout(),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: PendingPage(
        title: officer ? 'Officer console' : 'Consultant console',
        useCases: officer ? 'O1 to O6' : 'C1 and C2',
      ),
    );
  }
}
