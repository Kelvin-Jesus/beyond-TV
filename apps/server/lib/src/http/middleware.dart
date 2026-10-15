import 'package:logging/logging.dart';
import 'package:shelf/shelf.dart';

import '../logging.dart';
import 'json.dart';

final _log = Logger('http');

/// Registra cada requisição com método, caminho, status e duração.
///
/// Sucesso sai em `debug`, erro do cliente (4xx) em `info` e erro do servidor
/// (5xx) em `warning`.
///
/// A *query string* fica de fora porque pode carregar tokens.
Middleware requestLogger() =>
    (inner) => (request) async {
      final watch = Stopwatch()..start();
      final response = await inner(request);
      final status = response.statusCode;
      _log.log(
        switch (status) {
          >= 500 => Level.WARNING,
          >= 400 => Level.INFO,
          _ => Level.FINE,
        },
        LogEvent('requisição', {
          'method': request.method,
          'path': request.requestedUri.path,
          'status': status,
          'ms': watch.elapsedMilliseconds,
        }),
      );
      return response;
    };

/// Transforma exceções em respostas JSON.
///
/// [ApiException] vira a resposta que ela descreve. Qualquer outro erro é
/// registrado com o stack trace e vira um `500` genérico, sem vazar detalhes
/// internos para o cliente.
Middleware errorHandler() =>
    (inner) => (request) async {
      try {
        return await inner(request);
      } on HijackException {
        // Usada pelo shelf para entregar o socket ao WebSocket.
        rethrow;
      } on ApiException catch (e) {
        return e.toResponse();
      } on Object catch (e, stackTrace) {
        _log.severe(
          LogEvent('erro não tratado', {
            'method': request.method,
            'path': request.requestedUri.path,
          }),
          e,
          stackTrace,
        );
        return const ApiException(
          500,
          'internal_error',
          'Erro interno do servidor.',
        ).toResponse();
      }
    };
