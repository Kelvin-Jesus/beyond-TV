import 'package:flutter/material.dart';

import 'pages/server_select_page.dart';
import 'server/discovery.dart';
import 'server/server_address.dart';
import 'server/tv_api.dart';
import 'theme.dart';
import 'widgets/tv_page.dart';

class TvApp extends StatelessWidget {
  TvApp({super.key, ServerDiscovery? discovery, TvApi? api})
      : discovery = discovery ?? const UdpServerDiscovery(),
        api = api ?? TvApi();

  final ServerDiscovery discovery;
  final TvApi api;

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
          onSelected: (server) => Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => _SelectedServerPage(server),
            ),
          ),
        ),
      ),
    );
  }
}

/// Provisória: a tela de pareamento chega no próximo passo.
class _SelectedServerPage extends StatelessWidget {
  const _SelectedServerPage(this.server);

  final ServerAddress server;

  @override
  Widget build(BuildContext context) {
    return TvPage(
      title: 'Servidor selecionado',
      subtitle: '${server.name ?? 'Servidor'} · ${server.hostPort}',
      children: const [],
    );
  }
}
