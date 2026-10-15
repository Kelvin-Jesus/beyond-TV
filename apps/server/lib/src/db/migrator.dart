import 'package:sqlite3/sqlite3.dart';

/// Uma alteração versionada do esquema do banco.
///
/// As versões começam em 1 e são sequenciais. Uma migração já publicada
/// **nunca** é editada: para mudar o esquema, crie a próxima.
class Migration {
  const Migration(this.version, this.name, this.sql);

  final int version;
  final String name;

  /// Um ou mais comandos SQL separados por `;`.
  final String sql;
}

/// Falha ao aplicar ou validar as migrações.
class MigrationException implements Exception {
  MigrationException(this.message, [this.cause]);

  final String message;
  final Object? cause;

  @override
  String toString() =>
      'MigrationException: $message${cause == null ? '' : ' ($cause)'}';
}

/// Aplica em [db] as [migrations] que ainda não foram aplicadas.
///
/// A versão atual fica em `PRAGMA user_version`. Cada migração roda numa
/// transação própria: se falhar, nada dela fica no banco e a versão não muda.
/// Retorna as versões aplicadas nesta chamada.
List<int> migrate(Database db, List<Migration> migrations) {
  for (var i = 0; i < migrations.length; i++) {
    if (migrations[i].version != i + 1) {
      throw MigrationException(
        'Migrações fora de ordem: esperado ${i + 1}, '
        'encontrado ${migrations[i].version}.',
      );
    }
  }

  final current = db.userVersion;
  if (current > migrations.length) {
    throw MigrationException(
      'O banco está na versão $current, mais nova que a deste servidor '
      '(${migrations.length}). Atualize o Beyond TV.',
    );
  }

  final applied = <int>[];
  for (final migration in migrations.skip(current)) {
    db.execute('BEGIN');
    try {
      db
        ..execute(migration.sql)
        ..userVersion = migration.version
        ..execute('COMMIT');
    } on Object catch (e) {
      db.execute('ROLLBACK');
      throw MigrationException(
        'Falha na migração ${migration.version} (${migration.name}).',
        e,
      );
    }
    applied.add(migration.version);
  }
  return applied;
}
