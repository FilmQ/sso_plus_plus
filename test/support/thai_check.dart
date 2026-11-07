import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sso_plus_plus/l10n/tr.dart';

/// The Thai text of an English label.
String th(String text, [Map<String, Object?> args = const <String, Object?>{}]) => translate('th', text, args);

final RegExp _word = RegExp(r'[A-Za-z]*[a-z][A-Za-z]*');

/// Fails when a shown text or tooltip still has an English word. Only a word
/// with a lowercase letter counts, so codes such as 'SST' and 'PDF' pass.
/// [data] lists the test data that a person types (for example a body part).
void expectNoEnglishLabels(WidgetTester tester, {List<String> data = const <String>[]}) {
  final List<String> shown = <String>[
    for (final Text t in tester.widgetList<Text>(find.byType(Text))) t.data ?? t.textSpan?.toPlainText() ?? '',
    // The language toggle names English in English.
    for (final Tooltip t in tester.widgetList<Tooltip>(find.byType(Tooltip)))
      if (t.message != 'English') t.message ?? '',
  ];
  final List<String> english = <String>[
    for (final String s in shown)
      if (_word.hasMatch(data.fold<String>(s, (String text, String d) => text.replaceAll(d, '')))) s,
  ];
  expect(english, isEmpty, reason: 'These labels are still English');
}
