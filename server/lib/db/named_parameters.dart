/// Converts the report's `:name` parameters to PostgreSQL `$n` placeholders.
///
/// The SQL text stays as in the report. This class does not change string
/// literals ('HH24:MI'), quoted names, comments or `::type` casts.
class NamedParameters {
  NamedParameters._(this.sql, this.names);

  /// The SQL text with `$1`, `$2`, ... in place of `:name`.
  final String sql;

  /// The parameter names, in placeholder order. `names[0]` is `$1`.
  final List<String> names;

  static final _cache = <String, NamedParameters>{};

  static NamedParameters parse(String source) =>
      _cache.putIfAbsent(source, () => _parse(source));

  /// Makes the positional value list for [values]. A missing name is an error.
  List<Object?> bind(Map<String, Object?> values) => [
        for (final name in names)
          if (values.containsKey(name))
            values[name]
          else
            throw ArgumentError('No value for SQL parameter :$name'),
      ];

  static NamedParameters _parse(String src) {
    final out = StringBuffer();
    final names = <String>[];
    var i = 0;
    while (i < src.length) {
      final c = src[i];
      final next = i + 1 < src.length ? src[i + 1] : '';
      if (c == "'") {
        final escapes = i > 0 && (src[i - 1] == 'E' || src[i - 1] == 'e');
        final end = _endOfQuoted(src, i, "'", backslashEscapes: escapes);
        out.write(src.substring(i, end));
        i = end;
      } else if (c == '"') {
        final end = _endOfQuoted(src, i, '"');
        out.write(src.substring(i, end));
        i = end;
      } else if (c == '-' && next == '-') {
        final end = src.indexOf('\n', i);
        final stop = end < 0 ? src.length : end;
        out.write(src.substring(i, stop));
        i = stop;
      } else if (c == ':' && next == ':') {
        out.write('::');
        i += 2;
      } else if (c == ':' && _isNameStart(next)) {
        var j = i + 1;
        while (j < src.length && _isNamePart(src[j])) {
          j++;
        }
        final name = src.substring(i + 1, j);
        var index = names.indexOf(name);
        if (index < 0) {
          names.add(name);
          index = names.length - 1;
        }
        out.write('\$${index + 1}');
        i = j;
      } else {
        out.write(c);
        i++;
      }
    }
    return NamedParameters._(out.toString(), List.unmodifiable(names));
  }

  /// Returns the index after the closing quote. A doubled quote is an escape.
  static int _endOfQuoted(String s, int start, String q,
      {bool backslashEscapes = false}) {
    var i = start + 1;
    while (i < s.length) {
      if (backslashEscapes && s[i] == r'\') {
        i += 2;
        continue;
      }
      if (s[i] == q) {
        if (i + 1 < s.length && s[i + 1] == q) {
          i += 2;
          continue;
        }
        return i + 1;
      }
      i++;
    }
    return s.length;
  }

  static bool _isNameStart(String c) => RegExp(r'[A-Za-z_]').hasMatch(c);
  static bool _isNamePart(String c) => RegExp(r'[A-Za-z0-9_]').hasMatch(c);
}
