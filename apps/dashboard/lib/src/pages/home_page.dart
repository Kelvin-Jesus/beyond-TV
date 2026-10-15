import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../auth/auth_controller.dart';
import '../theme.dart';

/// Página inicial do painel. A lista de TVs chega nas próximas fases.
class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final username = switch (ref.watch(authProvider)) {
      AsyncData(value: SignedIn(:final username)) => username,
      _ => '',
    };
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.tv, color: brandAccent),
            SizedBox(width: 8),
            Text('Beyond TV'),
          ],
        ),
        actions: [
          Center(child: Text(username)),
          const SizedBox(width: 8),
          IconButton(
            tooltip: 'Sair',
            icon: const Icon(Icons.logout),
            onPressed: () => ref.read(authProvider.notifier).logout(),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Center(
        child: Text('Nenhuma TV pareada ainda.', style: textTheme.titleMedium),
      ),
    );
  }
}
