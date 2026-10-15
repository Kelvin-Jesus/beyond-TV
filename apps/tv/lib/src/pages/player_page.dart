import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../content/content_controller.dart';
import '../player/web_player.dart';
import '../realtime/device_connection.dart';
import 'paired_page.dart';

/// Tela da TV pareada: o site em tela cheia, ou o estado vazio enquanto não
/// há conteúdo. Também leva de volta ao pareamento se a TV for removida.
class PlayerPage extends StatefulWidget {
  const PlayerPage({
    super.key,
    required this.content,
    required this.connection,
    required this.onUnauthorized,
    this.webPlayer = defaultWebPlayer,
    this.setWakelock = _defaultWakelock,
  });

  final ContentController content;
  final DeviceConnection connection;
  final WebPlayerBuilder webPlayer;

  /// Liga ou desliga o *wakelock*; os testes trocam por um registro.
  final Future<void> Function(bool on) setWakelock;

  /// Chamado quando esta TV foi removida; leva de volta ao pareamento.
  final void Function(BuildContext context) onUnauthorized;

  static Future<void> _defaultWakelock(bool on) =>
      on ? WakelockPlus.enable() : WakelockPlus.disable();

  @override
  State<PlayerPage> createState() => _PlayerPageState();
}

class _PlayerPageState extends State<PlayerPage> {
  Timer? _tick;
  bool _left = false;
  bool _immersive = false;

  DeviceConnection get _connection => widget.connection;
  ContentController get _content => widget.content;

  @override
  void initState() {
    super.initState();
    unawaited(widget.setWakelock(true));
    _connection.addListener(_onChanged);
    _content.addListener(_onChanged);
    // Atualiza o "tentando de novo em N s" a cada segundo.
    _tick = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_connection.status == ConnectionStatus.offline && !_playing) {
        setState(() {});
      }
    });
    unawaited(_content.start());
    _connection.start();
  }

  bool get _playing => _content.currentUrl != null;

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

  void _syncSystemUi() {
    if (_playing == _immersive) return;
    _immersive = _playing;
    unawaited(
      SystemChrome.setEnabledSystemUIMode(
        _immersive ? SystemUiMode.immersiveSticky : SystemUiMode.edgeToEdge,
      ),
    );
  }

  @override
  void dispose() {
    _tick?.cancel();
    _connection.removeListener(_onChanged);
    _content.removeListener(_onChanged);
    unawaited(widget.setWakelock(false));
    if (_immersive) {
      unawaited(SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge));
    }
    _content.dispose();
    unawaited(_connection.dispose());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final url = _content.currentUrl;
    _syncSystemUi();

    final Widget body;
    if (url == null) {
      _content.player = null;
      body = PairedPage(connection: _connection);
    } else {
      body = Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          fit: StackFit.expand,
          children: [
            widget.webPlayer(
              context,
              url,
              (controller) => _content.player = controller,
            ),
            if (_connection.status == ConnectionStatus.offline)
              const Positioned(
                top: 16,
                right: 16,
                child: Icon(Icons.circle, size: 12, color: Colors.orange),
              ),
          ],
        ),
      );
    }

    final name = _content.identifyName;
    return Stack(
      fit: StackFit.expand,
      children: [
        body,
        if (name != null)
          Positioned.fill(
            child: Container(
              color: const Color(0xCC000000),
              alignment: Alignment.center,
              padding: const EdgeInsets.all(48),
              child: Text(
                name,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 120,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  decoration: TextDecoration.none,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
