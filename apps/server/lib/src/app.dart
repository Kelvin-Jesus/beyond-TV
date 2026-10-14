import 'dart:io';

import 'package:beyond_protocol/beyond_protocol.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:sqlite3/sqlite3.dart';

import 'api/auth_api.dart';
import 'api/setup_api.dart';
import 'auth/admins.dart';
import 'auth/passwords.dart';
import 'auth/sessions.dart';
import 'clock.dart';
import 'http/json.dart';
import 'http/middleware.dart';
import 'http/static_site.dart';

/// Versão do servidor exposta em `/health`.
const serverVersion = '0.1.0';

/// Monta o handler HTTP completo do servidor.
///
/// As rotas da API ficam em `/health`, `/api/` e `/ws/`. O resto é o
/// dashboard, servido de [webDir] quando a pasta existe.
Handler buildHandler({
  required Database db,
  String? webDir,
  PasswordHasher hasher = const PasswordHasher(),
  Clock clock = DateTime.now,
}) {
  final Handler site = switch (webDir) {
    final dir? when Directory(dir).existsSync() => staticSiteHandler(dir),
    final dir? =>
      (request) => request.url.path.isEmpty
          ? dashboardMissing(dir)
          : throw const ApiException.notFound(),
    null => (_) => throw const ApiException.notFound(),
  };

  final router = Router(
    notFoundHandler: (request) => _isApiPath(request.url.path)
        ? throw const ApiException.notFound()
        : site(request),
  )..get('/health', _health);

  final admins = AdminStore(db);
  final sessions = SessionStore(db, clock: clock);
  SetupApi(
    admins: admins,
    sessions: sessions,
    hasher: hasher,
  ).addRoutes(router);
  AuthApi(admins: admins, sessions: sessions, hasher: hasher).addRoutes(router);

  return const Pipeline()
      .addMiddleware(requestLogger())
      .addMiddleware(errorHandler())
      .addHandler(router.call);
}

bool _isApiPath(String path) =>
    path == 'api' ||
    path.startsWith('api/') ||
    path == 'ws' ||
    path.startsWith('ws/');

Response _health(Request request) => jsonResponse({
  'status': 'ok',
  'version': serverVersion,
  'protocol': protocolVersion,
});
