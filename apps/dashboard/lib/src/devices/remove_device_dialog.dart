import 'package:beyond_protocol/beyond_protocol.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/api_client.dart';
import 'devices_controller.dart';

/// Pede confirmação e remove a TV (o servidor revoga o token dela).
Future<void> showRemoveDeviceDialog(
  BuildContext context,
  DeviceSummary device,
) async {
  final messenger = ScaffoldMessenger.of(context);
  final container = ProviderScope.containerOf(context);
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (_) => AlertDialog(
      title: const Text('Remover TV'),
      content: Text(
        'Remover ${device.name}? A TV volta para a tela de pareamento e '
        'precisa de um código novo para voltar.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.error,
            foregroundColor: Theme.of(context).colorScheme.onError,
          ),
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text('Remover'),
        ),
      ],
    ),
  );
  if (confirmed != true) return;
  try {
    await container.read(devicesProvider.notifier).remove(device.id);
    messenger.showSnackBar(const SnackBar(content: Text('TV removida.')));
  } on ApiException catch (e) {
    messenger.showSnackBar(SnackBar(content: Text(e.message)));
  }
}
