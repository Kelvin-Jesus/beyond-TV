import 'dart:convert';
import 'dart:io';

import 'package:beyond_server/server.dart';
import 'package:http/http.dart' as http;
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:sqlite3/sqlite3.dart';
import 'package:test/test.dart';

/// bcrypt com o custo mínimo, para os testes não demorarem.
const fastHasher = PasswordHasher(cost: 4);

/// Servidor real numa porta efêmera com banco em memória.
///
/// É encerrado automaticamente no fim do teste.
class TestServer {
  TestServer._(this.db, this._server);

  static Future<TestServer> start({
    Handler Function(Database db)? handler,
  }) async {
    final db = openDatabase();
    final server = await shelf_io.serve(
      handler?.call(db) ?? buildHandler(db: db, hasher: fastHasher),
      InternetAddress.loopbackIPv4,
      0,
    );
    final testServer = TestServer._(db, server);
    addTearDown(testServer.close);
    return testServer;
  }

  final Database db;
  final HttpServer _server;

  Uri uri(String path) =>
      Uri.parse('http://${_server.address.host}:${_server.port}$path');

  Future<http.Response> get(String path, {Map<String, String>? headers}) =>
      http.get(uri(path), headers: headers);

  Future<http.Response> post(
    String path, {
    Object? json,
    Map<String, String>? headers,
  }) => http.post(
    uri(path),
    headers: {'content-type': 'application/json', ...?headers},
    body: json == null ? null : jsonEncode(json),
  );

  Future<void> close() async {
    await _server.close(force: true);
    db.close();
  }
}

/// Corpo JSON de [response].
Object? jsonBody(http.Response response) => jsonDecode(response.body);

/// Código de erro (`error.code`) de [response].
Object? errorCode(http.Response response) =>
    (jsonBody(response)! as Map)['error']['code'];
