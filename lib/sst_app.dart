import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'l10n/language_provider.dart';
import 'l10n/tr.dart';
import 'theme/app_theme.dart';

/// The root widget of both apps.
class SstApp extends ConsumerWidget {
  const SstApp({super.key, required this.title, required this.router});

  final String title;
  final Provider<GoRouter> router;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      onGenerateTitle: (BuildContext context) => context.tr(title),
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      locale: Locale(ref.watch(languageProvider).value ?? LanguageNotifier.firstLanguage),
      supportedLocales: const <Locale>[Locale('en'), Locale('th')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      routerConfig: ref.watch(router),
    );
  }
}
