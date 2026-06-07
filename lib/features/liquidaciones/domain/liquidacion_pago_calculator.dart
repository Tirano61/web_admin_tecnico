import 'package:web_admin_tecnico/features/liquidaciones/domain/liquidaciones_repository.dart';

// Regla de negocio: pago tecnico = salida fija + suma de items de tipo servicio.
double calculateLiquidacionTotalTecnicoUsd({
  required double tipoSalidaPrecioUsd,
  required List<LiquidacionItemDetalle> items,
}) {
  final itemsSubtotal = items.fold<double>(
    0,
    (sum, item) => sum + item.precioUsdSnapshot,
  );

  return tipoSalidaPrecioUsd + itemsSubtotal;
}
