import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:shelf/shelf.dart';
import 'package:shelf_static/shelf_static.dart';

/// Serve o build do dashboard (Flutter Web) que está em [webDir].
///
/// Caminhos sem extensão que não existem no disco (ex.: `/tvs/123`) recebem o
/// `index.html`, para que o roteamento do dashboard funcione ao recarregar a
/// página. As respostas usam `Cache-Control: no-cache`: o navegador revalida
/// a cada acesso e recebe `304` se nada mudou, então uma atualização do
/// dashboard aparece sem precisar limpar o cache.
Handler staticSiteHandler(String webDir) {
  final files = createStaticHandler(webDir, defaultDocument: 'index.html');
  final index = File(p.join(webDir, 'index.html'));

  return (request) async {
    var response = await files(request);
    if (response.statusCode == 404 && _isPageNavigation(request)) {
      response = Response.ok(
        index.openRead(),
        headers: {'content-type': 'text/html; charset=utf-8'},
      );
    }
    return response.change(
      headers: {
        'cache-control': 'no-cache',
        'x-content-type-options': 'nosniff',
      },
    );
  };
}

/// Resposta para quando o dashboard ainda não foi compilado.
Response dashboardMissing(String webDir) => Response(
  503,
  body:
      'O dashboard ainda não foi compilado.\n\n'
      'Rode "flutter build web" em apps/dashboard ou indique a pasta do build '
      'com --web-dir. Pasta procurada: ${p.absolute(webDir)}\n',
  headers: {'content-type': 'text/plain; charset=utf-8'},
);

bool _isPageNavigation(Request request) =>
    (request.method == 'GET' || request.method == 'HEAD') &&
    p.url.extension(request.url.path).isEmpty;
