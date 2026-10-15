import 'package:beyond_dashboard/src/api/api_client.dart';
import 'package:beyond_dashboard/src/app.dart';
import 'package:beyond_dashboard/src/auth/auth_controller.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
}

/// O dashboard completo usando [api].
Widget dashboardWith(FakeApi api) => ProviderScope(
      overrides: [apiClientProvider.overrideWithValue(api)],
      child: const DashboardApp(),
    );
