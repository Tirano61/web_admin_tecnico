# Endpoints API

## Base URL

- `http://localhost:3000/api/v1`

## Auth

Header para privados:

```http
Authorization: Bearer <token>
```

## Auth publico

| Metodo | Endpoint |
|---|---|
| POST | `/auth/register` |
| POST | `/auth/login` |

## Auth privado

| Metodo | Endpoint | Rol |
|---|---|---|
| GET | `/auth/tecnicos?page=&limit=&q=&activos=` | admin-tecnico, admin |
| POST | `/auth/tecnicos` | admin-tecnico, admin |
| GET | `/auth/tecnicos/:id` | admin-tecnico, admin |
| PATCH | `/auth/tecnicos/:id` | admin-tecnico, admin |
| PATCH | `/auth/tecnicos/:id/estado` | admin-tecnico, admin |

### GET /auth/tecnicos (selector de técnicos)

Query params:

- `page` (opcional, default `1`)
- `limit` (opcional, default `20`, max `100`)
- `q` (opcional, busca por `fullName` o `email`)
- `activos` (opcional, default `true`; enviar `false` para incluir inactivos)

Ejemplo:

`GET /auth/tecnicos?page=1&limit=20&q=juan&activos=true`

Respuesta ejemplo:

```json
{
  "data": [
    {
      "id": "{{tecnicoId}}",
      "fullName": "Juan Perez",
      "email": "juan@example.com",
      "isActive": true
    }
  ],
  "meta": {
    "page": 1,
    "limit": 20,
    "total": 1,
    "totalPages": 1
  }
}
```

### POST /auth/tecnicos

Payload:

```json
{
  "email": "tecnico.nuevo@example.com",
  "password": "ClaveSegura123!",
  "fullName": "Tecnico Nuevo",
  "isActive": true
}
```

Notas:

- Crea un usuario con rol `tecnico`.
- `isActive` es opcional (default `true`).

Respuesta ejemplo:

```json
{
  "id": "{{tecnicoId}}",
  "fullName": "Tecnico Nuevo",
  "email": "tecnico.nuevo@example.com",
  "isActive": true,
  "roles": ["tecnico"]
}
```

### GET /auth/tecnicos/:id

Respuesta ejemplo:

```json
{
  "id": "{{tecnicoId}}",
  "fullName": "Juan Perez",
  "email": "juan@example.com",
  "isActive": true,
  "roles": ["tecnico"],
  "created_at": "2026-07-11T10:00:00.000Z",
  "updated_at": "2026-07-11T10:00:00.000Z"
}
```

### PATCH /auth/tecnicos/:id

Payload (al menos un campo):

```json
{
  "fullName": "Juan Perez Actualizado",
  "email": "juan.perez@example.com"
}
```

Respuesta ejemplo:

```json
{
  "id": "{{tecnicoId}}",
  "fullName": "Juan Perez Actualizado",
  "email": "juan.perez@example.com",
  "isActive": true,
  "roles": ["tecnico"]
}
```

### PATCH /auth/tecnicos/:id/estado

Payload:

```json
{
  "isActive": false
}
```

Respuesta ejemplo:

```json
{
  "id": "{{tecnicoId}}",
  "fullName": "Juan Perez",
  "email": "juan@example.com",
  "isActive": false,
  "roles": ["tecnico"]
}
```

## Servicios

| Metodo | Endpoint | Rol |
|---|---|---|
| POST | `/servicios` | tecnico |
| GET | `/servicios/mios` | tecnico |
| GET | `/servicios` | admin-tecnico, admin-desarrollo, admin |
| GET | `/servicios/:id` | tecnico, admin-tecnico, admin-desarrollo, admin |
| PATCH | `/servicios/:id` | tecnico |
| GET | `/servicios/:id/documento` | tecnico, admin-tecnico, admin-desarrollo, admin |
| GET | `/servicios/:id/documento/pdf` | tecnico, admin-tecnico, admin-desarrollo, admin |
| PATCH | `/servicios/:id/documento` | tecnico, admin-tecnico, admin-desarrollo, admin |
| POST | `/servicios/:id/documento/firmado` | tecnico, admin-tecnico, admin-desarrollo, admin |

### Payload ejemplo POST /servicios

```json
{
  "idempotencyKey": "2f7b4d37-2f7f-4b0f-b2f0-1f9d9d1a7a1f",
  "fechaHoraServicio": "2026-03-26T14:22:10-03:00",
  "timezoneIana": "America/Argentina/Buenos_Aires",
  "utcOffsetMinutos": -180,
  "canal": "campo",
  "clienteId": "{{clienteId}}",
  "lugarProvinciaId": "{{zonaId}}",
  "lugarDetalle": "Cestari 14",
  "equipoNroSerie": "SN-001",
  "equipoModelo": "ST455",
  "equipoUbicacion": "Tolva principal",
  "equipoAnio": 2021,
  "partesFallaron": ["celda", "app_movil"],
  "km": 120,
  "sintoma": "No inicia",
  "diagnosticoDetalle": "Fuente sin salida",
  "diagnosticoCatId": ["{{diagnosticoId}}"],
  "resolucionId": ["{{resolucionId}}"],
  "observaciones": "Cliente solicita seguimiento",
  "productosFalla": [
    { "parteFallo": "celda", "productoFallaId": "{{productoId}}" },
    { "parteFallo": "app_movil", "productoFallaId": "{{productoId}}" }
  ],
  "facturacion": {
    "kmCantidad": 120,
    "subtotalKmUsd": 90,
    "subtotalKmArs": 100845,
    "subtotalGeneralUsd": 331.5,
    "subtotalGeneralArs": 371557.75,
    "ivaPorcentaje": 21,
    "totalConIvaArs": 449584.88,
    "descuentoPorcentaje": 10,
    "totalFinalArs": 404626.39,
    "version": 1
  },
  "facturacionItems": [
    {
      "tipoItem": "mano_obra",
      "referenciaId": null,
      "descripcion": "Servicio tecnico",
      "cantidad": 1,
      "precioUnitarioUsd": 80,
      "precioUnitarioArs": 89640,
      "subtotalUsd": 80,
      "subtotalArs": 89640
    },
    {
      "tipoItem": "viatico",
      "referenciaId": null,
      "descripcion": "Viatico por km",
      "cantidad": 120,
      "precioUnitarioUsd": 0.75,
      "precioUnitarioArs": 840.375,
      "subtotalUsd": 90,
      "subtotalArs": 100845
    },
    {
      "tipoItem": "repuesto",
      "referenciaId": "{{repuestoId}}",
      "descripcion": "Celda CZAP 20000",
      "cantidad": 2,
      "precioUnitarioUsd": 120.75,
      "precioUnitarioArs": 135356.375,
      "subtotalUsd": 241.5,
      "subtotalArs": 270712.75
    }
  ],
  "documento": {
    "pdfHashSha256": null,
    "pdfUrl": null,
    "firmaClienteNombre": null,
    "firmaClienteDocumento": null,
    "firmaFechaHora": null
  }
}
```

### Respuesta ejemplo POST /servicios (orden completa)

```json
{
  "replayed": false,
  "servicioId": "2f4d8b22-d4df-4939-8f89-0d38e2c93c37",
  "idempotencyKey": "2f7b4d37-2f7f-4b0f-b2f0-1f9d9d1a7a1f",
  "estadoOrden": "cerrada",
  "version": 1,
  "fechaHoraServicio": "2026-03-26T14:22:10-03:00",
  "timezoneIana": "America/Argentina/Buenos_Aires",
  "utcOffsetMinutos": -180,
  "servicio": {
    "canal": "campo",
    "clienteId": "{{clienteId}}",
    "cliente": {
      "id": "{{clienteId}}",
      "cuit": "20304050607",
      "nombre": "Agro SRL",
      "contacto": "Juan Perez",
      "telefono": "+54 9 11 5555-0001",
      "localidad": "Pergamino"
    },
    "lugarProvinciaId": "{{zonaId}}",
    "lugarProvinciaNombre": "Buenos Aires",
    "lugarDetalle": "Cestari 14",
    "equipoNroSerie": "SN-001",
    "equipoModelo": "ST455",
    "equipoUbicacion": "Tolva principal",
    "equipoAnio": 2021,
    "partesFallaron": ["celda", "app_movil"],
    "km": 120,
    "sintoma": "No inicia",
    "diagnosticoDetalle": "Fuente sin salida",
    "diagnosticoCatId": ["{{diagnosticoId}}"],
    "resolucionId": ["{{resolucionId}}"],
    "observaciones": "Cliente solicita seguimiento",
    "productosFalla": [
      { "parteFallo": "celda", "productoFallaId": "{{productoId}}" },
      { "parteFallo": "app_movil", "productoFallaId": "{{productoId}}" }
    ]
  },
  "facturacion": {
    "cotizacionDolarSnapshot": 1120.5,
    "valorKmUsdSnapshot": 0.75,
    "kmCantidad": 120,
    "subtotalKmUsd": 90,
    "subtotalKmArs": 100845,
    "subtotalGeneralUsd": 331.5,
    "subtotalGeneralArs": 371557.75,
    "ivaPorcentaje": 21,
    "totalConIvaArs": 449584.88,
    "descuentoPorcentaje": 10,
    "totalFinalArs": 404626.39
  },
  "facturacionItems": [
    {
      "tipoItem": "mano_obra",
      "referenciaId": null,
      "descripcion": "Servicio tecnico",
      "cantidad": 1,
      "precioUnitarioUsd": 80,
      "precioUnitarioArs": 89640,
      "subtotalUsd": 80,
      "subtotalArs": 89640
    },
    {
      "tipoItem": "viatico",
      "referenciaId": null,
      "descripcion": "Viatico por km",
      "cantidad": 120,
      "precioUnitarioUsd": 0.75,
      "precioUnitarioArs": 840.375,
      "subtotalUsd": 90,
      "subtotalArs": 100845
    },
    {
      "tipoItem": "repuesto",
      "referenciaId": "{{repuestoId}}",
      "descripcion": "Celda CZAP 20000",
      "cantidad": 2,
      "precioUnitarioUsd": 120.75,
      "precioUnitarioArs": 135356.375,
      "subtotalUsd": 241.5,
      "subtotalArs": 270712.75
    }
  ],
  "documento": {
    "pdfHashSha256": null,
    "pdfUrl": null,
    "firmaClienteNombre": null,
    "firmaClienteDocumento": null,
    "firmaFechaHora": null
  }
}
```

Notas:

- La app puede generar el PDF inmediatamente con esta respuesta, sin una segunda llamada.
- `facturacion.cotizacionDolarSnapshot` se define en backend con la ultima cotizacion disponible (no es necesario enviarla en el request).
- `facturacion.valorKmUsdSnapshot` se define en backend con la ultima tarifa de km activa (no es necesario enviarla en el request).
- `facturacionItems` debe incluir al menos un item con `tipoItem = mano_obra` para representar el cobro del servicio al cliente.
- `facturacion.subtotalGeneralUsd/Ars` deben coincidir con la suma de subtotales de `facturacionItems`.
- `facturacion.totalConIvaArs` y `facturacion.totalFinalArs` deben ser consistentes con IVA y descuento.
- `servicio.cliente` incluye los datos completos del cliente para generar PDF sin llamadas extra.
- `servicio.lugarProvinciaNombre` incluye el nombre de la zona/provincia para mostrar en PDF.
- `idempotencyKey` viaja en el body de `POST /servicios`.
- Si un tecnico reintenta con el mismo `idempotencyKey`, el backend devuelve la misma orden creada previamente.
- `replayed = true` indica que la respuesta es un replay idempotente (no una nueva insercion).
- Si ocurre una carrera de concurrencia con la misma clave, la deduplicacion se resuelve en base de datos (sin duplicar ordenes).
- Al crear una orden elegible (`canal = campo`) se crea automaticamente una liquidacion en estado `pendiente` para el tecnico dueño de la orden.
- La creacion de orden + liquidacion se ejecuta de forma consistente en una misma transaccion.
- Si hay replay por `idempotencyKey`, se devuelve la misma orden y se mantiene una sola liquidacion asociada al servicio.
- Existe unicidad por `servicio_id` en liquidacion para evitar duplicados ante reintentos/concurrencia.

### Payload PATCH /servicios/:id/documento

```json
{
  "pdfHashSha256": "f4f4b4f8518fcb9d06b6a88c0ec5f23f1f9d1a7a1f9f7b4d372f7f4b0fb2f0a1",
  "pdfUrl": "https://storage.example.com/ordenes/2f4d8b22.pdf",
  "firmaClienteNombre": "Juan Perez",
  "firmaClienteDocumento": "30111222",
  "firmaFechaHora": "2026-03-26T16:10:00-03:00"
}
```

### Respuesta PATCH /servicios/:id/documento

Devuelve el mismo shape de `POST /servicios`, con `replayed = false` y `estadoOrden` actualizado (`firmada` solo para ordenes de `canal = campo`).

### Respuesta GET /servicios/:id/documento

```json
{
  "servicioId": "2f4d8b22-d4df-4939-8f89-0d38e2c93c37",
  "estadoOrden": "cerrada",
  "documento": {
    "pdfHashSha256": "f4f4b4f8518fcb9d06b6a88c0ec5f23f1f9d1a7a1f9f7b4d372f7f4b0fb2f0a1",
    "pdfUrl": "https://res.cloudinary.com/.../orden-firmada-v1.pdf",
    "firmaClienteNombre": null,
    "firmaClienteDocumento": null,
    "firmaFechaHora": null
  }
}
```

### GET /servicios/:id/documento/pdf

- Devuelve el archivo PDF (`application/pdf`) para visualizacion/descarga autenticada.
- Ideal para Flutter cuando no se quiere abrir la URL remota directamente.

### Payload POST /servicios/:id/documento/firmado

Content-Type: `multipart/form-data`

Campos:

- `file`: archivo PDF (requerido)
- `firmaClienteNombre`: string (opcional; requerido solo si se informa firma)
- `firmaClienteDocumento`: string (opcional)
- `firmaFechaHora`: datetime ISO-8601 (opcional; requerido solo si se informa firma)

Ejemplo cURL:

```bash
curl -X POST "{{baseUrl}}/servicios/{{servicioId}}/documento/firmado" \
  -H "Authorization: Bearer {{token}}" \
  -F "file=@orden-firmada.pdf;type=application/pdf" \
  -F "firmaClienteNombre=Juan Perez" \
  -F "firmaClienteDocumento=30111222" \
  -F "firmaFechaHora=2026-03-29T10:30:00-03:00"
```

Notas:

- El backend calcula `pdfHashSha256` automaticamente a partir del archivo recibido.
- El backend sube el PDF a Cloudinary y persiste `pdfUrl` con la URL remota del archivo.
- Las nuevas subidas se publican con entrega habilitada en Cloudinary. Si un archivo viejo aparece como `Blocked for delivery`, hay que cambiar su access control a publico o re-subirlo.
- Si Cloudinary responde `show_original_customer_untrusted` / `Customer is marked as untrusted`, la cuenta/entorno requiere habilitacion por un administrador o soporte de Cloudinary.
- En ordenes `campo`, se puede subir PDF sin firma (por ejemplo, cliente ausente); en ese caso la orden no pasa a `firmada`.
- Cuando hay firma en `campo`, `firmaClienteNombre` puede ser del cliente o de un empleado/responsable presente.
- En ordenes `remoto` y `fabrica`, se puede subir el PDF sin firma; si llega data de firma, el backend la rechaza.
- Si se recibe archivo PDF + datos de firma validos en `canal = campo`, el estado de la orden pasa a `firmada`.
- Flujo de estados de orden: `abierta` -> `cerrada` -> `firmada`.

## Clientes

| Metodo | Endpoint | Rol |
|---|---|---|
| GET | `/clientes?page=&limit=` | tecnico, admin-tecnico, admin |
| GET | `/clientes/buscar?q=` | tecnico, admin-tecnico, admin |
| GET | `/clientes/:id` | tecnico, admin-tecnico, admin |
| POST | `/clientes` | tecnico, admin-tecnico |
| PATCH | `/clientes/:id` | admin-tecnico |

### GET /clientes (listado paginado)

Query params:

- `page` (opcional, default `1`)
- `limit` (opcional, default `20`)

Ejemplo:

`GET /clientes?page=1&limit=20`

Respuesta ejemplo:

```json
{
  "data": [
    {
      "id": "{{clienteId}}",
      "cuit": "20304050607",
      "nombre": "Agro SRL",
      "contacto": "Juan Perez",
      "telefono": "+54 9 11 5555-0001",
      "localidad": "Pergamino"
    }
  ],
  "meta": {
    "page": 1,
    "limit": 20,
    "total": 1,
    "totalPages": 1
  }
}
```

Notas:

- Endpoint pensado para listado general en web admin-tecnico.
- `GET /clientes/buscar?q=` se mantiene para autocompletes/busquedas rapidas.

## Catalogos

| Metodo | Endpoint | Rol |
|---|---|---|
| GET | `/cat/diagnosticos` | tecnico, admin-tecnico, admin-desarrollo, admin |
| POST | `/cat/diagnosticos` | admin-desarrollo, admin |
| PATCH | `/cat/diagnosticos/:id` | admin-desarrollo, admin |
| GET | `/cat/resoluciones` | tecnico, admin-tecnico, admin-desarrollo, admin |
| POST | `/cat/resoluciones` | admin-desarrollo, admin |
| PATCH | `/cat/resoluciones/:id` | admin-desarrollo, admin |
| GET | `/zonas` | tecnico, admin-tecnico, admin-desarrollo, admin |
| POST | `/zonas` | admin-tecnico, admin |
| PATCH | `/zonas/:id` | admin-tecnico, admin |

## Productos

| Metodo | Endpoint | Rol |
|---|---|---|
| GET | `/categorias-producto` | tecnico, admin-tecnico, admin-desarrollo, admin |
| POST | `/categorias-producto` | admin-tecnico, admin |
| PATCH | `/categorias-producto/:id` | admin-tecnico, admin |
| GET | `/productos?categoriaId=` | tecnico, admin-tecnico, admin-desarrollo, admin |
| POST | `/productos` | admin-tecnico, admin |
| PATCH | `/productos/:id` | admin-tecnico, admin |

## Repuestos

| Metodo | Endpoint | Rol |
|---|---|---|
| GET | `/repuestos?q=` | tecnico, admin-tecnico, admin |
| GET | `/repuestos/listado?page=&limit=&q=&activo=` | admin-tecnico, admin |
| POST | `/repuestos` | admin-tecnico |
| PATCH | `/repuestos/:id` | admin-tecnico |
| POST | `/servicios/:id/repuestos` | tecnico, admin-tecnico, admin |
| GET | `/servicios/:id/repuestos` | tecnico, admin-tecnico, admin |

### GET /repuestos/listado (admin paginado)

Query params:

- `page` (opcional, default `1`)
- `limit` (opcional, default `20`)
- `q` (opcional, busca por codigo o nombre)
- `activo` (opcional, `true` o `false`; si se omite trae activos e inactivos)

Ejemplo:

`GET /repuestos/listado?page=1&limit=20&q=celda&activo=true`

Respuesta ejemplo:

```json
{
  "data": [
    {
      "id": "{{repuestoId}}",
      "codigo": "05-01-CZAP-20000",
      "nombre": "Celda CZAP 20000",
      "precioUsd": 120.75,
      "activo": true
    }
  ],
  "meta": {
    "page": 1,
    "limit": 20,
    "total": 1,
    "totalPages": 1
  }
}
```

Notas:

- Endpoint pensado para grillas de administracion en web admin-tecnico.
- `GET /repuestos?q=` se mantiene como busqueda rapida (maximo 10 activos), util para autocompletes.

### Payload POST /servicios/:id/repuestos

Acepta ambos formatos:

```json
{ "repuestoId": "{{repuestoId}}", "cantidad": 1 }
```

```json
{ "repuesto_id": "{{repuestoId}}", "cantidad": 1 }
```

## Cotizacion

| Metodo | Endpoint | Rol |
|---|---|---|
| GET | `/cotizacion` | tecnico, admin-tecnico, admin |
| GET | `/cotizacion/historial` | tecnico, admin-tecnico, admin |
| POST | `/cotizacion` | admin-tecnico |

Notas:

- El backend sincroniza cotizacion automaticamente desde proveedor externo cada 30 minutos.
- `GET /cotizacion` devuelve la ultima cotizacion registrada.
- Cada sincronizacion se persiste en tabla `cotizacion_dolar` y queda disponible en historial.

## Tarifa Km

| Metodo | Endpoint | Rol |
|---|---|---|
| GET | `/tarifa-km` | tecnico, admin-tecnico, admin |
| GET | `/tarifa-km/historial` | tecnico, admin-tecnico, admin |
| POST | `/tarifa-km` | admin-tecnico |

### Payload POST /tarifa-km

```json
{
  "valorKmUsd": 0.75,
  "fecha": "2026-03-28"
}
```

Notas:

- `GET /tarifa-km` devuelve la ultima tarifa de km registrada.
- El backend usa esta tarifa para completar `facturacion.valorKmUsdSnapshot` al crear ordenes de servicio.

## Liquidacion

| Metodo | Endpoint | Rol |
|---|---|---|
| GET | `/tipos-salida` | tecnico, admin-tecnico |
| POST | `/tipos-salida` | admin-tecnico |
| PATCH | `/tipos-salida/:id` | admin-tecnico |
| GET | `/tipos-servicio` | tecnico, admin-tecnico |
| POST | `/tipos-servicio` | admin-tecnico |
| PATCH | `/tipos-servicio/:id` | admin-tecnico |
| POST | `/liquidaciones` | admin-tecnico |
| GET | `/liquidaciones/mias` | tecnico |
| GET | `/liquidaciones` | admin-tecnico |
| GET | `/liquidaciones/para-pago` | admin-tecnico |
| GET | `/liquidaciones/resumen-pago/preview` | admin-tecnico |
| PATCH | `/liquidaciones/resumen-pago/confirmar` | admin-tecnico |
| GET | `/liquidaciones/resumenes-pago` | admin-tecnico |
| GET | `/liquidaciones/resumenes-pago/ultimo` | admin-tecnico |
| GET | `/liquidaciones/resumenes-pago/:id` | admin-tecnico |
| PATCH | `/liquidaciones/marcar-pagadas` | admin-tecnico |
| GET | `/liquidaciones/pendientes` | admin-tecnico |
| GET | `/liquidaciones/:id/items` | admin-tecnico |
| PATCH | `/liquidaciones/:id` | admin-tecnico |
| PATCH | `/liquidaciones/:id/aprobar` | admin-tecnico |
| POST | `/liquidaciones/:id/items` | admin-tecnico |
| PATCH | `/liquidaciones/:id/items/:itemId/aprobar` | admin-tecnico |
| DELETE | `/liquidaciones/:id/items/:itemId` | admin-tecnico |

### Payloads importantes de liquidacion

Creacion automatica:

- `POST /servicios` crea automaticamente una liquidacion pendiente cuando la orden es elegible (`canal = campo`).
- `GET /liquidaciones/mias?estado=pendiente` debe reflejarla inmediatamente para el tecnico autenticado.
- `POST /liquidaciones` queda disponible como flujo manual/admin (fallback operativo).

`POST /liquidaciones`:

```json
{ "servicio_id": "{{servicioId}}", "km": 140 }
```

Tambien soporta camelCase:

```json
{ "servicioId": "{{servicioId}}", "km": 140 }
```

`PATCH /liquidaciones/:id`:

```json
{ "tipo_salida_id": "{{tipoSalidaId}}" }
```

`POST /liquidaciones/:id/items`:

```json
{ "tipo_servicio_id": "{{tipoServicioId}}" }
```

`GET /liquidaciones` (admin):

```text
/liquidaciones?aprobado=false&page=1&limit=20
```

Tambien soporta filtro por estado:

```text
/liquidaciones?estado=aprobada&page=1&limit=20
```

Tambien soporta filtro por estado de pago:

```text
/liquidaciones?liquidadaPago=false&page=1&limit=20
```

Notas:

- `tecnicoId` es opcional en query.
- `estado` es opcional: `pendiente | aprobada | reabierta | todas`.
- `liquidadaPago` es opcional: `true | false`.
- `GET /liquidaciones/mias?estado=pendiente` lista pendientes reales del tecnico autenticado aunque no tengan items de servicio cargados.
- Cada item del listado incluye `tecnicoId`, `tecnicoNombre` y `tecnicoEmail` para facilitar filtros/seleccion en UI.
- Cuando `admin-tecnico` edita una liquidacion (`PATCH /liquidaciones/:id`, `POST /liquidaciones/:id/items`, `DELETE /liquidaciones/:id/items/:itemId`), queda aprobada automaticamente al finalizar la operacion.
- `PATCH /liquidaciones/:id/reabrir` registra motivo/historial de reapertura para auditoria, pero no cambia el estado de aprobacion.
- Si `liquidadaPago = true`, la liquidacion ya fue pasada para pago y no se puede editar.

`GET /liquidaciones/para-pago` (admin):

```text
/liquidaciones/para-pago?page=1&limit=20
```

Notas:

- Devuelve solo liquidaciones aprobadas (`aprobado=true`) y no liquidadas para pago (`liquidadaPago=false`).
- Sirve como fuente para armar el lote de pago desde la web admin.

`PATCH /liquidaciones/marcar-pagadas`:

```json
{
  "liquidacionIds": [
    "{{liquidacionId1}}",
    "{{liquidacionId2}}"
  ]
}
```

Notas:

- Marca en lote las liquidaciones seleccionadas como `liquidadaPago=true`.
- Solo permite liquidaciones aprobadas, no liquidadas previamente y con al menos un item (`tipo_servicio`) asignado.
- Una vez marcadas, ya no se pueden volver a editar ni volver a seleccionar para otro lote de pago.

`GET /liquidaciones/resumen-pago/preview`:

```text
/liquidaciones/resumen-pago/preview?tecnicoId={{tecnicoId}}&desde=2026-07-01&hasta=2026-07-31
```

Notas:

- Genera el resumen por tecnico y rango de fechas.
- La elegibilidad exige: aprobada, no liquidada para pago, fechaAprobacion dentro del rango y con items de servicio.

Respuesta ejemplo:

```json
{
  "filtro": {
    "tecnicoId": "{{tecnicoId}}",
    "desde": "2026-07-01T00:00:00.000Z",
    "hasta": "2026-07-31T23:59:59.999Z"
  },
  "data": [
    {
      "id": "{{liquidacionId1}}",
      "fechaAprobacion": "2026-07-10T14:20:00.000Z",
      "servicioId": "{{servicioId1}}",
      "subtotalSalidaUsd": 80,
      "subtotalItemsUsd": 120.5,
      "totalLiquidacionUsd": 200.5
    }
  ],
  "meta": {
    "totalLiquidaciones": 1,
    "totalResumenUsd": 200.5
  }
}
```

`PATCH /liquidaciones/resumen-pago/confirmar`:

```json
{
  "tecnicoId": "{{tecnicoId}}",
  "desde": "2026-07-01",
  "hasta": "2026-07-31",
  "liquidacionIds": [
    "{{liquidacionId1}}",
    "{{liquidacionId2}}"
  ]
}
```

Notas:

- Revalida elegibilidad con tecnico + rango + estado antes de confirmar.
- Marca las seleccionadas como pasadas a pago (`liquidadaPago=true`) y devuelve resumen + confirmacion.
- Persiste cabecera y detalle del resumen para historial/auditoria.

Respuesta ejemplo:

```json
{
  "filtro": {
    "tecnicoId": "{{tecnicoId}}",
    "desde": "2026-07-01T00:00:00.000Z",
    "hasta": "2026-07-31T23:59:59.999Z"
  },
  "data": [
    {
      "id": "{{liquidacionId1}}",
      "fechaAprobacion": "2026-07-10T14:20:00.000Z",
      "servicioId": "{{servicioId1}}",
      "subtotalSalidaUsd": 80,
      "subtotalItemsUsd": 120.5,
      "totalLiquidacionUsd": 200.5
    }
  ],
  "meta": {
    "totalLiquidaciones": 1,
    "totalResumenUsd": 200.5
  },
  "confirmacion": {
    "updated": 1,
    "fechaLiquidadaPago": "2026-07-31T18:45:00.000Z"
  }
}
```

`GET /liquidaciones/resumenes-pago`:

```text
/liquidaciones/resumenes-pago?tecnicoId={{tecnicoId}}&page=1&limit=20
```

Notas:

- Lista el historial de resumenes confirmados.
- Soporta filtros opcionales por `tecnicoId`, `desde`, `hasta` (fecha de creacion del resumen).

Respuesta ejemplo:

```json
{
  "data": [
    {
      "id": "{{resumenPagoId}}",
      "tecnicoId": "{{tecnicoId}}",
      "tecnicoNombre": "Juan Perez",
      "desde": "2026-07-01T00:00:00.000Z",
      "hasta": "2026-07-31T23:59:59.999Z",
      "totalLiquidaciones": 2,
      "totalUsdSnapshot": 401,
      "liquidacionIds": ["{{liquidacionId1}}", "{{liquidacionId2}}"],
      "createdById": "{{adminId}}",
      "createdByNombre": "Admin Tecnico",
      "createdAt": "2026-07-31T18:45:00.000Z"
    }
  ],
  "meta": {
    "page": 1,
    "limit": 20,
    "total": 1,
    "totalPages": 1
  }
}
```

`GET /liquidaciones/resumenes-pago/ultimo`:

```text
/liquidaciones/resumenes-pago/ultimo?tecnicoId={{tecnicoId}}
```

Notas:

- Devuelve el ultimo resumen confirmado para el tecnico.
- Si no hay historial, responde `ultimoResumen: null`.

Respuesta ejemplo:

```json
{
  "ultimoResumen": {
    "id": "{{resumenPagoId}}",
    "desde": "2026-07-01T00:00:00.000Z",
    "hasta": "2026-07-31T23:59:59.999Z",
    "totalLiquidaciones": 2,
    "totalUsdSnapshot": 401,
    "createdAt": "2026-07-31T18:45:00.000Z"
  }
}
```

`GET /liquidaciones/resumenes-pago/:id`:

- Devuelve cabecera + detalle completo del resumen (liquidaciones incluidas y snapshots de montos).

Respuesta ejemplo:

```json
{
  "id": "{{resumenPagoId}}",
  "tecnico": {
    "id": "{{tecnicoId}}",
    "nombre": "Juan Perez",
    "email": "juan@example.com"
  },
  "periodo": {
    "desde": "2026-07-01T00:00:00.000Z",
    "hasta": "2026-07-31T23:59:59.999Z"
  },
  "resumen": {
    "totalLiquidaciones": 2,
    "totalUsdSnapshot": 401
  },
  "createdBy": {
    "id": "{{adminId}}",
    "nombre": "Admin Tecnico",
    "email": "admin@example.com"
  },
  "createdAt": "2026-07-31T18:45:00.000Z",
  "detalles": [
    {
      "id": "{{resumenDetalleId1}}",
      "liquidacionId": "{{liquidacionId1}}",
      "servicioId": "{{servicioId1}}",
      "fechaAprobacionSnapshot": "2026-07-10T14:20:00.000Z",
      "subtotalSalidaUsdSnapshot": 80,
      "subtotalItemsUsdSnapshot": 120.5,
      "totalLiquidacionUsdSnapshot": 200.5
    }
  ]
}
```

`GET /liquidaciones/pendientes` (servicios campo sin liquidacion):

```text
/liquidaciones/pendientes?page=1&limit=20
```

Notas:

- Lista servicios con `canal=campo` que todavia no tienen liquidacion.
- Soporta `tecnicoId` opcional en query.
- Cada item incluye `tecnicoId`, `tecnicoNombre` y `tecnicoEmail`.

`GET /liquidaciones/:id/items`:

```json
{
  "liquidacionId": "{{liquidacionId}}",
  "items": [
    {
      "id": "{{itemId}}",
      "tipoServicioId": "{{tipoServicioId}}",
      "tipoServicioNombre": "Instalacion",
      "precioUsdSnapshot": 120.5,
      "aprobado": false,
      "fechaAprobacion": null,
      "createdAt": "2026-04-04T10:00:00.000Z"
    }
  ],
  "meta": {
    "totalItems": 1,
    "aprobados": 0,
    "pendientes": 1,
    "subtotalUsdTotal": 120.5
  }
}
```

Notas:

- Este endpoint permite obtener `itemId` desde UI para aprobar/eliminar items sin ingreso manual.
- Si la liquidacion existe pero no tiene items, devuelve `items: []` y `meta.totalItems = 0`.

## Analytics (feedback)

| Metodo | Endpoint | Rol |
|---|---|---|
| GET | `/stats/por-canal` | admin-desarrollo, admin |
| GET | `/stats/por-diagnostico` | admin-desarrollo, admin |
| GET | `/stats/por-parte` | admin-desarrollo, admin |
| GET | `/stats/por-producto` | admin-desarrollo, admin |
| GET | `/stats/por-periodo` | admin-desarrollo, admin |
| GET | `/stats/resolucion` | admin-desarrollo, admin |
| GET | `/export` | admin-desarrollo, admin |
