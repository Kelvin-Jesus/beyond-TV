import 'dart:async';

import 'package:beyond_protocol/beyond_protocol.dart';
import 'package:flutter/foundation.dart';

import '../device/credentials.dart';
import '../player/web_player.dart';
import '../realtime/device_connection.dart';
import 'manifest_store.dart';

/// Guarda o que a TV exibe e executa as mensagens do servidor:
/// `content.sync`, `cmd.reload`, `cmd.identify` e `cmd.unpair`.
/// Toda mensagem tratada recebe `ack`.
class ContentController extends ChangeNotifier {
  ContentController({
    required this.store,
    required this.connection,
    this.credentials,
  });

  final ManifestStore store;
  final DeviceConnection connection;

  /// Apagadas no `cmd.unpair`.
  final CredentialStore? credentials;

  ContentManifest _manifest = ContentManifest.empty;
  StreamSubscription<Envelope>? _subscription;
  WebPlayerController? _player;
  Timer? _identifyTimer;
  String? _identifyName;
  bool _synced = false;
  bool _wasUnauthorized = false;
  bool _disposed = false;

  ContentManifest get manifest => _manifest;

  /// Nome do overlay de identificação, enquanto estiver visível.
  String? get identifyName => _identifyName;

  /// URL do primeiro item `url`, ou `null` sem conteúdo.
  String? get currentUrl {
    for (final item in _manifest.items) {
      if (item.kind == MediaKinds.url && item.url != null) return item.url;
    }
    return null;
  }

  /// Controle do player aberto; `null` no estado vazio.
  set player(WebPlayerController? value) => _player = value;

  /// Carrega o manifesto salvo e passa a ouvir o servidor.
  Future<void> start() async {
    _subscription ??= connection.messages.listen(_onMessage);
    connection.addListener(_onConnectionChanged);
    final saved = await store.load();
    // Um sync que chegou durante a leitura é mais novo que o disco.
    if (saved != null && !_synced && !_disposed) {
      _manifest = saved;
      notifyListeners();
    }
  }

  void _onConnectionChanged() {
    final unauthorized = connection.status == ConnectionStatus.unauthorized;
    if (unauthorized && !_wasUnauthorized) {
      // 4401: a TV não pertence mais ao servidor.
      unawaited(_clearManifest());
    }
    _wasUnauthorized = unauthorized;
  }

  Future<void> _clearManifest() async {
    try {
      await store.clear();
    } on Object catch (e) {
      debugPrint('Falha ao apagar o manifesto: $e');
    }
  }

  void _onMessage(Envelope envelope) {
    switch (envelope.type) {
      case MessageTypes.contentSync:
        _onSync(envelope);
      case MessageTypes.cmdReload:
        _ack(envelope);
        unawaited(_player?.reload());
      case MessageTypes.cmdIdentify:
        _onIdentify(envelope);
      case MessageTypes.cmdUnpair:
        unawaited(_onUnpair(envelope));
    }
  }

  void _onSync(Envelope envelope) {
    final ContentManifest incoming;
    try {
      incoming = ContentManifest.fromJson(envelope.payload);
    } on ProtocolException catch (e) {
      debugPrint('content.sync inválido: $e');
      return;
    }
    _synced = true;
    if (incoming.revision != _manifest.revision) {
      // Defesa extra: o servidor já valida, mas a TV não confia.
      final safe = ContentManifest(
        items: [
          for (final item in incoming.items)
            if (item.kind != MediaKinds.url ||
                (item.url != null && isSafeContentUrl(item.url!)))
              item,
        ],
      );
      _manifest = safe;
      notifyListeners();
      unawaited(_save(safe));
    }
    _ack(envelope);
  }

  Future<void> _save(ContentManifest manifest) async {
    try {
      await store.save(manifest);
    } on Object catch (e) {
      debugPrint('Falha ao salvar o manifesto: $e');
    }
  }

  void _onIdentify(Envelope envelope) {
    _ack(envelope);
    final IdentifyPayload payload;
    try {
      payload = IdentifyPayload.fromJson(envelope.payload);
    } on ProtocolException catch (e) {
      debugPrint('cmd.identify inválido: $e');
      return;
    }
    _identifyTimer?.cancel();
    _identifyName = payload.name;
    notifyListeners();
    _identifyTimer = Timer(Duration(seconds: payload.durationSeconds), () {
      _identifyName = null;
      if (!_disposed) notifyListeners();
    });
  }

  Future<void> _onUnpair(Envelope envelope) async {
    _ack(envelope);
    try {
      await credentials?.clear();
    } on Object catch (e) {
      debugPrint('Falha ao apagar as credenciais: $e');
    }
    await _clearManifest();
    // Sai agora, sem esperar o 4401 que o servidor manda em seguida.
    connection.markUnauthorized();
  }

  void _ack(Envelope envelope) => connection.send(
        Envelope.create(
          MessageTypes.ack,
          payload: AckPayload(ref: envelope.id).toJson(),
        ),
      );

  @override
  void dispose() {
    _disposed = true;
    _identifyTimer?.cancel();
    unawaited(_subscription?.cancel());
    connection.removeListener(_onConnectionChanged);
    super.dispose();
  }
}
