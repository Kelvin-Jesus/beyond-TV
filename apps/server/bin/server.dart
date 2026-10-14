import 'dart:io';

import 'package:beyond_server/server.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;

Future<void> main() async {
  final server = await shelf_io.serve(
    buildHandler(),
    InternetAddress.anyIPv4,
    defaultHttpPort,
  );
  stdout.writeln(
    'Beyond TV $serverVersion ouvindo em http://localhost:${server.port}',
  );

  // Encerra de forma limpa com Ctrl+C.
  await ProcessSignal.sigint.watch().first;
  await server.close();
  exit(0);
}
