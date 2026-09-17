import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../pages/console/arrange_consultation_page.dart';
import '../pages/console/confirmations_page.dart';
import '../pages/console/consultation_session_page.dart';
import '../pages/console/eligibility_decision_page.dart';
import '../pages/console/queue_pages.dart';
import '../pages/console/report_sign_off_page.dart';
import '../pages/console/schedule_appointment_page.dart';
import '../pages/console/schedule_treatment_page.dart';
import '../pages/console/verification_worklist_page.dart';
import '../widgets/console/console_shell.dart';

/// The routes of the staff console.
///
/// The console needs no role redirect. The rail shows every destination at
/// all times, and BR-22 is enforced in the repository. Section 7.2 of
/// IMPLEMENTATION.md records that.
final Provider<GoRouter> consoleRouterProvider = Provider<GoRouter>((Ref ref) {
  return GoRouter(
    // A demonstration can start at any screen, for example:
    //   flutter run -d chrome -t lib/main_console.dart \
    //     --dart-define=START_AT=/clinic/reports
    initialLocation: const String.fromEnvironment(
      'START_AT',
      defaultValue: '/officer/verification',
    ),
    routes: <RouteBase>[
      ShellRoute(
        builder: (BuildContext context, GoRouterState state, Widget child) =>
            ConsoleShell(child: child),
        routes: <RouteBase>[
          // --- Evaluation Officer ---
          GoRoute(
            path: '/officer/verification',
            builder: (BuildContext context, GoRouterState state) =>
                const VerificationWorklistPage(),
            routes: <RouteBase>[
              GoRoute(
                path: ':claimNumber',
                builder: (BuildContext context, GoRouterState state) =>
                    EligibilityDecisionPage(
                      claimNumber: state.pathParameters['claimNumber'] ?? '',
                    ),
              ),
            ],
          ),
          GoRoute(
            path: '/officer/scheduling',
            builder: (BuildContext context, GoRouterState state) =>
                const SchedulingQueuePage(),
            routes: <RouteBase>[
              GoRoute(
                path: ':claimNumber',
                builder: (BuildContext context, GoRouterState state) =>
                    ScheduleAppointmentPage(
                      claimNumber: state.pathParameters['claimNumber'] ?? '',
                    ),
              ),
            ],
          ),
          GoRoute(
            path: '/officer/confirmations',
            builder: (BuildContext context, GoRouterState state) =>
                const ConfirmationsPage(),
          ),
          GoRoute(
            path: '/officer/consultations',
            builder: (BuildContext context, GoRouterState state) =>
                const ConsultationsQueuePage(),
            routes: <RouteBase>[
              GoRoute(
                path: ':claimNumber',
                builder: (BuildContext context, GoRouterState state) =>
                    ArrangeConsultationPage(
                      claimNumber: state.pathParameters['claimNumber'] ?? '',
                    ),
              ),
            ],
          ),

          // --- Consultant ---
          GoRoute(
            path: '/clinic/sessions',
            builder: (BuildContext context, GoRouterState state) =>
                const SessionsQueuePage(),
            routes: <RouteBase>[
              GoRoute(
                path: ':sessionId',
                builder: (BuildContext context, GoRouterState state) =>
                    ConsultationSessionPage(
                      sessionId: state.pathParameters['sessionId'] ?? '',
                    ),
              ),
            ],
          ),
          GoRoute(
            path: '/clinic/reports',
            builder: (BuildContext context, GoRouterState state) =>
                const ReportsQueuePage(),
            routes: <RouteBase>[
              GoRoute(
                path: ':reportId',
                builder: (BuildContext context, GoRouterState state) =>
                    ReportSignOffPage(
                      reportId: state.pathParameters['reportId'] ?? '',
                    ),
              ),
            ],
          ),
          GoRoute(
            path: '/clinic/treatment',
            builder: (BuildContext context, GoRouterState state) =>
                const TreatmentQueuePage(),
            routes: <RouteBase>[
              GoRoute(
                path: ':reportId',
                builder: (BuildContext context, GoRouterState state) =>
                    ScheduleTreatmentPage(
                      reportId: state.pathParameters['reportId'] ?? '',
                    ),
              ),
            ],
          ),
        ],
      ),
    ],
  );
});
