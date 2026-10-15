import 'package:beyond_dashboard/src/api/api_client.dart';
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
