import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../pages/patient/appointment_detail_page.dart';
import '../pages/patient/appointments_page.dart';
import '../pages/patient/claim_detail_page.dart';
import '../pages/patient/claims_page.dart';
import '../pages/patient/consultation_report_page.dart';
import '../pages/patient/documents_page.dart';
import '../pages/patient/home_page.dart';
import '../pages/patient/inbox_page.dart';
import '../pages/patient/injury_details_page.dart';
import '../widgets/patient/patient_shell.dart';

/// The routes of the patient application.
///
/// The patient application has one actor, so the router needs no role
/// redirect. The console has its own router and its own entry point.
final Provider<GoRouter> patientRouterProvider = Provider<GoRouter>((Ref ref) {
  return GoRouter(
    // A demonstration can start at any screen. Give the route on the command
    // line, for example:
    //   flutter run --dart-define=START_AT=/appointments/APT-0143-1
    initialLocation: const String.fromEnvironment(
      'START_AT',
      defaultValue: '/home',
    ),
    routes: <RouteBase>[
      StatefulShellRoute.indexedStack(
        builder: (
          BuildContext context,
          GoRouterState state,
          StatefulNavigationShell navigationShell,
        ) => PatientShell(navigationShell: navigationShell),
        branches: <StatefulShellBranch>[
          StatefulShellBranch(
            routes: <RouteBase>[
              GoRoute(
                path: '/home',
                builder: (BuildContext context, GoRouterState state) =>
                    const HomePage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: <RouteBase>[
              GoRoute(
                path: '/claims',
                builder: (BuildContext context, GoRouterState state) =>
                    const ClaimsPage(),
                routes: <RouteBase>[
                  GoRoute(
                    path: ':claimNumber',
                    builder: (BuildContext context, GoRouterState state) =>
                        ClaimDetailPage(
                          claimNumber:
                              state.pathParameters['claimNumber'] ?? '',
                        ),
                    routes: <RouteBase>[
                      GoRoute(
                        path: 'report',
                        builder: (BuildContext context, GoRouterState state) =>
                            ConsultationReportPage(
                              claimNumber:
                                  state.pathParameters['claimNumber'] ?? '',
                            ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: <RouteBase>[
              GoRoute(
                path: '/appointments',
                builder: (BuildContext context, GoRouterState state) =>
                    const AppointmentsPage(),
                routes: <RouteBase>[
                  GoRoute(
                    path: ':appointmentId',
                    builder: (BuildContext context, GoRouterState state) =>
                        AppointmentDetailPage(
                          appointmentId:
                              state.pathParameters['appointmentId'] ?? '',
                        ),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: <RouteBase>[
              GoRoute(
                path: '/inbox',
                builder: (BuildContext context, GoRouterState state) =>
                    const InboxPage(),
              ),
            ],
          ),
        ],
      ),

      // The claim form covers the whole screen. It carries its own action
      // bar, so it stands outside the shell and shows no navigation bar.
      GoRoute(
        path: '/new-claim',
        builder: (BuildContext context, GoRouterState state) =>
            const InjuryDetailsPage(),
        routes: <RouteBase>[
          GoRoute(
            path: 'documents',
            builder: (BuildContext context, GoRouterState state) =>
                const DocumentsPage(),
          ),
        ],
      ),
    ],
  );
});
