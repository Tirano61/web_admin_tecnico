import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:web_admin_tecnico/core/widgets/module_page_layout.dart';
import 'package:web_admin_tecnico/features/app_shell/domain/app_module.dart';
import 'package:web_admin_tecnico/features/app_shell/presentation/bloc/app_shell_bloc.dart';
import 'package:web_admin_tecnico/features/dashboard/data/dashboard_repository_impl.dart';
import 'package:web_admin_tecnico/features/dashboard/domain/dashboard_repository.dart';
import 'package:web_admin_tecnico/features/dashboard/presentation/bloc/dashboard_bloc.dart';
import 'package:web_admin_tecnico/features/liquidaciones/presentation/widgets/liquidacion_estado_badge.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key, this.repository});

  /// Inyectable para tests; en la app real arma las metricas contra el backend.
  final DashboardRepository? repository;

  @override
  Widget build(BuildContext context) {
    return BlocProvider<DashboardBloc>(
      create: (_) =>
          DashboardBloc(repository ?? DashboardRepositoryImpl())..add(DashboardRequested()),
      child: const _DashboardView(),
    );
  }
}

class _DashboardView extends StatelessWidget {
  const _DashboardView();

  static const double _scale = 0.8;

  static const List<String> _meses = <String>[
    'enero',
    'febrero',
    'marzo',
    'abril',
    'mayo',
    'junio',
    'julio',
    'agosto',
    'septiembre',
    'octubre',
    'noviembre',
    'diciembre',
  ];

  void _irA(BuildContext context, AppModule module) {
    context.read<AppShellBloc>().add(AppShellModuleChanged(module));
  }

  String _valor(int? valor) => valor?.toString() ?? '—';

  String _hora(DateTime fecha) =>
      '${fecha.hour.toString().padLeft(2, '0')}:${fecha.minute.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    return ModulePageLayout(
      title: 'Dashboard',
      subtitle: 'Resumen operativo del periodo y pendientes que requieren accion.',
      trailing: BlocBuilder<DashboardBloc, DashboardState>(
        builder: (context, state) {
          return Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              if (state is DashboardLoaded) ...<Widget>[
                ModuleStatusChip(label: 'Actualizado ${_hora(state.actualizadoEn)}'),
                SizedBox(width: 8 * _scale),
              ],
              OutlinedButton.icon(
                onPressed: state is DashboardLoading
                    ? null
                    : () => context.read<DashboardBloc>().add(DashboardRequested()),
                icon: Icon(Icons.refresh_rounded, size: 18 * _scale),
                label: const Text('Actualizar'),
              ),
            ],
          );
        },
      ),
      child: BlocBuilder<DashboardBloc, DashboardState>(
        builder: (context, state) {
          if (state is DashboardFailure) {
            return _DashboardError(
              message: state.message,
              onRetry: () => context.read<DashboardBloc>().add(DashboardRequested()),
            );
          }
          if (state is! DashboardLoaded) {
            return const Center(child: CircularProgressIndicator());
          }

          final metricas = state.metricas;
          final servicios = metricas.serviciosMes;
          final pendientes = metricas.liquidacionesPendientes;

          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                if (metricas.requiereAtencion) ...<Widget>[
                  _AvisoAtencion(
                    reabiertas: metricas.reabiertas,
                    pendientesAntiguas: metricas.pendientesAntiguas,
                    diasAlerta: metricas.diasAlertaPendientes,
                    onVerLiquidaciones: () => _irA(context, AppModule.liquidaciones),
                  ),
                  SizedBox(height: 16 * _scale),
                ],
                _SeccionTitulo(texto: 'Periodo actual · ${_meses[state.inicioMes.month - 1]} ${state.inicioMes.year}'),
                SizedBox(height: 10 * _scale),
                _GrillaTarjetas(
                  children: <Widget>[
                    _MetricaCard(
                      etiqueta: 'Servicios del mes',
                      valor: _valor(servicios?.total),
                      icono: Icons.engineering_outlined,
                      detalle: servicios == null
                          ? null
                          : 'Campo ${servicios.campo} · Remoto ${servicios.remoto} · Fabrica ${servicios.fabrica}',
                    ),
                    _MetricaCard(
                      etiqueta: 'Liquidaciones pendientes',
                      valor: _valor(pendientes?.total),
                      icono: Icons.hourglass_top_rounded,
                      acento: LiquidacionEstadoColores.pendienteTexto,
                      detalle: pendientes == null
                          ? null
                          : '${pendientes.antiguas} con mas de ${metricas.diasAlertaPendientes} dias',
                    ),
                    _MetricaCard(
                      etiqueta: 'Liquidaciones reabiertas',
                      valor: _valor(metricas.liquidacionesReabiertas),
                      icono: Icons.replay_rounded,
                      acento: LiquidacionEstadoColores.reabiertaTexto,
                      detalle: 'Fuera del circuito de pago',
                    ),
                    _MetricaCard(
                      etiqueta: 'Listas para pago',
                      valor: _valor(metricas.liquidacionesParaPago),
                      icono: Icons.payments_outlined,
                      acento: LiquidacionEstadoColores.aprobadaTexto,
                      detalle: 'Aprobadas y no liquidadas',
                    ),
                    _MetricaCard(
                      etiqueta: 'Tecnicos activos',
                      valor: _valor(metricas.tecnicosActivos),
                      icono: Icons.badge_outlined,
                    ),
                  ],
                ),
                SizedBox(height: 22 * _scale),
                const _SeccionTitulo(texto: 'Accesos rapidos'),
                SizedBox(height: 10 * _scale),
                _GrillaTarjetas(
                  children: <Widget>[
                    _AccesoRapido(
                      titulo: 'Liquidaciones pendientes',
                      descripcion: 'Revisar, asignar items y aprobar.',
                      icono: AppModule.liquidaciones.icon,
                      onTap: () => _irA(context, AppModule.liquidaciones),
                    ),
                    _AccesoRapido(
                      titulo: 'Pagos a tecnicos',
                      descripcion: 'Generar y confirmar resumenes de pago.',
                      icono: AppModule.liquidacionesPagos.icon,
                      onTap: () => _irA(context, AppModule.liquidacionesPagos),
                    ),
                    _AccesoRapido(
                      titulo: 'Servicios',
                      descripcion: 'Ordenes cargadas, detalle y PDF.',
                      icono: AppModule.servicios.icon,
                      onTap: () => _irA(context, AppModule.servicios),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _SeccionTitulo extends StatelessWidget {
  const _SeccionTitulo({required this.texto});

  final String texto;

  @override
  Widget build(BuildContext context) {
    return Text(
      texto,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: const Color(0xFFE4F0FF),
            fontWeight: FontWeight.w700,
          ),
    );
  }
}

/// Grilla responsive: 1 columna en mobile, hasta 5 en pantallas anchas.
class _GrillaTarjetas extends StatelessWidget {
  const _GrillaTarjetas({required this.children});

  final List<Widget> children;

  static const double _scale = 0.8;
  static const double _anchoMinimo = 220 * _scale;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final espacio = 12 * _scale;
        final columnas = ((constraints.maxWidth + espacio) / (_anchoMinimo + espacio))
            .floor()
            .clamp(1, children.length);
        final ancho = (constraints.maxWidth - espacio * (columnas - 1)) / columnas;

        return Wrap(
          spacing: espacio,
          runSpacing: espacio,
          children: children.map((child) => SizedBox(width: ancho, child: child)).toList(),
        );
      },
    );
  }
}

class _MetricaCard extends StatelessWidget {
  const _MetricaCard({
    required this.etiqueta,
    required this.valor,
    required this.icono,
    this.detalle,
    this.acento = const Color(0xFF9BD5FF),
  });

  final String etiqueta;
  final String valor;
  final IconData icono;
  final String? detalle;
  final Color acento;

  static const double _scale = 0.8;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: EdgeInsets.all(16 * _scale),
      decoration: BoxDecoration(
        color: const Color(0xCC0F2C4A),
        borderRadius: BorderRadius.circular(14 * _scale),
        border: Border.all(color: const Color(0x334FAAE9)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Container(
                padding: EdgeInsets.all(7 * _scale),
                decoration: BoxDecoration(
                  color: acento.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10 * _scale),
                  border: Border.all(color: acento.withValues(alpha: 0.35)),
                ),
                child: Icon(icono, size: 18 * _scale, color: acento),
              ),
              SizedBox(width: 10 * _scale),
              Expanded(
                child: Text(
                  etiqueta,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.bodyMedium?.copyWith(
                    color: const Color(0xFFB3C8DF),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 12 * _scale),
          Text(
            valor,
            style: textTheme.headlineSmall?.copyWith(
              color: const Color(0xFFF2F8FF),
              fontSize: 30 * _scale,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: 4 * _scale),
          Text(
            detalle ?? ' ',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: textTheme.bodySmall?.copyWith(color: const Color(0xFF9FB9D5)),
          ),
        ],
      ),
    );
  }
}

class _AvisoAtencion extends StatelessWidget {
  const _AvisoAtencion({
    required this.reabiertas,
    required this.pendientesAntiguas,
    required this.diasAlerta,
    required this.onVerLiquidaciones,
  });

  final int reabiertas;
  final int pendientesAntiguas;
  final int diasAlerta;
  final VoidCallback onVerLiquidaciones;

  static const double _scale = 0.8;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final lineas = <String>[
      if (reabiertas > 0)
        reabiertas == 1
            ? '1 liquidacion reabierta espera volver a aprobarse.'
            : '$reabiertas liquidaciones reabiertas esperan volver a aprobarse.',
      if (pendientesAntiguas > 0)
        pendientesAntiguas == 1
            ? '1 liquidacion lleva mas de $diasAlerta dias pendiente.'
            : '$pendientesAntiguas liquidaciones llevan mas de $diasAlerta dias pendientes.',
    ];

    final contenido = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          'Requiere atencion',
          style: textTheme.titleSmall?.copyWith(
            color: LiquidacionEstadoColores.pendienteTexto,
            fontWeight: FontWeight.w700,
          ),
        ),
        SizedBox(height: 4 * _scale),
        for (final linea in lineas)
          Text(linea, style: textTheme.bodyMedium?.copyWith(color: const Color(0xFFEAF3FF))),
      ],
    );

    final boton = FilledButton.icon(
      onPressed: onVerLiquidaciones,
      icon: Icon(Icons.arrow_forward_rounded, size: 18 * _scale),
      label: const Text('Ver liquidaciones'),
    );

    return Container(
      padding: EdgeInsets.all(16 * _scale),
      decoration: BoxDecoration(
        color: LiquidacionEstadoColores.pendienteFondo,
        borderRadius: BorderRadius.circular(14 * _scale),
        border: Border.all(color: LiquidacionEstadoColores.pendienteTexto.withValues(alpha: 0.55)),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final icono = Icon(
            Icons.warning_amber_rounded,
            color: LiquidacionEstadoColores.pendienteTexto,
            size: 28 * _scale,
          );

          if (constraints.maxWidth < 560) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    icono,
                    SizedBox(width: 12 * _scale),
                    Expanded(child: contenido),
                  ],
                ),
                SizedBox(height: 12 * _scale),
                boton,
              ],
            );
          }

          return Row(
            children: <Widget>[
              icono,
              SizedBox(width: 12 * _scale),
              Expanded(child: contenido),
              SizedBox(width: 12 * _scale),
              boton,
            ],
          );
        },
      ),
    );
  }
}

class _AccesoRapido extends StatelessWidget {
  const _AccesoRapido({
    required this.titulo,
    required this.descripcion,
    required this.icono,
    required this.onTap,
  });

  final String titulo;
  final String descripcion;
  final IconData icono;
  final VoidCallback onTap;

  static const double _scale = 0.8;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Material(
      color: const Color(0x33163352),
      borderRadius: BorderRadius.circular(14 * _scale),
      child: InkWell(
        borderRadius: BorderRadius.circular(14 * _scale),
        onTap: onTap,
        child: Container(
          padding: EdgeInsets.all(14 * _scale),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14 * _scale),
            border: Border.all(color: const Color(0x554F89BE)),
          ),
          child: Row(
            children: <Widget>[
              Icon(icono, color: const Color(0xFF9BD5FF), size: 22 * _scale),
              SizedBox(width: 12 * _scale),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      titulo,
                      style: textTheme.bodyMedium?.copyWith(
                        color: const Color(0xFFEAF5FF),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(height: 2 * _scale),
                    Text(
                      descripcion,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.bodySmall?.copyWith(color: const Color(0xFF9FB9D5)),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: const Color(0xFFB3C8DF), size: 20 * _scale),
            ],
          ),
        ),
      ),
    );
  }
}

class _DashboardError extends StatelessWidget {
  const _DashboardError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          const Icon(Icons.cloud_off_rounded, color: Color(0xFFFF8E8E), size: 32),
          const SizedBox(height: 10),
          Text(message, textAlign: TextAlign.center),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Reintentar'),
          ),
        ],
      ),
    );
  }
}
