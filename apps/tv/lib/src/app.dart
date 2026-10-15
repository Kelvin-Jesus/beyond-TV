import 'package:flutter/material.dart';

import 'device/credentials.dart';
import 'device/device_info_source.dart';
import 'content/content_controller.dart';
import 'content/manifest_store.dart';
import 'pages/player_page.dart';
import 'player/web_player.dart';
import 'pages/pairing_page.dart';
import 'pages/server_select_page.dart';
import 'realtime/backoff.dart';
import 'realtime/device_connection.dart';
import 'realtime/socket_connector.dart';
import 'server/discovery.dart';
import 'server/server_address.dart';
import 'server/tv_api.dart';
import 'theme.dart';

class TvApp extends StatelessWidget {
  TvApp({
    super.key,
    ServerDiscovery? discovery,
    TvApi? api,
    DeviceInfoSource? deviceInfo,
    CredentialStore? credentials,
    SocketConnector? connector,
    this.backoffFactory,
    ManifestStore? manifestStore,
    WebPlayerBuilder? webPlayer,
  })  : discovery = discovery ?? const UdpServerDiscovery(),
        api = api ?? TvApi(),
        deviceInfo = deviceInfo ?? const PlatformDeviceInfoSource(),
        credentials = credentials ?? const SecureCredentialStore(),
        connector = connector ?? ioConnector,
        manifestStore = manifestStore ?? FileManifestStore(),
        webPlayer = webPlayer ?? defaultWebPlayer;

  final ServerDiscovery discovery;
  final TvApi api;
  final DeviceInfoSource deviceInfo;
  final CredentialStore credentials;
  final SocketConnector connector;
  final ManifestStore manifestStore;
  final WebPlayerBuilder webPlayer;

  /// Cria o backoff de cada conexão; os testes usam esperas curtas.
  final Backoff Function()? backoffFactory;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Beyond TV',
      debugShowCheckedModeBanner: false,
      theme: buildTvTheme(),
      home: _StartupPage(app: this),
    );
  }

  Widget _serverSelect() => Builder(
        builder: (context) => ServerSelectPage(
          discovery: discovery,
          api: api,
          onSelected: (server) => _openPairing(context, server),
        ),
      );

  Widget _paired(Credentials saved) {
    late final ContentController content;
    final connection = DeviceConnection(
      credentials: saved,
      deviceInfo: deviceInfo,
      store: credentials,
      discovery: discovery,
      connector: connector,
      backoff: backoffFactory?.call(),
      currentItem: () => content.currentUrl,
    );
    content = ContentController(
      store: manifestStore,
      connection: connection,
      credentials: credentials,
    );
    return PlayerPage(
      content: content,
      connection: connection,
      webPlayer: webPlayer,
      onUnauthorized: _backToPairing,
    );
  }

  /// A TV foi removida no painel: volta à seleção de servidor.
  void _backToPairing(BuildContext context) {
    final messenger = ScaffoldMessenger.of(context);
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute<void>(builder: (_) => _serverSelect()),
      (_) => false,
    );
    messenger.showSnackBar(
      const SnackBar(
        content: Text(
          'Esta TV foi removida do painel. Pareie de novo.',
          style: TextStyle(fontSize: 24),
        ),
      ),
    );
  }

  void _openPairing(BuildContext context, ServerAddress server) {
    final navigator = Navigator.of(context);
    navigator.push(
      MaterialPageRoute<void>(
        builder: (_) => PairingPage(
          server: server,
          api: api,
          deviceInfo: deviceInfo,
          onChangeServer: navigator.pop,
          onPaired: (pair) async {
            final saved = Credentials.fromPairing(server, pair);
            await credentials.save(saved);
            navigator.pushAndRemoveUntil(
              MaterialPageRoute<void>(
                builder: (_) => _paired(saved),
              ),
              (_) => false,
            );
          },
        ),
      ),
    );
  }
}

/// Splash: decide entre o pareamento e a TV já pareada.
class _StartupPage extends StatefulWidget {
  const _StartupPage({required this.app});

  final TvApp app;

  @override
  State<_StartupPage> createState() => _StartupPageState();
}

class _StartupPageState extends State<_StartupPage> {
  late final Future<Credentials?> _saved = _load();

  /// Guardada para um rebuild não abrir outra conexão.
  Widget? _page;

  Future<Credentials?> _load() async {
    try {
      return await widget.app.credentials.load();
    } on Exception {
      // Armazenamento indisponível: melhor parear de novo do que travar.
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _saved,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(
            body: Center(
              child: Icon(Icons.tv, size: 96, color: brandAccent),
            ),
          );
        }
        return switch (snapshot.data) {
          final saved? => _page ??= widget.app._paired(saved),
          null => widget.app._serverSelect(),
        };
      },
    );
  }
}
