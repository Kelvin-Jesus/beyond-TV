import 'package:beyond_protocol/beyond_protocol.dart';

import '../devices/devices.dart';
import '../media/media_store.dart';
import 'device_hub.dart';

/// Monta e envia o `content.sync` das TVs.
class ContentSync {
  ContentSync({
    required DeviceStore devices,
    required MediaStore media,
    required DeviceHub hub,
  }) : _devices = devices,
       _media = media,
       _hub = hub;

  final DeviceStore _devices;
  final MediaStore _media;
  final DeviceHub _hub;

  /// O que a TV [deviceId] deve exibir; vazio se não há conteúdo.
  ContentManifest manifestFor(String deviceId) {
    final mediaId = _devices.find(deviceId)?.mediaId;
    final media = mediaId == null ? null : _media.find(mediaId);
    return media == null
        ? ContentManifest.empty
        : ContentManifest(items: [media.toContentItem()]);
  }

  /// Manda o manifesto atual à TV, se ela estiver online.
  void syncDevice(String deviceId) {
    _hub.send(
      deviceId,
      Envelope.create(
        MessageTypes.contentSync,
        payload: manifestFor(deviceId).toJson(),
      ),
    );
  }
}
