import 'package:shelf/shelf.dart';

import '../auth/session_token.dart';
import '../auth/user_session.dart';
import '../controller/controller.dart';
import 'json.dart';

const _sessionKey = 'sst.session';

/// Reads `Authorization: Bearer <token>` and puts the session on the request.
Middleware sessionMiddleware(SessionToken tokens) => (inner) => (request) {
      final header = request.headers['authorization'] ?? '';
      final session = header.startsWith('Bearer ') ? tokens.verify(header.substring(7)) : null;
      return inner(request.change(context: {_sessionKey: session}));
    };

/// The session of the request, or null when the user is not signed in.
UserSession? sessionOf(Request request) => request.context[_sessionKey] as UserSession?;

/// Sends a [ControllerException] as JSON with its HTTP status.
Middleware errorMiddleware() => (inner) => (request) async {
      try {
        return await inner(request);
      } on ControllerException catch (e) {
        if (e.cause != null) print('ERROR ${request.method} ${request.url}: ${e.cause}');
        return jsonError(e.status, e.message, extra: e.details);
      } on FormatException catch (e) {
        return jsonError(400, 'The request is not correct: ${e.message}');
      }
    };
