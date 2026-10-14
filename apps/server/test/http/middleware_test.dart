import 'dart:async';
import 'dart:convert';

import 'package:beyond_server/server.dart';
import 'package:logging/logging.dart';
import 'package:shelf/shelf.dart';
import 'package:test/test.dart';

Request _get(String path) => Request('GET', Uri.parse('http://localhost$path'));

void main() {
  late List<LogRecord> records;
  late StreamSubscription<LogRecord> subscription;

  setUp(() {
    records = [];
    Logger.root.level = Level.ALL;
    subscription = Logger.root.onRecord.listen(records.add);
  });

  tearDown(() => subscription.cancel());

  group('errorHandler', () {
    Handler wrap(Handler handler) =>
        const Pipeline().addMiddleware(errorHandler()).addHandler(handler);

    test('responde 500 genérico e registra o erro com stack trace', () async {
      final handler = wrap((_) => throw StateError('segredo interno'));

      final response = await handler(_get('/x'));
      final body = await response.readAsString();

      expect(response.statusCode, 500);
      expect(response.headers['content-type'], startsWith('application/json'));
      expect(jsonDecode(body), {
        'error': {
          'code': 'internal_error',
          'message': 'Erro interno do servidor.',
        },
      });
      expect(body, isNot(contains('segredo')));

      final record = records.single;
      expect(record.level, Level.SEVERE);
      expect(record.error, isA<StateError>());
      expect(record.stackTrace, isNotNull);
    });

    test('transforma ApiException na resposta que ela descreve', () async {
      final handler = wrap(
        (_) => throw const ApiException.badRequest('Campo obrigatório.'),
      );

      final response = await handler(_get('/x'));

      expect(response.statusCode, 400);
      expect(jsonDecode(await response.readAsString()), {
        'error': {'code': 'bad_request', 'message': 'Campo obrigatório.'},
      });
      expect(records, isEmpty);
    });

    test('repassa HijackException para o WebSocket funcionar', () {
      final handler = wrap((_) => throw const HijackException());

      expect(() => handler(_get('/x')), throwsA(isA<HijackException>()));
    });
  });

  group('requestLogger', () {
    Handler wrap(int status) => const Pipeline()
        .addMiddleware(requestLogger())
        .addHandler((_) => Response(status));

    test('registra método, caminho, status e duração sem a query', () async {
      await wrap(200)(_get('/api/x?token=segredo'));

      final event = records.single.object! as LogEvent;
      expect(records.single.level, Level.FINE);
      expect(event.fields, {
        'method': 'GET',
        'path': '/api/x',
        'status': 200,
        'ms': isA<int>(),
      });
      expect(event.fields.values, isNot(contains(contains('segredo'))));
    });

    test('usa info para 4xx e warning para 5xx', () async {
      await wrap(404)(_get('/a'));
      await wrap(503)(_get('/b'));

      expect(records.map((r) => r.level), [Level.INFO, Level.WARNING]);
    });
  });
}
