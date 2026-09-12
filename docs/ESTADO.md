# Estado del proyecto — Panel Web Admin Técnico

> Documento generado a partir de una revisión directa del código fuente del repo
> (`lib/`, `test/`, `docs/`, `pubspec.yaml`, `.github/`), no de la documentación de diseño.
> Fecha del relevamiento: 2026-09-12 · Commit base: `311bfd0` · Rama: `main`

---

## 1. Resumen

Panel web interno (Flutter Web) para el rol `admin-tecnico` del sistema de servicio
técnico de balanzas. Consume la API NestJS compartida (`API_BASE_URL`, por defecto
`https://backend-feedback-11c2.onrender.com/api/v1`).

**Etapa: en desarrollo avanzado / funcional parcial.**

No es un esqueleto: hay 17.250 líneas de Dart en `lib/` repartidas en 53 archivos,
7 módulos navegables conectados a endpoints reales, 32 tests que pasan y
`flutter analyze` limpio (7 `info`, cero errores y cero warnings).

Pero tampoco está completo: faltan dos pantallas enteras que el `CLAUDE.md` define como
parte del panel (**Dashboard** y **Gestión de Técnicos**), la sesión no se persiste
(recargar la pestaña desloguea), y no existe el sistema de diseño
(`lib/core/theme/app_theme.dart`) que las convenciones declaran obligatorio.

El esfuerzo está muy concentrado: `liquidaciones` sola tiene 8.248 líneas (48% del código
de `lib/`) y es el 100% de la cobertura de tests. El resto de los módulos está
implementado pero sin tests.

---

## 2. Qué está implementado y funcionando

### Infraestructura núcleo

| Pieza | Archivo | Estado |
|---|---|---|
| Cliente HTTP con JWT | [authenticated_http_client.dart](../lib/core/api/authenticated_http_client.dart) | Completo. `getJson`/`postJson`/`patchJson`/`deleteJson`/`getBytes`, `API_BASE_URL` por `--dart-define`, extracción de mensaje de error desde `message`/`error` |
| Paginación genérica | [paged_result.dart](../lib/core/api/paged_result.dart) | Completo. `PagedResult.fromDynamic` tolera `data`/`items`/`results`/`rows` y `meta`/`pagination` |
| Excepción tipada | [app_failure.dart](../lib/core/error/app_failure.dart) | Existe `AppFailure(message, statusCode)` |
| Ruteo | [app_router.dart](../lib/core/routing/app_router.dart) · [app_routes.dart](../lib/core/routing/app_routes.dart) | Funcional. 8 rutas con guard: si `SessionStore.isAuthenticated` es falso, redirige a login |
| Descarga/apertura de PDF | [open_pdf_bytes.dart](../lib/core/utils/open_pdf_bytes.dart) | Completo, con split web/stub por conditional import |
| Layout de módulo | [module_page_layout.dart](../lib/core/widgets/module_page_layout.dart) | `ModulePageLayout` + `ModuleStatusChip`, usados por las 8 pantallas |

### Shell y autenticación

- **Login** ([login_page.dart](../lib/features/auth/presentation/pages/login_page.dart), 381 líneas) — formulario funcional contra `POST /auth/login`, con `AuthBloc` y manejo de error 400/401.
- **Shell de navegación** ([app_shell_page.dart](../lib/features/app_shell/presentation/pages/app_shell_page.dart), 574 líneas) — navegación superior en desktop y `Drawer` bajo 980px, `AnimatedSwitcher` entre módulos, logout. Los 7 módulos se enumeran en [app_module.dart](../lib/features/app_shell/domain/app_module.dart).

### Módulos completos

**Liquidaciones** — [liquidaciones_page.dart](../lib/features/liquidaciones/presentation/pages/liquidaciones_page.dart) (2.804 líneas), [liquidaciones_repository_impl.dart](../lib/features/liquidaciones/data/liquidaciones_repository_impl.dart) (1.964 líneas). Es el módulo más maduro:

- Listado con filtros por estado, aprobado, `liquidadaPago` y técnico
- Vista de pendientes (`GET /liquidaciones/pendientes`)
- Detalle con desglose de items ([liquidacion_items_breakdown.dart](../lib/features/liquidaciones/presentation/widgets/liquidacion_items_breakdown.dart))
- Cambio de tipo de salida, alta/aprobación/baja de items de servicio
- Aprobar liquidación, reabrir con motivo y consulta del historial de reaperturas
- Bloqueo funcional cuando `liquidadaPago = true` (badge `PASADA A PAGO`, sin edición)
- ABM de **tipos de salida** y **tipos de servicio** embebido en esta pantalla
- Regla de negocio aislada y testeada en [liquidacion_pago_calculator.dart](../lib/features/liquidaciones/domain/liquidacion_pago_calculator.dart)

**Pagos a técnicos** — [liquidaciones_pagos_page.dart](../lib/features/liquidaciones/presentation/pages/liquidaciones_pagos_page.dart) (854 líneas) + [liquidaciones_pagos_cubit.dart](../lib/features/liquidaciones/presentation/bloc/liquidaciones_pagos_cubit.dart) (531 líneas):

- Preview por técnico y rango de fechas, confirmación del resumen
- Historial paginado de resúmenes y detalle en modal
- Último resumen por técnico como sugerencia
- Selección múltiple con contador y total USD, caché de items por liquidación con estados `loading`/`loaded`/`unavailable`/`error` ([liquidacion_items_cache.dart](../lib/features/liquidaciones/presentation/bloc/liquidacion_items_cache.dart))
- Tabla en desktop y tarjetas en pantallas angostas ([resumen_pago_preview_table.dart](../lib/features/liquidaciones/presentation/widgets/resumen_pago_preview_table.dart))

**Servicios** — [servicios_page.dart](../lib/features/servicios/presentation/pages/servicios_page.dart) (738) + [servicio_detalle_page.dart](../lib/features/servicios/presentation/pages/servicio_detalle_page.dart) (546):

- Listado paginado con búsqueda y filtros por estado, canal y técnico (el selector de técnicos sale de `GET /auth/tecnicos?activos=true`)
- Detalle completo: equipo, cliente, diagnóstico, facturación con items, firma (hash SHA256, fecha)
- Ver / abrir / copiar URL del PDF de la orden (`GET /servicios/:id/documento` y `/documento/pdf`)

**Clientes** — [clientes_page.dart](../lib/features/clientes/presentation/pages/clientes_page.dart) (929): listado paginado, búsqueda vía `GET /clientes/buscar`, alta, edición y modal de detalle.

**Repuestos** — [repuestos_page.dart](../lib/features/repuestos/presentation/pages/repuestos_page.dart) (829): grilla paginada sobre `GET /repuestos/listado` con búsqueda y filtro activo/inactivo, alta y edición con precio USD.

**Catálogos** — [catalogos_page.dart](../lib/features/catalogos/presentation/pages/catalogos_page.dart) (675): zonas, categorías de producto y productos. Alta, edición y toggle activo/inactivo; los productos se cargan agrupados por categoría.

**Precios** — [precios_page.dart](../lib/features/precios/presentation/pages/precios_page.dart) (470): valores actuales de cotización y tarifa km, historial combinado paginado, alta manual de ambos.

### Tests

32 tests, todos verdes (`flutter test`). Cubren exclusivamente liquidaciones:

- [liquidacion_pago_calculator_test.dart](../test/features/liquidaciones/domain/liquidacion_pago_calculator_test.dart) — regla salida fija + items, e ignorar métricas KM legacy
- [liquidaciones_repository_impl_test.dart](../test/features/liquidaciones/data/liquidaciones_repository_impl_test.dart) — hidratación de cliente, deduplicación de requests, `estado=pendiente`
- [liquidaciones_pagos_cubit_test.dart](../test/features/liquidaciones/presentation/liquidaciones_pagos_cubit_test.dart) — caché de items, concurrencia, reintentos, selección
- [liquidaciones_pagos_page_test.dart](../test/features/liquidaciones/presentation/liquidaciones_pagos_page_test.dart) — 11 tests de widget del flujo de pagos
- [liquidaciones_contract_regression_test.dart](../test/features/liquidaciones/domain/liquidaciones_contract_regression_test.dart), [liquidaciones_bloc_regression_test.dart](../test/features/liquidaciones/presentation/liquidaciones_bloc_regression_test.dart)

### Cobertura de endpoints

De los ~55 endpoints que el `CLAUDE.md` asigna a este panel, **49 están consumidos**.
Los 6 ausentes se detallan en las secciones 3 y 4.

---

## 3. Qué está a medias

**No hay un solo comentario `TODO`, `FIXME` ni `HACK` en todo `lib/`.** Lo que sigue son
incompletitudes reales detectadas leyendo el código, no marcas dejadas por el autor.

### 3.1 Sesión en memoria — se pierde al recargar

[session_store.dart](../lib/core/auth/session_store.dart) guarda el token en una
`static AuthSession? _session`. No hay `flutter_secure_storage` (ni siquiera está en
`pubspec.yaml`), ni `localStorage`, ni refresh. **En una app web esto significa que F5
desloguea al usuario.** El `CLAUDE.md` especifica `flutter_secure_storage` para el token.

### 3.2 `logout()` es un cuerpo vacío

```dart
// lib/features/auth/data/auth_repository_impl.dart:98
@override
Future<void> logout() async {}
```

El logout real lo hace la vista llamando a `SessionStore.clear()` directamente
([app_shell_page.dart:40](../lib/features/app_shell/presentation/pages/app_shell_page.dart#L40)).
El `AuthLogoutRequested` del `AuthBloc` existe pero ninguna vista lo despacha.

### 3.3 El login no valida el rol

`AuthRepositoryImpl.login` acepta cualquier token válido. No se verifica que el usuario sea
`admin-tecnico` o `admin`. Un usuario con rol `tecnico` puede entrar al panel y ver los 7
módulos; los requests fallarán con 403 del backend, pero la UI no lo impide ni lo explica.

La única verificación de rol del proyecto está enterrada en la vista de liquidaciones
([liquidaciones_page.dart:61-88](../lib/features/liquidaciones/presentation/pages/liquidaciones_page.dart#L61-L88)),
donde un `State` decodifica el JWT a mano para decidir si muestra el botón "Reabrir".

### 3.4 Pagos: dos endpoints del flujo sin implementar

- `GET /liquidaciones/para-pago` — **no se llama desde ningún lado.** La pantalla de pagos
  usa solo `resumen-pago/preview`. La vista "liquidaciones listas para pago" que describe
  el `CLAUDE.md` no existe como tal.
- `PATCH /liquidaciones/marcar-pagadas` — **no se llama desde ningún lado.** El marcado en
  lote solo ocurre indirectamente al confirmar un resumen.

### 3.5 Flag muerto: `remoteEnabled`

`LiquidacionItemsResponse.remoteEnabled` existe en el modelo y la vista lo lee
([liquidaciones_page.dart:1410](../lib/features/liquidaciones/presentation/pages/liquidaciones_page.dart#L1410)),
pero el repositorio lo emite **siempre en `true`**
([liquidaciones_repository_impl.dart:605](../lib/features/liquidaciones/data/liquidaciones_repository_impl.dart#L605)).
Es un feature flag que quedó cableado en una sola posición.

### 3.6 Items locales no persistidos

Si `POST /liquidaciones/:id/items` no devuelve el item creado, la vista fabrica uno local
con `id: 'tmp-<timestamp>'` e `isPersisted: false`
([liquidaciones_page.dart:1545-1555](../lib/features/liquidaciones/presentation/pages/liquidaciones_page.dart#L1545-L1555)).
Ese item se muestra en la grilla pero no se puede aprobar ni borrar — la UI avisa
"Este item es local y no puede aprobarse aun". Es un parche de optimistic UI, no un flujo cerrado.

### 3.7 Branch de búsqueda rápida de repuestos: código muerto

`_fetchSimple` en [catalogos_repository_impl.dart](../lib/features/catalogos/data/catalogos_repository_impl.dart)
tiene toda una rama para el endpoint `/repuestos` (`isQuickSearchEndpoint`, `keepEmptyParams`),
pero `_fetchByTipo` nunca le pasa `/repuestos`: para `tipo == 'repuesto'` siempre usa
`/repuestos/listado`. La rama es inalcanzable.

### 3.8 Paginación resuelta en cliente en dos lugares

- `/productos` se trae entero y se pagina en memoria (`supportsServerPagination = false`).
- `fetchCatalogos` con `tipo: 'todos'` dispara 3 requests en paralelo, concatena y pagina a mano.
  Esta rama tampoco es alcanzable hoy: `catalogos_page` siempre manda un tipo concreto
  (`zona` por defecto) y `repuestos_page` siempre manda `repuesto`.

### 3.9 Logs de debug en producción

[servicios_repository_impl.dart](../lib/features/servicios/data/servicios_repository_impl.dart)
vuelca la respuesta completa de `GET /servicios` y `GET /servicios/:id` con
`developer.log` + `JsonEncoder.withIndent` (líneas 18 y 272). Quedó de una sesión de debug.

### 3.10 `AppShellData` no se usa

[app_shell_data.dart](../lib/features/app_shell/data/app_shell_data.dart) define
`availableModules()`; el shell usa `AppModule.values` directamente. Clase huérfana.

### 3.11 Documentación del repo desactualizada

- [README.md](../README.md) sigue siendo el template de `flutter create` ("A new Flutter project").
- `pubspec.yaml` tiene `description: "A new Flutter project."`.
- [Progreso_app.md](../Progreso_app.md) es una nota de progreso de un sprint puntual, no un estado general, y termina con una frase cortada ("Se pasaron a issue").
- `AGENTS.md` figura como borrado en git (`D AGENTS.md`); su contenido vive ahora en `CLAUDE.md`.

---

## 4. Qué falta por completo

Contrastado contra `CLAUDE.md` (el documento de arquitectura vigente; `AGENTS.md` fue
eliminado y reemplazado por él) y contra [plan-web-admin-tecnico.md](plan-web-admin-tecnico.md).

### 4.1 Módulo Dashboard — no existe

El `CLAUDE.md` lo lista primero entre las pantallas (métricas de servicios del mes,
servicios a campo, liquidaciones pendientes de aprobar, listas para pago, técnicos activos,
accesos rápidos). **No hay carpeta `lib/features/dashboard/`, ni ruta, ni entrada en `AppModule`.**
La app entra directo al módulo que pida la URL, y `/` cae en login.

### 4.2 Módulo Técnicos — no existe

El `CLAUDE.md` define alta de técnico, edición de `fullName`/`email` y activar/desactivar.
**No hay carpeta `lib/features/tecnicos/`.** De los 5 endpoints de técnicos solo se usa
`GET /auth/tecnicos`, y únicamente como fuente de un combo de filtro en servicios y pagos.
Sin implementar: `POST /auth/tecnicos`, `GET /auth/tecnicos/:id`, `PATCH /auth/tecnicos/:id`,
`PATCH /auth/tecnicos/:id/estado`.

### 4.3 Sistema de diseño `app_theme.dart` — no existe

El `CLAUDE.md` lo declara **obligatorio**: `lib/core/theme/app_theme.dart` con paleta
azul `#1A3A5C` / naranja `#E85D04`, modo claro y oscuro con toggle, y los widgets
`EstadoBadge`, `BotonAccion`, `CardSeccion`, `MetricaCard`, `CampoBusqueda`.

La realidad:

- **No existe el directorio `lib/core/theme/`.** El tema está inline en
  [main.dart](../lib/main.dart), es **dark-only**, y su paleta es otra (`#081B30`, `#69C3FF`).
- **No hay toggle de tema.**
- **Ninguno de los 5 widgets reutilizables existe.** Lo más cercano es `ModuleStatusChip`,
  que recibe los colores por parámetro en vez de derivarlos de un tipo semántico.
- Hay **371 literales `Color(0x…)` repartidos en 15 archivos** (83 solo en `liquidaciones_page.dart`).

### 4.4 Layout lateral especificado — no implementado

El `CLAUDE.md` describe sidebar de 240px colapsable a 64px bajo 900px. Lo implementado es
navegación **superior** que colapsa a `Drawer` bajo **980px**. Funciona, pero no es lo diseñado.

### 4.5 Historial de servicios por cliente

`CLAUDE.md` → "Clientes: ver historial de servicios por cliente". No hay nada en
`lib/features/clientes/` que consulte servicios.

### 4.6 Filtro por fecha en servicios

`CLAUDE.md` → "filtros por técnico, canal, fecha". `ServiciosQuery` tiene `search`,
`estado`, `canal`, `tecnicoId`, `page`, `limit`. **No hay filtro por fecha ni rango.**

### 4.7 Repuestos de un servicio

`GET /servicios/:id/repuestos` figura en `CLAUDE.md` y `endpoints.md`; el detalle de
servicio no lo consume.

### 4.8 Carga de PDF firmado

`POST /servicios/:id/documento/firmado` es la historia de usuario #3 y un criterio de
aceptación del MVP en [plan-web-admin-tecnico.md](plan-web-admin-tecnico.md).
`grep -rn "firmado" lib` no devuelve ninguna llamada. (Nota: este endpoint **no** está en la
lista del `CLAUDE.md`, así que puede haber sido descartado a propósito — conviene confirmarlo.)

### 4.9 Capa de casos de uso

`CLAUDE.md` → "Los use cases tienen un único método `ejecutar(...)`" y "Los BLoCs reciben
use cases por constructor". **No existe ningún use case**: `grep -rn "ejecutar(" lib` no
devuelve nada. Los BLoCs reciben repositorios directamente.

### 4.10 Inyección de dependencias

`CLAUDE.md` → "DI: clase `AppDependencies` sin get_it" y "BLoCs: MultiBlocProvider en main.dart".
**No existe `AppDependencies`** ni `lib/core/di/`. `main.dart` no tiene `MultiBlocProvider`:
cada página crea su propio `BlocProvider` y su propio `RepositoryImpl`, que a su vez
instancia su propio `AuthenticatedHttpClient`.

### 4.11 CI

`.github/` tiene agents, instructions y prompts de Copilot, pero **no hay `workflows/`**.
Nada corre `flutter analyze` ni `flutter test` automáticamente.

### 4.12 Tests fuera de liquidaciones

Cero tests para auth, servicios, clientes, catálogos, repuestos, precios, app_shell y
routing. [widget_test.dart](../test/widget_test.dart) es un smoke test de la pantalla de login.

---

## 5. Estructura actual del proyecto

```
web_admin_tecnico/
├── CLAUDE.md                  # arquitectura vigente (reemplaza al AGENTS.md borrado)
├── Progreso_app.md            # nota de sprint, desactualizada
├── README.md                  # template de flutter create, sin tocar
├── pubspec.yaml               # flutter_bloc, http, cupertino_icons, flutter_lints
├── analysis_options.yaml
│
├── .github/
│   ├── agents/review-frontend-flutter.agent.md
│   ├── instructions/          # flutter-web-admin-tecnico · ux-layout-panel-admin-web
│   ├── prompts/               # checklist-qa-modulo · scaffold-feature-flutter-admin
│   └── modernize/java-upgrade/hooks/scripts/   # ajeno al proyecto Flutter
│                              # (no hay workflows/)
│
├── docs/
│   ├── endpoints.md                        # fuente de verdad de la API (975 líneas)
│   ├── backend_feedback.postman_collection.json
│   ├── plan-web-admin-tecnico.md           # plan por sprints
│   ├── sistema_feedback_arquitectura.md
│   └── ESTADO.md                           # este documento
│
├── lib/                                    # 53 archivos · 17.250 líneas
│   ├── main.dart                           # tema inline dark-only + MaterialApp
│   ├── core/                               # 769 líneas
│   │   ├── api/        authenticated_http_client.dart · paged_result.dart
│   │   ├── auth/       auth_session.dart · session_store.dart   (solo memoria)
│   │   ├── error/      app_failure.dart
│   │   ├── routing/    app_router.dart · app_routes.dart
│   │   ├── utils/      open_external_url{,_stub,_web}.dart
│   │   │               open_pdf_bytes{,_stub,_web}.dart
│   │   │               paginated_table_prefs.dart
│   │   └── widgets/    module_page_layout.dart · tech_admin_background.dart
│   │                   (no existe core/theme/ ni core/di/)
│   │
│   └── features/
│       ├── liquidaciones/                  # 8.248 líneas (48% de lib/)
│       │   ├── data/        liquidaciones_repository_impl.dart      (1.964)
│       │   ├── domain/      liquidaciones_repository.dart            (727)
│       │   │                liquidacion_pago_calculator.dart          (14)
│       │   ├── presentation/bloc/    liquidaciones_bloc.dart         (482)
│       │   │                         liquidaciones_pagos_cubit.dart  (531)
│       │   │                         liquidacion_items_cache.dart     (41)
│       │   ├── presentation/pages/   liquidaciones_page.dart       (2.804)
│       │   │                         liquidaciones_pagos_page.dart   (854)
│       │   └── presentation/widgets/ resumen_pago_preview_table.dart (554)
│       │                             liquidacion_items_breakdown.dart(277)
│       ├── servicios/       # 2.118 · data + domain + bloc + 2 pages
│       ├── clientes/        # 1.393 · data + domain + bloc + page
│       ├── catalogos/       # 1.359 · data + domain + bloc + page (zonas/categorías/productos/repuestos)
│       ├── precios/         #   968 · data + domain + bloc + page (cotización + tarifa km)
│       ├── repuestos/       #   829 · SOLO page — reusa CatalogosBloc/Repository
│       ├── app_shell/       #   704 · domain/app_module + bloc + page (+ data huérfana)
│       └── auth/            #   589 · data + domain + bloc + login_page
│                            # (no existen features/dashboard/ ni features/tecnicos/)
│
├── test/                                   # 7 archivos · 1.510 líneas · 32 tests OK
│   ├── widget_test.dart                    # smoke test del login
│   └── features/liquidaciones/             # 100% de la cobertura real
│       ├── data/liquidaciones_repository_impl_test.dart
│       ├── domain/liquidacion_pago_calculator_test.dart
│       ├── domain/liquidaciones_contract_regression_test.dart
│       └── presentation/  liquidaciones_bloc_regression_test.dart
│                          liquidaciones_pagos_cubit_test.dart
│                          liquidaciones_pagos_page_test.dart
│
├── web/                                    # target real (7 archivos)
└── android/ ios/ linux/ macos/ windows/    # 128 archivos de scaffolding sin uso
```

---

## 6. Próximos pasos sugeridos

Ordenados por relación impacto / esfuerzo.

**1. Persistir la sesión.** Es el bug más visible para el usuario final: cualquier F5 lo
saca del panel. Agregar `flutter_secure_storage` (o `window.localStorage` vía el mismo
patrón de conditional import que ya usa `open_pdf_bytes`) y rehidratar `SessionStore` antes
del `runApp`. Sin esto el panel no es usable en jornada real.

**2. Validar el rol en el login.** Decodificar el JWT una sola vez, en `core/auth`, guardar
el rol en `AuthSession`, y rechazar el acceso si no es `admin-tecnico` ni `admin`. De paso
elimina el decodificador de JWT que hoy vive dentro de un `State` de la vista de liquidaciones.

**3. Eliminar los fallbacks de nombres de parámetros** (ver 7.1). Es el problema técnico más
serio del repo: degrada la performance y esconde errores reales de la API. `docs/endpoints.md`
ya define las formas exactas.

**4. Crear `lib/core/theme/app_theme.dart`** con la paleta y los 5 widgets del `CLAUDE.md`,
y migrar los 371 `Color(0x…)`. Conviene hacerlo antes de sumar pantallas nuevas, para no
multiplicar la deuda. Decidir explícitamente si se mantiene el dark-only actual o se
implementa el toggle especificado.

**5. Implementar el módulo Técnicos.** Es una pantalla ABM contra 4 endpoints ya
documentados; se puede calcar de `clientes`, que es el módulo más simple y limpio.

**6. Implementar el Dashboard.** Puede armarse componiendo llamadas existentes
(`/servicios`, `/liquidaciones?estado=pendiente`, `/liquidaciones/para-pago`,
`/auth/tecnicos?activos=true`) — y de paso da uso a `GET /liquidaciones/para-pago`,
que hoy está sin consumir.

**7. Agregar CI.** Un workflow que corra `flutter analyze` + `flutter test` en cada PR.
El repo ya está verde, así que arranca sin deuda que arrastrar.

**8. Romper `liquidaciones_page.dart` (2.804 líneas).** Extraer los diálogos de detalle,
de tipos de salida y de tipos de servicio a widgets propios, y mover las 4 llamadas
directas al repositorio hacia el `LiquidacionesBloc`.

**9. Cerrar los huecos menores:** filtro por fecha en servicios, historial de servicios por
cliente, `GET /servicios/:id/repuestos` en el detalle, y `PATCH /liquidaciones/marcar-pagadas`.

**10. Limpieza:** sacar los `developer.log`, borrar `AppShellData`, eliminar las ramas
muertas de `catalogos_repository_impl`, actualizar README y `description` del `pubspec.yaml`.

**11. Extender los tests** más allá de liquidaciones, empezando por auth (que es el camino
crítico) y servicios.

---

## 7. Deuda técnica o problemas detectados

### 7.1 🔴 Fallbacks por fuerza bruta sobre nombres de parámetros

Es el problema estructural más grave y está en 4 repositorios. En vez de usar el contrato
documentado, el código **prueba combinaciones de nombres de campo hasta que una no da 400**.

| Archivo | Qué hace | Peor caso |
|---|---|---|
| [servicios_repository_impl.dart](../lib/features/servicios/data/servicios_repository_impl.dart) | `_buildServiciosQueryCandidates` combina `q`/`search` × `estado`/`estadoOrden`/`estado_orden` × `canal`/`canalServicio`/`canal_servicio` × `tecnicoId`/`tecnico_id` × sort × paginación | **hasta 144 GET secuenciales** para un solo listado |
| [catalogos_repository_impl.dart](../lib/features/catalogos/data/catalogos_repository_impl.dart) | `_buildBodyCandidates` combina `nombre`/`descripcion`/`detalle` × `precioUsd`/`precio_usd`/`precio` × con/sin `activo` | **~24 POST/PATCH secuenciales** por alta de repuesto |
| [auth_repository_impl.dart](../lib/features/auth/data/auth_repository_impl.dart) | prueba `email`/`usuario`/`username`/`user`/`identifier` como clave de credencial | 5 POST de login |
| [liquidaciones_repository_impl.dart](../lib/features/liquidaciones/data/liquidaciones_repository_impl.dart) | snake_case + camelCase | 2 requests (aceptable — `endpoints.md` documenta que la API acepta ambos) |

Tres problemas concretos:

1. **Contradice la regla explícita del `CLAUDE.md`**: *"No inventar campos ni estructuras — copiarlos de esos archivos"*.
2. **Performance**: un listado de servicios puede disparar decenas de requests contra un backend en Render.
3. **Enmascara errores**: cualquier 400 legítimo (validación, filtro mal armado) se interpreta
   como "probá el siguiente nombre" y termina en un mensaje genérico.

El shape correcto ya está en `docs/endpoints.md`: por ejemplo, un repuesto es
`{ codigo, nombre, precioUsd, activo }` (líneas 524-563), no hace falta adivinarlo.

### 7.2 🔴 Las vistas contienen lógica de negocio y llaman a repositorios

La regla marcada como **fundamental** en el `CLAUDE.md` es: *"Las vistas no tienen lógica.
Cero lógica de negocio fuera de los BLoCs"*. Hay **9 llamadas directas a repositorios desde
`presentation/pages/`**:

| Página | Llamadas |
|---|---|
| `liquidaciones_page.dart` | `addLiquidacionItem`, `approveLiquidacionItem`, `deleteLiquidacionItem`, `fetchLiquidacionItems`, `fetchCategorias` |
| `servicio_detalle_page.dart` | `fetchServicioDetalle`, `fetchDocumento`, `fetchDocumentoPdfBytes` ×2 |
| `clientes_page.dart` | `fetchClienteDetalle` ×2 |

Además la vista de liquidaciones mantiene estado de negocio en variables locales
(`items`, `meta`), recalcula `_buildItemsMeta` y decodifica el JWT para resolver permisos.

### 7.3 🟠 El sistema de diseño obligatorio no existe

Detallado en 4.3. En resumen: sin `app_theme.dart`, sin los 5 widgets reutilizables, sin
toggle de tema, con otra paleta que la especificada y con 371 colores hardcodeados. Es una
divergencia total entre la convención declarada y el código.

### 7.4 🟠 Convenciones de arquitectura del `CLAUDE.md` no aplicadas

| Convención declarada | Realidad |
|---|---|
| "Estado: flutter_bloc + **equatable**" · "Props de Equatable siempre declarados" | **`equatable` no está ni en `pubspec.yaml`.** Ningún modelo ni estado lo extiende → todos los `BlocBuilder` re-renderizan aunque el estado sea equivalente |
| "Storage: flutter_secure_storage para el token" | No está en `pubspec.yaml`; token en memoria estática |
| "DI: clase `AppDependencies`" | No existe; cada página instancia su repo y su `AuthenticatedHttpClient` |
| "BLoCs: MultiBlocProvider en main.dart" | `main.dart` no provee ningún BLoC |
| "Routing: Navigator 2.0 nativo via BlocBuilder" | Navigator 1.0 con `onGenerateRoute` y rutas nombradas |
| "Los use cases tienen un único método `ejecutar(...)`" | No hay capa de use cases |
| "DTOs con `fromJson` factory y `toJson` method" | El parseo es inline dentro de los repositorios; no hay clases DTO con `toJson` |

No todas son necesariamente errores — varias parecen decisiones deliberadas de simplificación.
Pero el `CLAUDE.md` las presenta como vigentes, así que **o se corrige el código o se corrige
el documento**. Hoy quien lea el `CLAUDE.md` para orientarse va a buscar archivos que no existen.

### 7.5 🟠 `liquidaciones_page.dart`: 2.804 líneas en un archivo

El 16% de todo `lib/` en un solo archivo, con 83 colores hardcodeados y los ABM de tipos de
salida y tipos de servicio embebidos. Es difícil de testear y de revisar en PRs.

### 7.6 🟡 Duplicación entre `repuestos_page` y `catalogos_page`

Son 1.504 líneas que manejan el mismo `CatalogosBloc` y el mismo `CatalogosRepository` con
grillas, diálogos de alta/edición, paginación y filtros muy parecidos. `repuestos/` además
no tiene `data/` ni `domain/` propios — rompe la estructura DDD que sigue el resto de features.

### 7.7 🟡 Ubicación inconsistente de los tipos de salida y servicio

`CLAUDE.md` los pone en "Precios y tarifas" junto a tarifa km y cotización. En el código
viven en `liquidaciones` (repositorio, bloc y UI), mientras que `precios` solo maneja
cotización y tarifa km. La pantalla "Precios" queda más chica de lo especificado y la de
liquidaciones más cargada.

### 7.8 🟡 Dependencia sin usar y scaffolding muerto

- `cupertino_icons` está en `pubspec.yaml` y **no se usa** (`grep -rn "cupertino" lib` → vacío).
- `android/`, `ios/`, `linux/`, `macos/`, `windows/` suman **128 archivos** de scaffolding para
  plataformas que el proyecto no soporta ("solo web, no compila a mobile").
- El repo incluye `.github/modernize/java-upgrade/hooks/` — herramientas de upgrade de Java,
  ajenas a un proyecto Flutter.

### 7.9 🟡 Warnings de `flutter analyze`

7 `info`, ninguno bloqueante:

- 4 por `dart:html` deprecado en `open_external_url_web.dart` y `open_pdf_bytes_web.dart`
  (migrar a `package:web` + `dart:js_interop`)
- 2 `unnecessary_underscores` en `clientes_page.dart:693` y `repuestos_page.dart:630`
- 1 `unnecessary_import` de `dart:async` en `liquidaciones_bloc_regression_test.dart:1`

### 7.10 🟡 Sin manejo global de 401

`AuthenticatedHttpClient` convierte todo `>= 400` en `AppFailure`, pero nada intercepta un
401 para limpiar la sesión y redirigir al login. Con un token expirado el usuario ve
mensajes de error por pantalla sin entender que tiene que volver a loguearse.

### 7.11 🟢 Excepciones tipadas simplificadas

`CLAUDE.md` define `ServerException`, `AuthException` y `NetworkException`. El código usa un
único `AppFailure` con `statusCode`. Funciona bien y es más simple — pero conviene actualizar
el documento para que coincida.

---

## Porcentaje aproximado de avance: **70%**

### Cómo se compone

| Dimensión | Avance | Fundamento |
|---|---|---|
| Módulos funcionales | **~78%** | 7 de 9 pantallas del `CLAUDE.md` existen y están conectadas. Faltan Dashboard y Técnicos enteras; Precios está parcial |
| Cobertura de endpoints | **~89%** | 49 de ~55 operaciones consumidas. Faltan los 4 de ABM de técnicos, `para-pago` y `marcar-pagadas` |
| Infraestructura núcleo | **~75%** | Cliente HTTP, paginación, errores y ruteo sólidos. Falta persistencia de sesión, DI centralizada y manejo global de 401 |
| Sistema de diseño | **~25%** | Hay un tema coherente y un layout de módulo reutilizable, pero no es el especificado: sin `app_theme.dart`, sin los 5 widgets, sin toggle, 371 colores hardcodeados |
| Tests | **~35%** | 32 tests sólidos y `analyze` limpio, pero concentrados al 100% en liquidaciones. 6 features sin ningún test. Sin CI |
| Adherencia a convenciones | **~40%** | 7 de las convenciones declaradas no se aplican (equatable, secure storage, DI, use cases, MultiBlocProvider, Navigator 2.0, DTOs), más 9 violaciones de la regla "vistas sin lógica" |

### Lectura

El **núcleo de negocio está terminado y es de buena calidad**. Liquidaciones y Pagos —
lo más complejo y lo que justifica el panel — cubren el ciclo completo descrito en el
`CLAUDE.md`, tienen la regla de cálculo aislada y testeada, contemplan bloqueo por
`liquidadaPago`, manejan estados de carga diferenciados y son responsive. Servicios,
Clientes, Repuestos, Catálogos y Precios están operativos.

Lo que resta no es exploratorio: **son dos ABM más contra endpoints ya documentados, más
trabajo de consolidación** (sistema de diseño, persistencia de sesión, limpieza de los
fallbacks por fuerza bruta, tests, CI).

El 30% faltante pesa más de lo que sugiere la cuenta de pantallas, porque incluye dos cosas
que bloquean el uso real: **la sesión que no sobrevive a un refresh** y **los fallbacks que
pueden disparar decenas de requests por listado**. Ambas son acotadas y están bien
localizadas — ninguna exige rediseñar nada.
