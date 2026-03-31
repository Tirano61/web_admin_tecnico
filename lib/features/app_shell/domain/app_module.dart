import 'package:web_admin_tecnico/core/routing/app_routes.dart';

enum AppModule {
  servicios,
  clientes,
  catalogos,
  precios,
  liquidaciones,
}

extension AppModuleX on AppModule {
  String get label {
    switch (this) {
      case AppModule.servicios:
        return 'Servicios';
      case AppModule.clientes:
        return 'Clientes';
      case AppModule.catalogos:
        return 'Catalogos';
      case AppModule.precios:
        return 'Precios';
      case AppModule.liquidaciones:
        return 'Liquidaciones';
    }
  }

  String get route {
    switch (this) {
      case AppModule.servicios:
        return AppRoutes.servicios;
      case AppModule.clientes:
        return AppRoutes.clientes;
      case AppModule.catalogos:
        return AppRoutes.catalogos;
      case AppModule.precios:
        return AppRoutes.precios;
      case AppModule.liquidaciones:
        return AppRoutes.liquidaciones;
    }
  }
}
