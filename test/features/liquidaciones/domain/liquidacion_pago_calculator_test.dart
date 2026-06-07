import 'package:flutter_test/flutter_test.dart';
import 'package:web_admin_tecnico/features/liquidaciones/domain/liquidacion_pago_calculator.dart';
import 'package:web_admin_tecnico/features/liquidaciones/domain/liquidaciones_repository.dart';

void main() {
  group('calculateLiquidacionTotalTecnicoUsd', () {
    test('retorna solo salida fija cuando no hay items', () {
      final total = calculateLiquidacionTotalTecnicoUsd(
        tipoSalidaPrecioUsd: 85,
        items: const <LiquidacionItemDetalle>[],
      );

      expect(total, 85);
    });

    test('suma salida fija mas items de servicio', () {
      final total = calculateLiquidacionTotalTecnicoUsd(
        tipoSalidaPrecioUsd: 100,
        items: const <LiquidacionItemDetalle>[
          LiquidacionItemDetalle(
            id: '1',
            tipoServicioId: 'a',
            tipoServicioNombre: 'Servicio A',
            precioUsdSnapshot: 40,
            aprobado: false,
          ),
          LiquidacionItemDetalle(
            id: '2',
            tipoServicioId: 'b',
            tipoServicioNombre: 'Servicio B',
            precioUsdSnapshot: 15.5,
            aprobado: true,
          ),
        ],
      );

      expect(total, 155.5);
    });

    test('ignora completamente cualquier metrica de KM legacy', () {
      final liquidacion = LiquidacionItem(
        id: 'liq-1',
        servicioId: 'srv-1',
        servicioCanal: 'campo',
        tipoSalidaPrecioUsd: 120,
        km: 999,
        precioKmUsdSnapshotLegacy: 999,
        aprobada: false,
      );

      final total = calculateLiquidacionTotalTecnicoUsd(
        tipoSalidaPrecioUsd: liquidacion.tipoSalidaPrecioUsd,
        items: const <LiquidacionItemDetalle>[
          LiquidacionItemDetalle(
            id: 'x',
            tipoServicioId: 'ts-1',
            tipoServicioNombre: 'Extra',
            precioUsdSnapshot: 10,
            aprobado: false,
          ),
        ],
      );

      expect(total, 130);
    });
  });
}
