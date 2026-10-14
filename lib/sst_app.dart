import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'theme/app_theme.dart';

/// The root widget of both apps.
class SstApp extends ConsumerWidget {
  const SstApp({super.key, required this.title, required this.router});

  final String title;
  final Provider<GoRouter> router;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      title: title,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      routerConfig: ref.watch(router),
    );
  }
}
