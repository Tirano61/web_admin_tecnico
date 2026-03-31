---
name: Checklist QA Modulo Admin Tecnico
description: "Ejecuta checklist QA de un modulo del admin-tecnico en Flutter web con foco en permisos, estado UI, serializacion, formularios/tablas y pruebas."
argument-hint: "Modulo, rutas, endpoints y alcance de cambios"
agent: review-frontend-flutter
---

Revisa el modulo indicado del panel admin-tecnico y entrega un checklist QA accionable.

## Checklist obligatorio

1. Permisos por rol
   - Validar visibilidad de menu, rutas y acciones para `admin-tecnico` y `admin`.
   - Verificar que no se expongan vistas/acciones de `admin-desarrollo`.
2. Estado y UI
   - Verificar estados loading, error, vacio, exito.
   - Detectar regresiones visuales y perdida de filtros/paginacion.
3. Modelos y serializacion
   - Verificar mapeo `snake_case`/`camelCase`.
   - Revisar nulos/opcionales y compatibilidad de payloads.
4. Formularios, filtros y tablas
   - Validaciones por campo y mensajes de error.
   - Control de submits duplicados y confirmaciones en acciones riesgosas.
5. Pruebas
   - Confirmar cobertura minima en widget tests e integration tests.
   - Listar faltantes concretos por prioridad.

## Formato de entrega

1. Hallazgos por severidad con archivo/linea.
2. Riesgos abiertos.
3. Ajustes minimos recomendados.
