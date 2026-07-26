import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:web_admin_tecnico/core/api/paged_result.dart';
import 'package:web_admin_tecnico/features/liquidaciones/domain/liquidaciones_repository.dart';
import 'package:web_admin_tecnico/features/liquidaciones/presentation/bloc/liquidaciones_bloc.dart';

void main() {
  group('LiquidacionesBloc regresion', () {
    test('crear liquidacion manual fallback sigue disponible', () async {
      final repository = _FakeLiquidacionesRepository();
      final bloc = LiquidacionesBloc(repository);
      addTearDown(bloc.close);

      final expectation = expectLater(
        bloc.stream,
        emitsThrough(
          predicate<LiquidacionesState>(
            (state) => state is LiquidacionesLoaded && state.message == 'Liquidacion creada correctamente',
          ),
        ),
      );

      bloc.add(
        LiquidacionesCreateRequested(
          input: const CreateLiquidacionInput(servicioId: 'srv-10', km: 120),
        ),
      );

      await expectation.timeout(const Duration(seconds: 2));
      expect(repository.createCalls, 1);
      expect(repository.lastCreateInput?.servicioId, 'srv-10');
      expect(repository.lastCreateInput?.km, 120);
      expect(repository.lastPendientesQuery?.estado, 'pendiente');
    });

    test('aprobar liquidacion mantiene flujo y refresco', () async {
      final repository = _FakeLiquidacionesRepository();
      final bloc = LiquidacionesBloc(repository);
      addTearDown(bloc.close);

      final expectation = expectLater(
        bloc.stream,
        emitsThrough(
          predicate<LiquidacionesState>(
            (state) => state is LiquidacionesLoaded &&
                (state.message?.startsWith('Liquidacion aprobada correctamente') ?? false),
          ),
        ),
      );

      bloc.add(LiquidacionesApproveRequested('liq-1'));

      await expectation.timeout(const Duration(seconds: 2));
      expect(repository.approveCalls, 1);
      expect(repository.lastApprovedLiquidacionId, 'liq-1');
      expect(repository.lastPendientesQuery?.estado, 'pendiente');
    });
  });
}

class _FakeLiquidacionesRepository implements LiquidacionesRepository {
  int createCalls = 0;
  int approveCalls = 0;
  String? lastApprovedLiquidacionId;
  CreateLiquidacionInput? lastCreateInput;
  LiquidacionesPendientesQuery? lastPendientesQuery;

  @override
  Future<PagedResult<LiquidacionItem>> fetchLiquidaciones({
    required LiquidacionesQuery query,
  }) async {
    return const PagedResult<LiquidacionItem>(
      items: <LiquidacionItem>[],
      total: 0,
      page: 1,
      limit: 20,
    );
  }

  @override
  Future<PagedResult<LiquidacionPendienteItem>> fetchLiquidacionesPendientes({
    required LiquidacionesPendientesQuery query,
  }) async {
    lastPendientesQuery = query;
    return const PagedResult<LiquidacionPendienteItem>(
      items: <LiquidacionPendienteItem>[],
      total: 0,
      page: 1,
      limit: 20,
    );
  }

  @override
  Future<LiquidacionItemsResponse?> fetchLiquidacionItems(String liquidacionId) async {
    return const LiquidacionItemsResponse(
      liquidacionId: 'liq-1',
      items: <LiquidacionItemDetalle>[
        LiquidacionItemDetalle(
          id: 'item-1',
          tipoServicioId: 'tipo-1',
          tipoServicioNombre: 'Normal',
          precioUsdSnapshot: 50,
          aprobado: false,
        ),
      ],
      meta: LiquidacionItemsMeta(totalItems: 1, aprobados: 0, pendientes: 1, subtotalUsdTotal: 50),
      remoteEnabled: true,
    );
  }

  @override
  Future<List<TipoSalidaCatalogoItem>> fetchTiposSalida() async {
    return const <TipoSalidaCatalogoItem>[];
  }

  @override
  Future<List<TipoServicioCatalogoItem>> fetchTiposServicio() async {
    return const <TipoServicioCatalogoItem>[
      TipoServicioCatalogoItem(id: 'tipo-1', nombre: 'Normal', precioUsd: 50, activo: true),
    ];
  }

  @override
  Future<void> createLiquidacion({required CreateLiquidacionInput input}) async {
    createCalls += 1;
    lastCreateInput = input;
  }

  @override
  Future<void> updateLiquidacion({required UpdateLiquidacionInput input}) async {}

  @override
  Future<void> approveLiquidacion(String liquidacionId) async {
    approveCalls += 1;
    lastApprovedLiquidacionId = liquidacionId;
  }

  @override
  Future<void> reopenLiquidacion({required ReopenLiquidacionInput input}) async {}

  @override
  Future<LiquidacionReaperturasResponse> fetchLiquidacionReaperturas(String liquidacionId) async {
    return const LiquidacionReaperturasResponse(
      liquidacionId: 'liq-1',
      reaperturas: <LiquidacionReaperturaItem>[],
      total: 0,
    );
  }

  @override
  Future<LiquidacionItemDetalle?> addLiquidacionItem({required AddLiquidacionItemInput input}) async {
    return null;
  }

  @override
  Future<void> approveLiquidacionItem({required ApproveLiquidacionItemInput input}) async {}

  @override
  Future<void> deleteLiquidacionItem({required DeleteLiquidacionItemInput input}) async {}

  @override
  Future<void> createTipoSalida({required CreateTipoSalidaInput input}) async {}

  @override
  Future<void> updateTipoSalida({required UpdateTipoSalidaInput input}) async {}

  @override
  Future<void> createTipoServicio({required CreateTipoServicioInput input}) async {}

  @override
  Future<void> updateTipoServicio({required UpdateTipoServicioInput input}) async {}

  @override
  Future<ResumenPagoPreviewResponse> fetchResumenPagoPreview({
    required ResumenPagoPreviewQuery query,
  }) async {
    return const ResumenPagoPreviewResponse(
      items: <ResumenPagoPreviewItem>[],
      meta: ResumenPagoPreviewMeta(totalLiquidaciones: 0, totalResumenUsd: 0),
    );
  }

  @override
  Future<ResumenPagoPreviewResponse> confirmarResumenPago({
    required ConfirmarResumenPagoInput input,
  }) async {
    return const ResumenPagoPreviewResponse(
      items: <ResumenPagoPreviewItem>[],
      meta: ResumenPagoPreviewMeta(totalLiquidaciones: 0, totalResumenUsd: 0),
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
  Future<UltimoResumenPagoItem?> fetchUltimoResumenPago(String tecnicoId) async => null;

  @override
  Future<ResumenPagoDetalleResponse> fetchResumenPagoDetalle(String resumenId) async {
    return const ResumenPagoDetalleResponse(
      id: 'res-1',
      tecnicoId: 'tec-1',
      tecnicoNombre: 'Tecnico',
      tecnicoEmail: 'tecnico@example.com',
      desde: '2026-07-01T00:00:00.000Z',
      hasta: '2026-07-31T23:59:59.999Z',
      totalLiquidaciones: 0,
      totalUsdSnapshot: 0,
      createdByNombre: 'admin',
      createdAt: '2026-07-31T00:00:00.000Z',
      detalles: <ResumenPagoDetalleItem>[],
    );
  }
}
