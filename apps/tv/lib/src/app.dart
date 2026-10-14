import 'package:flutter/material.dart';

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
  })  : discovery = discovery ?? const UdpServerDiscovery(),
        api = api ?? TvApi(),
        deviceInfo = deviceInfo ?? const PlatformDeviceInfoSource();

  final ServerDiscovery discovery;
  final TvApi api;
  final DeviceInfoSource deviceInfo;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Beyond TV',
      debugShowCheckedModeBanner: false,
      theme: buildTvTheme(),
      home: Builder(
        builder: (context) => ServerSelectPage(
          discovery: discovery,
          api: api,
          onSelected: (server) => _openPairing(context, server),
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
          onPaired: (_) => navigator.pushAndRemoveUntil(
            MaterialPageRoute<void>(
              builder: (_) => PairedPage(server: server),
            ),
            (_) => false,
          ),
        ),
      ),
    );
  }
}
