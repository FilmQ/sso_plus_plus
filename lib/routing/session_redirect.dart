import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../session/session_providers.dart';
import '../session/user_session.dart';

/// The redirect rules that both apps share.
///
/// While the kept session is checked, a protected page waits on `/loading`
/// and then opens; so a link to a page (web) still works after a reload.
String? sessionRedirect(
  Ref ref,
  GoRouterState state, {
  required Set<String> public,
  required String home,
  required String start,
}) {
  final AsyncValue<UserSession?> session = ref.read(sessionProvider);
  final String at = state.matchedLocation;
  if (session.isLoading) {
    return public.contains(at) || at == '/loading' ? null : '/loading?from=${Uri.encodeComponent(state.uri.toString())}';
  }
  final bool signedIn = session.value != null;
  if (at == '/loading') {
    return signedIn ? (state.uri.queryParameters['from'] ?? home) : start;
  }
  if (!signedIn) return public.contains(at) ? null : start;
  return public.contains(at) ? home : null;
}

/// The page that waits for the session check.
final GoRoute loadingRoute = GoRoute(
  path: '/loading',
  builder: (BuildContext context, GoRouterState state) =>
      const Scaffold(body: Center(child: CircularProgressIndicator())),
);
