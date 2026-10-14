import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import 'server_address.dart';

/// Falha ao falar com o servidor, com mensagem pronta para a tela da TV.
class TvApiException implements Exception {
  const TvApiException(this.message, {this.code});

  final String message;

  /// Código do erro devolvido pelo servidor (ex.: `expired_code`), ou `null`
  /// se o servidor nem respondeu.
  final String? code;

  @override
  String toString() => 'TvApiException($code): $message';
}

/// Cliente HTTP do app da TV.
class TvApi {
  TvApi({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  static const _timeout = Duration(seconds: 8);

  /// Confere se [server] é um servidor Beyond TV que está respondendo.
  Future<void> checkServer(ServerAddress server) async {
    final json = await _send(http.Request('GET', server.resolve('/health')));
    if (json['status'] != 'ok') throw _notBeyondServer;
  }

  /// Envia [request] e devolve o corpo JSON.
  ///
  /// Lança [TvApiException] com a mensagem do servidor quando ele responde
  /// com erro, ou com "servidor inacessível" quando não responde.
  Future<Map<String, Object?>> _send(http.Request request) async {
    final http.Response response;
    try {
      response = await http.Response.fromStream(
        await _client.send(request).timeout(_timeout),
      ).timeout(_timeout);
    } on TimeoutException {
      throw unreachable;
    } on http.ClientException {
      throw unreachable;
    }

    final Object? json;
    try {
      json = response.body.isEmpty ? const {} : jsonDecode(response.body);
    } on FormatException {
      throw _notBeyondServer;
    }
    if (json is! Map<String, Object?>) throw _notBeyondServer;

    if (response.statusCode >= 400) {
      throw switch (json['error']) {
        {'code': final String code, 'message': final String message} =>
          TvApiException(message, code: code),
        _ => _notBeyondServer,
      };
    }
    return json;
  }

  static const unreachable = TvApiException(
    'Servidor inacessível. Confira se o servidor está ligado e se a TV está '
    'na mesma rede.',
  );

  static const _notBeyondServer = TvApiException(
    'Esse endereço não é de um servidor Beyond TV.',
  );
}
