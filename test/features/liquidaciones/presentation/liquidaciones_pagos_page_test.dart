import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:web_admin_tecnico/core/api/paged_result.dart';
import 'package:web_admin_tecnico/core/error/app_failure.dart';
import 'package:web_admin_tecnico/features/liquidaciones/domain/liquidaciones_repository.dart';
import 'package:web_admin_tecnico/features/liquidaciones/presentation/pages/liquidaciones_pagos_page.dart';

void main() {
  group('LiquidacionesPagosPage', () {
    testWidgets('confirmar deshabilitado sin seleccion', (tester) async {
      await _setDesktopSurface(tester);
      final repository = _FakeLiquidacionesRepository();

      await tester.pumpWidget(_testApp(repository));
      await tester.pumpAndSettle();

      await _fillFiltersAndPreview(tester);

      final confirmButton = tester.widget<FilledButton>(_confirmButtonFinder());
      expect(confirmButton.onPressed, isNull);
    });

    testWidgets('confirmacion exitosa limpia seleccion y refresca preview', (tester) async {
      await _setDesktopSurface(tester);
      final repository = _FakeLiquidacionesRepository();

      await tester.pumpWidget(_testApp(repository));
      await tester.pumpAndSettle();

      await _fillFiltersAndPreview(tester);
      await tester.tap(find.byType(Checkbox).first);
      await tester.pumpAndSettle();

      final enabledButton = tester.widget<FilledButton>(_confirmButtonFinder());
      expect(enabledButton.onPressed, isNotNull);

      await tester.tap(_confirmButtonFinder());
      await tester.pumpAndSettle();

      expect(repository.confirmCalls, 1);
      expect(repository.previewCalls, 2);
      expect(find.text('Seleccionadas 0'), findsOneWidget);
      expect(find.textContaining('Resumen confirmado.'), findsOneWidget);
    });

    testWidgets('error de elegibilidad muestra mensaje y refresca lista', (tester) async {
      await _setDesktopSurface(tester);
      final repository = _FakeLiquidacionesRepository(
        confirmError: const AppFailure('No elegible para pago', statusCode: 409),
      );

      await tester.pumpWidget(_testApp(repository));
      await tester.pumpAndSettle();

      await _fillFiltersAndPreview(tester);
      await tester.tap(find.byType(Checkbox).first);
      await tester.pumpAndSettle();

      await tester.tap(_confirmButtonFinder());
      await tester.pumpAndSettle();

      expect(repository.confirmCalls, 1);
      expect(repository.previewCalls, 2);
      expect(
        find.text('Algunas liquidaciones ya no son elegibles; actualizamos la lista.'),
        findsOneWidget,
      );
    });
  });
}

Future<void> _setDesktopSurface(WidgetTester tester) async {
  await tester.binding.setSurfaceSize(const Size(1800, 1200));
  addTearDown(() async {
    await tester.binding.setSurfaceSize(null);
  });
}

Widget _testApp(LiquidacionesRepository repository) {
  return MediaQuery(
    data: const MediaQueryData(
      size: Size(1800, 1200),
      textScaler: TextScaler.linear(1),
    ),
    child: MaterialApp(
      home: Scaffold(
        body: LiquidacionesPagosPage(repository: repository),
      ),
    ),
  );
}

Finder _confirmButtonFinder() =>
    find.widgetWithText(FilledButton, 'Confirmar resumen de pago');

Future<void> _fillFiltersAndPreview(WidgetTester tester) async {
  await tester.enterText(
    find.widgetWithText(TextField, 'Tecnico ID (obligatorio)'),
    'tec-1',
  );

  await tester.enterText(
    find.widgetWithText(TextField, 'Desde (YYYY-MM-DD)'),
    '2026-07-01',
  );
  await tester.enterText(
    find.widgetWithText(TextField, 'Hasta (YYYY-MM-DD)'),
    '2026-07-31',
  );

  await tester.tap(find.widgetWithText(FilledButton, 'Previsualizar resumen'));
  await tester.pumpAndSettle();
}

class _FakeLiquidacionesRepository implements LiquidacionesRepository {
  _FakeLiquidacionesRepository({
    this.confirmError,
  });

  final AppFailure? confirmError;
  int previewCalls = 0;
  int confirmCalls = 0;

  @override
  Future<PagedResult<TecnicoListadoItem>> fetchTecnicosListado({
    required TecnicosListadoQuery query,
  }) async {
    return const PagedResult<TecnicoListadoItem>(
      items: <TecnicoListadoItem>[],
      total: 0,
      page: 1,
      limit: 20,
    );
  }

  @override
  Future<ResumenPagoPreviewResponse> fetchResumenPagoPreview({
    required ResumenPagoPreviewQuery query,
  }) async {
    previewCalls += 1;
    return const ResumenPagoPreviewResponse(
      items: <ResumenPagoPreviewItem>[
        ResumenPagoPreviewItem(
          id: 'liq-1',
          servicioId: 'srv-1',
          fechaAprobacion: '2026-07-10T14:20:00.000Z',
          subtotalSalidaUsd: 80,
          subtotalItemsUsd: 120.5,
          totalLiquidacionUsd: 200.5,
        ),
      ],
      meta: ResumenPagoPreviewMeta(totalLiquidaciones: 1, totalResumenUsd: 200.5),
    );
  }

  @override
  Future<ResumenPagoPreviewResponse> confirmarResumenPago({
    required ConfirmarResumenPagoInput input,
  }) async {
    confirmCalls += 1;
    if (confirmError != null) {
      throw confirmError!;
    }

    return const ResumenPagoPreviewResponse(
      items: <ResumenPagoPreviewItem>[
        ResumenPagoPreviewItem(
          id: 'liq-1',
          servicioId: 'srv-1',
          fechaAprobacion: '2026-07-10T14:20:00.000Z',
          subtotalSalidaUsd: 80,
          subtotalItemsUsd: 120.5,
          totalLiquidacionUsd: 200.5,
        ),
      ],
      meta: ResumenPagoPreviewMeta(totalLiquidaciones: 1, totalResumenUsd: 200.5),
      confirmacion: ResumenPagoConfirmacion(
        updated: 1,
        resumenPagoId: null,
        fechaLiquidadaPago: '2026-07-31T18:45:00.000Z',
      ),
    );
  }

  @override
  Future<PagedResult<ResumenPagoHistorialItem>> fetchResumenesPago({
    required ResumenesPagoQuery query,
  }) async {
    return const PagedResult<ResumenPagoHistorialItem>(
      items: <ResumenPagoHistorialItem>[],
      total: 0,
      page: 1,
      limit: 20,
    );
  }

  @override
  Future<UltimoResumenPagoItem?> fetchUltimoResumenPago(String tecnicoId) async =>
      const UltimoResumenPagoItem(
        id: 'res-1',
        desde: '2026-07-01T00:00:00.000Z',
        hasta: '2026-07-31T23:59:59.999Z',
        totalLiquidaciones: 1,
        totalUsdSnapshot: 200.5,
        createdAt: '2026-07-31T18:45:00.000Z',
      );

  @override
  Future<ResumenPagoDetalleResponse> fetchResumenPagoDetalle(String resumenId) async {
    return const ResumenPagoDetalleResponse(
      id: 'res-1',
      tecnicoId: 'tec-1',
      tecnicoNombre: 'Juan Perez',
      tecnicoEmail: 'juan@example.com',
      desde: '2026-07-01T00:00:00.000Z',
      hasta: '2026-07-31T23:59:59.999Z',
      totalLiquidaciones: 1,
      totalUsdSnapshot: 200.5,
      createdByNombre: 'Admin Tecnico',
      createdAt: '2026-07-31T18:45:00.000Z',
      detalles: <ResumenPagoDetalleItem>[
        ResumenPagoDetalleItem(
          id: 'det-1',
          liquidacionId: 'liq-1',
          servicioId: 'srv-1',
          fechaAprobacionSnapshot: '2026-07-10T14:20:00.000Z',
          subtotalSalidaUsdSnapshot: 80,
          subtotalItemsUsdSnapshot: 120.5,
          totalLiquidacionUsdSnapshot: 200.5,
        ),
      ],
    );
  }

  @override
  Future<PagedResult<LiquidacionItem>> fetchLiquidaciones({
    required LiquidacionesQuery query,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<PagedResult<LiquidacionPendienteItem>> fetchLiquidacionesPendientes({
    required LiquidacionesPendientesQuery query,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<LiquidacionItemsResponse?> fetchLiquidacionItems(String liquidacionId) async {
    throw UnimplementedError();
  }

  @override
  Future<List<TipoSalidaCatalogoItem>> fetchTiposSalida() async {
    throw UnimplementedError();
  }

  @override
  Future<List<TipoServicioCatalogoItem>> fetchTiposServicio() async {
    throw UnimplementedError();
  }

  @override
  Future<void> createLiquidacion({required CreateLiquidacionInput input}) async {
    throw UnimplementedError();
  }

  @override
  Future<void> updateLiquidacion({required UpdateLiquidacionInput input}) async {
    throw UnimplementedError();
  }

  @override
  Future<void> approveLiquidacion(String liquidacionId) async {
    throw UnimplementedError();
  }

  @override
  Future<void> reopenLiquidacion({required ReopenLiquidacionInput input}) async {
    throw UnimplementedError();
  }

  @override
  Future<LiquidacionReaperturasResponse> fetchLiquidacionReaperturas(String liquidacionId) async {
    throw UnimplementedError();
  }

  @override
  Future<LiquidacionItemDetalle?> addLiquidacionItem({required AddLiquidacionItemInput input}) async {
    throw UnimplementedError();
  }

  @override
  Future<void> approveLiquidacionItem({required ApproveLiquidacionItemInput input}) async {
    throw UnimplementedError();
  }

  @override
  Future<void> deleteLiquidacionItem({required DeleteLiquidacionItemInput input}) async {
    throw UnimplementedError();
  }

  @override
  Future<void> createTipoSalida({required CreateTipoSalidaInput input}) async {
    throw UnimplementedError();
  }

  @override
  Future<void> updateTipoSalida({required UpdateTipoSalidaInput input}) async {
    throw UnimplementedError();
  }

  @override
  Future<void> createTipoServicio({required CreateTipoServicioInput input}) async {
    throw UnimplementedError();
  }

  @override
  Future<void> updateTipoServicio({required UpdateTipoServicioInput input}) async {
    throw UnimplementedError();
  }
}
