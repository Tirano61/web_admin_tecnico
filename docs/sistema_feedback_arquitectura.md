# Sistema de Gestión de Servicio Técnico

**Balanzas electrónicas para uso agropecuario**
Documento de arquitectura y funcionamiento — Marzo 2026

---

## 1. Objetivo del sistema

Digitalizar y sistematizar el trabajo del servicio técnico de la empresa. El sistema reemplaza las planillas de papel y las hojas de cálculo, y cubre tres necesidades concretas:

- **Operativa** — el técnico genera una orden de servicio digital que reemplaza la planilla de papel. Al finalizar puede compartir o imprimir un PDF equivalente a la orden actual.
- **Administrativa** — el admin-técnico aprueba las salidas y servicios realizados, gestiona los precios y consulta la liquidación de cada técnico.
- **Analítica** — el equipo de desarrollo filtra las órdenes para detectar patrones de falla y generar documentación para el bot de atención al cliente.

Los tres objetivos se alimentan del mismo registro. Una orden de servicio es simultáneamente un comprobante para el cliente, una liquidación para el técnico y un servicio de feedback para desarrollo.

---

## 2. Los tres canales de atención

| Canal | Descripción | Reemplaza |
|---|---|---|
| Visita en campo | El técnico se desplaza al cliente. Registro completo del equipo, síntoma, diagnóstico y resolución. | Planilla de papel en campo |
| Soporte remoto | Atención telefónica o por videollamada. El técnico diagnostica sin ver el equipo. | Sin registro hasta ahora |
| Reparación en fábrica | El equipo ingresa al taller. Se documenta el trabajo realizado. | Planilla de papel en fábrica |

El envío de repuesto no es un canal separado — es una opción dentro del campo Resolución, disponible en cualquiera de los tres canales.

---

## 3. Datos que se registran en una orden

### 3.1 Cliente

El técnico busca al cliente por CUIT o nombre. Si no existe lo crea en el momento. Los datos del cliente quedan guardados para reutilizar en órdenes futuras.

- CUIT (obligatorio — es el identificador único)
- Nombre o razón social
- Nombre de contacto
- Teléfono
- Localidad

### 3.2 Equipo atendido

El equipo no está pre-registrado — se describe en cada orden. Un mismo equipo puede aparecer en distintos clientes si fue vendido usado.

- Número de serie del indicador (obligatorio — identifica la balanza completa)
- Modelo del indicador (ej: ST455, ST108)
- "Colocada en" — campo libre para la marca de la tolva, nombre del campo, o lo que corresponda (ej: "Cestari 14")
- Año de fabricación o compra (estimado)

### 3.3 Falla y diagnóstico

- **Partes que fallaron** — selección múltiple de los componentes que requirieron el servicio. Pueden ser uno o varios a la vez: indicador, celda de carga, app móvil, app PC, tablet/remoto, página web, otro. El indicador da el número de serie de la balanza pero la falla puede estar en cualquier parte que lo compone.
- **Síntoma** — texto libre con las palabras del cliente. Ejemplo: "la balanza muestra pesos distintos cada vez que se pesa lo mismo"
- **Categoría de falla** — selección única administrable: Mal uso, Bug de aplicación, Falla de hardware, App poco intuitiva, Error de configuración, Documentación insuficiente, Sin diagnóstico claro
- **Detalle técnico** — texto libre con el diagnóstico preciso. Ejemplo: "celda CZAP N° 123456789 con el cero roto por sobrecarga reiterada"

### 3.4 Resolución

Selección única administrable: Resuelto en el momento, Requiere seguimiento, Derivado a fábrica, Repuesto enviado, Sin resolución / pendiente.

El nombre del campo cambia según el canal:

| Canal | Label |
|---|---|
| Campo | Resolución |
| Remoto | Resultado del contacto |
| Fábrica | Trabajo realizado |

### 3.5 Repuestos utilizados

El técnico busca repuestos por código o por nombre. Cada repuesto tiene un precio en dólares que se multiplica por la cotización del día al momento de generar la orden. El precio queda congelado en la orden — si después cambia el precio del repuesto o el dólar, la orden ya emitida no se modifica.

- Código (ej: 05-01-CZAP-20000)
- Descripción (ej: Celda CZAP 20000)
- Cantidad
- Precio unitario en USD al momento de la orden
- Cotización del dólar al momento de la orden

### 3.6 Kilometraje

En órdenes de campo el técnico ingresa los km recorridos. El precio por km viene de la tabla de precios administrable del servidor y se multiplica por la cantidad de km ingresada.

### 3.7 Observaciones

Campo libre opcional para contexto adicional, condiciones del entorno, historial previo del equipo, o cualquier dato que no entre en los campos anteriores.

---

## 4. Flujo del técnico paso a paso

```
1. Login con usuario y contraseña
        ↓
2. Buscar cliente por CUIT o nombre
   → Si existe: seleccionarlo
   → Si no existe: crear (CUIT, nombre, contacto, teléfono, localidad)
        ↓
3. Describir el equipo atendido
   → Número de serie del indicador
   → Modelo
   → "Colocada en" (campo libre)
   → Año estimado
   → Componentes presentes
        ↓
4. Completar la orden
   → Canal (campo / remoto / fábrica)
   → Componente que falló
   → Síntoma (texto libre)
   → Categoría de falla + detalle técnico
   → Resolución
   → Repuestos usados (busca por código o nombre)
   → Km recorridos (solo en campo)
   → Observaciones (opcional)
        ↓
5. Guardar → el backend calcula totales con cotización del día
        ↓
6. Compartir o imprimir PDF de la orden
```

---

## 5. El PDF generado

El PDF replica la orden de servicio actual en papel e incluye:

- Encabezado con logo y datos de la empresa
- Fecha, lugar, datos del cliente (nombre, CUIT, contacto, teléfono)
- Datos del equipo (modelo, número de serie, "colocada en")
- Detalle de falla y trabajo realizado
- Tabla de repuestos con código, descripción, cantidad y precio
- Subtotal repuestos + service + km + IVA
- Descuento si corresponde
- Total final
- Espacio para firmas de cliente y técnico

---

## 6. Flujo de liquidación del técnico

La liquidación es interna — no aparece en la orden del cliente.

```
Técnico carga la orden
        ↓
Admin-técnico ve la orden en su panel
        ↓
Asigna tipos de servicio realizados (hasta 6 por salida)
        ↓
Aprueba o rechaza cada item
        ↓
El técnico ve en su app los items aprobados
que le corresponden
```

Cada salida tiene:
- **Tipo de salida** — con precio en USD administrable (ej: local, media distancia, larga distancia)
- **Km recorridos** — multiplicados por el precio del km (también administrable)
- **Tipos de servicio** — hasta 6 items adicionales por salida, cada uno con nombre y precio USD. Se suman entre sí. Solo cuentan cuando el admin los aprueba.

---

## 7. Flujo de análisis de fallas (feedback → bot)

Toda orden es feedback en sí misma. Los datos estructurados (componente que falló, categoría de falla, resolución) permiten filtrar sin depender del texto libre del síntoma.

```
Se acumulan órdenes con el mismo patrón
        ↓
Desarrollo filtra por componente + categoría de falla + resolución
        ↓
Exporta los servicios que coinciden
        ↓
Un humano revisa y redacta el flujo del bot
        ↓
Se incorpora al bot de atención al cliente
```

El proceso de exportación a documentación es deliberadamente manual — el humano decide qué patrones tienen suficiente consistencia para convertirse en un flujo del bot.

---

## 8. Arquitectura del sistema

### 8.1 Interfaces

| Interfaz | Tecnología | Usuarios |
|---|---|---|
| App técnico | Flutter web + APK Android | Técnicos propios |
| Web admin-técnico | Flutter web | Administración interna |
| Web feedback / desarrollo | Flutter web | Equipo de desarrollo |

Las tres interfaces son un mismo proyecto Flutter que muestra distinta UI según el rol del usuario autenticado.

### 8.2 Roles

Los roles se guardan como array en el usuario — una persona puede tener más de un rol.

| Rol | Qué puede hacer |
|---|---|
| tecnico | Cargar órdenes, ver sus servicios, ver su liquidación aprobada, generar PDF |
| admin-tecnico | Todo lo anterior + ver todas las órdenes + aprobar liquidaciones + administrar precios, repuestos y cotización del dólar + historial por cliente o equipo |
| admin-desarrollo | Filtrar y exportar feedback + administrar catálogos de diagnóstico |

### 8.2.1 Mapeo por aplicación

- App técnico (carga de órdenes): `tecnico`
- Web de administración técnica (operación): `admin-tecnico`
- Web de feedback/desarrollo (análisis): `admin-desarrollo`
- Compatibilidad temporal: usuarios con rol `admin` conservan acceso equivalente mientras se completa la migración.

### 8.3 Backend — módulos NestJS

**Módulos existentes**

| Módulo | Endpoints | Acceso |
|---|---|---|
| auth | POST /auth/login, POST /auth/register | Público |
| servicios | POST /servicios, GET /servicios/mios, GET /servicios, GET /servicios/:id, PATCH /servicios/:id | tecnico (mios) / admin-tecnico+admin-desarrollo (todos) |
| catalogos | GET\|POST\|PATCH /cat/diagnosticos, /cat/resoluciones, /zonas | GET: tecnico+admins / diag+res: admin-desarrollo / zonas: admin-tecnico |
| productos | GET\|POST\|PATCH /categorias-producto, /productos | GET: tecnico+admins / POST+PATCH: admin-tecnico |
| clientes | GET /clientes/buscar?q=, POST /clientes, PATCH /clientes/:id | tecnico, admin-tecnico |
| cotizacion | GET /cotizacion, POST /cotizacion | GET: tecnico/admin-tecnico / POST: admin-tecnico |
| repuestos | GET /repuestos?q=, POST /repuestos, PATCH /repuestos/:id, POST /servicios/:id/repuestos, GET /servicios/:id/repuestos | GET: tecnico/admin-tecnico / POST+PATCH: admin-tecnico / servicios: tecnico-admin-tecnico |
| liquidacion | GET\|POST\|PATCH /tipos-salida, GET\|POST\|PATCH /tipos-servicio, POST /liquidaciones, GET /liquidaciones/mias, PATCH /liquidaciones/:id/aprobar, POST /liquidaciones/:id/items | tecnico/admin-tecnico segun endpoint |
| analytics | GET /stats/por-canal, GET /stats/por-diagnostico, GET /stats/por-parte, GET /stats/por-periodo, GET /export | admin-desarrollo |

**Módulos nuevos — orden de servicio**

| Módulo | Endpoints principales | Acceso |
|---|---|---|
| clientes | GET\|POST\|PATCH /clientes, GET /clientes/buscar | tecnico, admin-tecnico |
| repuestos | GET\|POST\|PATCH /repuestos | GET: tecnico / POST+PATCH: admin-tecnico |
| cotizacion | GET\|POST /cotizacion | GET: todos / POST: admin-tecnico |
| orden-repuestos | POST\|GET /servicios/:id/repuestos | tecnico, admin-tecnico |
| pdf | GET /servicios/:id/pdf | tecnico, admin-tecnico |

**Módulos nuevos — liquidación**

| Módulo | Endpoints principales | Acceso |
|---|---|---|
| tipo-salida | GET\|POST\|PATCH /tipos-salida | GET: tecnico / POST+PATCH: admin-tecnico |
| tipo-servicio | GET\|POST\|PATCH /tipos-servicio | GET: tecnico / POST+PATCH: admin-tecnico |
| liquidacion | GET\|POST /liquidaciones, PATCH /liquidaciones/:id/aprobar | tecnico (las propias) / admin-tecnico (todas) |
| liquidacion-items | POST\|PATCH /liquidaciones/:id/items | admin-tecnico |
| analytics | GET /stats/*, GET /export | admin-desarrollo |

### 8.4 Base de datos — tablas

**Usuarios y autenticación**

| Tabla | Campos clave |
|---|---|
| usuario | id, nombre, email, password_hash, roles (array), activo |

**Clientes y equipos**

| Tabla | Campos clave |
|---|---|
| cliente | id, cuit, nombre, contacto, telefono, localidad, activo |

**Órdenes de servicio**

| Tabla | Campos clave |
|---|---|
| caso_servicio | id, tecnico_id, cliente_id, canal, fecha, equipo_nro_serie, equipo_modelo, equipo_ubicacion, equipo_anio, componente_fallo, sintoma, diagnostico_detalle, km, resuelto, observaciones |
| caso_servicio_diagnostico | caso_id, diagnostico_cat_id |
| caso_servicio_resolucion | caso_id, resolucion_id |
| caso_repuesto | id, caso_id, repuesto_id, cantidad, precio_usd_snapshot, cotizacion_snapshot |
| caso_componente | id, caso_id, tipo (indicador/celda/tablet/impresora/otro), nro_serie, modelo, observacion |

**Catálogos de feedback**

| Tabla | Campos clave |
|---|---|
| cat_diagnostico | id, nombre, activo |
| cat_resolucion | id, nombre, activo |
| zona | id, nombre, provincia, activo |
| categoria_producto | id, nombre, activo |
| producto | id, nombre, categoria_id, activo |

**Repuestos y precios**

| Tabla | Campos clave |
|---|---|
| repuesto | id, codigo, nombre, precio_usd, activo |
| cotizacion_dolar | id, valor, fecha, activo |

**Liquidación técnico**

| Tabla | Campos clave |
|---|---|
| tipo_salida | id, nombre, precio_usd, activo |
| tipo_servicio | id, nombre, precio_usd, activo |
| liquidacion | id, caso_id, tecnico_id, tipo_salida_id, km, aprobado, fecha_aprobacion |
| liquidacion_item | id, liquidacion_id, tipo_servicio_id, aprobado, fecha_aprobacion |

> Los catálogos nunca se eliminan — solo se desactivan con `activo: false`. Esto preserva la integridad de las órdenes históricas que los referencian. El `precio_usd_snapshot` en `caso_repuesto` y `cotizacion_snapshot` congelan el valor al momento de la orden — cambios futuros de precios no afectan órdenes ya emitidas.

---

## 9. Aplicación Flutter

### 9.1 Un solo proyecto, tres targets

| Target | Comando | Uso |
|---|---|---|
| APK Android | flutter build apk --release | Técnico en campo con celular |
| Web técnico / admin | flutter build web --release | Técnico en taller, admin-técnico, admin-desarrollo |

La diferencia entre interfaces la determina el rol en el JWT después del login. Un solo build web sirve para todos los roles web.

### 9.2 Estructura del proyecto

```
lib/
├── core/
│   ├── api/          # ApiClient con JWT automático
│   ├── auth/         # SecureStorage del token
│   ├── error/        # Excepciones tipadas
│   ├── di/           # AppDependencies (sin get_it)
│   └── widgets/      # Widgets compartidos
│
├── features/
│   ├── auth/         # Login
│   ├── catalogos/    # Catálogos de feedback
│   ├── servicios/    # Orden de servicio (núcleo)
│   ├── clientes/     # Alta y búsqueda de clientes
│   ├── repuestos/    # Lista de repuestos
│   ├── liquidacion/  # Liquidación del técnico
│   └── admin/        # Panel admin-técnico y admin-desarrollo
│
└── main.dart         # MultiBlocProvider + routing por rol
```

### 9.3 Distribución del APK

Para uso interno no se publica en Play Store. El APK se distribuye por WhatsApp o link de descarga. El técnico lo instala habilitando "instalar desde fuentes desconocidas" en Android. Para actualizaciones se redistribuye el nuevo APK.

---

## 10. Estado actual del backend

| Método | Endpoint | Estado |
|---|---|---|
| POST | /api/v1/auth/login | Implementado |
| POST | /api/v1/auth/register | Implementado |
| GET\|POST\|PATCH | /api/v1/cat/diagnosticos | Implementado |
| GET\|POST\|PATCH | /api/v1/cat/resoluciones | Implementado |
| GET\|POST\|PATCH | /api/v1/zonas | Implementado |
| GET\|POST\|PATCH | /api/v1/categorias-producto | Implementado |
| GET\|POST\|PATCH | /api/v1/productos | Implementado |
| POST | /api/v1/servicios | Implementado |
| GET | /api/v1/servicios/mios | Implementado |
| GET | /api/v1/servicios | Implementado |
| GET | /api/v1/servicios/:id | Implementado |
| PATCH | /api/v1/servicios/:id | Implementado |
| GET | /api/v1/clientes/buscar?q= | Implementado |
| POST | /api/v1/clientes | Implementado |
| PATCH | /api/v1/clientes/:id | Implementado |
| GET | /api/v1/repuestos?q= | Implementado |
| POST | /api/v1/repuestos | Implementado |
| PATCH | /api/v1/repuestos/:id | Implementado |
| POST | /api/v1/servicios/:id/repuestos | Implementado |
| GET | /api/v1/servicios/:id/repuestos | Implementado |
| GET | /api/v1/cotizacion | Implementado |
| POST | /api/v1/cotizacion | Implementado |
| GET | /api/v1/tipos-salida | Implementado |
| POST | /api/v1/tipos-salida | Implementado |
| PATCH | /api/v1/tipos-salida/:id | Implementado |
| GET | /api/v1/tipos-servicio | Implementado |
| POST | /api/v1/tipos-servicio | Implementado |
| PATCH | /api/v1/tipos-servicio/:id | Implementado |
| POST | /api/v1/liquidaciones | Implementado |
| GET | /api/v1/liquidaciones/mias | Implementado |
| PATCH | /api/v1/liquidaciones/:id/aprobar | Implementado |
| POST | /api/v1/liquidaciones/:id/items | Implementado |
| GET | /api/v1/servicios/:id/pdf | Pendiente |
| GET | /api/v1/stats/por-canal | Implementado |
| GET | /api/v1/stats/por-diagnostico | Implementado |
| GET | /api/v1/stats/por-parte | Implementado |
| GET | /api/v1/stats/por-periodo | Implementado |
| GET | /api/v1/export | Implementado |

---

## 11. Próximos pasos

1. **Ampliar `caso_servicio`** — agregar los campos nuevos: cliente_id, equipo_nro_serie, equipo_modelo, equipo_ubicacion, equipo_anio, componente_fallo, km.
2. **Módulo clientes** — alta, búsqueda por CUIT o nombre, edición.
3. **Módulo repuestos** — implementado: lista de precios con código y precio USD, búsqueda por código o nombre, alta en órdenes con snapshot de cotización.
4. **Módulo cotización** — implementado: valor del dólar administrable, historial de cotizaciones.
5. **Seeds de catálogos** — datos iniciales de diagnósticos, resoluciones, zonas, categorías y modelos de producto.
6. **App Flutter del técnico** — formulario completo con búsqueda de cliente, descripción del equipo, orden y repuestos.
7. **Generación de PDF** — orden de servicio imprimible equivalente a la planilla actual.
8. **Módulo liquidación** — implementado: tipos de salida, tipos de servicio, creación de liquidación por servicio, items (hasta 6) y aprobación por admin.
9. **Panel admin-técnico** — aprobación de liquidaciones, administración de precios y repuestos.
10. **Panel feedback / desarrollo** — dashboard con charts, tabla filtrable, exportación.
11. **Módulo analytics** — implementado: queries agregadas y exportación (pendiente validación con volumen de datos reales).
