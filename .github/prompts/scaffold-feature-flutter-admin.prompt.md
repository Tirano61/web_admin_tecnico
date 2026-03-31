---
name: Scaffold Feature Flutter Admin
description: "Genera scaffolding de una feature Flutter web admin-tecnico con capas data/domain/presentation, estado, rutas protegidas y pruebas base."
argument-hint: "Nombre de feature, endpoints, permisos de rol y alcance"
agent: agent
---

Genera el scaffolding de una feature para la web Flutter admin-tecnico.

## Entradas esperadas

- Nombre de la feature.
- Endpoints involucrados (`/api/v1/...`) y metodos HTTP.
- Roles habilitados para leer/escribir.
- Reglas de negocio criticas (validaciones, filtros, estados).

## Requisitos de salida

1. Proponer estructura de carpetas por capas:
   - `data/` (dto, datasource, repository impl, mappers)
   - `domain/` (entities, repository contract, use cases)
   - `presentation/` (pages, widgets, estado)
2. Incluir modelos con mapeo `snake_case` a `camelCase`.
3. Incluir contrato de repositorio y caso(s) de uso minimo(s).
4. Incluir manejo de token JWT en llamadas privadas (sin secretos hardcodeados).
5. Incluir guardas de navegacion y visibilidad por rol.
6. Incluir pruebas base:
   - widget test para estado UI principal.
   - prueba de serializacion DTO.
7. Mantener cambios en frontend Flutter; no tocar backend.

## Formato de respuesta

- Paso 1: breve checklist de archivos a crear/editar.
- Paso 2: contenido inicial de archivos clave.
- Paso 3: comandos de validacion sugeridos (`flutter analyze`, `flutter test`).
