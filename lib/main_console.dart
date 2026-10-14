import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'routing/console_router.dart';
import 'session/session_providers.dart';
import 'sst_app.dart';

/// The console of the Evaluation Officer and the Consultant: desktop layout.
///   flutter run -d chrome -t lib/main_console.dart
void main() {
  runApp(ProviderScope(
    overrides: [appKindProvider.overrideWithValue('console')],
    child: SstApp(title: 'SST Console', router: consoleRouterProvider),
  ));
}
