import 'dart:io';

import 'package:shelf/shelf_io.dart' as io;
import 'package:sst_server/app.dart';
import 'package:sst_server/config.dart';

/// Starts the SST API server.
Future<void> main() async {
  final config = Config();
  final db = config.connector();
  await db.connect();
  final app = App(config, db);
  final server = await io.serve(app.handler, InternetAddress.anyIPv4, config.serverPort);
  print('SST server on http://${server.address.host}:${server.port} (${db.url})');
}
