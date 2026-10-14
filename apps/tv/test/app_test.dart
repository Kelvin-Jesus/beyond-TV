import 'package:beyond_tv/src/app.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fakes.dart';

void main() {
  testWidgets('lista os servidores encontrados com foco no primeiro', (
    tester,
  ) async {
    useTvScreen(tester);
    await tester.pumpWidget(
      TvApp(discovery: FakeDiscovery([pcSala]), api: fakeApi()),
    );
    await tester.pumpAndSettle();

    expect(find.text('PC-SALA'), findsOneWidget);
    expect(find.text('192.168.0.10:8787'), findsOneWidget);

    // OK do controle remoto no item focado seleciona o servidor.
    await tester.sendKeyEvent(LogicalKeyboardKey.select);
    await tester.pumpAndSettle();

    expect(find.text('Parear esta TV'), findsOneWidget);
    expect(find.text('Servidor: PC-SALA · 192.168.0.10:8787'), findsOneWidget);
  });

  testWidgets('sem servidores explica e foca em "Digitar IP"', (tester) async {
    final discovery = FakeDiscovery();
    await tester.pumpWidget(TvApp(discovery: discovery, api: fakeApi()));
    await tester.pumpAndSettle();

    expect(find.textContaining('Nenhum servidor encontrado'), findsOneWidget);
    final focused = FocusManager.instance.primaryFocus!.context!;
    expect(
      find.descendant(
        of: find.byWidget(focused.widget),
        matching: find.text('Digitar IP'),
      ),
      findsOneWidget,
    );

    await tester.tap(find.text('Procurar de novo'));
    await tester.pumpAndSettle();
    expect(discovery.calls, 2);
  });

  group('IP manual', () {
    Future<void> openManual(WidgetTester tester) async {
      useTvScreen(tester);
      await tester.pumpWidget(
        TvApp(discovery: FakeDiscovery(), api: fakeApi()),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Digitar IP'));
      await tester.pumpAndSettle();
    }

    testWidgets('conecta num servidor que responde', (tester) async {
      await openManual(tester);

      await tester.enterText(find.byType(TextField), '192.168.0.10');
      await tester.tap(find.text('Conectar'));
      await tester.pumpAndSettle();

      expect(find.text('Parear esta TV'), findsOneWidget);
      expect(find.textContaining('192.168.0.10:8787'), findsOneWidget);
    });

    testWidgets('recusa endereço malformado', (tester) async {
      await openManual(tester);

      await tester.enterText(find.byType(TextField), '300.1.1.1');
      await tester.tap(find.text('Conectar'));
      await tester.pumpAndSettle();

      expect(find.textContaining('Endereço inválido'), findsOneWidget);
    });

    testWidgets('avisa quando o servidor não responde', (tester) async {
      await openManual(tester);

      await tester.enterText(find.byType(TextField), '192.168.0.99:9000');
      await tester.tap(find.text('Conectar'));
      await tester.pumpAndSettle();

      expect(find.textContaining('Servidor inacessível'), findsOneWidget);
    });
  });
}
