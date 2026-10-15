import 'dart:async';

import 'package:flutter/material.dart';

import '../realtime/device_connection.dart';
import '../widgets/tv_page.dart';

/// Exibida depois do pareamento, até o player chegar (fase 6). Também mostra
/// a situação da conexão com o servidor.
class PairedPage extends StatefulWidget {
  const PairedPage({
    super.key,
    required this.connection,
    required this.onUnauthorized,
  });

  final DeviceConnection connection;

  /// Chamado quando o servidor removeu esta TV; leva de volta ao pareamento.
  final void Function(BuildContext context) onUnauthorized;

  @override
  State<PairedPage> createState() => _PairedPageState();
}

class _PairedPageState extends State<PairedPage> {
  Timer? _tick;
  bool _left = false;

  DeviceConnection get _connection => widget.connection;

  @override
  void initState() {
    super.initState();
    _connection.addListener(_onChanged);
    // Atualiza o "tentando de novo em N s" a cada segundo.
    _tick = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_connection.status == ConnectionStatus.offline) setState(() {});
    });
    _connection.start();
  }

  void _onChanged() {
    if (!mounted) return;
    if (_connection.status == ConnectionStatus.unauthorized && !_left) {
      _left = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) widget.onUnauthorized(context);
      });
    }
    setState(() {});
  }

  @override
  void dispose() {
    _tick?.cancel();
    _connection.removeListener(_onChanged);
    unawaited(_connection.dispose());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final server = _connection.credentials.server;

    return TvPage(
      title: 'TV pareada!',
      subtitle: 'Conectada a ${server.name ?? 'servidor'} · '
          '${server.hostPort}',
      children: [
        Text(
          'Aguardando conteúdo. Escolha no painel o que esta TV vai exibir.',
          style: textTheme.titleLarge,
        ),
        const SizedBox(height: 24),
        _StatusLine(connection: _connection),
      ],
    );
  }
}

class _StatusLine extends StatelessWidget {
  const _StatusLine({required this.connection});

  final DeviceConnection connection;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.headlineSmall;
    final text = switch (connection.status) {
      ConnectionStatus.online => 'Conectada',
      ConnectionStatus.connecting => 'Conectando…',
      ConnectionStatus.offline => _offlineText(connection.nextRetryIn),
      ConnectionStatus.replaced => 'Esta TV foi aberta em outro lugar.',
      ConnectionStatus.outdated => 'Atualize o app da TV.',
      ConnectionStatus.unauthorized => 'Esta TV foi removida do painel.',
    };
    return Row(
      children: [
        if (connection.status == ConnectionStatus.online) ...[
          const Icon(Icons.circle, color: Colors.green, size: 20),
          const SizedBox(width: 12),
        ],
        Flexible(child: Text(text, style: style)),
      ],
    );
  }

  static String _offlineText(Duration? left) {
    final seconds = left == null ? 0 : (left.inMilliseconds / 1000).ceil();
    return 'Sem conexão com o servidor. Tentando de novo em $seconds s.';
  }
}
