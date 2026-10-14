import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

import '../auth/sessions.dart';
import '../http/json.dart';
import '../pairing/pairing_codes.dart';

/// Rotas de pareamento das TVs.
///
/// - `POST /api/v1/pairing-codes` (admin): gera um código.
/// - `GET /api/v1/pairing-codes/<code>` (admin): situação do código, para o
///   dashboard saber quando a TV pareou.
class PairingApi {
  PairingApi({required SessionStore sessions, required PairingCodeStore codes})
    : _sessions = sessions,
      _codes = codes;

  final SessionStore _sessions;
  final PairingCodeStore _codes;

  void addRoutes(Router router) {
    final admin = const Pipeline().addMiddleware(_sessions.requireAdmin());
    router
      ..post('/api/v1/pairing-codes', admin.addHandler(_create))
      ..get('/api/v1/pairing-codes/<code>', admin.addHandler(_status));
  }

  Response _create(Request request) =>
      jsonResponse(_codes.generate().toJson(), status: 201);

  Response _status(Request request) {
    final found = _codes.lookup(request.params['code']!);
    if (found == null) {
      throw const ApiException.notFound('Código não encontrado.');
    }
    final (entry, status) = found;
    return jsonResponse({
      'code': entry.code,
      'expiresAt': entry.expiresAt.toIso8601String(),
      'status': status.name,
      'deviceId': ?entry.deviceId,
    });
  }
}
