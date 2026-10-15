import 'dart:convert';

import 'package:shelf/shelf.dart';

/// Resposta HTTP com corpo JSON.
Response jsonResponse(Object? body, {int status = 200}) => Response(
  status,
  body: jsonEncode(body),
  headers: {'content-type': 'application/json; charset=utf-8'},
);

/// Erro que a API devolve ao cliente como
/// `{"error": {"code": ..., "message": ...}}`.
///
/// Os handlers podem lançá-lo; o middleware de erros transforma em resposta.
class ApiException implements Exception {
  const ApiException(this.status, this.code, this.message);

  const ApiException.badRequest(String message)
    : this(400, 'bad_request', message);

  const ApiException.notFound([String message = 'Recurso não encontrado.'])
    : this(404, 'not_found', message);

  /// Status HTTP.
  final int status;

  /// Código estável, para o cliente tratar sem depender do texto.
  final String code;

  /// Mensagem em português, pronta para exibir.
  final String message;

  Response toResponse() => jsonResponse({
    'error': {'code': code, 'message': message},
  }, status: status);

  @override
  String toString() => 'ApiException($status, $code): $message';
}
