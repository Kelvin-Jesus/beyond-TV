import 'dart:async';

import 'package:logging/logging.dart';

/// Configura o logger raiz para escrever cada registro em [sink], uma linha
/// por registro, a partir de [level].
///
/// Retorna a assinatura para quem quiser cancelar (por exemplo, nos testes).
StreamSubscription<LogRecord> setupLogging(
  Level level, {
  required void Function(String line) sink,
}) {
  Logger.root.level = level;
  return Logger.root.onRecord.listen((record) => sink(formatLogRecord(record)));
}

/// Mensagem de log com campos estruturados.
///
/// ```dart
/// log.info(LogEvent('requisição', {'method': 'GET', 'status': 200}));
/// // ts=2026-10-13T12:00:00.000Z level=INFO logger=http msg=requisição method=GET status=200
/// ```
class LogEvent {
  const LogEvent(this.message, [this.fields = const {}]);

  final String message;
  final Map<String, Object?> fields;

  @override
  String toString() => message;
}

/// Formata [record] no estilo *logfmt*: `chave=valor` separados por espaço.
///
/// Os campos de um [LogEvent] entram depois de `msg`.
String formatLogRecord(LogRecord record) {
  final fields = <String, Object?>{
    'ts': record.time.toUtc().toIso8601String(),
    'level': record.level.name,
    'logger': record.loggerName,
    'msg': record.message,
    if (record.object case LogEvent(:final fields)) ...fields,
    if (record.error != null) 'error': record.error,
  };

  final line = fields.entries
      .where((field) => field.value != null)
      .map((field) => '${field.key}=${_quote('${field.value}')}')
      .join(' ');

  final stackTrace = record.stackTrace;
  return stackTrace == null ? line : '$line\n$stackTrace';
}

final _needsQuotes = RegExp(r'[\s"=]');

String _quote(String value) {
  if (value.isNotEmpty && !_needsQuotes.hasMatch(value)) return value;
  final escaped = value
      .replaceAll(r'\', r'\\')
      .replaceAll('"', r'\"')
      .replaceAll('\n', r'\n');
  return '"$escaped"';
}
