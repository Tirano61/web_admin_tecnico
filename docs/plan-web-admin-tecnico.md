# Plan Web Flutter Admin-Tecnico

Fecha: 2026-03-30
Objetivo: definir el alcance funcional y tecnico de la web Flutter para el rol `admin-tecnico` usando los contratos actuales de backend.

## 1) Objetivo de la aplicacion admin-tecnico

La web admin-tecnico cubre la operacion diaria del servicio tecnico:

- Ver todas las ordenes (`servicios`) con filtros.
- Gestionar clientes.
- Gestionar catalogos operativos (zonas, categorias de producto, productos, repuestos).
- Gestionar precios operativos (cotizacion dolar y tarifa km).
- Ejecutar flujo de liquidacion tecnica (crear, editar, aprobar).
- Consultar documento/PDF de orden y registrar documento firmado cuando corresponda.

Fuera de alcance para este rol:

- Analytics y export de feedback (`admin-desarrollo`).
- Edicion de catalogos de diagnostico y resolucion (solo `admin-desarrollo`/`admin`).

## 2) Supuestos funcionales clave (tomados de docs)

- API base: `/api/v1`.
- Auth por JWT (`POST /auth/login`) y control de rol en backend.
- `admin-tecnico` puede ver todos los servicios, pero no crea servicios tecnicos desde web.
- Solo servicios con `canal=campo` pueden liquidarse.
- Montos de liquidacion trabajan en USD (snapshots).
- Catalogos no se eliminan fisicamente: se desactivan (`activo=false`).
- `admin` legado mantiene permisos equivalentes para compatibilidad.

## 3) Alcance MVP (Fase 1)

### 3.1 Modulo Auth

- Login con email/password.
- Guardado de token JWT y perfil en memoria segura.
- Guard de rutas por rol (`admin-tecnico` y `admin`).
- Logout con limpieza de sesion.

### 3.2 Modulo Servicios (panel principal)

- Listado de servicios (`GET /servicios`) con:
  - busqueda por texto (cliente, serie, tecnico si backend lo soporta)
  - filtro por canal (`campo`, `remoto`, `fabrica`)
  - filtro por estado de orden (`abierta`, `cerrada`, `firmada`)
  - filtro por rango de fechas
- Vista detalle de servicio (`GET /servicios/:id`) con:
  - bloque tecnico
  - bloque facturacion
  - items facturados
  - repuestos asociados
  - estado del documento
- Documento:
  - ver metadatos (`GET /servicios/:id/documento`)
  - descargar/visualizar PDF autenticado (`GET /servicios/:id/documento/pdf`)
  - cargar PDF firmado (`POST /servicios/:id/documento/firmado`) cuando aplique.

### 3.3 Modulo Clientes

- Listado paginado (`GET /clientes?page=&limit=`).
- Busqueda (`GET /clientes/buscar?q=`).
- Vista detalle (`GET /clientes/:id`).
- Alta cliente (`POST /clientes`).
- Edicion cliente (`PATCH /clientes/:id`).

### 3.4 Modulo Catalogos Operativos

- Zonas: listar/crear/editar (`GET/POST/PATCH /zonas`).
- Categorias producto: listar/crear/editar (`GET/POST/PATCH /categorias-producto`).
- Productos: listar/crear/editar (`GET/POST/PATCH /productos`).
- Repuestos: listar/crear/editar (`GET/POST/PATCH /repuestos`).

Nota de permisos UX: diagnosticos/resoluciones se muestran en modo lectura para admin-tecnico.

### 3.5 Modulo Precios

- Cotizacion actual e historial (`GET /cotizacion`, `GET /cotizacion/historial`).
- Alta de cotizacion (`POST /cotizacion`).
- Tarifa km actual e historial (`GET /tarifa-km`, `GET /tarifa-km/historial`).
- Alta tarifa km (`POST /tarifa-km`).

### 3.6 Modulo Liquidaciones

- Catalogos de liquidacion:
  - tipos salida (`GET/POST/PATCH /tipos-salida`)
  - tipos servicio (`GET/POST/PATCH /tipos-servicio`)
- Gestion de liquidaciones:
  - crear (`POST /liquidaciones`)
  - listar (`GET /liquidaciones`)
  - listar items por liquidacion (`GET /liquidaciones/:id/items`)
  - editar cabecera (`PATCH /liquidaciones/:id`)
  - aprobar liquidacion (`PATCH /liquidaciones/:id/aprobar`)
  - agregar item (`POST /liquidaciones/:id/items`)
  - aprobar item (`PATCH /liquidaciones/:id/items/:itemId/aprobar`)
  - eliminar item (`DELETE /liquidaciones/:id/items/:itemId`)

## 4) Arquitectura Flutter recomendada (web)

## 4.1 Estructura por features

```
lib/
  core/
    api/
    auth/
    error/
    routing/
    widgets/
  features/
    auth/
    servicios/
    clientes/
    catalogos/
    precios/
    liquidaciones/
    app_shell/
```

## 4.2 Capas por feature

- `data`: models DTO, datasource HTTP, mappers.
- `domain`: entities, repository contracts, use cases.
- `presentation`: pages, widgets, state management.

## 4.3 Estado y DI

- Estado: `flutter_bloc` (alineado al enfoque existente en docs de arquitectura).
- DI: proveedor manual por modulo (sin dependencia obligatoria de service locator global).
- HTTP: cliente unico con interceptor JWT + refresco de sesion controlado.

## 4.4 Ruteo

- Rutas protegidas por rol:
  - `/login`
  - `/servicios`
  - `/servicios/:id`
  - `/clientes`
  - `/catalogos/*`
  - `/precios/*`
  - `/liquidaciones/*`
- Si el rol no corresponde: redireccion a pantalla 403.

## 5) Mapa de permisos UI (admin-tecnico)

- Mostrar:
  - servicios (listado y detalle)
  - clientes
  - zonas
  - categorias/productos
  - repuestos
  - cotizacion y tarifa km
  - liquidaciones y sus catalogos
- Ocultar o bloquear:
  - analytics y export
  - alta/edicion de cat diagnostico y cat resolucion

## 6) Plan de implementacion por sprints

## Sprint 0 (2-3 dias): base tecnica

- Bootstrap Flutter web + app shell.
- Auth JWT y guard de rutas por rol.
- Cliente HTTP base, manejo de errores y toast global.
- Layout responsive (desktop first, usable en tablet).

Entrega: login funcional + shell con menu lateral y proteccion por rol.

## Sprint 1 (5 dias): servicios y documento

- Listado de servicios con filtros basicos.
- Detalle de servicio.
- Viewer/descarga PDF autenticado.
- Carga de documento firmado por formulario `multipart`.

Entrega: flujo operativo de consulta y documentacion de orden.

## Sprint 2 (4 dias): clientes y catalogos operativos

- Clientes: listar paginado, buscar, detalle, crear, editar.
- Zonas: ABM basico.
- Categorias/productos: ABM basico.
- Repuestos: ABM basico.

Entrega: mantenimiento operativo completo.

## Sprint 3 (4 dias): precios y liquidaciones

- Cotizacion y tarifa km (actual + historial + alta).
- Tipos salida/tipos servicio.
- Liquidaciones: crear, listar, ver items, editar, aprobacion.
- Reglas UX para `canal=campo` (evitar liquidar otros canales).

Entrega: circuito de liquidacion cerrado.

## Sprint 4 (3 dias): hardening

- Pruebas E2E de flujos criticos.
- Auditoria de permisos visuales y de API.
- Estado vacio, errores y performance de tablas.
- Ajustes de UX con usuarios internos.

Entrega: version candidata a produccion interna.

## 7) Historias de usuario prioritarias

1. Como admin-tecnico quiero ver todas las ordenes con filtros para gestionar el trabajo diario.
2. Como admin-tecnico quiero abrir una orden y descargar su PDF para control administrativo.
3. Como admin-tecnico quiero cargar un PDF firmado en una orden para cerrar documentacion.
4. Como admin-tecnico quiero crear y editar clientes para mantener datos de contacto correctos.
5. Como admin-tecnico quiero actualizar cotizacion y tarifa km para calculos vigentes.
6. Como admin-tecnico quiero crear y aprobar liquidaciones para pago tecnico.
7. Como admin-tecnico quiero administrar repuestos/productos para mantener catalogos operativos.

## 8) Criterios de aceptacion (MVP)

- Login de admin-tecnico funciona y bloquea rutas no permitidas.
- Servicios listan y permiten abrir detalle con documento/PDF.
- Carga de documento firmado responde con estado actualizado de orden.
- Clientes y catalogos operativos se pueden listar/crear/editar sin refresco completo.
- Liquidaciones soportan ciclo completo de alta -> items -> aprobacion.
- Aprobacion/eliminacion de item en liquidaciones se realiza desde listado (sin pedir `itemId` manual).
- Analytics no aparece en UI admin-tecnico.

## 9) Riesgos y mitigacion

- Contrato de filtros de `GET /servicios` no esta 100% explicitado.
  - Mitigacion: acordar query params en una mini especificacion antes de Sprint 1.
- Ambiguedad entre docs historicos (`caso_repuesto`) y estado actual (`servicio_repuesto`).
  - Mitigacion: usar `docs/base-de-datos.md` como fuente primaria y validar con backend.
- Carga de PDF firmados depende de configuracion Cloudinary.
  - Mitigacion: caso de prueba temprano en Sprint 1 con endpoint real.
- Diferencias snake_case/camelCase en algunos payloads.
  - Mitigacion: normalizar mappers y agregar tests de serializacion.
- Falta de endpoint de lectura de items por liquidacion puede forzar ingreso manual de `itemId` en UI.
  - Mitigacion: cerrar contrato con `GET /liquidaciones/:id/items` antes del desarrollo de pantallas de aprobacion/eliminacion.

## 10) Decisiones a cerrar antes de construir

1. Definir exactamente filtros y paginacion de `GET /servicios` para web.
2. Confirmar si admin-tecnico puede usar `PATCH /servicios/:id/documento` ademas de `POST /firmado` en UI.
3. Definir comportamiento de ordenes `remoto/fabrica` respecto a firma y estados en la interfaz.
4. Confirmar si se requiere export CSV operativo para admin-tecnico (no analytics).
5. Definir estrategia de auditoria visual (quien cambio precios/liquidaciones y cuando) en frontend.
6. Confirmar disponibilidad de `GET /liquidaciones/:id/items` para evitar ingreso manual de `itemId`.
