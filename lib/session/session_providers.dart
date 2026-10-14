import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../api/api_client.dart';
import '../api/api_exception.dart';
import 'user_session.dart';

/// The one API client of the app.
final Provider<ApiClient> apiClientProvider = Provider<ApiClient>((Ref ref) => ApiClient());

/// Which app this is: 'user' or 'console'. The entry point overrides it.
final Provider<String> appKindProvider = Provider<String>((Ref ref) => 'user');

/// The signed-in person, or null. The token is kept on the device.
final AsyncNotifierProvider<SessionNotifier, UserSession?> sessionProvider =
    AsyncNotifierProvider<SessionNotifier, UserSession?>(SessionNotifier.new);

class SessionNotifier extends AsyncNotifier<UserSession?> {
  static const String _tokenKey = 'sst.token';

  ApiClient get _api => ref.read(apiClientProvider);
  String get _storeKey => '$_tokenKey.${ref.read(appKindProvider)}';

  /// Reads the kept token and asks the server if it is still valid.
  @override
  Future<UserSession?> build() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_storeKey);
    if (token == null) return null;
    _api.token = token;
    try {
      final body = await _api.get('/auth/me');
      return UserSession.fromJson(body['session']! as Map<String, Object?>);
    } on ApiException {
      _api.token = null;
      await prefs.remove(_storeKey);
      return null;
    }
  }

  /// Signs in. Throws [ApiException] when the login name or password is wrong.
  Future<void> login(String loginName, String password) async {
    final body = await _api.post('/auth/login', {
      'login_name': loginName,
      'password': password,
      'app': ref.read(appKindProvider),
    });
    await signedIn(body);
  }

  /// Keeps a token and a session from the server (login or U1 registration).
  Future<void> signedIn(Map<String, Object?> body) async {
    final token = body['token']! as String;
    _api.token = token;
    await (await SharedPreferences.getInstance()).setString(_storeKey, token);
    state = AsyncData(UserSession.fromJson(body['session']! as Map<String, Object?>));
  }

  Future<void> logout() async {
    _api.token = null;
    await (await SharedPreferences.getInstance()).remove(_storeKey);
    state = const AsyncData(null);
  }
}
