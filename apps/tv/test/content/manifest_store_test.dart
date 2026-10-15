import 'dart:io';

import 'package:beyond_protocol/beyond_protocol.dart';
import 'package:beyond_tv/src/content/manifest_store.dart';
import 'package:flutter_test/flutter_test.dart';

ContentManifest _manifest(String url) => ContentManifest(
      items: [
        ContentItem(
          mediaId: 'm1',
          kind: MediaKinds.url,
          name: 'Site',
          url: url,
        ),
      ],
    );

void main() {
  late Directory dir;
  late FileManifestStore store;

  setUp(() async {
    dir = await Directory.systemTemp.createTemp('manifest_test');
    store = FileManifestStore(directory: () async => dir);
  });

  tearDown(() => dir.delete(recursive: true));

  test('sem arquivo devolve null', () async {
    expect(await store.load(), isNull);
  });

  test('salva e carrega', () async {
    final manifest = _manifest('https://example.local/a');
    await store.save(manifest);
    final loaded = await store.load();
    expect(loaded!.revision, manifest.revision);
    expect(loaded.items.single.url, 'https://example.local/a');
    expect(File('${dir.path}/manifest.json.tmp').existsSync(), isFalse);
  });

  test('arquivo corrompido devolve null e é apagado', () async {
    final file = File('${dir.path}/manifest.json');
    await file.writeAsString('{ isto não é json');
    expect(await store.load(), isNull);
    expect(file.existsSync(), isFalse);
  });

  test('clear apaga o manifesto', () async {
    await store.save(_manifest('https://example.local/a'));
    await store.clear();
    expect(await store.load(), isNull);
  });
}
