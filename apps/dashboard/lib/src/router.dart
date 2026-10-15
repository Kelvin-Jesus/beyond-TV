import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'auth/auth_controller.dart';
import 'pages/home_page.dart';
import 'pages/login_page.dart';
import 'pages/setup_page.dart';
import 'pages/startup_page.dart';

/// Rotas do dashboard.
abstract final class Routes {
  static const startup = '/carregando';
  static const setup = '/configuracao';
  static const login = '/login';
  static const home = '/';
}

/// Roteador que leva cada estado de autenticação para a tela certa.
final routerProvider = Provider<GoRouter>((ref) {
  final auth = ValueNotifier<AsyncValue<AuthState>>(const AsyncLoading());
  ref
    ..listen(
      authProvider,
      (_, next) => auth.value = next,
      fireImmediately: true,
    )
    ..onDispose(auth.dispose);

  final router = GoRouter(
    initialLocation: Routes.home,
    refreshListenable: auth,
    redirect: (context, state) =>
        redirectFor(auth.value, state.matchedLocation),
    routes: [
      GoRoute(
        path: Routes.startup,
        builder: (context, state) => const StartupPage(),
      ),
      GoRoute(
        path: Routes.setup,
        builder: (context, state) => const SetupPage(),
      ),
      GoRoute(
        path: Routes.login,
        builder: (context, state) => const LoginPage(),
      ),
      GoRoute(
        path: Routes.home,
        builder: (context, state) => const HomePage(),
      ),
    ],
  );
  ref.onDispose(router.dispose);
  return router;
});

/// Para onde ir a partir de [location], ou `null` para ficar.
@visibleForTesting
String? redirectFor(AsyncValue<AuthState> auth, String location) {
  final target = switch (auth) {
    AsyncData(value: NeedsSetup()) => Routes.setup,
    AsyncData(value: SignedOut()) => Routes.login,
    AsyncData(value: SignedIn()) => switch (location) {
        Routes.startup || Routes.setup || Routes.login => Routes.home,
        _ => location,
      },
    _ => Routes.startup,
  };
  return target == location ? null : target;
}
