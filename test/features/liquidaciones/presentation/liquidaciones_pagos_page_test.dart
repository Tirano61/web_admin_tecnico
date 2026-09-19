import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:web_admin_tecnico/core/api/paged_result.dart';
import 'package:web_admin_tecnico/core/error/app_failure.dart';
import 'package:web_admin_tecnico/features/liquidaciones/domain/liquidaciones_repository.dart';
import 'package:web_admin_tecnico/features/liquidaciones/presentation/pages/liquidaciones_pagos_page.dart';

void main() {
  group('LiquidacionesPagosPage', () {
    testWidgets('avisa las reabiertas que quedaron fuera del resumen', (tester) async {
      // Sin este aviso la liquidacion solo desaparece de la lista y el admin no
      // sabe por que no puede pagarla.
      await _setDesktopSurface(tester);
      final repository = _FakeLiquidacionesRepository(
        reabiertas: <LiquidacionItem>[_reabierta()],
      );

      await tester.pumpWidget(_testApp(repository));
      await tester.pumpAndSettle();
      await _fillFiltersAndPreview(tester);

      expect(
        find.byKey(const ValueKey<String>('aviso-reabiertas-fuera-de-pago')),
        findsOneWidget,
      );
      expect(find.text('Reabiertas 1'), findsOneWidget);
      expect(find.textContaining('Km mal cargados'), findsOneWidget);
      expect(find.textContaining('Campo Norte SA'), findsOneWidget);
      expect(find.textContaining('hasta volver a aprobarlas'), findsOneWidget);
    });

    testWidgets('resumen vacio por reaperturas lo explica en el vacio', (tester) async {
      await _setDesktopSurface(tester);
      final repository = _FakeLiquidacionesRepository(
        previewVacio: true,
        reabiertas: <LiquidacionItem>[_reabierta()],
      );

      await tester.pumpWidget(_testApp(repository));
      await tester.pumpAndSettle();
      await _fillFiltersAndPreview(tester);

      expect(
        find.textContaining('las reabiertas listadas arriba no entran'),
        findsOneWidget,
      );
    });

    testWidgets('sin reabiertas no aparece el aviso', (tester) async {
      await _setDesktopSurface(tester);
      final repository = _FakeLiquidacionesRepository();

      await tester.pumpWidget(_testApp(repository));
      await tester.pumpAndSettle();
      await _fillFiltersAndPreview(tester);

      expect(
        find.byKey(const ValueKey<String>('aviso-reabiertas-fuera-de-pago')),
        findsNothing,
      );
    });

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
      await tester.tap(find.byKey(const ValueKey<String>('preview-check-liq-1')));
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
      await tester.tap(find.byKey(const ValueKey<String>('preview-check-liq-1')));
      await tester.pumpAndSettle();

      await tester.tap(_confirmButtonFinder());
      await tester.pumpAndSettle();

      expect(repository.confirmCalls, 1);
      expect(repository.previewCalls, 2);
      expect(
        find.text(
          'Algunas liquidaciones ya no son elegibles (pueden haberse reabierto); '
          'actualizamos la lista.',
        ),
        findsOneWidget,
      );
    });

    testWidgets('la grilla muestra el cliente y no los uuid', (tester) async {
      await _setDesktopSurface(tester);
      final repository = _FakeLiquidacionesRepository();

      await tester.pumpWidget(_testApp(repository));
      await tester.pumpAndSettle();
      await _fillFiltersAndPreview(tester);

      expect(find.text('Agro SRL'), findsOneWidget);
      // Los ids salieron de la grilla: solo estan dentro del panel expandido.
      expect(find.text('Liq liq-1'), findsNothing);
      expect(find.text('Srv srv-1'), findsNothing);
    });

    testWidgets('muestra el tipo de salida sin tener que expandir',
        (tester) async {
      // El endpoint de resumen no manda el tipo de salida y el de items no lo
      // garantiza: lo resuelve la capa data contra GET /liquidaciones, asi que
      // tiene que verse en la grilla antes de cualquier expansion.
      await _setDesktopSurface(tester);
      final repository = _FakeLiquidacionesRepository();

      await tester.pumpWidget(_testApp(repository));
      await tester.pumpAndSettle();
      await _fillFiltersAndPreview(tester);

      expect(find.text('Media distancia'), findsOneWidget);
      expect(repository.itemsCalls, 0);
    });

    testWidgets('si no se resuelve el tipo de salida cae al del endpoint de items',
        (tester) async {
      // Degradacion: sin nombre en el listado, la fila muestra '-' pero al
      // expandir aparece lo que si devuelva el endpoint de items.
      await _setDesktopSurface(tester);
      final repository = _FakeLiquidacionesRepository(tipoSalidaNombre: null);

      await tester.pumpWidget(_testApp(repository));
      await tester.pumpAndSettle();
      await _fillFiltersAndPreview(tester);

      expect(find.text('Media distancia'), findsNothing);
      expect(find.text('-'), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey<String>('preview-row-liq-1')));
      await tester.pumpAndSettle();

      expect(find.text('Visita normal'), findsOneWidget);
    });

    testWidgets('en pantalla angosta usa tarjetas en vez de la grilla',
        (tester) async {
      await _setSurface(tester, const Size(600, 900));
      final repository = _FakeLiquidacionesRepository();

      await tester.pumpWidget(_testApp(repository, size: const Size(600, 900)));
      await tester.pumpAndSettle();
      await _fillFiltersAndPreview(tester);

      // Sin grilla horizontal, la info sigue estando y no hay overflow.
      expect(find.byType(Card), findsWidgets);
      expect(find.text('Agro SRL'), findsOneWidget);
      expect(find.textContaining('Salida Media distancia'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('sin cliente resuelto la grilla lo marca como sin dato',
        (tester) async {
      // El backend no manda cliente y la hidratacion es best-effort: la fila
      // tiene que seguir siendo aprobable aunque el nombre no se resuelva.
      await _setDesktopSurface(tester);
      final repository = _FakeLiquidacionesRepository(clienteNombre: null);

      await tester.pumpWidget(_testApp(repository));
      await tester.pumpAndSettle();
      await _fillFiltersAndPreview(tester);

      expect(find.text('Sin dato'), findsOneWidget);
      expect(find.text('200.50'), findsOneWidget);
    });

    testWidgets('expandir una fila muestra tipo de salida e items', (tester) async {
      await _setDesktopSurface(tester);
      final repository = _FakeLiquidacionesRepository();

      await tester.pumpWidget(_testApp(repository));
      await tester.pumpAndSettle();
      await _fillFiltersAndPreview(tester);

      expect(find.text('Instalacion'), findsNothing);

      await tester.tap(find.byKey(const ValueKey<String>('preview-row-liq-1')));
      await tester.pumpAndSettle();

      expect(repository.itemsCalls, 1);
      expect(find.text('Instalacion'), findsOneWidget);
      expect(find.textContaining('Total liquidacion USD 200.50'), findsOneWidget);
    });

    testWidgets('items no disponibles ofrece reintentar', (tester) async {
      // Regresion del bug: una respuesta null dejaba la fila colgada sin forma
      // de volver a pedir el detalle.
      await _setDesktopSurface(tester);
      final repository = _FakeLiquidacionesRepository(
        itemsQueue: <LiquidacionItemsResponse?>[
          null,
          _FakeLiquidacionesRepository.itemsResponse(),
        ],
      );

      await tester.pumpWidget(_testApp(repository));
      await tester.pumpAndSettle();
      await _fillFiltersAndPreview(tester);

      await tester.tap(find.byKey(const ValueKey<String>('preview-row-liq-1')));
      await tester.pumpAndSettle();

      expect(
        find.text('El detalle de items no esta disponible en este momento.'),
        findsOneWidget,
      );

      await tester.tap(find.widgetWithText(FilledButton, 'Reintentar'));
      await tester.pumpAndSettle();

      expect(repository.itemsCalls, 2);
      expect(find.text('Instalacion'), findsOneWidget);
    });

    testWidgets('muestra los totales del resumen y permite seleccionar todo',
        (tester) async {
      await _setDesktopSurface(tester);
      final repository = _FakeLiquidacionesRepository();

      await tester.pumpWidget(_testApp(repository));
      await tester.pumpAndSettle();
      await _fillFiltersAndPreview(tester);

      expect(find.text('Elegibles 1'), findsOneWidget);
      expect(find.text('Total resumen USD 200.50'), findsOneWidget);
      expect(find.text('Seleccionadas 0 de 1'), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey<String>('preview-check-all')));
      await tester.pumpAndSettle();
      expect(find.text('Seleccionadas 1 de 1'), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey<String>('preview-check-all')));
      await tester.pumpAndSettle();
      expect(find.text('Seleccionadas 0 de 1'), findsOneWidget);
    });
  });
}

Future<void> _setDesktopSurface(WidgetTester tester) =>
    _setSurface(tester, const Size(1800, 1200));

Future<void> _setSurface(WidgetTester tester, Size size) async {
  await tester.binding.setSurfaceSize(size);
  addTearDown(() async {
    await tester.binding.setSurfaceSize(null);
  });
}

Widget _testApp(
  LiquidacionesRepository repository, {
  Size size = const Size(1800, 1200),
}) {
  return MediaQuery(
    data: MediaQueryData(
      size: size,
      textScaler: const TextScaler.linear(1),
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
    clienteNombre: 'Campo Norte SA',
    tipoSalidaNombre: 'Larga distancia',
    motivoReapertura: 'Km mal cargados',
    fechaReapertura: '2026-07-12T09:00:00.000Z',
  );
}

// Los campos de fecha son readOnly y abren un date picker al tocarlos, asi que
// no aceptan enterText. Aceptamos el initialDate: la validacion del cubit solo
// exige que desde/hasta no esten vacios, el valor concreto es indistinto.
Future<void> _pickDate(WidgetTester tester, String label) async {
  await tester.tap(find.widgetWithText(TextField, label));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Aceptar'));
  await tester.pumpAndSettle();
}

Future<void> _fillFiltersAndPreview(WidgetTester tester) async {
  await tester.enterText(
    find.widgetWithText(TextField, 'Tecnico ID (obligatorio)'),
    'tec-1',
  );

  await _pickDate(tester, 'Desde');
  await _pickDate(tester, 'Hasta');

  await tester.tap(find.widgetWithText(FilledButton, 'Previsualizar resumen'));
  await tester.pumpAndSettle();
}

class _FakeLiquidacionesRepository implements LiquidacionesRepository {
  _FakeLiquidacionesRepository({
    this.confirmError,
    this.clienteNombre = 'Agro SRL',
    this.tipoSalidaNombre = 'Media distancia',
    this.reabiertas = const <LiquidacionItem>[],
    this.previewVacio = false,
    List<LiquidacionItemsResponse?>? itemsQueue,
  }) : _itemsQueue = itemsQueue;

  /// Liquidaciones del tecnico en estado reabierta: el backend las excluye del
  /// resumen y la pagina las tiene que mostrar aparte.
  final List<LiquidacionItem> reabiertas;
  final bool previewVacio;

  final AppFailure? confirmError;
  final String? clienteNombre;

  /// Lo resuelve la capa data contra GET /liquidaciones; el endpoint de items
  /// devuelve otro nombre a proposito, para verificar cual tiene prioridad.
  final String? tipoSalidaNombre;

  /// Permite guionar la secuencia de respuestas: null primero (endpoint no
  /// disponible) y valor despues, para ejercitar el reintento.
  final List<LiquidacionItemsResponse?>? _itemsQueue;

  int previewCalls = 0;
  int confirmCalls = 0;
  int itemsCalls = 0;

  ResumenPagoPreviewItem get _previewRow => ResumenPagoPreviewItem(
        id: 'liq-1',
        servicioId: 'srv-1',
        fechaAprobacion: '2026-07-10T14:20:00.000Z',
        subtotalSalidaUsd: 80,
        subtotalItemsUsd: 120.5,
        totalLiquidacionUsd: 200.5,
        clienteNombre: clienteNombre,
        tipoSalidaNombre: tipoSalidaNombre,
      );

  static LiquidacionItemsResponse itemsResponse() {
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
    if (previewVacio) {
      return const ResumenPagoPreviewResponse(
        items: <ResumenPagoPreviewItem>[],
        meta: ResumenPagoPreviewMeta(
          totalLiquidaciones: 0,
          totalResumenUsd: 0,
        ),
      );
    }
    return ResumenPagoPreviewResponse(
      items: <ResumenPagoPreviewItem>[_previewRow],
      meta: const ResumenPagoPreviewMeta(
        totalLiquidaciones: 1,
        totalResumenUsd: 200.5,
      ),
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

    return ResumenPagoPreviewResponse(
      items: <ResumenPagoPreviewItem>[_previewRow],
      meta: const ResumenPagoPreviewMeta(
        totalLiquidaciones: 1,
        totalResumenUsd: 200.5,
      ),
      confirmacion: const ResumenPagoConfirmacion(
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
    return PagedResult<LiquidacionItem>(
      items: reabiertas,
      total: reabiertas.length,
      page: 1,
      limit: 50,
    );
  }

  @override
  Future<PagedResult<LiquidacionPendienteItem>> fetchLiquidacionesPendientes({
    required LiquidacionesPendientesQuery query,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<LiquidacionItemsResponse?> fetchLiquidacionItems(String liquidacionId) async {
    itemsCalls += 1;
    final queue = _itemsQueue;
    if (queue == null) {
      return itemsResponse();
    }
    final index = itemsCalls - 1 >= queue.length ? queue.length - 1 : itemsCalls - 1;
    return queue[index];
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
