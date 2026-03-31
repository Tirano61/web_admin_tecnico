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
- `servicio.cliente` incluye los datos completos del cliente para generar PDF sin llamadas extra.
- `servicio.lugarProvinciaNombre` incluye el nombre de la zona/provincia para mostrar en PDF.
- `idempotencyKey` viaja en el body de `POST /servicios`.
- Si un tecnico reintenta con el mismo `idempotencyKey`, el backend devuelve la misma orden creada previamente.
- `replayed = true` indica que la respuesta es un replay idempotente (no una nueva insercion).
- Si ocurre una carrera de concurrencia con la misma clave, la deduplicacion se resuelve en base de datos (sin duplicar ordenes).
- La liquidacion de tecnico sigue siendo un flujo separado.

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
| GET | `/clientes/buscar?q=` | tecnico, admin-tecnico, admin |
| GET | `/clientes/:id` | tecnico, admin-tecnico, admin |
| POST | `/clientes` | tecnico, admin-tecnico |
| PATCH | `/clientes/:id` | admin-tecnico |

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
| POST | `/repuestos` | admin-tecnico |
| PATCH | `/repuestos/:id` | admin-tecnico |
| POST | `/servicios/:id/repuestos` | tecnico, admin-tecnico, admin |
| GET | `/servicios/:id/repuestos` | tecnico, admin-tecnico, admin |

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
| PATCH | `/liquidaciones/:id` | admin-tecnico |
| PATCH | `/liquidaciones/:id/aprobar` | admin-tecnico |
| POST | `/liquidaciones/:id/items` | admin-tecnico |
| PATCH | `/liquidaciones/:id/items/:itemId/aprobar` | admin-tecnico |
| DELETE | `/liquidaciones/:id/items/:itemId` | admin-tecnico |

### Payloads importantes de liquidacion

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
