import 'package:flutter_test/flutter_test.dart';
import 'package:web_admin_tecnico/core/api/paged_result.dart';
import 'package:web_admin_tecnico/core/error/app_failure.dart';
import 'package:web_admin_tecnico/features/liquidaciones/domain/liquidaciones_repository.dart';
import 'package:web_admin_tecnico/features/liquidaciones/presentation/bloc/liquidacion_items_cache.dart';
import 'package:web_admin_tecnico/features/liquidaciones/presentation/bloc/liquidaciones_pagos_cubit.dart';

void main() {
  group('LiquidacionesPagosCubit items', () {
    test('carga los items una sola vez y los cachea', () async {
      final repository = _FakeRepository();
      final cubit = LiquidacionesPagosCubit(repository);

      await cubit.ensureLiquidacionItems('liq-1');
      await cubit.ensureLiquidacionItems('liq-1');

      final entry = cubit.state.itemsByLiquidacion['liq-1'];
      expect(entry?.status, LiquidacionItemsLoadStatus.loaded);
      expect(entry?.response?.items.single.tipoServicioNombre, 'Instalacion');
      expect(repository.itemsCalls, 1);
    });

    test('respuesta null queda unavailable y se puede reintentar', () async {
      // Regresion: antes el null se cacheaba como si fuera exito y la vista
      // quedaba colgada sin forma de reintentar.
      final repository = _FakeRepository(
        itemsQueue: <LiquidacionItemsResponse?>[null, _itemsResponse()],
      );
      final cubit = LiquidacionesPagosCubit(repository);

      await cubit.ensureLiquidacionItems('liq-1');
      expect(
        cubit.state.itemsByLiquidacion['liq-1']?.status,
        LiquidacionItemsLoadStatus.unavailable,
      );
      expect(cubit.state.itemsByLiquidacion['liq-1']?.canRetry, isTrue);

      await cubit.ensureLiquidacionItems('liq-1');
      expect(repository.itemsCalls, 2);
      expect(
        cubit.state.itemsByLiquidacion['liq-1']?.status,
        LiquidacionItemsLoadStatus.loaded,
      );
    });

    test('error queda registrado y el reintento vuelve a pedir', () async {
      final repository = _FakeRepository(
        itemsError: const AppFailure('boom', statusCode: 500),
      );
      final cubit = LiquidacionesPagosCubit(repository);

      await cubit.ensureLiquidacionItems('liq-1');
      final entry = cubit.state.itemsByLiquidacion['liq-1'];
      expect(entry?.status, LiquidacionItemsLoadStatus.error);
      expect(entry?.error, 'boom');

      await cubit.ensureLiquidacionItems('liq-1');
      expect(repository.itemsCalls, 2);
    });

    test('dos cargas concurrentes disparan un solo request', () async {
      final repository = _FakeRepository(delay: const Duration(milliseconds: 20));
      final cubit = LiquidacionesPagosCubit(repository);

      await Future.wait(<Future<void>>[
        cubit.ensureLiquidacionItems('liq-1'),
        cubit.ensureLiquidacionItems('liq-1'),
      ]);

      expect(repository.itemsCalls, 1);
    });

    test('un preview nuevo limpia cache y expandidos', () async {
      final repository = _FakeRepository();
      final cubit = LiquidacionesPagosCubit(repository);

      await cubit.ensureLiquidacionItems('liq-1');
      cubit.toggleExpanded('liq-1', true);
      expect(cubit.state.itemsByLiquidacion, isNotEmpty);
      expect(cubit.state.expandedLiquidacionIds, isNotEmpty);

      cubit.updateFilters(
        tecnicoId: 'tec-1',
        desde: '2026-07-01',
        hasta: '2026-07-31',
      );
      await cubit.previewResumen();

      expect(cubit.state.itemsByLiquidacion, isEmpty);
      expect(cubit.state.expandedLiquidacionIds, isEmpty);
    });
  });

  group('LiquidacionesPagosCubit reabiertas', () {
    test('el preview trae aparte las reabiertas del tecnico', () async {
      // El backend las excluye del resumen: sin este listado el admin solo ve
      // que la fila desaparecio.
      final repository = _FakeRepository(
        reabiertas: <LiquidacionItem>[_reabierta()],
      );
      final cubit = LiquidacionesPagosCubit(repository);

      cubit.updateFilters(
        tecnicoId: 'tec-1',
        desde: '2026-07-01',
        hasta: '2026-07-31',
      );
      await cubit.previewResumen();

      expect(cubit.state.reabiertas, hasLength(1));
      expect(cubit.state.reabiertas.single.motivoReapertura, 'Km mal cargados');
      expect(cubit.state.loadingReabiertas, isFalse);

      final query = repository.lastLiquidacionesQuery;
      expect(query?.tecnicoId, 'tec-1');
      expect(query?.estado, 'reabierta');
      expect(query?.liquidadaPago, isFalse);
      // Al reabrirse pierden fechaAprobacion: no pertenecen a ningun periodo.
      expect(query?.aprobado, isNull);
    });

    test('si el listado de reabiertas falla el preview igual queda', () async {
      final repository = _FakeRepository(
        reabiertasError: const AppFailure('boom', statusCode: 500),
      );
      final cubit = LiquidacionesPagosCubit(repository);

      cubit.updateFilters(
        tecnicoId: 'tec-1',
        desde: '2026-07-01',
        hasta: '2026-07-31',
      );
      await cubit.previewResumen();

      expect(cubit.state.reabiertas, isEmpty);
      expect(cubit.state.previewItems, hasLength(2));
      expect(cubit.state.error, isNull);
    });
  });

  group('LiquidacionesPagosCubit seleccion', () {
    test('toggleSelectAll selecciona y limpia todo el preview', () async {
      final repository = _FakeRepository();
      final cubit = LiquidacionesPagosCubit(repository);

      cubit.updateFilters(
        tecnicoId: 'tec-1',
        desde: '2026-07-01',
        hasta: '2026-07-31',
      );
      await cubit.previewResumen();

      cubit.toggleSelectAll(true);
      expect(cubit.state.selectedLiquidacionIds, <String>{'liq-1', 'liq-2'});
      expect(cubit.state.allPreviewSelected, isTrue);
      expect(cubit.state.somePreviewSelected, isFalse);

      cubit.toggleSelected('liq-1', false);
      expect(cubit.state.allPreviewSelected, isFalse);
      expect(cubit.state.somePreviewSelected, isTrue);

      cubit.toggleSelectAll(false);
      expect(cubit.state.selectedLiquidacionIds, isEmpty);
      expect(cubit.state.allPreviewSelected, isFalse);
      expect(cubit.state.somePreviewSelected, isFalse);
    });
  });
}

LiquidacionItem _reabierta() {
  return const LiquidacionItem(
    id: 'liq-9',
    servicioId: 'srv-9',
    servicioCanal: 'campo',
    tipoSalidaPrecioUsd: 80,
    km: 40,
    precioKmUsdSnapshotLegacy: 0,
    aprobada: false,
    liquidadaPago: false,
    estado: 'reabierta',
    clienteNombre: 'Agro SRL',
    tipoSalidaNombre: 'Media distancia',
    motivoReapertura: 'Km mal cargados',
    fechaReapertura: '2026-07-12T09:00:00.000Z',
  );
}

LiquidacionItemsResponse _itemsResponse() {
  return const LiquidacionItemsResponse(
    liquidacionId: 'liq-1',
    items: <LiquidacionItemDetalle>[
      LiquidacionItemDetalle(
        id: 'item-1',
        tipoServicioId: 'ts-1',
        tipoServicioNombre: 'Instalacion',
        precioUsdSnapshot: 120.5,
        aprobado: true,
      ),
    ],
    meta: LiquidacionItemsMeta(
      totalItems: 1,
      aprobados: 1,
      pendientes: 0,
      subtotalUsdTotal: 120.5,
    ),
    remoteEnabled: true,
    tipoSalidaNombre: 'Visita normal',
  );
}

class _FakeRepository implements LiquidacionesRepository {
  _FakeRepository({
    List<LiquidacionItemsResponse?>? itemsQueue,
    this.itemsError,
    this.delay,
    this.reabiertas,
    this.reabiertasError,
  }) : _itemsQueue = itemsQueue;

  final List<LiquidacionItemsResponse?>? _itemsQueue;
  final AppFailure? itemsError;
  final Duration? delay;
  final List<LiquidacionItem>? reabiertas;
  final Object? reabiertasError;

  int itemsCalls = 0;
  LiquidacionesQuery? lastLiquidacionesQuery;

  @override
  Future<LiquidacionItemsResponse?> fetchLiquidacionItems(
    String liquidacionId,
  ) async {
    itemsCalls += 1;
    if (delay != null) {
      await Future<void>.delayed(delay!);
    }
    if (itemsError != null) {
      throw itemsError!;
    }
    final queue = _itemsQueue;
    if (queue == null) {
      return _itemsResponse();
    }
    final index =
        itemsCalls - 1 >= queue.length ? queue.length - 1 : itemsCalls - 1;
    return queue[index];
  }

  @override
  Future<ResumenPagoPreviewResponse> fetchResumenPagoPreview({
    required ResumenPagoPreviewQuery query,
  }) async {
    return const ResumenPagoPreviewResponse(
      items: <ResumenPagoPreviewItem>[
        ResumenPagoPreviewItem(
          id: 'liq-1',
          servicioId: 'srv-1',
          totalLiquidacionUsd: 200.5,
        ),
        ResumenPagoPreviewItem(
          id: 'liq-2',
          servicioId: 'srv-2',
          totalLiquidacionUsd: 140,
        ),
      ],
      meta: ResumenPagoPreviewMeta(
        totalLiquidaciones: 2,
        totalResumenUsd: 340.5,
      ),
    );
  }

  @override
  Future<ResumenPagoPreviewResponse> confirmarResumenPago({
    required ConfirmarResumenPagoInput input,
  }) async =>
      throw UnimplementedError();

  @override
  Future<PagedResult<ResumenPagoHistorialItem>> fetchResumenesPago({
    required ResumenesPagoQuery query,
  }) async =>
      throw UnimplementedError();

  @override
  Future<PagedResult<TecnicoListadoItem>> fetchTecnicosListado({
    required TecnicosListadoQuery query,
  }) async =>
      throw UnimplementedError();

  @override
  Future<UltimoResumenPagoItem?> fetchUltimoResumenPago(String tecnicoId) async =>
      throw UnimplementedError();

  @override
  Future<ResumenPagoDetalleResponse> fetchResumenPagoDetalle(
    String resumenId,
  ) async =>
      throw UnimplementedError();

  @override
  Future<PagedResult<LiquidacionItem>> fetchLiquidaciones({
    required LiquidacionesQuery query,
  }) async {
    lastLiquidacionesQuery = query;
    if (reabiertasError != null) {
      throw reabiertasError!;
    }
    final items = reabiertas;
    if (items == null) {
      throw UnimplementedError();
    }
    return PagedResult<LiquidacionItem>(
      items: items,
      total: items.length,
      page: 1,
      limit: 50,
    );
  }

  @override
  Future<PagedResult<LiquidacionPendienteItem>> fetchLiquidacionesPendientes({
    required LiquidacionesPendientesQuery query,
  }) async =>
      throw UnimplementedError();

  @override
  Future<List<TipoSalidaCatalogoItem>> fetchTiposSalida() async =>
      throw UnimplementedError();

  @override
  Future<List<TipoServicioCatalogoItem>> fetchTiposServicio() async =>
      throw UnimplementedError();

  @override
  Future<void> createLiquidacion({required CreateLiquidacionInput input}) async =>
      throw UnimplementedError();

  @override
  Future<void> updateLiquidacion({required UpdateLiquidacionInput input}) async =>
      throw UnimplementedError();

  @override
  Future<void> approveLiquidacion(String liquidacionId) async =>
      throw UnimplementedError();

  @override
  Future<void> reopenLiquidacion({required ReopenLiquidacionInput input}) async =>
      throw UnimplementedError();

  @override
  Future<LiquidacionReaperturasResponse> fetchLiquidacionReaperturas(
    String liquidacionId,
  ) async =>
      throw UnimplementedError();

  @override
  Future<LiquidacionItemDetalle?> addLiquidacionItem({
    required AddLiquidacionItemInput input,
  }) async =>
      throw UnimplementedError();

  @override
  Future<void> approveLiquidacionItem({
    required ApproveLiquidacionItemInput input,
  }) async =>
      throw UnimplementedError();

  @override
  Future<void> deleteLiquidacionItem({
    required DeleteLiquidacionItemInput input,
  }) async =>
      throw UnimplementedError();

  @override
  Future<void> createTipoSalida({required CreateTipoSalidaInput input}) async =>
      throw UnimplementedError();

  @override
  Future<void> updateTipoSalida({required UpdateTipoSalidaInput input}) async =>
      throw UnimplementedError();

  @override
  Future<void> createTipoServicio({required CreateTipoServicioInput input}) async =>
      throw UnimplementedError();

  @override
  Future<void> updateTipoServicio({required UpdateTipoServicioInput input}) async =>
      throw UnimplementedError();
}
