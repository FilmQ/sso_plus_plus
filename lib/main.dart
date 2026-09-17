import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'providers/patient_router.dart';
import 'widgets/app_theme.dart';

/// The entry point of the patient application.
///
/// This build runs on a phone. The officer and the consultant use the web
/// console, which starts at `lib/main_console.dart`.
void main() {
  runApp(const ProviderScope(child: PatientApp()));
}

/// The root of the patient application.
class PatientApp extends ConsumerWidget {
  const PatientApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      title: 'SST Claims',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      routerConfig: ref.watch(patientRouterProvider),
    );
  }
}
