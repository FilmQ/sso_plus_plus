/// An error from the server, or no connection to it (status 0).
class ApiException implements Exception {
  const ApiException(this.status, this.message, [this.body = const {}]);

  final int status;
  final String message;
  final Map<String, Object?> body;

  @override
  String toString() => message;
}
