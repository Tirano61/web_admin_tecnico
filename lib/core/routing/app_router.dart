import 'package:flutter/material.dart';
import 'package:web_admin_tecnico/core/auth/session_store.dart';
import 'package:web_admin_tecnico/core/routing/app_routes.dart';
import 'package:web_admin_tecnico/features/app_shell/domain/app_module.dart';
import 'package:web_admin_tecnico/features/app_shell/presentation/pages/app_shell_page.dart';
import 'package:web_admin_tecnico/features/auth/presentation/pages/login_page.dart';

class AppRouter {
  Route<dynamic> onGenerateRoute(RouteSettings settings) {
    final route = settings.name ?? AppRoutes.login;

    if (route == AppRoutes.login) {
      return MaterialPageRoute<void>(builder: (_) => const LoginPage());
    }

    if (!SessionStore.isAuthenticated) {
      return MaterialPageRoute<void>(builder: (_) => const LoginPage());
    }

    switch (route) {
      case AppRoutes.servicios:
        return _shellRoute(AppModule.servicios);
      case AppRoutes.clientes:
        return _shellRoute(AppModule.clientes);
      case AppRoutes.catalogos:
        return _shellRoute(AppModule.catalogos);
      case AppRoutes.repuestos:
        return _shellRoute(AppModule.repuestos);
      case AppRoutes.precios:
        return _shellRoute(AppModule.precios);
      case AppRoutes.liquidaciones:
        return _shellRoute(AppModule.liquidaciones);
      default:
        return MaterialPageRoute<void>(builder: (_) => const LoginPage());
    }
  }

  MaterialPageRoute<void> _shellRoute(AppModule module) {
    return MaterialPageRoute<void>(
      builder: (_) => AppShellPage(initialModule: module),
    );
  }
}
