---
name: UX Layout Panel Admin Web
description: "Usar cuando se construyan vistas Dart del panel admin web: layout, navegacion, tablas, filtros, formularios y feedback UX con foco operativo admin-tecnico."
applyTo: "lib/features/**/presentation/**/*.dart, lib/core/widgets/**/*.dart, test/**/*_test.dart, integration_test/**/*.dart"
---

# Guia UX y layout para panel administrativo web

## Objetivo UX

- Priorizar productividad operativa: menos clics, estados claros, acciones seguras.
- En desktop usar jerarquia visual para lectura rapida de tablas y KPIs operativos.
- En tablet conservar usabilidad (sin romper flujo principal del backoffice).

## Estructura de pantalla

- Usar shell administrativo con menu lateral estable y area principal.
- Mantener rutas consistentes por modulo: servicios, clientes, catalogos, precios, liquidaciones.
- Incluir breadcrumbs o encabezado contextual en vistas de detalle.
- Evitar modales gigantes para flujos largos; preferir pagina de detalle/edicion.

## Tablas, filtros y listados

- Los listados deben incluir: loading, vacio, error y resultado.
- Filtros persistentes al volver del detalle.
- Debounce en busquedas de texto y paginacion estable.
- Acciones por fila deben respetar permisos de rol antes de mostrarse.

## Formularios y validaciones

- Validacion local antes de enviar y resumen de errores visible.
- Mensajes de error accionables por campo.
- Boton submit deshabilitado durante envio para evitar duplicados.
- En acciones riesgosas (aprobar, eliminar item) pedir confirmacion explicita.

## Visibilidad por rol

- `admin-tecnico` y `admin`: acceso completo a modulos operativos habilitados.
- No mostrar analytics/export ni acciones exclusivas de `admin-desarrollo`.
- Para recursos de solo lectura en este rol, renderizar estado read-only en lugar de ocultar contexto clave.

## Criterios visuales de consistencia

- Mantener espaciado, tipografia y componentes de forma uniforme en toda la app.
- Evitar sobrecarga de color; usar color para estado y prioridad, no decoracion.
- Mensajes de exito/error deben ser breves, trazables y sin ambiguedad.
