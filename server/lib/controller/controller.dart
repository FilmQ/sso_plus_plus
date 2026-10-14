import '../auth/user_session.dart';

/// Base class of all controllers (SA report 2.18, class Controller).
///
/// A controller is made for one request, with the session of that request.
abstract class Controller {
  Controller(this.session);

  final UserSession? session;

  /// True when the request has a session with [role].
  bool authorize(String role) => session?.role == role;

  /// Stops the request when the session does not have [role].
  UserSession requireRole(String role) {
    final s = session;
    if (s == null || s.role != role) throw const NotAuthorizedException();
    return s;
  }

  /// Changes a lower-level error into a [ControllerException] for the page.
  Never handleError(Object e) {
    if (e is ControllerException) throw e;
    throw ControllerException(500, 'The request failed. Try again later.', cause: e);
  }
}

/// An error that the HTTP layer sends to the page.
class ControllerException implements Exception {
  const ControllerException(this.status, this.message, {this.details, this.cause});

  final int status;
  final String message;
  final Map<String, Object?>? details;
  final Object? cause;

  @override
  String toString() => 'ControllerException($status): $message${cause == null ? '' : ' ($cause)'}';
}

class NotAuthorizedException extends ControllerException {
  const NotAuthorizedException() : super(401, 'Sign in to continue.');
}
