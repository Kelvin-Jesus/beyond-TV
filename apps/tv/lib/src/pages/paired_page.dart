import 'package:flutter/material.dart';

import '../server/server_address.dart';
import '../widgets/tv_page.dart';

/// Exibida depois do pareamento, até o player chegar (fases 5 e 6).
class PairedPage extends StatelessWidget {
  const PairedPage({super.key, required this.server});

  final ServerAddress server;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return TvPage(
      title: 'TV pareada!',
      subtitle: 'Conectada a ${server.name ?? 'servidor'} · '
          '${server.hostPort}',
      children: [
        Text(
          'Aguardando conteúdo. Escolha no painel o que esta TV vai exibir.',
          style: textTheme.titleLarge,
        ),
      ],
    );
  }
}
