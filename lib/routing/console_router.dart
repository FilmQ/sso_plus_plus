import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../pages/console/console_home_page.dart';
import '../pages/console/console_login_page.dart';
import 'session_redirect.dart';
import 'session_refresh.dart';

/// The routes of the officer and consultant console
/// (site map: diagrams/sitemap-officer.png, diagrams/sitemap-consultant.png).
final Provider<GoRouter> consoleRouterProvider = Provider<GoRouter>((Ref ref) {
  final SessionRefresh refresh = SessionRefresh(ref);
  ref.onDispose(refresh.dispose);
  return GoRouter(
    initialLocation: '/login',
    refreshListenable: refresh,
    redirect: (BuildContext context, GoRouterState state) =>
        sessionRedirect(ref, state, public: const <String>{'/login'}, home: '/console', start: '/login'),
    routes: <RouteBase>[
      loadingRoute,
      GoRoute(
        path: '/login',
        builder: (BuildContext context, GoRouterState state) => const ConsoleLoginPage(),
      ),
      GoRoute(
        path: '/console',
        builder: (BuildContext context, GoRouterState state) => const ConsoleHomePage(),
      ),
    ],
  );
});
