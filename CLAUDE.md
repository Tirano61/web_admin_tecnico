# AGENTS.md — Panel Web Admin Técnico

## Descripción general del sistema

Sistema de gestión de servicio técnico para balanzas electrónicas de uso agropecuario. Este repo es el panel web del admin-técnico para administración interna: gestiona técnicos, aprueba y liquida pagos, administra precios, repuestos, tarifas, cotización, clientes y catálogos de productos/zonas. Es una aplicación **Flutter Web**.

Es uno de cuatro repos:
- **backend** — NestJS + PostgreSQL (API compartida)
- **app-tecnico** — Flutter web + APK, carga de servicios
- **admin-web** — este repo
- **feedback-web** — panel de análisis de fallas (repo separado)

---

## Fuentes de verdad para los modelos

Para armar los modelos de parseo y los shapes exactos de request/response, usar SIEMPRE estos archivos del repo backend:
- `endpoints.md` — todos los endpoints con ejemplos de payload y respuesta
- `backend_feedback_postman_collection.json` — colección Postman con requests reales

No inventar campos ni estructuras — copiarlos de esos archivos. Muchos endpoints devuelven `{ data, meta: { page, limit, total, totalPages } }` y aceptan camelCase y snake_case en el body.

---
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

## Stack

- **Flutter Web** — solo web, no compila a mobile
- **Backend** — NestJS en `http://localhost:3000/api/v1`
- **Estado** — flutter_bloc + equatable
- **HTTP** — http con ApiClient wrapper JWT
- **Storage** — flutter_secure_storage para el token
- **DI** — clase `AppDependencies` sin get_it
- **BLoCs** — MultiBlocProvider en main.dart
- **Routing** — Navigator 2.0 nativo via BlocBuilder

---

## Rol que accede a este panel

| Rol | Qué puede hacer |
|---|---|
| `admin-tecnico` | Gestión de técnicos, órdenes, liquidaciones y pagos, precios, repuestos, tarifa km, cotización, clientes, zonas y productos |

El backend también acepta el rol `admin` (superusuario). El panel de feedback/desarrollo (rol `admin-desarrollo`) es un repo separado y administra los catálogos de diagnóstico/resolución — este panel NO los administra.

---

## Regla fundamental de arquitectura

**Las vistas no tienen lógica.** Solo renderizan estado con `BlocBuilder`, escuchan efectos con `BlocListener` y despachan eventos con `context.read<XBloc>().add(XEvent())`. Cero lógica de negocio fuera de los BLoCs.

---

## Pantallas del panel

### Dashboard
- Métricas: total servicios del mes, servicios a campo, liquidaciones pendientes de aprobar, liquidaciones listas para pago, técnicos activos
- Accesos rápidos a las secciones más usadas

### Técnicos
- Listado paginado con búsqueda (`GET /auth/tecnicos?page=&limit=&q=&activos=`)
- Alta de técnico nuevo (crea usuario con rol tecnico)
- Editar datos (fullName, email)
- Activar / desactivar técnico

### Órdenes / Servicios
- Tabla con todos los servicios, filtros por técnico, canal, fecha
- Ver detalle completo de cada servicio (incluye facturación e items)
- Ver y descargar el PDF de la orden (`GET /servicios/:id/documento/pdf`)

### Liquidaciones
- Tabla de liquidaciones con filtros: estado (pendiente/aprobada/reabierta/todas), aprobado, liquidadaPago, técnico
- Ver liquidaciones pendientes: servicios de campo sin liquidación (`GET /liquidaciones/pendientes`)
- Detalle de liquidación: tipo de salida, km, items de servicio con precios snapshot en USD
- Cambiar el tipo de salida asignado (auto-aprueba al editar)
- Asignar hasta 6 tipos de servicio por liquidación (auto-aprueba)
- Aprobar liquidación e items individualmente
- Reabrir una liquidación registrando motivo (para auditoría)

### Pagos a técnicos
- Ver liquidaciones listas para pago (`GET /liquidaciones/para-pago`) — aprobadas y no liquidadas
- Generar preview de resumen por técnico y rango de fechas (`GET /liquidaciones/resumen-pago/preview`)
- Confirmar el resumen y marcar las liquidaciones como pagadas (`PATCH /liquidaciones/resumen-pago/confirmar`)
- Marcar liquidaciones en lote como pagadas (`PATCH /liquidaciones/marcar-pagadas`)
- Ver historial de resúmenes de pago confirmados (`GET /liquidaciones/resumenes-pago`)
- Ver detalle de un resumen (`GET /liquidaciones/resumenes-pago/:id`)

### Clientes
- Listado paginado (`GET /clientes?page=&limit=`) y búsqueda rápida (`GET /clientes/buscar?q=`)
- Alta y edición de clientes
- Ver historial de servicios por cliente

### Repuestos
- Grilla paginada (`GET /repuestos/listado?page=&limit=&q=&activo=`)
- Alta y edición de repuestos con precio en USD
- Activar / desactivar

### Precios y tarifas
- Tipos de salida: nombre, rango de km (km_hasta), precio USD
- Tipos de servicio: nombre y precio USD (hasta 6 por liquidación)
- Tarifa km: valor por km en USD (`GET/POST /tarifa-km`) con historial
- Cotización del dólar: valor actual e historial (se sincroniza sola cada 30 min, pero admin puede cargar manual con `POST /cotizacion`)

### Catálogos de productos y zonas
- Zonas / provincias: listado, alta, editar, activar/desactivar
- Categorías de producto: listado, alta, editar, activar/desactivar
- Productos / modelos: listado filtrable por categoría, alta, editar, activar/desactivar

Nota: los catálogos de diagnóstico y resolución NO se administran acá — son del panel de feedback (admin-desarrollo).

---

## Endpoints que usa este panel

Base URL: `http://localhost:3000/api/v1` · Header `Authorization: Bearer <token>`

### Técnicos
```
GET   /auth/tecnicos?page=&limit=&q=&activos=
POST  /auth/tecnicos
GET   /auth/tecnicos/:id
PATCH /auth/tecnicos/:id
PATCH /auth/tecnicos/:id/estado
```

### Servicios (admin ve todos)
```
GET  /servicios                    filtros por query
GET  /servicios/:id
GET  /servicios/:id/documento
GET  /servicios/:id/documento/pdf
GET  /servicios/:id/repuestos
```

### Clientes
```
GET   /clientes?page=&limit=
GET   /clientes/buscar?q=
GET   /clientes/:id
POST  /clientes
PATCH /clientes/:id
```

### Repuestos
```
GET   /repuestos?q=
GET   /repuestos/listado?page=&limit=&q=&activo=
POST  /repuestos
PATCH /repuestos/:id
```

### Cotización y tarifa km
```
GET  /cotizacion
GET  /cotizacion/historial
POST /cotizacion
GET  /tarifa-km
GET  /tarifa-km/historial
POST /tarifa-km             body: { valorKmUsd, fecha }
```

### Tipos de salida y servicio
```
GET|POST|PATCH  /tipos-salida
GET|POST|PATCH  /tipos-servicio
```

### Liquidaciones
```
GET    /liquidaciones                              filtros: estado, aprobado, liquidadaPago, tecnicoId, page, limit
GET    /liquidaciones/pendientes?tecnicoId=&page=&limit=
GET    /liquidaciones/:id/items
POST   /liquidaciones                              body: { servicio_id, km } (fallback manual)
PATCH  /liquidaciones/:id                          body: { tipo_salida_id }
PATCH  /liquidaciones/:id/aprobar
PATCH  /liquidaciones/:id/reabrir
POST   /liquidaciones/:id/items                    body: { tipo_servicio_id }
PATCH  /liquidaciones/:id/items/:itemId/aprobar
DELETE /liquidaciones/:id/items/:itemId
```

### Pagos
```
GET   /liquidaciones/para-pago?page=&limit=
PATCH /liquidaciones/marcar-pagadas                body: { liquidacionIds: [...] }
GET   /liquidaciones/resumen-pago/preview?tecnicoId=&desde=&hasta=
PATCH /liquidaciones/resumen-pago/confirmar
GET   /liquidaciones/resumenes-pago?tecnicoId=&page=&limit=
GET   /liquidaciones/resumenes-pago/ultimo?tecnicoId=
GET   /liquidaciones/resumenes-pago/:id
```

### Catálogos de zonas y productos
```
GET|POST|PATCH  /zonas
GET|POST|PATCH  /categorias-producto
GET|POST|PATCH  /productos
```

Los endpoints de feedback/analytics (`/stats/*`, `/export`) y los catálogos de diagnóstico/resolución NO se usan en este panel — pertenecen al repo de feedback.

---

## Lógica de liquidaciones — flujo completo

1. El técnico carga un servicio de campo → el backend crea automáticamente una liquidación en estado `pendiente`
2. El admin-técnico ve la liquidación pendiente en su panel
3. Puede cambiar el tipo de salida si lo considera necesario
4. Asigna hasta 6 tipos de servicio realizados
5. Al editar (cambiar salida o agregar/quitar items), la liquidación queda aprobada automáticamente
6. Puede reabrir una liquidación registrando el motivo (auditoría)
7. Cuando llega el momento de pagar: genera un resumen por técnico y rango de fechas, lo confirma y marca las liquidaciones como pagadas
8. Una vez `liquidadaPago = true`, la liquidación no se puede editar más

**Todos los valores en USD** — la conversión a pesos la hace administración al pagar, fuera del sistema.

---

## Sistema de diseño — obligatorio

El archivo `lib/core/theme/app_theme.dart` define todo el sistema visual. Paleta: azul oscuro `#1A3A5C` primario, naranja fuerte `#E85D04` acento, modo claro y oscuro con toggle.

Widgets reutilizables:
```dart
EstadoBadge(tipo: EstadoBadgeTipo.aprobado, texto: 'Aprobado')
BotonAccion(texto: 'Aprobar', icono: Icons.check, onPressed: () {})
CardSeccion(titulo: 'Liquidaciones pendientes', child: ...)
MetricaCard(etiqueta: 'Servicios este mes', valor: '24', icono: Icons.build)
CampoBusqueda(placeholder: 'Buscar técnico...', onChanged: ...)
```

Estados sugeridos para las liquidaciones: pendiente (naranja), aprobada (verde), reabierta (info azul), pagada (gris/neutro).

---

## Layout general

```
┌─────────────────────────────────────────────┐
│ AppBar — título de sección + toggle tema     │
├──────────┬──────────────────────────────────┤
│ Sidebar  │  Contenido (padding 24px)         │
│ 240px    │                                   │
│ Nav Rail │                                   │
└──────────┴──────────────────────────────────┘
```

Bajo 900px el sidebar se colapsa a íconos (64px).

---

## Estructura de carpetas — DDD

```
lib/
├── core/
│   ├── api/           # ApiClient con JWT
│   ├── auth/          # SecureStorage
│   ├── error/         # Excepciones tipadas
│   ├── di/            # AppDependencies
│   ├── theme/         # app_theme.dart
│   └── widgets/       # widgets compartidos
│
├── features/
│   ├── auth/                  # Login
│   ├── dashboard/             # Métricas
│   ├── tecnicos/              # Gestión de técnicos
│   ├── servicios/             # Listado y detalle de servicios
│   ├── liquidaciones/         # Aprobación de liquidaciones
│   ├── pagos/                 # Resúmenes y pagos a técnicos
│   ├── clientes/              # Administración de clientes
│   ├── repuestos/             # Administración de repuestos
│   ├── precios/               # Tipos de salida/servicio, tarifa km, cotización
│   └── catalogos/             # Zonas, categorías, productos
│
└── main.dart
```

---

## Manejo de errores

```dart
class ServerException implements Exception { final String mensaje; final int? statusCode; }
class AuthException implements Exception { final String mensaje; }
class NetworkException implements Exception { final String mensaje; }
```

Los repositorios lanzan excepciones tipadas. Los BLoCs las capturan con try/catch y emiten estados de error.

---

## Convenciones de código

- Nombres de archivos: snake_case · Clases: PascalCase
- Todo en español salvo keywords de Flutter/Dart
- Vistas solo renderizan — cero lógica fuera de BlocBuilder/BlocListener
- Los use cases tienen un único método `ejecutar(...)`
- Los BLoCs reciben use cases por constructor
- Las páginas leen dependencias con `context.read<XBloc>()`
- DTOs con `fromJson` factory y `toJson` method
- `diagnosticoCatId`, `resolucionId` y `partesFallaron` son arrays — modelar como List
- Props de Equatable siempre declarados
- Usar siempre widgets y colores de `app_theme.dart` — nunca hardcodear
- Para el shape exacto de cualquier respuesta, consultar `endpoints.md` del backend
