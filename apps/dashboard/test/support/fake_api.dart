import 'package:beyond_dashboard/src/api/api_client.dart';
import 'package:beyond_dashboard/src/api/media.dart';
import 'package:beyond_dashboard/src/app.dart';
import 'package:beyond_dashboard/src/auth/auth_controller.dart';
import 'package:beyond_dashboard/src/realtime/admin_events.dart';
import 'package:beyond_protocol/beyond_protocol.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'fake_admin_socket.dart';

/// Servidor falso em memória, com as mesmas regras básicas do real.
class FakeApi implements ApiClient {
  FakeApi({this.adminPassword, this.loggedIn = false});

  /// Senha do administrador; `null` enquanto o setup não foi feito.
  String? adminPassword;
  bool loggedIn;

  /// Se preenchido, toda chamada falha com este erro.
  ApiException? failure;

  void _maybeFail() {
    if (failure case final failure?) throw failure;
  }

  @override
  Future<bool> isConfigured() async {
    _maybeFail();
    return adminPassword != null;
  }

  @override
  Future<String?> currentUser() async {
    _maybeFail();
    return loggedIn ? 'admin' : null;
  }

  @override
  Future<String> setup({
    required String username,
    required String password,
  }) async {
    _maybeFail();
    adminPassword = password;
    loggedIn = true;
    return username;
  }

  @override
  Future<String> login({
    required String username,
    required String password,
  }) async {
    _maybeFail();
    if (username != 'admin' || password != adminPassword) {
      throw const ApiException(
        'Usuário ou senha incorretos.',
        code: 'invalid_login',
        status: 401,
      );
    }
    loggedIn = true;
    return username;
  }

  @override
  Future<void> logout() async => loggedIn = false;

  /// Códigos gerados, em ordem.
  final codes = <String>[];

  /// Situação que [pairingStatus] devolve.
  PairingStatus status = const PairingStatus(PairingState.pending);
  int statusCalls = 0;

  @override
  Future<PairingCode> createPairingCode() async {
    _maybeFail();
    final code = 'K7M4Q${codes.length + 2}';
    codes.add(code);
    return PairingCode(
      code: code,
      expiresAt: DateTime.now().add(pairingCodeTtl),
    );
  }

  /// TVs que o servidor falso conhece.
  final devices = <DeviceSummary>[];

  @override
  Uri get baseUri => Uri.parse('http://localhost:8080/');

  @override
  Future<List<DeviceSummary>> listDevices() async {
    _maybeFail();
    return [...devices];
  }

  @override
  Future<DeviceSummary> renameDevice(String id, String name) async {
    _maybeFail();
    final i = devices.indexWhere((d) => d.id == id);
    return devices[i] = devices[i].copyWith(name: name);
  }

  @override
  Future<void> removeDevice(String id) async {
    _maybeFail();
    devices.removeWhere((d) => d.id == id);
  }

  /// Sites salvos que [listMedia] devolve.
  final media = <Media>[];

  /// Comandos recebidos, como `(id, tipo)`.
  final commands = <(String, String)>[];

  /// Quantas vezes [setDeviceContentUrl] foi chamado.
  int setUrlCalls = 0;

  DeviceSummary _withContent(String id, ContentItem? content) {
    final i = devices.indexWhere((d) => d.id == id);
    if (i < 0) {
      throw const ApiException(
        'TV não encontrada.',
        code: 'not_found',
        status: 404,
      );
    }
    final d = devices[i];
    return devices[i] = DeviceSummary(
      id: d.id,
      name: d.name,
      online: d.online,
      createdAt: d.createdAt,
      info: d.info,
      groupId: d.groupId,
      lastSeenAt: d.lastSeenAt,
      currentItem: d.currentItem,
      content: content,
    );
  }

  @override
  Future<List<Media>> listMedia() async {
    _maybeFail();
    return [...media];
  }

  @override
  Future<DeviceSummary> setDeviceContentUrl(
    String id,
    String url, {
    String? name,
  }) async {
    _maybeFail();
    setUrlCalls++;
    if (!isSafeContentUrl(url)) {
      throw const ApiException(
        'Endereço inválido.',
        code: 'invalid_url',
        status: 400,
      );
    }
    final label = name == null || name.trim().isEmpty ? url : name.trim();
    return _withContent(
      id,
      ContentItem(
        mediaId: 'm${media.length + 1}',
        kind: MediaKinds.url,
        name: label,
        url: url,
      ),
    );
  }

  @override
  Future<DeviceSummary> setDeviceMedia(String id, String? mediaId) async {
    _maybeFail();
    if (mediaId == null) return _withContent(id, null);
    final m = media.firstWhere((m) => m.id == mediaId);
    return _withContent(
      id,
      ContentItem(mediaId: m.id, kind: m.kind, name: m.name, url: m.url),
    );
  }

  @override
  Future<void> sendCommand(String id, String type) async {
    _maybeFail();
    final device = devices.firstWhere((d) => d.id == id);
    if (type != DeviceCommands.unpair && !device.online) {
      throw const ApiException(
        'A TV está offline.',
        code: 'device_offline',
        status: 409,
      );
    }
    commands.add((id, type));
    if (type == DeviceCommands.unpair) devices.remove(device);
  }

  @override
  Future<PairingStatus> pairingStatus(String code) async {
    _maybeFail();
    statusCalls++;
    return status;
  }
}

/// O dashboard completo usando [api] e o canal ao vivo falso [socket].
Widget dashboardWith(FakeApi api, {FakeAdminSocket? socket}) {
  final fake = socket ?? FakeAdminSocket();
  return ProviderScope(
    overrides: [
      apiClientProvider.overrideWithValue(api),
      adminSocketConnectorProvider.overrideWithValue((_) => fake),
    ],
    child: const DashboardApp(),
  );
}
