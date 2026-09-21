# Estado del proyecto — Panel Web Admin Técnico

> Documento generado a partir de una revisión directa del código fuente del repo
> (`lib/`, `test/`, `docs/`, `pubspec.yaml`, `.github/`), no de la documentación de diseño.
> Fecha del relevamiento: 2026-09-20 · Commit base: `6ca40ef` · Rama: `main`
>
> Reemplaza al relevamiento del 2026-09-12 (`311bfd0`). Cada hallazgo de esa versión
> fue verificado de nuevo contra el código: los que se resolvieron están marcados en
> la tabla de la sección 1, los que siguen abiertos se repiten con su estado actual.

---

## 1. Resumen

Panel web interno (Flutter Web) para el rol `admin-tecnico` del sistema de servicio
técnico de balanzas. Consume la API NestJS compartida (`API_BASE_URL`, por defecto
`https://backend-feedback-11c2.onrender.com/api/v1`).

**Etapa: funcional, en consolidación.**

19.208 líneas de Dart en `lib/` repartidas en 65 archivos, **8 módulos navegables**
conectados a endpoints reales, **105 tests que pasan** y `flutter analyze` limpio
(7 `info`, cero errores y cero warnings).

Lo que cambió respecto del relevamiento anterior es sustancial: los dos problemas que
ese documento marcaba como bloqueantes para el uso real —**la sesión que no sobrevivía a
un refresh** y **los fallbacks que disparaban decenas de requests por listado**— están
resueltos, y el módulo de Técnicos, que faltaba entero, está completo con tests.

Lo que queda pendiente es más acotado y de otra naturaleza: **falta el Dashboard** (la
única de las 9 pantallas del `CLAUDE.md` que no existe), **no existe el sistema de diseño
`app_theme.dart`** que las convenciones declaran obligatorio, y varias convenciones de
arquitectura del `CLAUDE.md` siguen sin aplicarse (equatable, use cases, `AppDependencies`,
DTOs). Nada de eso impide operar el panel; todo eso sí hace que el `CLAUDE.md` describa
archivos que no existen.

El esfuerzo sigue concentrado: `liquidaciones` sola tiene 8.469 líneas (44% del código de
`lib/`), aunque ya no es el 100% de la cobertura de tests: ahora hay 4 áreas testeadas.

### Qué se resolvió desde el 2026-09-12

Cinco commits (`21d7265`, `a6c690b`, `4718d8b`, `a0fb6ba`, `e6171cd`) cerraron estos puntos:

| Hallazgo anterior | Estado hoy |
|---|---|
| 3.1 Sesión en memoria, F5 desloguea | **Resuelto.** `flutter_secure_storage` en `pubspec.yaml`, `SecureSessionStorage` + `SplashPage` + `AuthSessionRestoreRequested` |
| 3.2 `logout()` con cuerpo vacío | **Resuelto.** `AuthRepositoryImpl.logout()` limpia el storage; el shell despacha `AuthLogoutRequested` |
| 3.3 El login no valida el rol | **Resuelto.** `RolesPanel` + `ValidadorSesionPersistida`; estado `AuthAccesoDenegado`; el JWT ya no se decodifica en la vista |
| 7.1 Fallbacks por fuerza bruta sobre nombres de parámetros | **Resuelto en los 4 repositorios.** Un solo request por operación, con el shape de `endpoints.md` |
| 7.10 Sin manejo global de 401 | **Resuelto.** `SessionExpiration` notifica desde `AuthenticatedHttpClient` y el `AuthBloc` cierra la sesión |
| 4.2 Módulo Técnicos inexistente | **Resuelto.** `features/tecnicos/` completo, 5/5 endpoints, 11 tests |
| 3.7 Rama muerta de búsqueda rápida de repuestos | **Resuelto.** `isQuickSearchEndpoint`/`keepEmptyParams` eliminados |
| 4.12 Tests solo en liquidaciones | **Mejorado.** De 32 a 105 tests; se sumaron auth, core/auth y tecnicos |
| Estado `reabierta` en el circuito de pago | **Nuevo.** Filtro, badge propio y exclusión del circuito de pago |
| Paginación real en `GET /servicios` | **Nuevo.** Server-side; se quitaron los filtros que el backend no soporta |

Siguen abiertos: Dashboard (4.1), sistema de diseño (4.3 / 7.3), layout lateral (4.4),
capa de use cases (4.9), `AppDependencies` (4.10), CI (4.11), `para-pago` y
`marcar-pagadas` (3.4), `remoteEnabled` (3.5), items locales (3.6), logs de debug (3.9),
`AppShellData` (3.10) y documentación del repo (3.11).

---

## 2. Qué está implementado y funcionando

### Infraestructura núcleo

| Pieza | Archivo | Estado |
|---|---|---|
| Cliente HTTP con JWT | [authenticated_http_client.dart](../lib/core/api/authenticated_http_client.dart) | Completo. `getJson`/`postJson`/`patchJson`/`deleteJson`/`getBytes`, `API_BASE_URL` por `--dart-define`, mensajes de error desde `message`/`error` (incluye el array de class-validator) y **notificación de 401** |
| Paginación genérica | [paged_result.dart](../lib/core/api/paged_result.dart) | Completo. `PagedResult.fromDynamic` tolera `data`/`items`/`results`/`rows` y `meta`/`pagination` |
| Excepción tipada | [app_failure.dart](../lib/core/error/app_failure.dart) | `AppFailure(message, statusCode)` |
| Lectura de JWT | [jwt_token.dart](../lib/core/auth/jwt_token.dart) | Completo. `payload`, `id`, `roles`, `expiracion`, `estaVencido` con margen de 30 s |
| Reglas de acceso | [roles_panel.dart](../lib/core/auth/roles_panel.dart) | `admin-tecnico` y `admin`, con normalización de guiones y mayúsculas |
| Persistencia de sesión | [session_storage.dart](../lib/core/auth/session_storage.dart) | Completo. `flutter_secure_storage`, token y usuario en claves separadas, tolerante a storage bloqueado o contenido corrupto |
| Canal de expiración | [session_expiration.dart](../lib/core/auth/session_expiration.dart) | Stream broadcast único; lo notifica el HTTP client y lo escucha el `AuthBloc` |
| Ruteo | [app_router.dart](../lib/core/routing/app_router.dart) · [app_routes.dart](../lib/core/routing/app_routes.dart) | Funcional. **Toda** ruta pasa por `SessionGate`; el acceso lo decide el estado de la sesión, no la URL pedida |
| Descarga/apertura de PDF | [open_pdf_bytes.dart](../lib/core/utils/open_pdf_bytes.dart) | Completo, con split web/stub por conditional import |
| Layout de módulo | [module_page_layout.dart](../lib/core/widgets/module_page_layout.dart) | `ModulePageLayout` + `ModuleStatusChip`, usados por las 9 páginas de módulo (no por login ni splash) |

### Shell y autenticación

El circuito de sesión es lo más sólido que se agregó desde el último relevamiento:

- **Login** ([login_page.dart](../lib/features/auth/presentation/pages/login_page.dart), 418 líneas) — formulario contra `POST /auth/login` con el shape exacto del `LoginUserDto` (`{ email, password }`), manejo de 400/401 y mensaje propio para acceso denegado por rol.
- **Guard de rol** — `AuthBloc` rechaza con `AuthAccesoDenegado` a quien no sea `admin-tecnico` ni `admin`. Un `tecnico` con credenciales válidas no entra al panel.
- **Restauración de sesión** — al arrancar, `AuthSessionRestoreRequested` lee el storage y `ValidadorSesionPersistida` revalida: token legible, no vencido y con rol habilitado. **Nada de lo guardado se toma por bueno**: la identidad (id + roles) sale del token firmado y solo email/nombre se leen del usuario persistido, porque `localStorage` se edita a mano. Mientras se lee se muestra [splash_page.dart](../lib/features/auth/presentation/pages/splash_page.dart).
- **Cierre por 401** — un 401 del backend con sesión activa dispara `SessionExpiration`, el `AuthBloc` limpia y `main.dart` descarta las pantallas apiladas y vuelve al login con el motivo. Un 403 no cuenta: ahí el token sirve y lo que falta es permiso.
- **Shell de navegación** ([app_shell_page.dart](../lib/features/app_shell/presentation/pages/app_shell_page.dart), 577 líneas) — navegación superior en desktop y `Drawer` bajo 980px, `AnimatedSwitcher` entre módulos, logout vía `AuthLogoutRequested`. Los 8 módulos se enumeran en [app_module.dart](../lib/features/app_shell/domain/app_module.dart).

### Módulos completos

**Liquidaciones** — [liquidaciones_page.dart](../lib/features/liquidaciones/presentation/pages/liquidaciones_page.dart) (2.786 líneas), [liquidaciones_repository_impl.dart](../lib/features/liquidaciones/data/liquidaciones_repository_impl.dart) (1.801 líneas). Sigue siendo el módulo más maduro:

- Listado con filtros por estado (`todas`/`pendiente`/`aprobada`/`reabierta`), aprobado, `liquidadaPago` y técnico
- Vista de pendientes (`GET /liquidaciones/pendientes`)
- Detalle con desglose de items ([liquidacion_items_breakdown.dart](../lib/features/liquidaciones/presentation/widgets/liquidacion_items_breakdown.dart))
- Cambio de tipo de salida, alta/aprobación/baja de items de servicio
- Aprobar liquidación, reabrir con motivo y consulta del historial de reaperturas
- **Estado `reabierta` con badge propio** ([liquidacion_estado_badge.dart](../lib/features/liquidaciones/presentation/widgets/liquidacion_estado_badge.dart)) y aviso con el motivo registrado: una reabierta sale del circuito de pago hasta volver a aprobarse
- Bloqueo funcional cuando `liquidadaPago = true` (badge `PASADA A PAGO`, sin edición)
- ABM de **tipos de salida** y **tipos de servicio** embebido en esta pantalla
- Regla de negocio aislada y testeada en [liquidacion_pago_calculator.dart](../lib/features/liquidaciones/domain/liquidacion_pago_calculator.dart)

**Pagos a técnicos** — [liquidaciones_pagos_page.dart](../lib/features/liquidaciones/presentation/pages/liquidaciones_pagos_page.dart) (961 líneas) + [liquidaciones_pagos_cubit.dart](../lib/features/liquidaciones/presentation/bloc/liquidaciones_pagos_cubit.dart) (597 líneas):

- Preview por técnico y rango de fechas, confirmación del resumen
- Historial paginado de resúmenes y detalle en modal
- Último resumen por técnico como sugerencia
- Aviso explícito de las liquidaciones reabiertas que quedaron fuera del resumen
- Selección múltiple con contador y total USD, caché de items por liquidación con estados `loading`/`loaded`/`unavailable`/`error` ([liquidacion_items_cache.dart](../lib/features/liquidaciones/presentation/bloc/liquidacion_items_cache.dart))
- Tabla en desktop y tarjetas en pantallas angostas ([resumen_pago_preview_table.dart](../lib/features/liquidaciones/presentation/widgets/resumen_pago_preview_table.dart))

**Técnicos** — [tecnicos_page.dart](../lib/features/tecnicos/presentation/pages/tecnicos_page.dart) (1.078 líneas) + [tecnicos_repository_impl.dart](../lib/features/tecnicos/data/tecnicos_repository_impl.dart) (133). Nuevo desde el último relevamiento y el único módulo que consume **todos** sus endpoints:

- Listado paginado con búsqueda (`q`) y selector activos/inactivos. El param `activos` viaja siempre explícito, porque el backend asume `true` si se omite y los inactivos nunca aparecerían
- Alta de técnico (`POST /auth/tecnicos`); el rol lo asigna el backend, no se manda desde el panel
- Edición de `fullName`/`email` (el panel manda siempre los dos, porque el backend rechaza el PATCH vacío)
- Activar / desactivar con confirmación previa
- Detalle con fechas de alta y última modificación
- Los shapes de los DTO están documentados en el propio [tecnicos_repository.dart](../lib/features/tecnicos/domain/tecnicos_repository.dart)

**Servicios** — [servicios_page.dart](../lib/features/servicios/presentation/pages/servicios_page.dart) (678) + [servicio_detalle_page.dart](../lib/features/servicios/presentation/pages/servicio_detalle_page.dart) (546):

- Listado con **paginación real en el servidor** y filtros por canal y técnico (el selector de técnicos sale de `GET /auth/tecnicos?activos=true`, deduplicado y ordenado por nombre)
- Detalle completo: equipo, cliente, diagnóstico, facturación con items, firma (hash SHA256, fecha)
- Ver / abrir / copiar URL del PDF de la orden (`GET /servicios/:id/documento` y `/documento/pdf`), con normalización de URLs relativas

**Clientes** — [clientes_page.dart](../lib/features/clientes/presentation/pages/clientes_page.dart) (929): listado paginado, búsqueda vía `GET /clientes/buscar`, alta, edición y modal de detalle.

**Repuestos** — [repuestos_page.dart](../lib/features/repuestos/presentation/pages/repuestos_page.dart) (829): grilla paginada sobre `GET /repuestos/listado` con búsqueda y filtro activo/inactivo/todos (server-side), alta y edición con precio USD.

**Catálogos** — [catalogos_page.dart](../lib/features/catalogos/presentation/pages/catalogos_page.dart) (675): zonas, categorías de producto y productos. Alta, edición y toggle activo/inactivo; los productos se cargan agrupados por categoría. Los bodies salen de los DTO del backend, documentados en el propio repositorio.

**Precios** — [precios_page.dart](../lib/features/precios/presentation/pages/precios_page.dart) (470): valores actuales de cotización y tarifa km, historial combinado paginado, alta manual de ambos.

### Tests

**105 tests, todos verdes** (`flutter test`), en 14 archivos más un helper. Ya no están
concentrados en un solo módulo:

| Área | Tests | Archivos |
|---|---|---|
| Liquidaciones | 44 | [repository_impl](../test/features/liquidaciones/data/liquidaciones_repository_impl_test.dart) (10) · [pago_calculator](../test/features/liquidaciones/domain/liquidacion_pago_calculator_test.dart) (3) · [contract_regression](../test/features/liquidaciones/domain/liquidaciones_contract_regression_test.dart) (5) · [bloc_regression](../test/features/liquidaciones/presentation/liquidaciones_bloc_regression_test.dart) (4) · [pagos_cubit](../test/features/liquidaciones/presentation/liquidaciones_pagos_cubit_test.dart) (8) · [pagos_page](../test/features/liquidaciones/presentation/liquidaciones_pagos_page_test.dart) (14) |
| Auth | 33 | [auth_bloc](../test/features/auth/presentation/auth_bloc_test.dart) (18) · [validador_sesion_persistida](../test/features/auth/domain/validador_sesion_persistida_test.dart) (9) · [auth_repository_impl](../test/features/auth/data/auth_repository_impl_test.dart) (6) |
| core/auth | 12 | [jwt_token](../test/core/auth/jwt_token_test.dart) (7) · [session_storage](../test/core/auth/session_storage_test.dart) (5) |
| Técnicos | 11 | [tecnicos_repository_impl](../test/features/tecnicos/data/tecnicos_repository_impl_test.dart) (7) · [tecnicos_page](../test/features/tecnicos/presentation/tecnicos_page_test.dart) (4) |
| Shell / login | 5 | [widget_test.dart](../test/widget_test.dart) — incluye que el botón de salir cierra la sesión y vuelve al login |

Hay un helper compartido, [test/support/jwt_de_prueba.dart](../test/support/jwt_de_prueba.dart),
para armar tokens firmados de prueba.

### Cobertura de endpoints

De los **57 endpoints** que el `CLAUDE.md` asigna a este panel, **53 están consumidos (93%)**.
Los 4 ausentes se detallan en las secciones 3 y 4. El panel además consume dos que no figuran
en esa lista: `POST /auth/login` y `GET /liquidaciones/:id/reaperturas` (este último sí está
en la colección Postman).

| Grupo | Consumidos |
|---|---|
| Técnicos | 5 / 5 |
| Clientes | 5 / 5 |
| Cotización y tarifa km | 6 / 6 |
| Tipos de salida y servicio | 6 / 6 |
| Liquidaciones | 10 / 10 |
| Catálogos (zonas, categorías, productos) | 9 / 9 |
| Servicios | 4 / 5 — falta `GET /servicios/:id/repuestos` |
| Repuestos | 3 / 4 — falta `GET /repuestos?q=` |
| Pagos | 5 / 7 — faltan `para-pago` y `marcar-pagadas` |

---

## 3. Qué está a medias

**No hay un solo comentario `TODO`, `FIXME` ni `HACK` en todo `lib/`.** Lo que sigue son
incompletitudes reales detectadas leyendo el código, no marcas dejadas por el autor.

### 3.1 🔴 Catálogos no puede ver ni reactivar lo que desactiva

Es el hallazgo nuevo más importante de este relevamiento, y aparece precisamente porque
`docs/endpoints.md` se actualizó en el último commit.

El diálogo de edición de [catalogos_page.dart](../lib/features/catalogos/presentation/pages/catalogos_page.dart#L289)
tiene un switch `activo` que viaja en el `PATCH`. Pero `_fetchSimple` en
[catalogos_repository_impl.dart](../lib/features/catalogos/data/catalogos_repository_impl.dart#L180)
solo manda query params cuando el endpoint es `/repuestos/listado`:

```dart
final filtraEnServidor = endpoint == '/repuestos/listado';
```

Y el comentario que lo justifica dice que `/zonas` y `/categorias-producto` *"no declaran
query params"*. **Eso ya no es cierto.** `endpoints.md` (líneas 654-678) documenta que los
tres listados aceptan `activo` con valores `true` / `false` / `todos`, y que **omitirlo
devuelve solo los activos**, porque esos tres endpoints los consume también la app del
técnico.

Consecuencia concreta: si el admin desactiva una zona, una categoría o un producto,
**desaparece del listado y no hay forma de volver a activarlo desde el panel.** El módulo
Repuestos no tiene el problema porque en `/repuestos/listado` omitir `activo` sí trae ambos.
La corrección es de una línea por endpoint: mandar `activo=todos` (ojo con la letra final:
acá es `todos`, no `todas`).

`fetchProductosPorCategoria` tiene el mismo techo: manda solo `categoriaId`, así que la
vista agrupada por categoría nunca muestra productos inactivos.

### 3.2 Pagos: dos endpoints del flujo sin implementar

Sin cambios desde el relevamiento anterior.

- `GET /liquidaciones/para-pago` — **no se llama desde ningún lado.** La pantalla de pagos
  usa solo `resumen-pago/preview`. La vista "liquidaciones listas para pago" que describe
  el `CLAUDE.md` no existe como tal.
- `PATCH /liquidaciones/marcar-pagadas` — **no se llama desde ningún lado.** El marcado en
  lote solo ocurre indirectamente al confirmar un resumen.

Los dos están documentados y el código los menciona en comentarios
([liquidaciones_repository.dart:214-215](../lib/features/liquidaciones/domain/liquidaciones_repository.dart#L214-L215)),
pero nunca se llaman.

### 3.3 Flag muerto: `remoteEnabled`

`LiquidacionItemsResponse.remoteEnabled` existe en el modelo y la vista lo lee
([liquidaciones_page.dart:1400](../lib/features/liquidaciones/presentation/pages/liquidaciones_page.dart#L1400)),
pero el repositorio lo emite **siempre en `true`**
([liquidaciones_repository_impl.dart:592](../lib/features/liquidaciones/data/liquidaciones_repository_impl.dart#L592)).
Es un feature flag que quedó cableado en una sola posición.

### 3.4 Items locales no persistidos

Si `POST /liquidaciones/:id/items` no devuelve el item creado, la vista fabrica uno local
con `id: 'tmp-<timestamp>'` e `isPersisted: false`
([liquidaciones_page.dart:1536-1541](../lib/features/liquidaciones/presentation/pages/liquidaciones_page.dart#L1536-L1541)).
Ese item se muestra en la grilla pero no se puede aprobar ni borrar — la UI avisa
"Este item es local y no puede aprobarse aun". Es un parche de optimistic UI, no un flujo cerrado.

Vale notar que el repositorio ya intenta tres lugares para encontrar el item devuelto
(raíz, `data`, `item`), así que el camino local debería ser raro.

### 3.5 Paginación resuelta en cliente, con una rama inalcanzable

- `/zonas`, `/categorias-producto` y `/productos` se traen enteros y se paginan en memoria.
  Acá es una decisión correcta: el backend no pagina esos listados.
- `fetchCatalogos` con `tipo: 'todos'` dispara 3 requests en paralelo, concatena y pagina a
  mano. **Esa rama no es alcanzable:** `catalogos_page` define `_tipos = ['zona', 'categoria',
  'producto']` y arranca en `zona`, y `repuestos_page` siempre manda `repuesto`. Adentro de
  esa rama hay además una línea doblemente muerta (`: <String>[normalizedTipo]`), inalcanzable
  por el `if` que la precede.

### 3.6 Param muerto en el cliente HTTP: `keepEmptyQueryParameters`

`AuthenticatedHttpClient` thread-ea `keepEmptyQueryParameters` por sus 6 métodos públicos,
pero **ningún llamador de `lib/` lo pasa en `true`** (solo aparece en los fakes de tests, que
replican la firma). Quedó de la rama de búsqueda rápida de repuestos que se eliminó.

### 3.7 Logs de debug en producción

[servicios_repository_impl.dart](../lib/features/servicios/data/servicios_repository_impl.dart)
vuelca la respuesta completa de `GET /servicios` y `GET /servicios/:id` con
`developer.log` + `JsonEncoder.withIndent` (líneas 32 y 132). Es el único lugar del repo con
logs de debug y sigue igual que en el relevamiento anterior.

### 3.8 `AppShellData` no se usa

[app_shell_data.dart](../lib/features/app_shell/data/app_shell_data.dart) define
`availableModules()`; el shell usa `AppModule.values` directamente. Clase huérfana, sin
referencias en `lib/` ni en `test/`.

### 3.9 Filtros de servicios disponibles y no usados

`GET /servicios` acepta según la colección Postman `canal`, `lugarProvinciaId`, `resuelto`,
`page` y `limit`. El panel usa `canal`, `tecnicoId`, `page` y `limit`: **`lugarProvinciaId` y
`resuelto` están disponibles y no se ofrecen**. Filtrar por zona o por resuelto/no resuelto
sería barato de agregar.

En sentido inverso, el commit de paginación **quitó** la búsqueda por texto y el filtro por
estado de orden que la versión anterior de este documento listaba como implementados. La
decisión está justificada en el código
([servicios_repository.dart:129-130](../lib/features/servicios/domain/servicios_repository.dart#L129-L130)):
el `FilterServiciosDto` no los acepta, así que antes se resolvían adivinando nombres de
parámetros. Es una pérdida de función a cambio de corrección.

### 3.10 Gate de rol redundante en liquidaciones

`_canReopenByRole` en [liquidaciones_page.dart:65-72](../lib/features/liquidaciones/presentation/pages/liquidaciones_page.dart#L65-L72)
decide si mostrar "Reabrir" con `RolesPanel.puedeAccederAlPanel(JwtToken.roles(token))`, que
es **la misma condición que ya exigió `SessionGate` para dejar entrar al panel**. En la
práctica es siempre `true`. No es un bug (es defensivo, y ya no decodifica el JWT a mano como
antes), pero tampoco distingue nada: si la intención es que solo `admin` pueda reabrir y no
`admin-tecnico`, hoy no lo hace.

### 3.11 Documentación del repo desactualizada

- [README.md](../README.md) sigue siendo el template de `flutter create` ("A new Flutter project").
- `pubspec.yaml` tiene `description: "A new Flutter project."`.
- [Progreso_app.md](../Progreso_app.md) es una nota de progreso de un sprint puntual, no un estado general, y termina con una frase cortada ("Se pasaron a issue").
- `AGENTS.md` ya no existe en el árbol (el borrado quedó commiteado); su contenido vive en `CLAUDE.md`.

---

## 4. Qué falta por completo

Contrastado contra `CLAUDE.md` (el documento de arquitectura vigente) y contra
[plan-web-admin-tecnico.md](plan-web-admin-tecnico.md).

### 4.1 Módulo Dashboard — no existe

Es la única de las 9 pantallas del `CLAUDE.md` que falta entera, y el `CLAUDE.md` la lista
primero: métricas de servicios del mes, servicios a campo, liquidaciones pendientes de
aprobar, listas para pago, técnicos activos, más accesos rápidos.

**No hay carpeta `lib/features/dashboard/`, ni ruta en `AppRoutes`, ni entrada en `AppModule`.**
`AppRouter._moduleForRoute` cae por default en `AppModule.servicios`, así que cualquier ruta
desconocida —incluida `/`— abre Servicios.

Se puede armar componiendo llamadas que ya existen: `/servicios`,
`/liquidaciones?estado=pendiente`, `/auth/tecnicos?activos=true`; para "listas para pago"
haría falta `GET /liquidaciones/para-pago`, que hoy está sin consumir (3.2).

### 4.2 Sistema de diseño `app_theme.dart` — no existe

El `CLAUDE.md` lo declara **obligatorio**: `lib/core/theme/app_theme.dart` con paleta
azul `#1A3A5C` / naranja `#E85D04`, modo claro y oscuro con toggle, y los widgets
`EstadoBadge`, `BotonAccion`, `CardSeccion`, `MetricaCard`, `CampoBusqueda`.

La realidad, sin cambios desde el relevamiento anterior:

- **No existe el directorio `lib/core/theme/`.** El tema está inline en
  [main.dart](../lib/main.dart) (299 líneas, de las cuales la mayoría es el `ThemeData` más
  el escalado responsive), es **dark-only**, y su paleta es otra (`#081B30`, `#69C3FF`).
- **No hay toggle de tema.**
- **Ninguno de los 5 widgets del `CLAUDE.md` existe con ese nombre.** Lo más cercano son
  `ModuleStatusChip` (73 usos, pero recibe los colores por parámetro en vez de
  derivarlos de un tipo semántico) y el nuevo `LiquidacionEstadoBadge`, que sí resuelve los
  colores desde el estado — pero solo para liquidaciones y con la paleta hardcodeada en
  `LiquidacionEstadoColores`.
- Hay **412 literales `Color(0x…)` repartidos en 18 archivos** (73 solo en
  `liquidaciones_page.dart`). Eran 371 en 15 archivos: la deuda creció con cada pantalla nueva,
  que es exactamente lo que se esperaba.

### 4.3 Layout lateral especificado — no implementado

El `CLAUDE.md` describe sidebar de 240px colapsable a 64px bajo 900px. Lo implementado es
navegación **superior** que colapsa a `Drawer` bajo **980px**
([app_shell_page.dart:33](../lib/features/app_shell/presentation/pages/app_shell_page.dart#L33)).
Funciona, pero no es lo diseñado.

### 4.4 Historial de servicios por cliente

`CLAUDE.md` → "Clientes: ver historial de servicios por cliente". `grep -rn "servicio"
lib/features/clientes` no devuelve nada: no hay ninguna consulta de servicios en el módulo.

### 4.5 Filtro por fecha en servicios

`CLAUDE.md` → "filtros por técnico, canal, fecha". `ServiciosQuery` tiene `canal`,
`tecnicoId`, `page` y `limit`. **No hay filtro por fecha ni rango.**

A diferencia de los otros huecos, este **no se puede cerrar solo desde el panel**: ni
`endpoints.md` ni la colección Postman documentan params de fecha para `GET /servicios`. El
comentario del repositorio los menciona, pero conviene confirmar con el backend si existen
antes de implementarlo.

### 4.6 Repuestos de un servicio

`GET /servicios/:id/repuestos` figura en `CLAUDE.md` y en `endpoints.md` (línea 794); el
detalle de servicio no lo consume.

### 4.7 Búsqueda rápida de repuestos

`GET /repuestos?q=` está documentado y en la lista del `CLAUDE.md`. El código nunca lo llama
en GET: `_fetchByTipo` siempre usa `/repuestos/listado`. El literal `'/repuestos'` solo se usa
para el `POST` y el `PATCH`. Puede ser deliberado (el listado paginado cubre el caso del admin
y `?q=` está pensado para la app del técnico) — conviene decidirlo y sacarlo de la lista.

### 4.8 Carga de PDF firmado

`POST /servicios/:id/documento/firmado` está documentado en `endpoints.md` (líneas 557-577,
`multipart/form-data`) y es la historia de usuario #3 del
[plan-web-admin-tecnico.md](plan-web-admin-tecnico.md). `grep -rn "firmado" lib` no devuelve
ninguna llamada. Sigue **fuera** de la lista de endpoints del `CLAUDE.md`, así que
probablemente se descartó a propósito — conviene confirmarlo y cerrar el plan.

### 4.9 Capa de casos de uso

`CLAUDE.md` → "Los use cases tienen un único método `ejecutar(...)`" y "Los BLoCs reciben
use cases por constructor". **No existe ningún use case**: `grep -rn "ejecutar(" lib` no
devuelve nada. Los BLoCs reciben repositorios directamente.

### 4.10 Inyección de dependencias

`CLAUDE.md` → "DI: clase `AppDependencies` sin get_it" y "BLoCs: MultiBlocProvider en main.dart".
**No existe `AppDependencies`** ni `lib/core/di/`.

Hubo un avance parcial: `main.dart` ahora sí provee un BLoC —`BlocProvider<AuthBloc>`, con el
`AuthRepository` inyectable para tests— pero no es un `MultiBlocProvider`, y cada página sigue
creando su propio `BlocProvider` y su propio `RepositoryImpl`, que a su vez instancia su propio
`AuthenticatedHttpClient`. Las páginas nuevas (`tecnicos`, `liquidaciones_pagos`) al menos
aceptan el repositorio por constructor con default, que es lo que hace testeable el widget.

### 4.11 CI

`.github/` tiene agents, instructions y prompts de Copilot, pero **no hay `workflows/`**.
Nada corre `flutter analyze` ni `flutter test` automáticamente, con 105 tests verdes que
podrían estar protegiendo cada PR.

### 4.12 Tests de los módulos restantes

Siguen sin ningún test: **servicios, clientes, catálogos, repuestos, precios, app_shell y
routing**. Son 7.002 líneas de `lib/` sin cobertura, incluido `catalogos_repository_impl`, que
es donde apareció el problema de 3.1.

---

## 5. Estructura actual del proyecto

```
web_admin_tecnico/
├── CLAUDE.md                  # arquitectura vigente (reemplaza al AGENTS.md borrado)
├── Progreso_app.md            # nota de sprint, desactualizada
├── README.md                  # template de flutter create, sin tocar
├── pubspec.yaml               # flutter_bloc, http, flutter_secure_storage,
│                              # cupertino_icons (sin usar), flutter_lints
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
│   ├── endpoints.md                        # fuente de verdad de la API
│   ├── backend_feedback.postman_collection.json
│   ├── plan-web-admin-tecnico.md           # plan por sprints
│   ├── sistema_feedback_arquitectura.md
│   └── ESTADO.md                           # este documento
│
├── lib/                                    # 65 archivos · 19.208 líneas
│   ├── main.dart                           # tema inline dark-only + BlocProvider<AuthBloc>
│   │                                       # + escalado responsive          (299)
│   ├── core/                               # 1.062 líneas
│   │   ├── api/        authenticated_http_client.dart (190) · paged_result.dart (102)
│   │   ├── auth/       auth_session.dart (81) · jwt_token.dart (80)
│   │   │               session_storage.dart (83) · session_store.dart (23)
│   │   │               session_expiration.dart (24) · roles_panel.dart (21)
│   │   ├── error/      app_failure.dart
│   │   ├── routing/    app_router.dart · app_routes.dart
│   │   ├── utils/      open_external_url + stub + web
│   │   │               open_pdf_bytes + stub + web
│   │   │               paginated_table_prefs.dart
│   │   └── widgets/    module_page_layout.dart (181) · tech_admin_background.dart (109)
│   │                   (no existe core/theme/ ni core/di/)
│   │
│   └── features/
│       ├── liquidaciones/                  # 8.469 líneas (44% de lib/)
│       │   ├── data/        liquidaciones_repository_impl.dart      (1.801)
│       │   ├── domain/      liquidaciones_repository.dart            (805)
│       │   │                liquidacion_pago_calculator.dart          (14)
│       │   ├── presentation/bloc/    liquidaciones_bloc.dart         (497)
│       │   │                         liquidaciones_pagos_cubit.dart  (597)
│       │   │                         liquidacion_items_cache.dart     (41)
│       │   ├── presentation/pages/   liquidaciones_page.dart       (2.786)
│       │   │                         liquidaciones_pagos_page.dart   (961)
│       │   └── presentation/widgets/ resumen_pago_preview_table.dart (554)
│       │                             liquidacion_items_breakdown.dart(277)
│       │                             liquidacion_estado_badge.dart   (136)
│       ├── servicios/       # 1.900 · data + domain + bloc + 2 pages
│       ├── tecnicos/        # 1.531 · data + domain + bloc + page   (NUEVO)
│       ├── clientes/        # 1.314 · data + domain + bloc + page
│       ├── catalogos/       # 1.284 · data + domain + bloc + page (zonas/categorías/productos/repuestos)
│       ├── precios/         #   908 · data + domain + bloc + page (cotización + tarifa km)
│       ├── auth/            #   896 · data + domain(+validador) + bloc
│       │                    #         + login_page + splash_page + session_gate
│       ├── repuestos/       #   829 · SOLO page — reusa CatalogosBloc/Repository
│       └── app_shell/       #   716 · domain/app_module + bloc + page (+ data huérfana)
│                            # (no existe features/dashboard/)
│
├── test/                                   # 15 archivos · 3.182 líneas · 105 tests OK
│   ├── widget_test.dart                    # login + logout del shell            (5)
│   ├── support/jwt_de_prueba.dart          # helper de tokens firmados
│   ├── core/auth/                          # jwt_token (7) · session_storage (5)
│   └── features/
│       ├── auth/                           # repository (6) · validador (9) · bloc (18)
│       ├── tecnicos/                       # repository (7) · page (4)
│       └── liquidaciones/                  # 44 tests en 6 archivos
│                                           # (servicios, clientes, catalogos,
│                                           #  repuestos y precios sin tests)
│
├── web/                                    # target real
└── android/ ios/ linux/ macos/ windows/    # scaffolding sin uso
```

---

## 6. Próximos pasos sugeridos

Ordenados por relación impacto / esfuerzo. Los dos primeros de la lista anterior
(persistir la sesión, validar el rol) y el tercero (eliminar los fallbacks) ya están hechos.

**1. Mandar `activo=todos` en los listados de catálogos** (ver 3.1). Es el único bug funcional
abierto: hoy desactivar una zona, categoría o producto es irreversible desde el panel. Son
tres líneas en `_fetchSimple` más una en `fetchProductosPorCategoria`, y conviene agregar el
selector activo/inactivo/todos que ya tiene Repuestos. **Es lo más urgente del documento.**

**2. Crear `lib/core/theme/app_theme.dart`** con la paleta y los widgets del `CLAUDE.md`, y
migrar los 412 colores literales. La deuda creció de 371 a 412 desde el último relevamiento
justamente por no haberlo hecho antes de sumar Técnicos: conviene cerrarlo antes del Dashboard.
Decidir explícitamente si se mantiene el dark-only actual o se implementa el toggle especificado
—y si se mantiene, corregir el `CLAUDE.md`. `LiquidacionEstadoBadge` es un buen punto de
partida: generalizarlo a `EstadoBadge` con tipo semántico.

**3. Implementar el Dashboard.** Es la última pantalla que falta. Puede armarse componiendo
llamadas existentes, y de paso da uso a `GET /liquidaciones/para-pago`.

**4. Agregar CI.** Un workflow que corra `flutter analyze` + `flutter test` en cada PR. Con
105 tests verdes y `analyze` limpio, arranca sin deuda que arrastrar y protege lo que se
construyó en estos cinco commits.

**5. Cerrar el circuito de pagos:** `GET /liquidaciones/para-pago` como vista propia y
`PATCH /liquidaciones/marcar-pagadas` para el marcado en lote. Son los dos únicos endpoints del
flujo de liquidaciones/pagos sin consumir, y el `CLAUDE.md` los describe como pantalla.

**6. Romper `liquidaciones_page.dart` (2.786 líneas).** Extraer los diálogos de detalle, de
tipos de salida y de tipos de servicio a widgets propios, y mover las 6 llamadas directas al
repositorio hacia el `LiquidacionesBloc`. Es el 14% de `lib/` en un archivo.

**7. Extender los tests a los módulos sin cobertura**, empezando por
`catalogos_repository_impl` (donde vive 3.1) y `servicios`.

**8. Cerrar los huecos menores de endpoints:** historial de servicios por cliente,
`GET /servicios/:id/repuestos` en el detalle, y los filtros `lugarProvinciaId` / `resuelto`
que el backend ya ofrece.

**9. Confirmar con el backend** si `GET /servicios` acepta filtros de fecha (4.5) y si
`POST /servicios/:id/documento/firmado` sigue en alcance (4.8). Son los dos únicos puntos que
no se pueden resolver leyendo este repo.

**10. Limpieza:** sacar los dos `developer.log`, borrar `AppShellData`, eliminar la rama
`todos` inalcanzable de `catalogos_repository_impl`, sacar `keepEmptyQueryParameters` del
cliente HTTP, resolver `remoteEnabled`, y actualizar README y `description` del `pubspec.yaml`.

**11. Alinear `CLAUDE.md` con el código** en las convenciones que se decidió no aplicar
(ver 7.3). Hoy quien lo lea para orientarse va a buscar archivos que no existen.

---

## 7. Deuda técnica o problemas detectados

### 7.1 🔴 Catálogos no puede ver ni reactivar inactivos

Detallado en 3.1. Es el único hallazgo de esta revisión con impacto funcional directo sobre el
usuario: un ABM que puede desactivar pero no reactivar. Aparece porque el código quedó atrás
respecto de un `endpoints.md` que se actualizó en el mismo commit.

### 7.2 🟠 Las vistas contienen lógica de negocio y llaman a repositorios

La regla marcada como **fundamental** en el `CLAUDE.md` es: *"Las vistas no tienen lógica.
Cero lógica de negocio fuera de los BLoCs"*. Hay **15 llamadas directas a repositorios desde
`presentation/pages/`** (eran 9; crecieron con las pantallas nuevas):

| Página | Llamadas |
|---|---|
| `liquidaciones_page.dart` | `fetchLiquidacionItems` ×2, `fetchReaperturas`, `addLiquidacionItem`, `approveLiquidacionItem`, `deleteLiquidacionItem` |
| `servicio_detalle_page.dart` | `fetchServicioDetalle`, `fetchDocumento`, `fetchDocumentoPdfBytes` ×2 |
| `clientes_page.dart` | `fetchClienteDetalle` ×2 |
| `catalogos_page.dart` | `fetchCategorias` |
| `liquidaciones_pagos_page.dart` | `fetchLiquidacionItems` |
| `tecnicos_page.dart` | `fetchTecnicoDetalle` |

Además la vista de liquidaciones mantiene estado de negocio en variables locales
(`items`, `meta`) y recalcula `_buildItemsMeta` en 6 lugares distintos. Lo que **sí** salió de
la vista es la decodificación del JWT: ahora vive en `core/auth/jwt_token.dart`.

Vale aclarar que en las pantallas nuevas el patrón es intencional y acotado: el repositorio
entra por constructor con default (`repository ?? TecnicosRepositoryImpl()`) para que el widget
sea testeable, y las llamadas directas son cargas de detalle puntuales dentro de un diálogo,
no lógica de negocio. Sigue siendo una divergencia con la regla declarada.

### 7.3 🟠 Convenciones de arquitectura del `CLAUDE.md` no aplicadas

| Convención declarada | Realidad |
|---|---|
| "Estado: flutter_bloc + **equatable**" · "Props de Equatable siempre declarados" | **`equatable` no está en `pubspec.yaml`.** Ningún modelo ni estado lo extiende → todos los `BlocBuilder` re-renderizan aunque el estado sea equivalente |
| "Storage: flutter_secure_storage para el token" | ✅ **Cumplido** desde `a6c690b` |
| "DI: clase `AppDependencies`" | No existe; cada página instancia su repo y su `AuthenticatedHttpClient` |
| "BLoCs: MultiBlocProvider en main.dart" | Parcial: hay un `BlocProvider<AuthBloc>`, no un `MultiBlocProvider`; los demás BLoCs los provee cada página |
| "Routing: Navigator 2.0 nativo via BlocBuilder" | Navigator 1.0 con `onGenerateRoute`, pero **el guard sí es un `BlocBuilder`** (`SessionGate`), que es la parte que importaba |
| "Los use cases tienen un único método `ejecutar(...)`" | No hay capa de use cases |
| "DTOs con `fromJson` factory y `toJson` method" | Parcial: `AuthSession` tiene `fromJson`/`toJson`; el resto se parsea inline dentro de los repositorios |
| "Excepciones tipadas `ServerException`/`AuthException`/`NetworkException`" | Un único `AppFailure` con `statusCode`. Funciona bien y es más simple |

Varias de estas son decisiones deliberadas de simplificación, no errores. Pero el `CLAUDE.md`
las presenta como vigentes, así que **o se corrige el código o se corrige el documento**.

### 7.4 🟠 El sistema de diseño obligatorio no existe

Detallado en 4.2. Sin `app_theme.dart`, sin los 5 widgets, sin toggle de tema, con otra paleta
que la especificada y con **412 colores hardcodeados en 18 archivos**. La deuda creció un 11%
desde el relevamiento anterior.

### 7.5 🟠 `liquidaciones_page.dart`: 2.786 líneas en un archivo

El 14% de todo `lib/` en un solo archivo, con 73 colores hardcodeados y los ABM de tipos de
salida y tipos de servicio embebidos. Es difícil de testear y de revisar en PRs. El segundo
archivo más grande es `liquidaciones_repository_impl.dart` (1.801), y el tercero
`tecnicos_page.dart` (1.078): la tendencia a la página monolítica se repitió en el módulo nuevo.

### 7.6 🟡 Duplicación entre `repuestos_page` y `catalogos_page`

Son 1.504 líneas que manejan el mismo `CatalogosBloc` y el mismo `CatalogosRepository` con
grillas, diálogos de alta/edición, paginación y filtros muy parecidos. `repuestos/` además
no tiene `data/` ni `domain/` propios — rompe la estructura DDD que sigue el resto de features.
La ironía es que la duplicación no alcanzó para copiar lo que hacía falta: el filtro
activo/inactivo está en `repuestos_page` y no en `catalogos_page` (3.1).

### 7.7 🟡 Ubicación inconsistente de los tipos de salida y servicio

`CLAUDE.md` los pone en "Precios y tarifas" junto a tarifa km y cotización. En el código
viven en `liquidaciones` (repositorio, bloc y UI), mientras que `precios` solo maneja
cotización y tarifa km. La pantalla "Precios" (470 líneas) queda más chica de lo especificado
y la de liquidaciones (2.786) más cargada.

### 7.8 🟡 Código muerto acumulado

- La rama `tipo: 'todos'` de `fetchCatalogos`, inalcanzable (3.5), con una línea doblemente
  muerta adentro.
- `keepEmptyQueryParameters` en los 6 métodos del cliente HTTP, nunca `true` (3.6).
- `AppShellData`, sin referencias (3.8).
- `remoteEnabled`, cableado en `true` (3.3).
- `cupertino_icons` en `pubspec.yaml` sin usar (`grep -rn "cupertino" lib` → vacío).

### 7.9 🟡 Scaffolding y herramientas ajenas

- `android/`, `ios/`, `linux/`, `macos/`, `windows/` son scaffolding para plataformas que el
  proyecto no soporta ("solo web, no compila a mobile").
- El repo incluye `.github/modernize/java-upgrade/hooks/` — herramientas de upgrade de Java,
  ajenas a un proyecto Flutter.

### 7.10 🟡 Warnings de `flutter analyze`

7 `info`, ninguno bloqueante, los mismos que en el relevamiento anterior:

- 4 por `dart:html` deprecado en `open_external_url_web.dart` y `open_pdf_bytes_web.dart`
  (migrar a `package:web` + `dart:js_interop`)
- 2 `unnecessary_underscores` en `clientes_page.dart:693` y `repuestos_page.dart:630`
- 1 `unnecessary_import` de `dart:async` en `liquidaciones_bloc_regression_test.dart:1`

### 7.11 🟢 El token se guarda en `localStorage` del navegador

`SecureSessionStorage` usa `flutter_secure_storage`, que en web cifra sobre `localStorage`. Es
la opción razonable para una app web sin backend de sesión, y el código lo asume correctamente:
`ValidadorSesionPersistida` **no confía en nada de lo guardado** y saca la identidad del token
firmado, con el comentario explícito de que `localStorage` se edita a mano. Queda anotado como
característica del diseño, no como defecto: un XSS en el panel puede leer el token, y el techo
real de exposición lo pone el `expiresIn: 2h` del backend.

---

## Porcentaje aproximado de avance: **82%**

### Cómo se compone

| Dimensión | Avance | Antes | Fundamento |
|---|---|---|---|
| Módulos funcionales | **~88%** | 78% | 8 de 9 pantallas del `CLAUDE.md` existen y están conectadas. Falta solo el Dashboard; Precios queda parcial porque los tipos de salida/servicio viven en Liquidaciones |
| Cobertura de endpoints | **~93%** | 89% | 53 de 57 operaciones consumidas. Faltan `para-pago`, `marcar-pagadas`, `GET /servicios/:id/repuestos` y `GET /repuestos?q=` |
| Infraestructura núcleo | **~85%** | 75% | Sesión persistente con revalidación de rol, cierre global por 401, guard de ruta por estado, cliente HTTP, paginación y errores sólidos. Falta DI centralizada y la capa de use cases |
| Sistema de diseño | **~30%** | 25% | Hay un tema coherente, un layout de módulo reutilizable y un badge de estado semántico, pero no es el especificado: sin `app_theme.dart`, sin los 5 widgets, sin toggle, 412 colores hardcodeados |
| Tests | **~55%** | 35% | 105 tests y `analyze` limpio, con auth y el circuito de sesión bien cubiertos. Todavía 7 features sin ningún test y sin CI |
| Adherencia a convenciones | **~45%** | 40% | Secure storage cumplido y los fallbacks eliminados; siguen sin aplicarse equatable, DI, use cases, MultiBlocProvider y DTOs, más 15 llamadas directas a repositorios desde vistas |

El número global pesa las dos primeras dimensiones por encima de las tres últimas: un panel que
cubre el ciclo de negocio completo está más avanzado que uno con el sistema de diseño prolijo y
media funcionalidad. Con el mismo criterio, el relevamiento anterior daba 70%.

### Lectura

El **núcleo de negocio está terminado y el circuito de acceso ahora también**. Liquidaciones y
Pagos —lo más complejo y lo que justifica el panel— cubren el ciclo completo descrito en el
`CLAUDE.md`, incluido el estado `reabierta` que se agregó en este período, con la regla de
cálculo aislada y testeada. Servicios, Clientes, Repuestos, Catálogos, Precios y el nuevo
Técnicos están operativos.

Lo importante de estos cinco commits no es tanto lo que sumaron como lo que sacaron: **el panel
pasó de adivinar el contrato de la API a respetarlo**. Los fallbacks que probaban hasta 144
requests por listado desaparecieron de los cuatro repositorios, y cada operación manda hoy el
shape documentado en `endpoints.md`. Junto con la sesión que sobrevive a un F5 y el cierre
automático por 401, eso convierte el panel en algo usable en jornada real, que es lo que el
documento anterior decía que faltaba.

El 18% restante tiene una sola cosa que rompe algo hoy —**el catálogo que no puede reactivar lo
que desactivó** (3.1), de arreglo trivial— y después es trabajo conocido y acotado: una pantalla
más (Dashboard), el sistema de diseño, CI, y decidir qué convenciones del `CLAUDE.md` se
implementan y cuáles se corrigen en el documento. Ninguna exige rediseñar nada.

Conviene notar el patrón: **la deuda de diseño y de convenciones creció** (de 371 a 412 colores,
de 9 a 15 llamadas directas a repositorios) porque el módulo nuevo se calcó de los existentes.
Cada pantalla que se agregue antes de `app_theme.dart` va a multiplicarla de nuevo.
