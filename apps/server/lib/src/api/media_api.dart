import 'package:beyond_protocol/beyond_protocol.dart';
import 'package:logging/logging.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

import '../auth/sessions.dart';
import '../devices/devices.dart';
import '../http/json.dart';
import '../logging.dart';
import '../media/media_store.dart';
import '../media/media_validation.dart';
import '../realtime/content_sync.dart';
import '../realtime/device_hub.dart';

final _log = Logger('media');

/// Rotas da biblioteca de mídia (todas de admin).
///
/// - `GET /api/v1/media`: lista.
/// - `POST /api/v1/media`: cadastra um site.
/// - `PATCH /api/v1/media/<id>`: altera nome e/ou URL e atualiza as TVs.
/// - `DELETE /api/v1/media/<id>`: apaga e esvazia as TVs que a exibiam.
class MediaApi {
  MediaApi({
    required SessionStore sessions,
    required MediaStore media,
    required DeviceStore devices,
    required DeviceHub hub,
    required ContentSync sync,
  }) : _sessions = sessions,
       _media = media,
       _devices = devices,
       _hub = hub,
       _sync = sync;

  final SessionStore _sessions;
  final MediaStore _media;
  final DeviceStore _devices;
  final DeviceHub _hub;
  final ContentSync _sync;

  void addRoutes(Router router) {
    final admin = const Pipeline().addMiddleware(_sessions.requireAdmin());
    router
      ..get('/api/v1/media', admin.addHandler(_list))
      ..post('/api/v1/media', admin.addHandler(_create))
      ..patch('/api/v1/media/<id>', admin.addHandler(_update))
      ..delete('/api/v1/media/<id>', admin.addHandler(_delete));
  }

  Response _list(Request request) => jsonResponse({
    'media': [for (final m in _media.list()) m.toJson()],
  });

  Future<Response> _create(Request request) async {
    final body = await readJsonObject(request);
    if (body['kind'] != MediaKinds.url) {
      throw const ApiException.badRequest(
        'Por enquanto só sites (kind = url).',
      );
    }
    final url = validateUrl(body['url']);
    final name = body['name'] == null ? null : validateMediaName(body['name']);
    final media = _media.createUrl(url: url, name: name);
    _log.info(LogEvent('mídia criada', {'mediaId': media.id}));
    return jsonResponse(media.toJson(), status: 201);
  }

  Future<Response> _update(Request request) async {
    final id = request.params['id']!;
    final body = await readJsonObject(request);
    if (_media.find(id) == null) throw _notFound;
    final name = body['name'] == null ? null : validateMediaName(body['name']);
    final url = body['url'] == null ? null : validateUrl(body['url']);
    final media = _media.update(id, name: name, url: url)!;
    _refresh(_devices.devicesShowing(id));
    return jsonResponse(media.toJson());
  }

  Response _delete(Request request) {
    final id = request.params['id']!;
    final showing = _devices.devicesShowing(id);
    if (!_media.delete(id)) throw _notFound;
    _refresh(showing);
    _log.info(LogEvent('mídia removida', {'mediaId': id}));
    return Response(204);
  }

  void _refresh(List<String> deviceIds) {
    for (final deviceId in deviceIds) {
      _sync.syncDevice(deviceId);
      final row = _devices.find(deviceId);
      if (row != null) {
        _hub.publish(MessageTypes.deviceState, _hub.summaryOf(row).toJson());
      }
    }
  }

  static const _notFound = ApiException.notFound('Mídia não encontrada.');
}
