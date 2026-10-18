import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../pages/console/console_home_page.dart';
import '../pages/console/console_login_page.dart';
import '../pages/console/scheduling/schedule_appointment_page.dart';
import '../pages/console/shell/console_shell.dart';
import '../pages/console/verification/eligibility_decision_page.dart';
import '../pages/console/verification/verification_page.dart';
import '../session/session_providers.dart';
import '../widgets/pending_page.dart';
import 'session_redirect.dart';
import 'session_refresh.dart';

/// The routes of the officer and consultant console
/// (site map: diagrams/sitemap-officer.png, diagrams/sitemap-consultant.png).
final Provider<GoRouter> consoleRouterProvider = Provider<GoRouter>((Ref ref) {
  final SessionRefresh refresh = SessionRefresh(ref);
  ref.onDispose(refresh.dispose);
  bool officer() => ref.read(sessionProvider).value?.isOfficer ?? false;
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
      // The officer starts on the Verification Page (O1); the consultant
      // pages (C1, C2) come later.
      GoRoute(
        path: '/console',
        redirect: (BuildContext context, GoRouterState state) => officer() ? '/verification' : null,
        builder: (BuildContext context, GoRouterState state) => const ConsoleHomePage(),
      ),
      ShellRoute(
        redirect: (BuildContext context, GoRouterState state) => officer() ? null : '/console',
        builder: (BuildContext context, GoRouterState state, Widget child) =>
            ConsoleShell(location: state.matchedLocation, child: child),
        routes: <RouteBase>[
          GoRoute(
            path: '/verification',
            builder: (BuildContext context, GoRouterState state) => const VerificationPage(),
            routes: <RouteBase>[
              GoRoute(
                path: ':claimId',
                builder: (BuildContext context, GoRouterState state) => EligibilityDecisionPage(
                    key: ValueKey<String>(state.pathParameters['claimId']!),
                    claimId: int.parse(state.pathParameters['claimId']!)),
              ),
            ],
          ),
          GoRoute(
            path: '/scheduling',
            builder: (BuildContext context, GoRouterState state) => const ScheduleAppointmentPage(),
          ),
          _pending('/treatment', 'Treatment', 'O5.1 and O5.2'),
          _pending('/reports', 'Consultation Reports', 'O6'),
        ],
      ),
    ],
  );
});

/// An officer page that a later step builds.
GoRoute _pending(String path, String title, String useCases) => GoRoute(
      path: path,
      builder: (BuildContext context, GoRouterState state) =>
          ConsolePage(title: title, subtitle: '', body: PendingPage(title: title, useCases: useCases)),
    );
