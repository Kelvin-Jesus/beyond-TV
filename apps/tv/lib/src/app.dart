import 'package:beyond_protocol/beyond_protocol.dart';
import 'package:flutter/material.dart';

/// Cores da marca (as mesmas dos ícones e do banner).
const brandBackground = Color(0xFF0F172A);
const brandAccent = Color(0xFF38BDF8);

class TvApp extends StatelessWidget {
  const TvApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Beyond TV',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: brandAccent,
          brightness: Brightness.dark,
          surface: brandBackground,
        ),
        scaffoldBackgroundColor: brandBackground,
      ),
      home: const _SplashPage(),
    );
  }
}

/// Tela inicial provisória. Na fase 4 ela decide entre pareamento e player.
class _SplashPage extends StatelessWidget {
  const _SplashPage();

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.tv, size: 96, color: brandAccent),
            const SizedBox(height: 24),
            Text('Beyond TV', style: textTheme.displaySmall),
            const SizedBox(height: 8),
            Text(
              'Protocolo v$protocolVersion',
              style: textTheme.titleMedium?.copyWith(color: Colors.white70),
            ),
          ],
        ),
      ),
    );
  }
}
