import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../pages/console/consultant/consultant_schedule_page.dart';
import '../pages/console/console_login_page.dart';
import '../pages/console/reports/consultation_report_page.dart';
import '../pages/console/reports/report_list_page.dart';
import '../pages/console/scheduling/schedule_appointment_page.dart';
import '../pages/console/shell/console_shell.dart';
import '../pages/console/treatment/schedule_treatment_page.dart';
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
  String home() => officer() ? '/verification' : '/schedule';
  bool consultantPath(String at) => at.startsWith('/schedule') || at.startsWith('/consultations');
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
      // The officer starts on the Verification Page (O1), the consultant on
      // the Schedule Page (C1).
      GoRoute(path: '/console', redirect: (BuildContext context, GoRouterState state) => home()),
      ShellRoute(
        // Each role opens only its own pages.
        redirect: (BuildContext context, GoRouterState state) =>
            consultantPath(state.matchedLocation) == officer() ? home() : null,
        builder: (BuildContext context, GoRouterState state, Widget child) =>
            ConsoleShell(location: state.matchedLocation, child: child),
        routes: <RouteBase>[
          GoRoute(
            path: '/schedule',
            builder: (BuildContext context, GoRouterState state) => const ConsultantSchedulePage(),
          ),
          GoRoute(
            path: '/consultations',
            builder: (BuildContext context, GoRouterState state) => const ConsolePage(
                title: 'Create Consultation Report',
                subtitle: '',
                body: PendingPage(title: 'Create Consultation Report', useCases: 'C2.1 to C2.3')),
          ),
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
          GoRoute(
            path: '/treatment',
            builder: (BuildContext context, GoRouterState state) => const ScheduleTreatmentPage(),
          ),
          GoRoute(
            path: '/reports',
            builder: (BuildContext context, GoRouterState state) => const ReportListPage(),
            routes: <RouteBase>[
              GoRoute(
                path: ':reportId',
                builder: (BuildContext context, GoRouterState state) => ConsultationReportPage(
                    key: ValueKey<String>(state.pathParameters['reportId']!),
                    reportId: int.parse(state.pathParameters['reportId']!)),
              ),
            ],
          ),
        ],
      ),
    ],
  );
});
