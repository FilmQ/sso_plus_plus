import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../pages/console/console_home_page.dart';
import '../pages/shared/login_page.dart';
import '../session/session_providers.dart';
import 'session_refresh.dart';

/// The routes of the officer and consultant console
/// (site map: diagrams/sitemap-officer.png, diagrams/sitemap-consultant.png).
final Provider<GoRouter> consoleRouterProvider = Provider<GoRouter>((Ref ref) {
  final SessionRefresh refresh = SessionRefresh(ref);
  ref.onDispose(refresh.dispose);
  return GoRouter(
    initialLocation: '/login',
    refreshListenable: refresh,
    redirect: (BuildContext context, GoRouterState state) {
      final bool signedIn = ref.read(sessionProvider).value != null;
      final bool atLogin = state.matchedLocation == '/login';
      if (!signedIn && !atLogin) return '/login';
      if (signedIn && atLogin) return '/console';
      return null;
    },
    routes: <RouteBase>[
      GoRoute(
        path: '/login',
        builder: (BuildContext context, GoRouterState state) =>
            const LoginPage(title: 'SST Console', loginLabel: 'E-mail'),
      ),
      GoRoute(
        path: '/console',
        builder: (BuildContext context, GoRouterState state) => const ConsoleHomePage(),
      ),
    ],
  );
});
