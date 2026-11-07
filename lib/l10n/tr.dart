import 'package:flutter/widgets.dart';

import 'en_from_thai.dart';
import 'th_console.dart';
import 'th_dates.dart';
import 'th_server.dart';
import 'th_user.dart';

const Map<String, String> _thai = <String, String>{...thUser, ...thServer, ...thConsole};

final RegExp _placeholder = RegExp(r'\{(\w+)\}');

/// Each server template as a pattern, the placeholder names in order, and the Thai template.
final List<(RegExp, List<String>, String)> _templates = <(RegExp, List<String>, String)>[
  for (final MapEntry<String, String> e in thServerTemplates.entries)
    (
      RegExp(
        '^${e.key.splitMapJoin(_placeholder, onMatch: (_) => '(.+?)', onNonMatch: RegExp.escape)}\$',
        dotAll: true,
      ),
      <String>[for (final Match m in _placeholder.allMatches(e.key)) m[1]!],
      e.value,
    ),
];

/// A full text from the server (for example a stored message), through the template that it matches.
String? _fromTemplate(String text) {
  for (final (RegExp pattern, List<String> names, String thai) in _templates) {
    final RegExpMatch? match = pattern.firstMatch(text);
    if (match != null) {
      return thai.replaceAllMapped(_placeholder, (Match m) => translate('th', match[names.indexOf(m[1]!) + 1]!));
    }
  }
  return null;
}

/// Gives [text] in [language]. The English text is the key. A text with no
/// entry stays as it is, so data such as a name is safe here.
/// Each `{name}` in the text takes its value from [args].
String translate(String language, String text, [Map<String, Object?> args = const <String, Object?>{}]) {
  final bool thai = language == 'th';
  final String template = thai ? (_thai[text] ?? _fromTemplate(text) ?? text) : (enFromThai[text] ?? text);
  final String result = args.isEmpty
      ? template
      : template.replaceAllMapped(_placeholder, (Match m) {
          return args.containsKey(m[1]) ? translate(language, '${args[m[1]]}') : m[0]!;
        });
  return thai ? thaiDates(result) : result;
}

/// The text in the language of the app. The widget rebuilds when the language
/// changes.
extension Tr on BuildContext {
  String tr(String text, [Map<String, Object?> args = const <String, Object?>{}]) =>
      translate(Localizations.localeOf(this).languageCode, text, args);

  /// [tr] for a text that can be null, such as a field error.
  String? trMaybe(String? text) => text == null ? null : tr(text);
}
