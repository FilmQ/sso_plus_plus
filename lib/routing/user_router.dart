import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../pages/shared/login_page.dart';
import '../pages/user/injury_form/injury_form_page.dart';
import '../pages/user/home/home_page.dart';
import '../pages/user/injury_forms_submitted_page.dart';
import '../pages/user/profile_page.dart';
import '../pages/user/register_page.dart';
import '../pages/user/submission_provider.dart';
import '../pages/user/user_shell.dart';
import '../session/session_providers.dart';
import '../widgets/pending_page.dart';
import 'session_redirect.dart';
import 'session_refresh.dart';

/// Routes that a person opens without a session.
const Set<String> _public = <String>{'/login', '/register', '/register/form'};

/// The routes of the user app (site map: diagrams/sitemap-user.png).
/// The first page is U1-1 Register Page; it links to the login page.
final Provider<GoRouter> userRouterProvider = Provider<GoRouter>((Ref ref) {
  final SessionRefresh refresh = SessionRefresh(ref);
  ref.onDispose(refresh.dispose);
  return GoRouter(
    initialLocation: '/register',
    refreshListenable: refresh,
    redirect: (BuildContext context, GoRouterState state) {
      // U1 step 6: after a submission the user is signed in and sees U1-5.
      final bool submitted = ref.read(submissionProvider) != null && ref.read(sessionProvider).value != null;
      if (submitted && state.matchedLocation == '/register/form') return '/register/submitted';
      return sessionRedirect(ref, state, public: _public, home: '/home', start: '/register');
    },
    routes: <RouteBase>[
      loadingRoute,
      GoRoute(
        path: '/login',
        builder: (BuildContext context, GoRouterState state) =>
            const LoginPage(
                title: 'Sign in', loginLabel: 'National ID', loginHelper: '13 digits, numbers only', registerRoute: '/register'),
      ),
      GoRoute(
        path: '/register',
        builder: (BuildContext context, GoRouterState state) => const RegisterPage(),
        routes: <RouteBase>[
          GoRoute(
            path: 'form',
            builder: (BuildContext context, GoRouterState state) => const InjuryFormPage(),
          ),
          GoRoute(
            path: 'submitted',
            builder: (BuildContext context, GoRouterState state) => const InjuryFormsSubmittedPage(),
          ),
        ],
      ),
      StatefulShellRoute.indexedStack(
        builder: (BuildContext context, GoRouterState state, StatefulNavigationShell shell) => UserShell(shell: shell),
        branches: <StatefulShellBranch>[
          _branch('/home', const HomePage()),
          _branch('/schedule', _pending('Schedule', 'U5 and U6')),
          _branch('/notifications', _pending('Notifications', 'U3')),
          _branch('/profile', const ProfilePage()),
        ],
      ),
    ],
  );
});

StatefulShellBranch _branch(String path, Widget page) => StatefulShellBranch(
      routes: <RouteBase>[GoRoute(path: path, builder: (BuildContext context, GoRouterState state) => page)],
    );

Widget _pending(String title, String useCases) =>
    Scaffold(appBar: AppBar(title: Text(title)), body: PendingPage(title: title, useCases: useCases));
