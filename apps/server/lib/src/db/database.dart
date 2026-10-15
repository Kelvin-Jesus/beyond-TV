import 'package:sqlite3/sqlite3.dart';

import 'migrations/migrations.dart';
import 'migrator.dart';

/// Nome do arquivo do banco dentro da pasta de dados.
const databaseFileName = 'beyond.db';

/// Abre o banco em [path], configura a conexão e aplica as migrações.
///
/// Sem [path], abre um banco em memória (usado nos testes).
Database openDatabase([String? path]) {
  final db = path == null ? sqlite3.openInMemory() : sqlite3.open(path);
  try {
    db.execute('PRAGMA foreign_keys = ON');
    db.execute('PRAGMA busy_timeout = 5000');
    if (path != null) db.execute('PRAGMA journal_mode = WAL');
    migrate(db, migrations);
    return db;
  } on Object {
    db.close();
    rethrow;
  }
}
