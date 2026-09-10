# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Qué es este repo

Panel web (**Flutter Web**, solo web) del rol `admin-tecnico` de un sistema de servicio técnico para balanzas agropecuarias. Consume una API NestJS compartida bajo `/api/v1`. Es uno de cuatro repos: backend (NestJS + PostgreSQL), app-tecnico (Flutter), este admin-web, y feedback-web (panel de `admin-desarrollo`, repo separado).

Fuera de alcance deliberado: analytics/export de feedback y catálogos de diagnóstico/resolución — pertenecen al panel de `admin-desarrollo`. No agregarlos acá.

## Comandos

```bash
flutter pub get

# Correr en Chrome (mismo puerto/backend que .vscode/launch.json)
flutter run -d chrome --web-port 5173 \
  --dart-define=API_BASE_URL=https://backend-feedback-11c2.onrender.com/api/v1

# Contra backend local
flutter run -d chrome --dart-define=API_BASE_URL=http://localhost:3000/api/v1

flutter analyze
flutter test
flutter test test/features/liquidaciones/domain/liquidacion_pago_calculator_test.dart
flutter test test/... --plain-name "suma salida fija mas items de servicio"

flutter build web --dart-define=API_BASE_URL=<url>
```

`--dart-define` disponibles:
- `API_BASE_URL` — default en [authenticated_http_client.dart:12](lib/core/api/authenticated_http_client.dart#L12) apunta al backend de Render, **no** a localhost.
- `LIQUIDACIONES_ENABLE_ITEMS_GET` (bool, default `true`) — kill switch para `GET /liquidaciones/:id/items` si el backend aún no lo expone; con `false` el repo devuelve `null` y la UI muestra el desglose como no disponible, con botón de reintento.
- `LIQUIDACIONES_ENABLE_PREVIEW_CLIENTE_HYDRATION` (bool, default `true`) — apaga la hidratación de cliente del flujo de pago (ver *Hidratación de datos del servicio*).

### Estado conocido de la suite

`flutter analyze` reporta 7 `info` preexistentes (4 por `dart:html` en `lib/core/utils/`, 2 `unnecessary_underscores`, 1 import redundante en un test). Sin errores.

`flutter test`: 32 tests, todos en verde.

Los campos de fecha de la pantalla de pagos son `readOnly` y abren un `showDatePicker`, así que en tests **no aceptan `enterText`**: hay que tocar el campo y confirmar con `'Aceptar'` (ver el helper `_pickDate` en `liquidaciones_pagos_page_test.dart`).

## Arquitectura

### Sin contenedor de DI — las páginas construyen sus dependencias

No hay `get_it` ni `AppDependencies`. Cada página raíz de módulo instancia su repositorio concreto dentro de `build()` y lo entrega a un `BlocProvider` local:

```dart
// features/liquidaciones/presentation/pages/liquidaciones_page.dart
final liquidacionesRepository = LiquidacionesRepositoryImpl();
return BlocProvider<LiquidacionesBloc>(
  create: (_) => LiquidacionesBloc(liquidacionesRepository)..add(LiquidacionesRequested(...)),
  child: _LiquidacionesView(liquidacionesRepository: liquidacionesRepository),
);
```

Consecuencia: el BLoC vive y muere con el módulo activo. Cambiar de módulo en el shell reconstruye la página y recarga desde la API. Para hacer una página testeable, exponer un parámetro opcional `repository` en el constructor — sólo `LiquidacionesPagosPage` lo hace hoy, y es el patrón a copiar.

### Sesión y routing

`SessionStore` ([core/auth/session_store.dart](lib/core/auth/session_store.dart)) es un **static holder en memoria** — no hay `flutter_secure_storage` ni persistencia. Recargar la pestaña desloguea.

`AppRouter.onGenerateRoute` es el único guard: cualquier ruta distinta de `/login` cae a `LoginPage` si `SessionStore.isAuthenticated` es false. Todas las rutas autenticadas devuelven el mismo `AppShellPage(initialModule: ...)`; la navegación real entre módulos ocurre **dentro** del shell vía `AppShellBloc`, sin tocar el Navigator ni la URL.

`AuthenticatedHttpClient` lee el token directamente de `SessionStore` en cada request. No hay refresh ni manejo global de 401 — un 401 se propaga como `AppFailure` y termina en un mensaje de error del BLoC.

### Agregar un módulo toca cinco lugares

`AppModule` es el registro central. Un módulo nuevo requiere:
1. constante en [core/routing/app_routes.dart](lib/core/routing/app_routes.dart)
2. valor en el enum `AppModule` + las cuatro ramas de `AppModuleX` (`label`, `route`, `icon`, `shortDescription`) en [features/app_shell/domain/app_module.dart](lib/features/app_shell/domain/app_module.dart)
3. `case` en `AppRouter.onGenerateRoute`
4. `case` en `_AppShellView._modulePage`
5. la página, envuelta en `ModulePageLayout`

Los switches sobre `AppModule` no tienen `default`, así que el analizador marca los que falten.

### Capas por feature

`lib/features/<feature>/{data,domain,presentation}`:
- `domain/<feature>_repository.dart` — entidades, inputs, query objects y la clase abstracta del repositorio, todo en un archivo. **No hay use cases** pese a lo que dice AGENTS.md; los BLoCs llaman al repositorio directo.
- `data/<feature>_repository_impl.dart` — implementa el contrato sobre `AuthenticatedHttpClient` y hace todo el parseo.
- `presentation/{bloc,pages}` — `Bloc` con eventos/estados tipados a mano (sin `equatable`, sin `freezed`); los estados usan `copyWith` con centinelas `_aprobadoNoChange` / `_messageNoChange` para distinguir "no cambiar" de "poner en null".

Excepciones a conocer:
- **`features/repuestos` sólo tiene `presentation/pages`** — reutiliza `CatalogosBloc` + `CatalogosRepositoryImpl` con `tipo: 'repuesto'`.
- **`CatalogosRepositoryImpl` multiplexa por `tipo`** (`zona` → `/zonas`, `categoria` → `/categorias-producto`, `producto` → `/productos`, `repuesto` → `/repuestos`) en un `switch`. Un catálogo nuevo se agrega ahí, no en una feature nueva.
- **Pagos vive dentro de `features/liquidaciones`** (`liquidaciones_pagos_page.dart` + `LiquidacionesPagosCubit`), no en una feature `pagos`.

### El contrato con el backend es tolerante a propósito

Es la característica dominante de la capa `data` y hay que respetarla al tocarla:

- **Lectura de campos**: cada campo se resuelve con una cadena de `??` que cubre camelCase y snake_case, nodos anidados (`liquidacion`, `servicio`, `tecnico`, `cliente`) y aliases legacy. Ver el mapper de `fetchLiquidaciones` en [liquidaciones_repository_impl.dart](lib/features/liquidaciones/data/liquidaciones_repository_impl.dart).
- **Paginación**: `PagedResult.fromDynamic` acepta lista pelada o envelope, busca items en `items`/`data`/`results`/`rows` (incluso anidados) y meta en `meta`/`pagination`, con fallback a la query original.
- **Escritura**: `_sendWithFallback(candidates, sender)` prueba varios shapes de body en orden y **sólo reintenta ante 400/422**; cualquier otro status se relanza. Mismo patrón para query params (`_buildLiquidacionesQueryCandidates`, que reintenta con/sin paginación y con `tecnicoId`/`tecnico_id`) y para el login (`AuthRepositoryImpl` prueba `email`/`usuario`/`username`/`user`/`identifier`).

Al agregar un campo o endpoint, verificar el shape real contra **[docs/endpoints.md](docs/endpoints.md)** y **[docs/backend_feedback.postman_collection.json](docs/backend_feedback.postman_collection.json)** antes de inventar claves.

### Hidratación en el flujo de pago

Los endpoints de resumen de pago (`resumen-pago/preview`, `resumenes-pago/:id`) devuelven **solo** ids y montos: ni cliente, ni nombre de tipo de salida. La capa data los completa en dos pasos, en este orden:

1. **`GET /liquidaciones`** filtrado por técnico (`_fetchLiquidacionResumenPorTecnico`) → aporta `tipoSalidaNombre` y, casi siempre, `clienteNombre`. Una consulta paginada resuelve todas las filas. Se cachea por `tecnicoId|liquidadaPago`: el preview mira las **no pagadas** y el detalle confirmado las **ya pagadas**, que son universos disjuntos — por eso el flag va en la clave. `confirmarResumenPago` invalida la entrada `|false`.
2. **`GET /servicios/:id`** (`_fetchServicioResumen`) solo para las filas que quedaron sin cliente, con caché por `servicioId`, deduplicación de requests en vuelo y fan-out acotado a 6 vía `_hydrateFromServicios<T>`. Este helper lo comparten también el listado de liquidaciones y los pendientes.

Reglas al tocarlo:
- Es **best-effort** en los dos pasos: si algo falla se devuelve la fila incompleta, nunca se propaga el error. Los montos siempre están.
- El **nombre del tipo de salida no está en el contrato documentado** de `GET /liquidaciones/:id/items`. No dependas de ese endpoint para mostrarlo: la UI lo recibe por parámetro desde la fila y solo usa el de items como respaldo.
- Descartado deducir el tipo de salida cruzando `subtotalSalidaUsd` contra `fetchTiposSalida()`: dos tipos pueden compartir precio, y una etiqueta equivocada en una pantalla de aprobación de pagos es peor que ninguna.
- Los mappers intentan primero leer cliente y fecha del propio payload (alias camel/snake y nodos anidados), así que si el backend algún día los manda, la hidratación no se dispara.

Errores: todo falla como `AppFailure(message, statusCode)`. `AuthenticatedHttpClient._decodeResponse` extrae el mensaje de `message` (string o lista) o `error`. No existen `ServerException`/`AuthException`/`NetworkException`.

### Reglas de negocio de liquidaciones

- **Total al técnico = precio del tipo de salida + suma de `precioUsdSnapshot` de los items.** El `km` y `precioKmUsdSnapshotLegacy` son legacy y se ignoran en el cálculo — hay un test que lo blinda ([liquidacion_pago_calculator_test.dart](test/features/liquidaciones/domain/liquidacion_pago_calculator_test.dart)). Todos los montos en USD.
- `LiquidacionItem.estadoNormalizado` normaliza `estado` del backend y cae a `aprobada ? 'aprobada' : 'pendiente'` si viene vacío o desconocido. `isEditable` = `!liquidadaPago && (isPendiente || isReabierta)`.
- `liquidadaPago = true` congela la liquidación: sin editar, aprobar, reabrir ni tocar items. La grilla muestra badge `PASADA A PAGO`.
- Aprobar una liquidación **sin items autoasigna uno** — `LiquidacionesBloc._resolveDefaultTipoServicioId` prefiere un tipo activo cuyo nombre contenga `normal`, luego el primer activo, luego cualquiera.
- Reabrir exige `motivo` (queda para auditoría). El permiso se decide **decodificando el JWT a mano** en `liquidaciones_page.dart` (`_canReopenByRole`, roles `admin-tecnico` / `admin`); no hay rol en `AuthSession`.
- Flujo de pago: preview por técnico + rango → confirmar → las liquidaciones quedan pagadas. `LiquidacionesPagosCubit` sostiene selección, historial paginado, detalle y el caché de desglose por liquidación.
- El desglose de una liquidación (tipo de salida + items de tipo servicio) se carga *lazy* al expandir la fila, vía `ensureLiquidacionItems`. `fetchLiquidacionItems` devuelve `null` cuando el endpoint no está disponible: eso se modela como `LiquidacionItemsLoadStatus.unavailable`, **distinto** de `loaded` con lista vacía, para que el reintento tenga sentido. No volver a cachear ese `null` como éxito.

### UI

**No existe `lib/core/theme/app_theme.dart`.** El tema (dark-only, azul `#081B30`/`#69C3FF`, Material 3, `Segoe UI`) está inline en [main.dart](lib/main.dart), junto con un escalado responsive por breakpoints (`430/560/900/1200`) aplicado desde `MaterialApp.builder` sobre `TextScaler`, `VisualDensity` e `IconTheme`.

Además, casi cada widget define su propio `static const double _scale = 0.8` y multiplica paddings, radios e íconos por él. Al escribir UI nueva, seguir esa convención y los hex literales del entorno — no hay tokens de color centralizados ni los widgets `EstadoBadge`/`BotonAccion`/`CardSeccion`/`MetricaCard` que menciona AGENTS.md.

Compartido en `core/widgets`: `ModulePageLayout` (contenedor estándar de módulo: título, subtítulo, `trailing`, divider) y `ModuleStatusChip`. `TechAdminBackground` pinta el fondo del shell.

Navegación del shell: bajo 980px pasa de barra superior a `Drawer`. Sin sidebar lateral fijo.

**Tablas anchas en web**: dos trampas que ya mordieron en la grilla de pagos. Un `Scrollbar` sobre un `SingleChildScrollView` horizontal **necesita `controller` explícito** — si no, se engancha al scroll vertical de la lista y la barra horizontal nunca aparece (y conviene poner `primary: false` en el `ListView` interno). Y en web el **arrastre con mouse está deshabilitado por defecto**: sin un `ScrollConfiguration` que agregue `PointerDeviceKind.mouse` a `dragDevices`, la tabla solo se mueve con shift+rueda. Por debajo de ~900px conviene directamente apilar tarjetas en vez de scrollear (ver `ResumenPagoPreviewTable` y `_buildCreatedLiquidacionesResponsive`).

Interop web (`dart:html`) va detrás de imports condicionales en `core/utils/` (`open_pdf_bytes.dart`, `open_external_url.dart`) con stubs que lanzan `UnsupportedError` fuera de web. Es la fuente de los 4 `info` del analyzer.

## Convenciones

- Todo el vocabulario del dominio en español; **strings de UI sin acentos ni tildes** (`'Liquidacion aprobada correctamente'`, `'Abrir menu'`). Mantenerlo por consistencia.
- Archivos `snake_case`, clases `PascalCase`, imports absolutos `package:web_admin_tecnico/...`.
- Los listados deben cubrir loading / vacío / error / resultado y preservar filtros y paginación tras un refresh.
- Acciones riesgosas (aprobar, borrar item, confirmar pago) piden confirmación explícita; el submit se deshabilita durante el envío.
- Tests: fakes escritos a mano que implementan la interfaz del repositorio (`_FakeLiquidacionesRepository`) o subclases de `AuthenticatedHttpClient` que graban llamadas (`_RecordingHttpClient`). No hay mockito.

## AGENTS.md está desactualizado

[AGENTS.md](AGENTS.md) describe bien el **dominio y los endpoints**, pero su sección técnica no refleja el código: promete `equatable`, `flutter_secure_storage`, `AppDependencies`, use cases con `ejecutar()`, `app_theme.dart` con modo claro/oscuro, Navigator 2.0 vía `BlocBuilder`, sidebar de 240px y features `tecnicos`/`pagos` que no existen. Tampoco hay pantalla de Dashboard ni ABM de técnicos (sólo se listan técnicos para filtrar y para el selector de pagos). Usarlo como referencia funcional, no como descripción de la arquitectura actual.

Las instrucciones de `.github/instructions/` (arquitectura por capas, mapeo snake_case→camelCase, permisos por rol, UX de tablas y formularios) sí coinciden con el código y valen como guía.
