import 'dart:convert';

import 'package:beyond_protocol/beyond_protocol.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

/// Versão do servidor exposta em `/health`.
const serverVersion = '0.1.0';

/// Porta HTTP padrão (dashboard, API, mídia e WebSocket).
const defaultHttpPort = 8787;

/// Monta o handler HTTP completo do servidor.
Handler buildHandler() {
  final router = Router()..get('/health', _health);

  return const Pipeline().addMiddleware(logRequests()).addHandler(router.call);
}

Response _health(Request request) => _json({
      'status': 'ok',
      'version': serverVersion,
      'protocol': protocolVersion,
    });

Response _json(Object body, {int status = 200}) => Response(
      status,
      body: jsonEncode(body),
      headers: {'content-type': 'application/json; charset=utf-8'},
    );
