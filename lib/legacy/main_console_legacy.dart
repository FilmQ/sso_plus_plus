import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'providers/console_router.dart';
import 'widgets/app_theme.dart';

/// LEGACY (September draft, D1 to D8). Superseded by lib/main_console.dart. See docs/DECISIONS.md, D-012.
///
/// The entry point of the staff console.
///
/// This build runs in a browser on a desktop. Build it with the target on
/// the command line:
///
///     flutter build web --release -t lib/main_console.dart
///
/// Without `-t` the build makes the patient application instead, which is
/// not a supported surface on the web.
void main() {
  runApp(const ProviderScope(child: ConsoleApp()));
}

/// The root of the staff console.
class ConsoleApp extends ConsumerWidget {
  const ConsoleApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      title: 'SST Console',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      routerConfig: ref.watch(consoleRouterProvider),
    );
  }
}
