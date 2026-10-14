import 'package:args/args.dart';
import 'package:logging/logging.dart';

/// Porta HTTP padrão (dashboard, API, mídia e WebSocket).
const defaultHttpPort = 8787;

/// Pasta padrão dos dados de execução, relativa ao diretório atual.
const defaultDataDir = 'data';

/// Níveis de log aceitos em `--log-level`, do mais ao menos detalhado.
const logLevels = {
  'debug': Level.FINE,
  'info': Level.INFO,
  'warning': Level.WARNING,
  'error': Level.SEVERE,
};

/// Erro de configuração inválida, com mensagem pronta para o usuário.
class ConfigException implements Exception {
  ConfigException(this.message);

  final String message;

  @override
  String toString() => 'ConfigException: $message';
}

/// Configuração do servidor.
///
/// Cada opção vem, em ordem de prioridade, do argumento de linha de comando,
/// da variável de ambiente ou do valor padrão.
class ServerConfig {
  const ServerConfig({
    this.port = defaultHttpPort,
    this.dataDir = defaultDataDir,
    this.logLevel = Level.INFO,
  });

  /// Lê a configuração de [args] e [environment].
  ///
  /// Lança [ConfigException] se algum valor for inválido. Quando
  /// `--help` é passado, retorna `null`; o texto de ajuda está em [usage].
  static ServerConfig? parse(
    List<String> args, {
    Map<String, String> environment = const {},
  }) {
    final ArgResults results;
    try {
      results = _parser.parse(args);
    } on FormatException catch (e) {
      throw ConfigException(e.message);
    }
    if (results.flag('help')) return null;

    String? option(String name, String envVar) {
      final value = results.option(name) ?? environment[envVar];
      return (value == null || value.trim().isEmpty) ? null : value.trim();
    }

    return ServerConfig(
      port: _parsePort(option('port', 'BEYOND_PORT')),
      dataDir: option('data-dir', 'BEYOND_DATA_DIR') ?? defaultDataDir,
      logLevel: _parseLogLevel(option('log-level', 'BEYOND_LOG_LEVEL')),
    );
  }

  /// Texto de ajuda com todas as opções.
  static String get usage => _parser.usage;

  /// Porta TCP do HTTP e do WebSocket.
  final int port;

  /// Pasta onde ficam o banco, as mídias e os logs.
  final String dataDir;

  /// Nível mínimo das mensagens de log.
  final Level logLevel;

  static int _parsePort(String? raw) {
    if (raw == null) return defaultHttpPort;
    final port = int.tryParse(raw);
    if (port == null || port < 1 || port > 65535) {
      throw ConfigException(
        'Porta inválida: "$raw". Use um número de 1 a 65535.',
      );
    }
    return port;
  }

  static Level _parseLogLevel(String? raw) {
    if (raw == null) return Level.INFO;
    final level = logLevels[raw.toLowerCase()];
    if (level == null) {
      throw ConfigException(
        'Nível de log inválido: "$raw". Use ${logLevels.keys.join(', ')}.',
      );
    }
    return level;
  }

  static final _parser = ArgParser()
    ..addOption(
      'port',
      abbr: 'p',
      help: 'Porta HTTP. Variável de ambiente: BEYOND_PORT.',
      valueHelp: '$defaultHttpPort',
    )
    ..addOption(
      'data-dir',
      abbr: 'd',
      help:
          'Pasta de dados (banco, mídias e logs). '
          'Variável de ambiente: BEYOND_DATA_DIR.',
      valueHelp: defaultDataDir,
    )
    ..addOption(
      'log-level',
      help: 'Nível de log. Variável de ambiente: BEYOND_LOG_LEVEL.',
      allowed: logLevels.keys,
      valueHelp: 'info',
    )
    ..addFlag('help', abbr: 'h', negatable: false, help: 'Mostra esta ajuda.');
}
