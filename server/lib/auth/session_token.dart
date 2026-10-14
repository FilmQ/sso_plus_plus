import 'dart:convert';

import 'package:crypto/crypto.dart';

import 'user_session.dart';

/// A signed login token: `base64url(session JSON) . base64url(HMAC-SHA256)`.
///
/// The server keeps no session table. A token is valid until [lifetime] ends.
class SessionToken {
  SessionToken(String secret, {this.lifetime = const Duration(hours: 12)})
      : _hmac = Hmac(sha256, utf8.encode(secret));

  final Hmac _hmac;
  final Duration lifetime;

  String issue(UserSession session, {DateTime? now}) {
    final expires = (now ?? DateTime.now()).add(lifetime).millisecondsSinceEpoch;
    final payload = base64Url.encode(utf8.encode(jsonEncode({...session.toJson(), 'exp': expires})));
    return '$payload.${_sign(payload)}';
  }

  /// The session of a valid token, else null.
  UserSession? verify(String token, {DateTime? now}) {
    final parts = token.split('.');
    if (parts.length != 2 || _sign(parts[0]) != parts[1]) return null;
    try {
      final json = jsonDecode(utf8.decode(base64Url.decode(parts[0]))) as Map<String, Object?>;
      final expires = json['exp'] as int;
      if ((now ?? DateTime.now()).millisecondsSinceEpoch > expires) return null;
      return UserSession.fromJson(json);
    } on FormatException {
      return null;
    }
  }

  String _sign(String payload) => base64Url.encode(_hmac.convert(utf8.encode(payload)).bytes);
}
