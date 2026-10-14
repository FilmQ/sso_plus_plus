import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../pages/shared/login_page.dart';
import '../pages/user/injury_form/injury_form_page.dart';
import '../pages/user/injury_forms_submitted_page.dart';
import '../pages/user/register_page.dart';
import '../pages/user/submission_provider.dart';
import '../session/session_providers.dart';
import '../widgets/pending_page.dart';
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
      final bool signedIn = ref.read(sessionProvider).value != null;
      final String at = state.matchedLocation;
      if (!signedIn) return _public.contains(at) ? null : '/register';
      // U1 step 6: after a submission the user is signed in and sees U1-5.
      if (at == '/register/form' && ref.read(submissionProvider) != null) return '/register/submitted';
      return _public.contains(at) ? '/home' : null;
    },
    routes: <RouteBase>[
      GoRoute(
        path: '/login',
        builder: (BuildContext context, GoRouterState state) =>
            const LoginPage(title: 'SST Injury Claim', loginLabel: 'National ID', registerRoute: '/register'),
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
