import 'package:beyond_protocol/beyond_protocol.dart';
import 'package:beyond_tv/src/app.dart';
import 'package:beyond_tv/src/content/manifest_store.dart';
import 'package:beyond_tv/src/device/credentials.dart';
import 'package:beyond_tv/src/realtime/backoff.dart';
import 'package:beyond_tv/src/content/content_controller.dart';
import 'package:beyond_tv/src/pages/player_page.dart';
import 'package:beyond_tv/src/realtime/device_connection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/fake_socket.dart';
import '../support/fakes.dart';

const _saved = Credentials(
  deviceId: 'tv-1',
  deviceToken: 'segredo',
  server: pcSala,
);

ContentManifest _site(String url) => ContentManifest(
      items: [
        ContentItem(
          mediaId: 'm1',
          kind: MediaKinds.url,
          name: 'Site',
          url: url,
        ),
      ],
    );

Envelope _sync(String url) =>
    Envelope.create(MessageTypes.contentSync, payload: _site(url).toJson());

void main() {
  late FakeConnector connector;
  late MemoryCredentialStore credentials;
  late MemoryManifestStore manifests;
  late FakePlayerLog log;

  Future<void> open(WidgetTester tester) async {
    useTvScreen(tester);
    connector = FakeConnector();
    credentials = MemoryCredentialStore(_saved);
    manifests = MemoryManifestStore();
    log = FakePlayerLog();
    await tester.pumpWidget(
      TvApp(
        credentials: credentials,
        discovery: FakeDiscovery(),
        api: fakeApi(),
        connector: connector.call,
        backoffFactory: () => Backoff(initial: const Duration(hours: 1)),
        manifestStore: manifests,
        webPlayer: fakeWebPlayer(log),
      ),
    );
    await tester.pump();
    await tester.pump();
    await tester.pump();
  }

  /// Entrega a mensagem do socket falso até a tela.
  Future<void> deliver(WidgetTester tester, Envelope envelope) async {
    connector.last.serverSend(envelope);
    await tester.pump();
    await tester.pump();
  }

  Future<void> close(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox());
  }

  testWidgets('manifesto vazio mostra "Aguardando conteúdo"', (tester) async {
    await open(tester);
    expect(find.textContaining('Aguardando conteúdo'), findsOneWidget);
    await close(tester);
  });

  testWidgets('content.sync abre o site e outro sync troca a URL', (
    tester,
  ) async {
    await open(tester);
    await deliver(tester, _sync('https://example.local/a'));
    expect(find.text('WEB:https://example.local/a'), findsOneWidget);
    expect(find.textContaining('Aguardando conteúdo'), findsNothing);

    await deliver(tester, _sync('https://example.local/b'));
    expect(find.text('WEB:https://example.local/b'), findsOneWidget);
    await close(tester);
  });

  testWidgets('cmd.reload recarrega o player e manda ack', (tester) async {
    await open(tester);
    await deliver(tester, _sync('https://example.local/a'));

    final reload = Envelope.create(MessageTypes.cmdReload);
    await deliver(tester, reload);
    expect(log.reloads, 1);
    final acks = connector.last.envelopes.where((e) => e.type == 'ack');
    expect(
      acks.map((e) => AckPayload.fromJson(e.payload).ref),
      contains(reload.id),
    );
    await close(tester);
  });

  testWidgets('cmd.identify mostra o nome e some depois da duração', (
    tester,
  ) async {
    await open(tester);
    await deliver(tester, _sync('https://example.local/a'));
    await deliver(
      tester,
      Envelope.create(
        MessageTypes.cmdIdentify,
        payload: const IdentifyPayload(name: 'Recepção', durationSeconds: 1)
            .toJson(),
      ),
    );
    expect(find.text('Recepção'), findsOneWidget);

    await tester.pump(const Duration(seconds: 1));
    expect(find.text('Recepção'), findsNothing);
    await close(tester);
  });

  testWidgets('cmd.unpair limpa tudo e volta à seleção de servidor', (
    tester,
  ) async {
    await open(tester);
    await deliver(tester, _sync('https://example.local/a'));
    expect(manifests.saved, isNotNull);

    await deliver(tester, Envelope.create(MessageTypes.cmdUnpair));
    await tester.pump();
    await tester.pump();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(credentials.saved, isNull);
    expect(manifests.saved, isNull);
    expect(find.text('Escolha o servidor'), findsOneWidget);
    expect(
      find.text('Esta TV foi removida do painel. Pareie de novo.'),
      findsOneWidget,
    );
    await close(tester);
  });

  testWidgets('wakelock liga no init e desliga no dispose', (tester) async {
    useTvScreen(tester);
    final connector = FakeConnector();
    final calls = <bool>[];
    final connection = DeviceConnection(
      credentials: _saved,
      deviceInfo: const FakeDeviceInfo(),
      store: MemoryCredentialStore(_saved),
      connector: connector.call,
      backoff: Backoff(initial: const Duration(hours: 1)),
    );
    final content = ContentController(
      store: MemoryManifestStore(),
      connection: connection,
    );
    await tester.pumpWidget(
      MaterialApp(
        home: PlayerPage(
          content: content,
          connection: connection,
          webPlayer: fakeWebPlayer(FakePlayerLog()),
          onUnauthorized: (_) {},
          setWakelock: (on) async => calls.add(on),
        ),
      ),
    );
    expect(calls, [true]);

    await tester.pumpWidget(const SizedBox());
    expect(calls, [true, false]);
  });
}
