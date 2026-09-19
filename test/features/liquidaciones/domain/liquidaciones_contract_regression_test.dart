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
        liquidadaPago: false,
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
        liquidadaPago: false,
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
        liquidadaPago: false,
        estado: 'aprobada',
      );

      expect(edited.isAprobadaEstado, isTrue);
      expect(edited.estadoNormalizado, 'aprobada');
    });

    test('reabrir deja estado reabierta, sin aprobar y editable', () {
      // Contrato nuevo del backend: PATCH /liquidaciones/:id/reabrir pone
      // estado=reabierta, aprobado=false y fechaAprobacion=null.
      const beforeReopen = LiquidacionItem(
        id: 'liq-3',
        servicioId: 'srv-3',
        servicioCanal: 'campo',
        tipoSalidaPrecioUsd: 60,
        km: 3,
        precioKmUsdSnapshotLegacy: 0,
        aprobada: true,
        liquidadaPago: false,
        estado: 'aprobada',
        fechaAprobacion: '2026-07-10T14:20:00.000Z',
      );

      const afterReopen = LiquidacionItem(
        id: 'liq-3',
        servicioId: 'srv-3',
        servicioCanal: 'campo',
        tipoSalidaPrecioUsd: 60,
        km: 3,
        precioKmUsdSnapshotLegacy: 0,
        aprobada: false,
        liquidadaPago: false,
        estado: 'reabierta',
        motivoReapertura: 'Faltaba un item de servicio',
        fechaReapertura: '2026-07-12T09:00:00.000Z',
      );

      expect(beforeReopen.isAprobadaEstado, isTrue);
      expect(beforeReopen.isElegibleParaPago, isTrue);

      expect(afterReopen.isReabierta, isTrue);
      expect(afterReopen.isAprobadaEstado, isFalse);
      expect(afterReopen.isPendiente, isFalse);
      expect(afterReopen.estadoNormalizado, 'reabierta');
      expect(afterReopen.isEditable, isTrue);
      expect(afterReopen.fechaAprobacion, isNull);
      expect(afterReopen.motivoReapertura, 'Faltaba un item de servicio');
    });

    test('la reabierta queda fuera del circuito de pago hasta re-aprobarse', () {
      const reabierta = LiquidacionItem(
        id: 'liq-4',
        servicioId: 'srv-4',
        servicioCanal: 'campo',
        tipoSalidaPrecioUsd: 60,
        km: 3,
        precioKmUsdSnapshotLegacy: 0,
        aprobada: false,
        liquidadaPago: false,
        estado: 'reabierta',
        motivoReapertura: 'Km mal cargados',
      );

      const reaprobada = LiquidacionItem(
        id: 'liq-4',
        servicioId: 'srv-4',
        servicioCanal: 'campo',
        tipoSalidaPrecioUsd: 60,
        km: 3,
        precioKmUsdSnapshotLegacy: 0,
        aprobada: true,
        liquidadaPago: false,
        estado: 'aprobada',
        fechaAprobacion: '2026-07-13T10:00:00.000Z',
      );

      expect(reabierta.isElegibleParaPago, isFalse);
      expect(reaprobada.isElegibleParaPago, isTrue);
    });

    test('sin estado en la respuesta, aprobado manda como antes', () {
      // Fallback legacy: si el payload no trae estado, se deriva de aprobado.
      const sinEstado = LiquidacionItem(
        id: 'liq-5',
        servicioId: 'srv-5',
        servicioCanal: 'campo',
        tipoSalidaPrecioUsd: 60,
        km: 3,
        precioKmUsdSnapshotLegacy: 0,
        aprobada: false,
        liquidadaPago: false,
      );

      expect(sinEstado.estadoNormalizado, 'pendiente');
      expect(sinEstado.isReabierta, isFalse);
    });
  });
}
