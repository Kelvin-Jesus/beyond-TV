import 'dart:convert';

import 'package:beyond_tv/src/server/discovery.dart';
import 'package:beyond_tv/src/server/server_address.dart';
import 'package:beyond_tv/src/server/tv_api.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

/// Descoberta que devolve uma lista fixa.
class FakeDiscovery implements ServerDiscovery {
  FakeDiscovery([this.servers = const []]);

  List<ServerAddress> servers;
  int calls = 0;

  @override
  Future<List<ServerAddress>> discover() async {
    calls++;
    return servers;
  }
}

/// Servidor HTTP falso: responde `/health` nos [onlineHosts].
///
/// [routes] permite responder outras rotas (`'POST /api/v1/pair'`).
TvApi fakeApi({
  Set<String> onlineHosts = const {'192.168.0.10'},
  Map<String, http.Response Function(http.Request request)> routes = const {},
}) =>
    TvApi(
      client: MockClient((request) async {
        if (!onlineHosts.contains(request.url.host)) {
          throw http.ClientException('conexão recusada', request.url);
        }
        final route = routes['${request.method} ${request.url.path}'];
        if (route != null) return route(request);
        if (request.url.path == '/health') {
          return http.Response(jsonEncode({'status': 'ok'}), 200);
        }
        return http.Response(
          jsonEncode({
            'error': {'code': 'not_found', 'message': 'Não encontrado.'},
          }),
          404,
        );
      }),
    );

const pcSala = ServerAddress(
  host: '192.168.0.10',
  name: 'PC-SALA',
  serverId: 'abc',
);
