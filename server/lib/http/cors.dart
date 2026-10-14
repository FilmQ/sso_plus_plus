import 'package:shelf/shelf.dart';

const _headers = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Methods': 'GET, POST, PUT, OPTIONS',
  'Access-Control-Allow-Headers': 'Authorization, Content-Type',
};

/// Lets the Flutter web app (other port) call the server.
Middleware cors() => (inner) => (request) async {
      if (request.method == 'OPTIONS') return Response.ok(null, headers: _headers);
      final response = await inner(request);
      return response.change(headers: _headers);
    };
