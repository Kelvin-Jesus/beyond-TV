import 'package:beyond_server/server.dart';
import 'package:logging/logging.dart';
import 'package:test/test.dart';

LogRecord _record(
  Object? message, {
  Level level = Level.INFO,
  Object? error,
  StackTrace? stackTrace,
}) => LogRecord(level, '$message', 'http', error, stackTrace, null, message);

void main() {
  group('formatLogRecord', () {
    test('escreve os campos básicos em logfmt', () {
      final line = formatLogRecord(_record('ok'));

      expect(line, matches(RegExp(r'^ts=\S+Z level=INFO logger=http msg=ok$')));
    });

    test('inclui os campos do LogEvent depois de msg', () {
      final line = formatLogRecord(
        _record(
          const LogEvent('requisição', {
            'method': 'GET',
            'status': 200,
            'nulo': null,
          }),
        ),
      );

      expect(line, endsWith('msg=requisição method=GET status=200'));
    });

    test('coloca aspas em valores com espaço, aspas ou =', () {
      final line = formatLogRecord(
        _record(
          const LogEvent('erro não tratado', {'path': 'a="b"', 'vazio': ''}),
        ),
      );

      expect(line, endsWith(r'msg="erro não tratado" path="a=\"b\"" vazio=""'));
    });

    test('anexa erro e stack trace', () {
      final line = formatLogRecord(
        _record(
          'falhou',
          level: Level.SEVERE,
          error: StateError('boom'),
          stackTrace: StackTrace.fromString('#0 main'),
        ),
      );

      expect(line, contains(r'error="Bad state: boom"'));
      expect(line, endsWith('\n#0 main'));
    });
  });

  test('setupLogging respeita o nível mínimo', () async {
    final lines = <String>[];
    final subscription = setupLogging(Level.WARNING, sink: lines.add);
    addTearDown(subscription.cancel);

    Logger('teste')
      ..info('ignorada')
      ..warning('registrada');
    await Future<void>.delayed(Duration.zero);

    expect(lines, hasLength(1));
    expect(lines.single, contains('msg=registrada'));
  });
}
