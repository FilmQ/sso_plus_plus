import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../pages/shared/login_page.dart';
import '../session/session_providers.dart';
import '../widgets/pending_page.dart';
import 'session_refresh.dart';

/// Routes that a person can open without a session.
const Set<String> _public = <String>{'/login'};

/// The routes of the user app (site map: diagrams/sitemap-user.png).
final Provider<GoRouter> userRouterProvider = Provider<GoRouter>((Ref ref) {
  final SessionRefresh refresh = SessionRefresh(ref);
  ref.onDispose(refresh.dispose);
  return GoRouter(
    initialLocation: '/login',
    refreshListenable: refresh,
    redirect: (BuildContext context, GoRouterState state) {
      final bool signedIn = ref.read(sessionProvider).value != null;
      final bool public = _public.contains(state.matchedLocation);
      if (!signedIn && !public) return '/login';
      if (signedIn && public) return '/home';
      return null;
    },
    routes: <RouteBase>[
      GoRoute(
        path: '/login',
        builder: (BuildContext context, GoRouterState state) =>
            const LoginPage(title: 'SST Injury Claim', loginLabel: 'National ID'),
      ),
      GoRoute(
        path: '/home',
        builder: (BuildContext context, GoRouterState state) => Scaffold(
          appBar: AppBar(title: const Text('Home')),
          body: PendingPage(
            title: 'Home',
            useCases: 'U2',
            action: OutlinedButton(
              onPressed: () => ref.read(sessionProvider.notifier).logout(),
              child: const Text('Sign out'),
            ),
          ),
        ),
      ),
    ],
  );
});
