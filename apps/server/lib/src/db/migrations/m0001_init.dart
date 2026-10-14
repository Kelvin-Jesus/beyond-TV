import '../migrator.dart';

/// Esquema inicial: configurações do servidor, administrador, sessões, grupos
/// e TVs.
///
/// Datas são texto ISO 8601 em UTC (`2026-10-13T12:00:00.000Z`), que ordena
/// e compara corretamente como string.
const migration0001 = Migration(1, 'init', r'''
CREATE TABLE settings (
  key   TEXT PRIMARY KEY,
  value TEXT NOT NULL
) STRICT, WITHOUT ROWID;

-- Identifica este servidor para as TVs (veja "Troca de servidor" no plano).
INSERT INTO settings (key, value) VALUES ('server_id', lower(hex(randomblob(16))));

CREATE TABLE admins (
  id            INTEGER PRIMARY KEY,
  username      TEXT NOT NULL UNIQUE COLLATE NOCASE,
  password_hash TEXT NOT NULL,
  created_at    TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%fZ', 'now'))
) STRICT;

-- O ID da sessão só existe em hash (SHA-256) no banco.
CREATE TABLE sessions (
  id_hash    TEXT PRIMARY KEY,
  admin_id   INTEGER NOT NULL REFERENCES admins (id) ON DELETE CASCADE,
  created_at TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%fZ', 'now')),
  expires_at TEXT NOT NULL
) STRICT, WITHOUT ROWID;

CREATE INDEX sessions_admin_id ON sessions (admin_id);
CREATE INDEX sessions_expires_at ON sessions (expires_at);

CREATE TABLE groups (
  id         INTEGER PRIMARY KEY,
  name       TEXT NOT NULL UNIQUE COLLATE NOCASE,
  created_at TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%fZ', 'now'))
) STRICT;

-- O token da TV só existe em hash (SHA-256) no banco.
CREATE TABLE devices (
  id           TEXT PRIMARY KEY,
  name         TEXT NOT NULL,
  token_hash   TEXT NOT NULL UNIQUE,
  group_id     INTEGER REFERENCES groups (id) ON DELETE SET NULL,
  info         TEXT NOT NULL DEFAULT '{}' CHECK (json_valid(info)),
  last_seen_at TEXT,
  created_at   TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%fZ', 'now'))
) STRICT, WITHOUT ROWID;

CREATE INDEX devices_group_id ON devices (group_id);
''');
