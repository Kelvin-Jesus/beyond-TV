import 'package:flutter/material.dart';

import 'device/credentials.dart';
import 'device/device_info_source.dart';
import 'pages/paired_page.dart';
import 'pages/pairing_page.dart';
import 'pages/server_select_page.dart';
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
  })  : discovery = discovery ?? const UdpServerDiscovery(),
        api = api ?? TvApi(),
        deviceInfo = deviceInfo ?? const PlatformDeviceInfoSource(),
        credentials = credentials ?? const SecureCredentialStore();

  final ServerDiscovery discovery;
  final TvApi api;
  final DeviceInfoSource deviceInfo;
  final CredentialStore credentials;

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
                builder: (_) => PairedPage(server: saved.server),
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
          final saved? => PairedPage(server: saved.server),
          null => widget.app._serverSelect(),
        };
      },
    );
  }
}
