import 'package:beyond_protocol/beyond_protocol.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

import 'http/json.dart';
import 'http/middleware.dart';

/// Versão do servidor exposta em `/health`.
const serverVersion = '0.1.0';

/// Monta o handler HTTP completo do servidor.
Handler buildHandler() {
  final router = Router(notFoundHandler: _notFound)..get('/health', _health);

  return const Pipeline()
      .addMiddleware(requestLogger())
      .addMiddleware(errorHandler())
      .addHandler(router.call);
}

Response _health(Request request) => jsonResponse({
  'status': 'ok',
  'version': serverVersion,
  'protocol': protocolVersion,
});

Response _notFound(Request request) => throw const ApiException.notFound();
