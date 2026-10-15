import 'package:beyond_protocol/beyond_protocol.dart';
import 'package:logging/logging.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

import '../auth/sessions.dart';
import '../devices/devices.dart';
import '../http/json.dart';
import '../logging.dart';
import '../realtime/device_hub.dart';

final _log = Logger('devices');

/// Rotas de TVs (todas de admin).
///
/// - `GET /api/v1/devices`: lista com o estado online.
/// - `PATCH /api/v1/devices/<id>`: renomeia.
/// - `DELETE /api/v1/devices/<id>`: remove e derruba o WebSocket da TV.
class DevicesApi {
  DevicesApi({
    required SessionStore sessions,
    required DeviceStore devices,
    required DeviceHub hub,
  }) : _sessions = sessions,
       _devices = devices,
       _hub = hub;

  final SessionStore _sessions;
  final DeviceStore _devices;
  final DeviceHub _hub;

  void addRoutes(Router router) {
    final admin = const Pipeline().addMiddleware(_sessions.requireAdmin());
    router
      ..get('/api/v1/devices', admin.addHandler(_list))
      ..patch('/api/v1/devices/<id>', admin.addHandler(_rename))
      ..delete('/api/v1/devices/<id>', admin.addHandler(_delete));
  }

  Response _list(Request request) => jsonResponse({
    'devices': [for (final s in _hub.summaries()) s.toJson()],
  });

  Future<Response> _rename(Request request) async {
    final id = request.params['id']!;
    final body = await readJsonObject(request);
    final name = requireString(body, 'name').trim();
    if (name.runes.isEmpty || name.runes.length > 64) {
      throw const ApiException.badRequest(
        'O nome deve ter de 1 a 64 caracteres.',
      );
    }
    if (!_devices.rename(id, name)) throw _notFound;
    final summary = _hub.summaryOf(_devices.find(id)!);
    _hub.publish(MessageTypes.deviceState, summary.toJson());
    return jsonResponse(summary.toJson());
  }

  Response _delete(Request request) {
    final id = request.params['id']!;
    if (!_devices.delete(id)) throw _notFound;
    _hub.disconnect(id, WsCloseCodes.unauthorized);
    _hub.publish(MessageTypes.deviceRemoved, {'deviceId': id});
    _log.info(LogEvent('TV removida', {'deviceId': id}));
    return Response(204);
  }

  static const _notFound = ApiException.notFound('TV não encontrada.');
}
