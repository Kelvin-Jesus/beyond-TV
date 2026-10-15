import 'package:beyond_protocol/beyond_protocol.dart';
import 'package:sqlite3/sqlite3.dart';

import '../auth/tokens.dart';
import '../clock.dart';

/// Acesso à tabela `media`.
class MediaStore {
  MediaStore(this._db, {Clock clock = DateTime.now}) : _clock = clock;

  final Database _db;
  final Clock _clock;

  static const _columns = 'id, kind, name, url, created_at';

  /// Todas as mídias, da mais nova para a mais antiga.
  List<MediaRow> list() => [
    for (final row in _db.select(
      'SELECT $_columns FROM media ORDER BY created_at DESC, id',
    ))
      _toRow(row),
  ];

  /// A mídia [id], ou `null` se não existe.
  MediaRow? find(String id) {
    final rows = _db.select('SELECT $_columns FROM media WHERE id = ?', [id]);
    return rows.isEmpty ? null : _toRow(rows.first);
  }

  /// A mídia do tipo url com o endereço [url], ou `null`.
  MediaRow? findByUrl(String url) {
    final rows = _db.select(
      'SELECT $_columns FROM media WHERE kind = ? AND url = ? '
      'ORDER BY created_at, id LIMIT 1',
      [MediaKinds.url, url],
    );
    return rows.isEmpty ? null : _toRow(rows.first);
  }

  /// Cadastra um site. Sem [name], usa o host da URL.
  MediaRow createUrl({required String url, String? name}) {
    final id = generateId();
    _db.execute(
      'INSERT INTO media (id, kind, name, url, created_at) '
      'VALUES (?, ?, ?, ?, ?)',
      [id, MediaKinds.url, name ?? Uri.parse(url).host, url, isoUtc(_clock())],
    );
    return find(id)!;
  }

  /// Altera nome e/ou URL. Devolve a mídia atualizada, ou `null` se não existe.
  MediaRow? update(String id, {String? name, String? url}) {
    _db.execute(
      'UPDATE media SET name = coalesce(?, name), url = coalesce(?, url) '
      'WHERE id = ?',
      [name, url, id],
    );
    return find(id);
  }

  /// Apaga a mídia [id]; as TVs que a exibiam ficam sem conteúdo.
  bool delete(String id) {
    _db.execute('DELETE FROM media WHERE id = ?', [id]);
    return _db.updatedRows > 0;
  }

  MediaRow _toRow(Row row) => MediaRow(
    id: row['id'] as String,
    kind: row['kind'] as String,
    name: row['name'] as String,
    url: row['url'] as String?,
    createdAt: DateTime.parse(row['created_at'] as String).toUtc(),
  );
}

/// Uma linha da tabela `media`.
class MediaRow {
  const MediaRow({
    required this.id,
    required this.kind,
    required this.name,
    required this.createdAt,
    this.url,
  });

  final String id;

  /// Um dos [MediaKinds].
  final String kind;
  final String name;
  final String? url;
  final DateTime createdAt;

  /// Formato `Media` do protocolo.
  Map<String, Object?> toJson() => {
    'id': id,
    'kind': kind,
    'name': name,
    'url': url,
    'createdAt': createdAt.toIso8601String(),
  };

  ContentItem toContentItem() =>
      ContentItem(mediaId: id, kind: kind, name: name, url: url);
}
