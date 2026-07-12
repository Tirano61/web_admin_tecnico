## Progreso

- Liquidaciones operativas: alta/edicion/aprobacion/items y reapertura con motivo.
- Se implemento bloqueo funcional para liquidaciones pasadas a pago (`liquidadaPago=true`):
	- no se pueden editar/aprobar/reabrir/gestionar items.
	- se muestra badge `PASADA A PAGO` en grilla.
- Se implemento nueva pantalla independiente de pagos y resumenes:
	- ruta/modulo: `/liquidaciones-pagos`.
	- preview por tecnico + periodo (`GET /liquidaciones/resumen-pago/preview`).
	- confirmacion de resumen (`PATCH /liquidaciones/resumen-pago/confirmar`).
	- historial paginado (`GET /liquidaciones/resumenes-pago`).
	- ultimo resumen por tecnico (`GET /liquidaciones/resumenes-pago/ultimo`) como sugerencia visual.
	- detalle de resumen (`GET /liquidaciones/resumenes-pago/:id`) en modal.
- UX adicional aplicada en pagos:
	- no permite confirmar sin seleccion.
	- muestra contador de seleccionadas y total USD seleccionado.
	- si hay conflicto de elegibilidad, refresca preview y muestra mensaje de sincronizacion.
	- selector asistido de tecnico (cuando hay historial) con fallback a ingreso manual por ID.
	- historial con navegacion de pagina `Anterior/Siguiente` y chips de contexto (pagina/total).

## Estado actual

- `flutter analyze` sin errores de compilacion nuevos.
- Quedan solo 4 `info` preexistentes por utilidades web (`dart:html`) fuera del alcance de este flujo.

1. Agregar test widget del flujo de pagos:
	 - confirmar deshabilitado sin seleccion.
	 - confirmacion exitosa limpia seleccion y refresca preview.
	 - error de elegibilidad muestra mensaje y refresca lista.
2. Mejorar selector de tecnico con fuente dedicada (endpoint/listado de tecnicos) para no depender del historial cargado.

## Pendiente recomendado

- Agregar selector de fecha para generar los resumenes.