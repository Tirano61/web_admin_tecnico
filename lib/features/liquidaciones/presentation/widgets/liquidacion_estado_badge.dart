import 'package:flutter/material.dart';
import 'package:web_admin_tecnico/core/widgets/module_page_layout.dart';
import 'package:web_admin_tecnico/features/liquidaciones/domain/liquidaciones_repository.dart';

/// Paleta de estados de liquidacion.
///
/// `reabierta` tiene color propio (magenta) para no confundirse ni con el
/// naranja de pendiente, ni con el verde de aprobada, ni con el azul que usan
/// los chips neutros del modulo.
class LiquidacionEstadoColores {
  const LiquidacionEstadoColores._();

  static const Color pendienteFondo = Color(0x1FF4B942);
  static const Color pendienteTexto = Color(0xFFFFD98B);

  static const Color aprobadaFondo = Color(0x1F0FA960);
  static const Color aprobadaTexto = Color(0xFF8FF0BC);

  static const Color reabiertaFondo = Color(0x2EFF4D9D);
  static const Color reabiertaTexto = Color(0xFFFFA8D2);
  static const Color reabiertaBorde = Color(0x66FF4D9D);

  static const Color pagadaFondo = Color(0x1F7A4CFF);
  static const Color pagadaTexto = Color(0xFFCFBEFF);
}

/// Badge de estado de una liquidacion: pendiente, aprobada, reabierta o pagada.
class LiquidacionEstadoBadge extends StatelessWidget {
  const LiquidacionEstadoBadge({super.key, required this.liquidacion});

  final LiquidacionItem liquidacion;

  @override
  Widget build(BuildContext context) {
    if (liquidacion.liquidadaPago) {
      return const ModuleStatusChip(
        label: 'PASADA A PAGO',
        backgroundColor: LiquidacionEstadoColores.pagadaFondo,
        foregroundColor: LiquidacionEstadoColores.pagadaTexto,
      );
    }

    if (liquidacion.isReabierta) {
      return const ModuleStatusChip(
        label: 'REABIERTA',
        backgroundColor: LiquidacionEstadoColores.reabiertaFondo,
        foregroundColor: LiquidacionEstadoColores.reabiertaTexto,
      );
    }

    if (liquidacion.isAprobadaEstado) {
      return const ModuleStatusChip(
        label: 'APROBADA PAGO',
        backgroundColor: LiquidacionEstadoColores.aprobadaFondo,
        foregroundColor: LiquidacionEstadoColores.aprobadaTexto,
      );
    }

    return const ModuleStatusChip(
      label: 'PENDIENTE',
      backgroundColor: LiquidacionEstadoColores.pendienteFondo,
      foregroundColor: LiquidacionEstadoColores.pendienteTexto,
    );
  }
}

/// Aviso de que una liquidacion reabierta quedo fuera del circuito de pago.
///
/// Muestra el motivo registrado en la reapertura para que el admin sepa por que
/// volvio a edicion.
class LiquidacionReabiertaAviso extends StatelessWidget {
  const LiquidacionReabiertaAviso({
    super.key,
    required this.motivo,
    this.fecha,
    this.titulo = 'Liquidacion reabierta',
  });

  final String? motivo;
  final String? fecha;
  final String titulo;

  @override
  Widget build(BuildContext context) {
    final motivoTexto = (motivo ?? '').trim();
    final fechaCruda = (fecha ?? '').trim();
    final fechaTexto = fechaCruda == '-' ? '' : fechaCruda;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: LiquidacionEstadoColores.reabiertaFondo,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: LiquidacionEstadoColores.reabiertaBorde),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              const Icon(
                Icons.lock_reset_outlined,
                size: 18,
                color: LiquidacionEstadoColores.reabiertaTexto,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  fechaTexto.isEmpty ? titulo : '$titulo - $fechaTexto',
                  style: const TextStyle(
                    color: LiquidacionEstadoColores.reabiertaTexto,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            motivoTexto.isEmpty
                ? 'Motivo: sin registrar.'
                : 'Motivo: $motivoTexto',
            style: const TextStyle(color: Color(0xFFEAF3FF)),
          ),
          const SizedBox(height: 6),
          const Text(
            'Queda fuera del circuito de pago: no entra en el resumen ni se '
            'puede marcar como pagada hasta volver a aprobarla.',
            style: TextStyle(color: Color(0xFF9AB1CC)),
          ),
        ],
      ),
    );
  }
}
