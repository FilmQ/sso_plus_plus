import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_web_plugins/url_strategy.dart';

import 'routing/console_router.dart';
import 'session/session_providers.dart';
import 'sst_app.dart';

/// The console of the Evaluation Officer and the Consultant: desktop layout.
///   flutter run -d chrome -t lib/main_console.dart
void main() {
  usePathUrlStrategy(); // web: /register/form, not /#/register/form
  runApp(ProviderScope(
    overrides: [appKindProvider.overrideWithValue('console')],
    child: SstApp(title: 'SST Console', router: consoleRouterProvider),
  ));
}
