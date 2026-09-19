import 'package:flutter/material.dart';
import 'package:web_admin_tecnico/core/routing/app_routes.dart';
import 'package:web_admin_tecnico/features/app_shell/domain/app_module.dart';
import 'package:web_admin_tecnico/features/auth/presentation/widgets/session_gate.dart';

class AppRouter {
  /// Toda ruta pasa por `SessionGate`: el acceso lo decide el estado de la
  /// sesion (splash mientras se restaura, panel si es valida, login si no),
  /// nunca la ruta pedida en el navegador.
  Route<dynamic> onGenerateRoute(RouteSettings settings) {
    final route = settings.name ?? AppRoutes.login;

    return MaterialPageRoute<void>(
      settings: settings,
      builder: (_) => SessionGate(modulo: _moduleForRoute(route)),
    );
  }

  AppModule _moduleForRoute(String route) {
    switch (route) {
      case AppRoutes.clientes:
        return AppModule.clientes;
      case AppRoutes.catalogos:
        return AppModule.catalogos;
      case AppRoutes.repuestos:
        return AppModule.repuestos;
      case AppRoutes.precios:
        return AppModule.precios;
      case AppRoutes.liquidaciones:
        return AppModule.liquidaciones;
      case AppRoutes.liquidacionesPagos:
        return AppModule.liquidacionesPagos;
      case AppRoutes.servicios:
      default:
        return AppModule.servicios;
    }
  }
}
