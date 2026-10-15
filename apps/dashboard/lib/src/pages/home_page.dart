import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../auth/auth_controller.dart';
import '../pairing/add_tv_dialog.dart';
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
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Nenhuma TV pareada ainda.', style: textTheme.titleMedium),
              const SizedBox(height: 8),
              const Text(
                'Instale o app Beyond TV na TV e clique em "Adicionar TV".',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: () => showAddTvDialog(context),
                icon: const Icon(Icons.add),
                label: const Text('Adicionar TV'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
