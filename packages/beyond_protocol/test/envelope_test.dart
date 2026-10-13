import 'package:beyond_protocol/beyond_protocol.dart';
import 'package:test/test.dart';

void main() {
  group('Envelope', () {
    test('ida e volta por JSON preserva todos os campos', () {
      final original = Envelope.create(
        MessageTypes.heartbeat,
        payload: {'uptime': 42, 'item': null},
        now: DateTime.utc(2026, 10, 13, 12),
      );

      final decoded = Envelope.decode(original.encode());

      expect(decoded.v, protocolVersion);
      expect(decoded.type, MessageTypes.heartbeat);
      expect(decoded.id, original.id);
      expect(decoded.ts, DateTime.utc(2026, 10, 13, 12));
      expect(decoded.payload, {'uptime': 42, 'item': null});
    });

    test('create gera UUID v4 diferente a cada chamada', () {
      final uuid = RegExp(
        r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
      );
      final a = Envelope.create(MessageTypes.hello);
      final b = Envelope.create(MessageTypes.hello);

      expect(a.id, matches(uuid));
      expect(b.id, matches(uuid));
      expect(a.id, isNot(b.id));
    });

    test('ts é sempre serializado em UTC', () {
      final local = DateTime(2026, 10, 13, 9);
      final envelope = Envelope.create(MessageTypes.hello, now: local);

      expect(envelope.ts.isUtc, isTrue);
      expect(envelope.toJson()['ts'], endsWith('Z'));
    });

    test('payload ausente vira objeto vazio', () {
      final envelope = Envelope.fromJson({
        'v': 1,
        'type': MessageTypes.cmdReload,
        'id': 'abc',
        'ts': '2026-10-13T12:00:00Z',
      });

      expect(envelope.payload, isEmpty);
    });

    test('isCompatible só aceita a versão atual', () {
      final json = Envelope.create(MessageTypes.hello).toJson();

      expect(Envelope.fromJson(json).isCompatible, isTrue);
      expect(Envelope.fromJson({...json, 'v': 2}).isCompatible, isFalse);
    });

    group('rejeita mensagem malformada', () {
      final valid = <String, Object?>{
        'v': 1,
        'type': MessageTypes.hello,
        'id': 'abc',
        'ts': '2026-10-13T12:00:00Z',
        'payload': <String, Object?>{},
      };

      final cases = <String, Map<String, Object?>>{
        'sem v': {...valid}..remove('v'),
        'v como texto': {...valid, 'v': '1'},
        'type vazio': {...valid, 'type': ''},
        'sem id': {...valid}..remove('id'),
        'ts inválido': {...valid, 'ts': 'ontem'},
        'payload como lista': {...valid, 'payload': <Object?>[]},
      };

      cases.forEach((description, json) {
        test(description, () {
          expect(
            () => Envelope.fromJson(json),
            throwsA(isA<ProtocolException>()),
          );
        });
      });

      test('JSON inválido', () {
        expect(() => Envelope.decode('{'), throwsA(isA<ProtocolException>()));
      });

      test('JSON que não é objeto', () {
        expect(
          () => Envelope.decode('[1]'),
          throwsA(isA<ProtocolException>()),
        );
      });
    });
  });
}
