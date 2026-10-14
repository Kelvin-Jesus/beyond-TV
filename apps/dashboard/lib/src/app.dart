import 'package:beyond_protocol/beyond_protocol.dart';
import 'package:flutter/material.dart';

/// Cor de destaque da marca Beyond TV (a mesma dos ícones).
const brandAccent = Color(0xFF38BDF8);

class DashboardApp extends StatelessWidget {
  const DashboardApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Beyond TV',
      debugShowCheckedModeBanner: false,
      theme: _theme(Brightness.light),
      darkTheme: _theme(Brightness.dark),
      home: const _HomePage(),
    );
  }

  ThemeData _theme(Brightness brightness) => ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: brandAccent,
          brightness: brightness,
        ),
      );
}

class _HomePage extends StatelessWidget {
  const _HomePage();

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.tv, size: 64, color: brandAccent),
            const SizedBox(height: 16),
            Text('Beyond TV', style: textTheme.headlineMedium),
            const SizedBox(height: 8),
            Text(
              'Painel em construção · protocolo v$protocolVersion',
              style: textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}
