import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../l10n/language_provider.dart';

/// The toggle of the UI language. Each language name stays in its own language,
/// so a person can always find their language.
class LanguageToggle extends ConsumerWidget {
  const LanguageToggle({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SegmentedButton<String>(
      key: const Key('language_toggle'),
      showSelectedIcon: false,
      segments: const <ButtonSegment<String>>[
        ButtonSegment<String>(value: 'en', label: Text('EN'), tooltip: 'English'),
        ButtonSegment<String>(value: 'th', label: Text('ไทย'), tooltip: 'ภาษาไทย'),
      ],
      selected: <String>{Localizations.localeOf(context).languageCode},
      onSelectionChanged: (Set<String> chosen) => ref.read(languageProvider.notifier).change(chosen.single),
    );
  }
}
