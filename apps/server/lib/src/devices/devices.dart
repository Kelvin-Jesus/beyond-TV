import 'dart:convert';

import 'package:beyond_protocol/beyond_protocol.dart';
import 'package:sqlite3/sqlite3.dart';

/// Acesso às tabelas `devices` e `settings`.
class DeviceStore {
  DeviceStore(this._db);

  final Database _db;

  /// Identificador deste servidor, gerado na primeira execução.
  String get serverId =>
      _db
              .select("SELECT value FROM settings WHERE key = 'server_id'")
              .single['value']
          as String;

  /// Cadastra uma TV recém-pareada.
  ///
  /// [tokenHash] é o SHA-256 do token; o token em claro nunca é gravado.
  void create({
    required String id,
    required String name,
    required String tokenHash,
    required DeviceInfo info,
  }) => _db.execute(
    'INSERT INTO devices (id, name, token_hash, info) VALUES (?, ?, ?, ?)',
    [id, name, tokenHash, jsonEncode(info.toJson())],
  );

  /// Nome da TV [id], ou `null` se ela não existe (ex.: foi removida).
  String? nameOf(String id) {
    final rows = _db.select('SELECT name FROM devices WHERE id = ?', [id]);
    return rows.isEmpty ? null : rows.single['name'] as String;
  }
}
