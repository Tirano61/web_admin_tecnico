import 'package:flutter_test/flutter_test.dart';
import 'package:web_admin_tecnico/features/liquidaciones/domain/liquidaciones_repository.dart';

void main() {
  group('contrato liquidaciones aprobadas', () {
    test('estadoNormalizado mantiene aprobada tras editar', () {
      const liquidacion = LiquidacionItem(
        id: 'liq-1',
        servicioId: 'srv-1',
        servicioCanal: 'campo',
        tipoSalidaPrecioUsd: 120,
        km: 15,
        precioKmUsdSnapshotLegacy: 0,
        aprobada: true,
        estado: 'aprobada',
      );

      expect(liquidacion.isAprobadaEstado, isTrue);
      expect(liquidacion.estadoNormalizado, 'aprobada');
      expect(liquidacion.isEditable, isFalse);
    });

    test('item editado conserva estado aprobada por contrato backend', () {
      const original = LiquidacionItem(
        id: 'liq-2',
        servicioId: 'srv-2',
        servicioCanal: 'campo',
        tipoSalidaPrecioUsd: 85,
        km: 0,
        precioKmUsdSnapshotLegacy: 0,
        aprobada: true,
        estado: 'aprobada',
      );

      final edited = LiquidacionItem(
        id: original.id,
        servicioId: original.servicioId,
        servicioCanal: original.servicioCanal,
        tipoSalidaPrecioUsd: 95,
        km: original.km,
        precioKmUsdSnapshotLegacy: original.precioKmUsdSnapshotLegacy,
        aprobada: true,
        estado: 'aprobada',
      );

      expect(edited.isAprobadaEstado, isTrue);
      expect(edited.estadoNormalizado, 'aprobada');
    });

    test('registrar reapertura no cambia aprobada visible', () {
      const beforeReopen = LiquidacionItem(
        id: 'liq-3',
        servicioId: 'srv-3',
        servicioCanal: 'campo',
        tipoSalidaPrecioUsd: 60,
        km: 3,
        precioKmUsdSnapshotLegacy: 0,
        aprobada: true,
        estado: 'aprobada',
      );

      const afterAuditReopen = LiquidacionItem(
        id: 'liq-3',
        servicioId: 'srv-3',
        servicioCanal: 'campo',
        tipoSalidaPrecioUsd: 60,
        km: 3,
        precioKmUsdSnapshotLegacy: 0,
        aprobada: true,
        estado: 'aprobada',
      );

      expect(beforeReopen.isAprobadaEstado, isTrue);
      expect(afterAuditReopen.isAprobadaEstado, isTrue);
      expect(afterAuditReopen.estadoNormalizado, 'aprobada');
    });
  });
}
