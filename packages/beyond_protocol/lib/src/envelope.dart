import 'dart:convert';
import 'dart:math';

import 'protocol_exception.dart';

/// Versão atual do protocolo, enviada no campo `v` de toda mensagem.
const int protocolVersion = 1;

/// Envelope único de todas as mensagens WebSocket.
///
/// ```json
/// { "v": 1, "type": "content.sync", "id": "uuid", "ts": "2026-10-13T12:00:00Z", "payload": { } }
/// ```
final class Envelope {
  Envelope({
    required this.type,
    required this.id,
    required DateTime ts,
    this.payload = const {},
    this.v = protocolVersion,
  }) : ts = ts.toUtc();

  /// Cria um envelope novo com `id` aleatório e `ts` igual a agora.
  factory Envelope.create(
    String type, {
    Map<String, Object?> payload = const {},
    DateTime? now,
  }) =>
      Envelope(
        type: type,
        id: _uuidV4(),
        ts: now ?? DateTime.now(),
        payload: payload,
      );

  /// Lê um envelope de um mapa JSON.
  ///
  /// Lança [ProtocolException] se algum campo faltar ou tiver o tipo errado.
  /// Não rejeita versões diferentes: use [isCompatible] para decidir.
  factory Envelope.fromJson(Map<String, Object?> json) {
    final v = json['v'];
    final type = json['type'];
    final id = json['id'];
    final ts = json['ts'];
    final payload = json['payload'] ?? const <String, Object?>{};

    if (v is! int) {
      throw const ProtocolException('campo "v" ausente ou inválido');
    }
    if (type is! String || type.isEmpty) {
      throw const ProtocolException('campo "type" ausente ou inválido');
    }
    if (id is! String || id.isEmpty) {
      throw const ProtocolException('campo "id" ausente ou inválido');
    }
    if (ts is! String) {
      throw const ProtocolException('campo "ts" ausente ou inválido');
    }
    final parsedTs = DateTime.tryParse(ts);
    if (parsedTs == null) {
      throw ProtocolException('campo "ts" não é uma data ISO 8601: $ts');
    }
    if (payload is! Map<String, Object?>) {
      throw const ProtocolException('campo "payload" deve ser um objeto');
    }

    return Envelope(v: v, type: type, id: id, ts: parsedTs, payload: payload);
  }

  /// Lê um envelope de um texto JSON recebido pelo WebSocket.
  factory Envelope.decode(String source) {
    final Object? json;
    try {
      json = jsonDecode(source);
    } on FormatException catch (e) {
      throw ProtocolException('JSON inválido: ${e.message}');
    }
    if (json is! Map<String, Object?>) {
      throw const ProtocolException('a mensagem deve ser um objeto JSON');
    }
    return Envelope.fromJson(json);
  }

  final int v;
  final String type;
  final String id;

  /// Momento de criação, sempre em UTC.
  final DateTime ts;
  final Map<String, Object?> payload;

  /// Indica se este envelope usa a mesma versão de protocolo deste código.
  bool get isCompatible => v == protocolVersion;

  Map<String, Object?> toJson() => {
        'v': v,
        'type': type,
        'id': id,
        'ts': ts.toIso8601String(),
        'payload': payload,
      };

  String encode() => jsonEncode(toJson());

  @override
  String toString() => 'Envelope($type, id: $id)';
}

final _random = Random.secure();

/// UUID v4 (RFC 9562) sem dependência externa.
String _uuidV4() {
  final bytes = List<int>.generate(16, (_) => _random.nextInt(256));
  bytes[6] = (bytes[6] & 0x0f) | 0x40; // versão 4
  bytes[8] = (bytes[8] & 0x3f) | 0x80; // variante RFC
  final hex = bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-'
      '${hex.substring(12, 16)}-${hex.substring(16, 20)}-${hex.substring(20)}';
}
