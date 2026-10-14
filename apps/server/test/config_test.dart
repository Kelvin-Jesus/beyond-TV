import 'package:beyond_server/server.dart';
import 'package:test/test.dart';

void main() {
  group('ServerConfig.parse', () {
    test('usa os padrões sem args nem env', () {
      final config = ServerConfig.parse([])!;

      expect(config.port, defaultHttpPort);
      expect(config.dataDir, defaultDataDir);
    });

    test('lê as variáveis de ambiente', () {
      final config = ServerConfig.parse(
        [],
        environment: {'BEYOND_PORT': '9000', 'BEYOND_DATA_DIR': '/srv/beyond'},
      )!;

      expect(config.port, 9000);
      expect(config.dataDir, '/srv/beyond');
    });

    test('argumentos têm prioridade sobre o ambiente', () {
      final config = ServerConfig.parse(
        ['--port', '9100', '-d', 'outra'],
        environment: {'BEYOND_PORT': '9000', 'BEYOND_DATA_DIR': '/srv/beyond'},
      )!;

      expect(config.port, 9100);
      expect(config.dataDir, 'outra');
    });

    test('ignora variáveis de ambiente vazias', () {
      final config = ServerConfig.parse(
        [],
        environment: {'BEYOND_PORT': ' ', 'BEYOND_DATA_DIR': ''},
      )!;

      expect(config.port, defaultHttpPort);
      expect(config.dataDir, defaultDataDir);
    });

    for (final port in ['0', '65536', 'abc', '-1']) {
      test('recusa porta inválida "$port"', () {
        expect(
          () => ServerConfig.parse(['--port=$port']),
          throwsA(isA<ConfigException>()),
        );
      });
    }

    test('recusa opção desconhecida', () {
      expect(
        () => ServerConfig.parse(['--nao-existe']),
        throwsA(isA<ConfigException>()),
      );
    });

    test('retorna null com --help', () {
      expect(ServerConfig.parse(['--help']), isNull);
      expect(ServerConfig.usage, contains('BEYOND_PORT'));
    });
  });
}
