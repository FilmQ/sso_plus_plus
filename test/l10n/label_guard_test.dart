import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sso_plus_plus/l10n/th_console.dart';
import 'package:sso_plus_plus/l10n/th_server.dart';
import 'package:sso_plus_plus/l10n/th_user.dart';

/// The labels that stay as they are: the language toggle names each language in that language.
const Map<String, Set<String>> _allowed = <String, Set<String>>{
  'lib/widgets/language_toggle.dart': <String>{'EN', 'ไทย', 'English', 'ภาษาไทย'},
};

/// The places where Flutter shows a text as it is.
final RegExp _rawPlace = RegExp(r'\bText\(|\b(tooltip|labelText|hintText|helperText):');

final RegExp _trCall = RegExp(r'\btr\(');

final RegExp _letter = RegExp(r'[A-Za-z฀-๿]');

/// One Dart string literal at [i]: the text without its interpolations, whether it had one, and the end.
(String, bool, int)? _literal(String src, int i) {
  final bool raw = src.startsWith('r', i);
  final int start = raw ? i + 1 : i;
  if (start >= src.length || (src[start] != "'" && src[start] != '"')) return null;
  final String quote = src[start];
  final StringBuffer text = StringBuffer();
  bool interpolated = false;
  int j = start + 1;
  while (j < src.length && src[j] != quote) {
    if (src[j] == r'\' && !raw) {
      text.write(src[j + 1]);
      j += 2;
    } else if (src[j] == r'$' && !raw) {
      interpolated = true;
      j = src.startsWith(r'${', j) ? _interpolationEnd(src, j + 2) : _identifierEnd(src, j + 1);
    } else {
      text.write(src[j++]);
    }
  }
  return (text.toString(), interpolated, j + 1);
}

int _identifierEnd(String src, int j) {
  while (j < src.length && RegExp(r'\w').hasMatch(src[j])) {
    j++;
  }
  return j;
}

/// The index after the '}' that closes the interpolation at [j]. Nested brackets and string
/// literals are skipped.
int _interpolationEnd(String src, int j) {
  int depth = 0;
  while (j < src.length) {
    final String c = src[j];
    if (c == "'" || c == '"') {
      j = _literal(src, j)!.$3;
      continue;
    }
    if (depth == 0 && c == '}') return j + 1;
    if ('([{'.contains(c)) depth++;
    if (')]}'.contains(c)) depth--;
    j++;
  }
  return j;
}

/// The string literals at the top level of the argument at [j] (up to ',' or ')'), with adjacent
/// literals joined: (text, interpolated).
List<(String, bool)> _topLiterals(String src, int j) {
  final List<(String, bool)> out = <(String, bool)>[];
  int depth = 0;
  while (j < src.length) {
    final String c = src[j];
    if (depth == 0 && (c == "'" || c == '"' || (c == 'r' && j + 1 < src.length && "'\"".contains(src[j + 1])))) {
      String text = '';
      bool interpolated = false;
      (String, bool, int)? lit;
      while ((lit = _literal(src, j)) != null) {
        text += lit!.$1;
        interpolated |= lit.$2;
        j = lit.$3;
        while (j < src.length && src[j].trim().isEmpty) {
          j++;
        }
      }
      out.add((text, interpolated));
      continue;
    }
    if (depth == 0 && (c == ',' || c == ')')) return out;
    if ('([{'.contains(c)) depth++;
    if (')]}'.contains(c)) {
      if (depth == 0) return out;
      depth--;
    }
    j++;
  }
  return out;
}

List<File> _sources() => Directory('lib')
    .listSync(recursive: true)
    .whereType<File>()
    .where((File f) => f.path.endsWith('.dart'))
    .where((File f) => !f.path.startsWith('lib/legacy/') && !f.path.startsWith('lib/l10n/'))
    .toList();

String _place(String path, String src, int at) => '$path:${'\n'.allMatches(src.substring(0, at)).length + 1}';

void main() {
  test('No label shows as it is: each one goes through tr', () {
    expect(_sources().length, greaterThan(50), reason: 'run the test from the project folder');
    final List<String> raw = <String>[
      for (final File f in _sources())
        for (final RegExpMatch m in _rawPlace.allMatches(f.readAsStringSync()))
          for (final (String text, bool _) in _topLiterals(f.readAsStringSync(), m.end))
            if (_letter.hasMatch(text) && !(_allowed[f.path]?.contains(text) ?? false))
              '${_place(f.path, f.readAsStringSync(), m.start)}: $text',
    ];
    expect(raw, isEmpty, reason: 'Wrap these labels in context.tr');
  });

  test('Each tr key has a Thai entry', () {
    final Set<String> keys = <String>{...thUser.keys, ...thServer.keys, ...thConsole.keys, ...thServerTemplates.keys};
    final List<String> missing = <String>[
      for (final File f in _sources())
        for (final RegExpMatch m in _trCall.allMatches(f.readAsStringSync()))
          for (final (String text, bool interpolated) in _topLiterals(f.readAsStringSync(), m.end))
            if (!interpolated && _letter.hasMatch(text) && !keys.contains(text))
              '${_place(f.path, f.readAsStringSync(), m.start)}: $text',
    ];
    expect(missing, isEmpty, reason: 'Add these keys to a table in lib/l10n');
  });

  test('The reader finds the literals of an argument', () {
    expect(_topLiterals("x ? 'A' : 'B')", 0), <(String, bool)>[('A', false), ('B', false)]);
    expect(_topLiterals("'one ' \"two\", 3)", 0), <(String, bool)>[('one two', false)]);
    expect(_topLiterals(r"'${r['k']} files')", 0), <(String, bool)>[(' files', true)]);
    expect(_topLiterals("s(row, 'injury'))", 0), isEmpty);
    expect(_topLiterals(r"'officer\'s')", 0), <(String, bool)>[("officer's", false)]);
  });
}
