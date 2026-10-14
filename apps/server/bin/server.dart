import 'dart:io';

import 'package:beyond_server/server.dart';
import 'package:path/path.dart' as p;
import 'package:shelf/shelf_io.dart' as shelf_io;

Future<void> main(List<String> args) async {
  final ServerConfig config;
  try {
    final parsed = ServerConfig.parse(args, environment: Platform.environment);
    if (parsed == null) {
      stdout
        ..writeln('Uso: server [opções]\n')
        ..writeln(ServerConfig.usage);
      return;
    }
    config = parsed;
  } on ConfigException catch (e) {
    stderr
      ..writeln(e.message)
      ..writeln()
      ..writeln(ServerConfig.usage);
    exit(64); // EX_USAGE
  }

  await Directory(config.dataDir).create(recursive: true);
  final db = openDatabase(p.join(config.dataDir, databaseFileName));

  final server = await shelf_io.serve(
    buildHandler(),
    InternetAddress.anyIPv4,
    config.port,
  );
  stdout
    ..writeln(
      'Beyond TV $serverVersion ouvindo em http://localhost:${server.port}',
    )
    ..writeln('Dados em ${Directory(config.dataDir).absolute.path}');

  // Encerra de forma limpa com Ctrl+C.
  await ProcessSignal.sigint.watch().first;
  await server.close();
  db.close();
  exit(0);
}
