import 'package:flutter/material.dart';
import 'package:web_admin_tecnico/core/routing/app_routes.dart';

enum AppModule {
  servicios,
  clientes,
  catalogos,
  repuestos,
  precios,
  liquidaciones,
  liquidacionesPagos,
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
      case AppModule.repuestos:
        return 'Repuestos';
      case AppModule.precios:
        return 'Precios';
      case AppModule.liquidaciones:
        return 'Liquidaciones';
      case AppModule.liquidacionesPagos:
        return 'Pagos';
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
      case AppModule.repuestos:
        return AppRoutes.repuestos;
      case AppModule.precios:
        return AppRoutes.precios;
      case AppModule.liquidaciones:
        return AppRoutes.liquidaciones;
      case AppModule.liquidacionesPagos:
        return AppRoutes.liquidacionesPagos;
    }
  }

  IconData get icon {
    switch (this) {
      case AppModule.servicios:
        return Icons.engineering_outlined;
      case AppModule.clientes:
        return Icons.groups_outlined;
      case AppModule.catalogos:
        return Icons.inventory_2_outlined;
      case AppModule.repuestos:
        return Icons.build_circle_outlined;
      case AppModule.precios:
        return Icons.attach_money_outlined;
      case AppModule.liquidaciones:
        return Icons.receipt_long_outlined;
      case AppModule.liquidacionesPagos:
        return Icons.payments_outlined;
    }
  }

  String get shortDescription {
    switch (this) {
      case AppModule.servicios:
        return 'Ordenes tecnicas, documentos y seguimiento diario.';
      case AppModule.clientes:
        return 'Base de clientes para operaciones y facturacion.';
      case AppModule.catalogos:
        return 'Mantenimiento de zonas, categorias y productos.';
      case AppModule.repuestos:
        return 'Listado, alta y edicion operativa de repuestos.';
      case AppModule.precios:
        return 'Valores vigentes de cotizacion y tarifa km.';
      case AppModule.liquidaciones:
        return 'Gestion de liquidaciones tecnicas e items.';
      case AppModule.liquidacionesPagos:
        return 'Resumenes de pago, confirmacion e historial.';
    }
  }
}
