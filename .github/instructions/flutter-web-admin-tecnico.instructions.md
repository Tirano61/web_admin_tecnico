---
name: Flutter Web Admin Tecnico
description: "Usar cuando se implemente o refactorice codigo Dart del panel admin-tecnico en Flutter web: features, estado, API JWT, mapeo de modelos y control por rol."
applyTo: "lib/core/**/*.dart, lib/features/**/*.dart, test/**/*_test.dart, integration_test/**/*.dart"
---

# Guia de desarrollo Flutter web admin-tecnico

## Alcance funcional

- Esta app corresponde al rol `admin-tecnico` (y `admin` por compatibilidad).
- API base esperada: `/api/v1`.
- No tocar codigo backend desde esta instruccion.

## Arquitectura por feature

- Organizar por feature dentro de `lib/features/<feature>/`.
- Mantener capas explicitas por feature:
  - `data`: DTOs, datasources HTTP, mappers.
  - `domain`: entities, contratos de repositorio, casos de uso.
  - `presentation`: pages, widgets, estado y coordinacion UI.
- Evitar logica de negocio en widgets.
- Evitar dependencias cruzadas entre features salvo contratos claros en `core`.

## Estado y flujo UI

- Preferir `flutter_bloc` o patron equivalente con estados tipados y eventos claros.
- Modelar estados de carga, exito, vacio y error de forma explicita.
- Preservar filtros, paginacion y orden en tablas cuando haya refresh de datos.
- Evitar `setState` para flujos complejos que involucren API o permisos.

## Consumo de API y JWT

- Centralizar llamadas HTTP en clientes/repositorios de `data`.
- Adjuntar `Authorization: Bearer <token>` en endpoints privados.
- Manejar `401/403` con flujo consistente: renovar sesion si aplica o forzar logout.
- Normalizar URLs relativas de documento/PDF contra host + prefijo `/api/v1` cuando sea necesario.

## Serializacion y mapeo snake_case -> camelCase

- En Dart usar `camelCase` para propiedades de modelos y entidades.
- Mapear payloads `snake_case` del backend a `camelCase` en DTOs/mappers.
- Tolerar compatibilidad cuando backend acepte ambas variantes (ej: `servicio_id` y `servicioId`).
- Agregar pruebas de serializacion para campos criticos y casos opcionales/null.

## Control por rol y navegacion

- Habilitar rutas y vistas segun rol JWT (`admin-tecnico`, `admin`).
- Mostrar 403 o redireccion controlada si el rol no tiene permiso.
- Ocultar o bloquear modulos de `admin-desarrollo` (analytics/export) en esta web.
- Respetar permisos por endpoint antes de renderizar acciones de UI (crear/editar/aprobar).

## Reglas de calidad minima

- Mantener nombres consistentes con endpoints y modulos del dominio: servicios, clientes, catalogos, precios, liquidaciones.
- Validar formularios antes de enviar y mostrar errores por campo.
- Agregar o actualizar tests cuando cambie logica de estado, serializacion o permisos.
