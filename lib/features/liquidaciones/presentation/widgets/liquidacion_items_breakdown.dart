import 'package:flutter/material.dart';
import 'package:web_admin_tecnico/features/liquidaciones/domain/liquidacion_pago_calculator.dart';
import 'package:web_admin_tecnico/features/liquidaciones/domain/liquidaciones_repository.dart';
import 'package:web_admin_tecnico/features/liquidaciones/presentation/bloc/liquidacion_items_cache.dart';

/// Desglose de una liquidacion: tipo de salida, items de tipo servicio con su
/// precio snapshot, y el total resultante.
///
/// El tipo de salida (nombre y precio) NO viene de GET /liquidaciones/:id/items:
/// el precio lo aporta la fila del resumen (`subtotalSalidaUsd` en el preview,
/// `subtotalSalidaUsdSnapshot` en el detalle) y el nombre lo resuelve la capa
/// data contra GET /liquidaciones. Por eso ambos entran por parametro.
class LiquidacionItemsBreakdown extends StatelessWidget {
  const LiquidacionItemsBreakdown({
    super.key,
    required this.entry,
    required this.onRetry,
    this.tipoSalidaNombre,
    this.subtotalSalidaUsd,
    this.expectedTotalUsd,
    this.header,
  });

  /// Null significa que todavia no se intento cargar.
  final LiquidacionItemsEntry? entry;
  final VoidCallback onRetry;

  /// Nombre resuelto por la capa data desde GET /liquidaciones. El endpoint de
  /// items no lo garantiza, asi que este parametro es la fuente principal y lo
  /// que venga en `entry` queda como respaldo.
  final String? tipoSalidaNombre;
  final double? subtotalSalidaUsd;
  final double? expectedTotalUsd;
  final Widget? header;

  static const double _scale = 0.8;
  static const Color _textColor = Color(0xFFBFD3E8);
  static const Color _mutedColor = Color(0xFF9FB9D5);
  static const Color _warningColor = Color(0xFFFFD98B);

  @override
  Widget build(BuildContext context) {
    final current = entry;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        if (header != null) ...<Widget>[
          header!,
          SizedBox(height: 8 * _scale),
        ],
        if (current == null || current.status == LiquidacionItemsLoadStatus.idle)
          _buildAction(
            context,
            message: 'Todavia no se cargaron los items.',
            actionLabel: 'Cargar items',
          )
        else if (current.isLoading)
          _buildLoading(context)
        else if (current.status == LiquidacionItemsLoadStatus.unavailable)
          _buildAction(
            context,
            message: 'El detalle de items no esta disponible en este momento.',
            actionLabel: 'Reintentar',
            warning: true,
          )
        else if (current.status == LiquidacionItemsLoadStatus.error)
          _buildAction(
            context,
            message: current.error ?? 'No se pudieron cargar los items.',
            actionLabel: 'Reintentar',
            warning: true,
          )
        else
          _buildLoaded(context, current.response!),
      ],
    );
  }

  Widget _buildLoading(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        SizedBox(
          width: 14 * _scale,
          height: 14 * _scale,
          child: const CircularProgressIndicator(strokeWidth: 2),
        ),
        SizedBox(width: 10 * _scale),
        Text(
          'Cargando items...',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(color: _mutedColor),
        ),
      ],
    );
  }

  Widget _buildAction(
    BuildContext context, {
    required String message,
    required String actionLabel,
    bool warning = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          message,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: warning ? _warningColor : _mutedColor,
              ),
        ),
        SizedBox(height: 8 * _scale),
        FilledButton.tonalIcon(
          onPressed: onRetry,
          icon: Icon(Icons.refresh, size: 16 * _scale),
          label: Text(actionLabel),
        ),
      ],
    );
  }

  Widget _buildLoaded(BuildContext context, LiquidacionItemsResponse response) {
    final theme = Theme.of(context);
    final salida = subtotalSalidaUsd ?? 0;
    final nombreSalida = (tipoSalidaNombre ?? '').trim().isNotEmpty
        ? tipoSalidaNombre!.trim()
        : (response.tipoSalidaNombre ?? '').trim();
    final total = calculateLiquidacionTotalTecnicoUsd(
      tipoSalidaPrecioUsd: salida,
      items: response.items,
    );
    final expected = expectedTotalUsd;
    final difiere = expected != null && (total - expected).abs() > 0.01;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        RichText(
          text: TextSpan(
            style: theme.textTheme.bodyMedium?.copyWith(color: _textColor),
            children: <TextSpan>[
              const TextSpan(text: 'Tipo de salida: '),
              TextSpan(
                text: nombreSalida.isEmpty ? 'sin dato' : nombreSalida,
                style: TextStyle(
                  color: nombreSalida.isEmpty ? _mutedColor : _textColor,
                  fontWeight: nombreSalida.isEmpty ? FontWeight.w400 : FontWeight.w600,
                ),
              ),
              TextSpan(text: '  ${salida.toStringAsFixed(2)} USD'),
            ],
          ),
        ),
        SizedBox(height: 8 * _scale),
        if (response.items.isEmpty)
          Text(
            'Sin items de tipo servicio registrados para esta liquidacion.',
            style: theme.textTheme.bodySmall?.copyWith(color: _mutedColor),
          )
        else
          _buildItemsTable(context, response),
        SizedBox(height: 10 * _scale),
        _buildTotalLine(context, total: total, difiere: difiere, esperado: expected),
      ],
    );
  }

  Widget _buildItemsTable(BuildContext context, LiquidacionItemsResponse response) {
    final theme = Theme.of(context);
    final headerStyle = theme.textTheme.labelMedium?.copyWith(
      color: _mutedColor,
      fontWeight: FontWeight.w700,
    );
    final cellStyle = theme.textTheme.bodySmall?.copyWith(color: _textColor);

    return Table(
      // Hereda el ancho del panel: un DataTable anidado meteria un segundo
      // scroll horizontal dentro del que ya tiene la grilla.
      columnWidths: <int, TableColumnWidth>{
        0: const FlexColumnWidth(),
        1: FixedColumnWidth(120 * _scale),
      },
      defaultVerticalAlignment: TableCellVerticalAlignment.middle,
      children: <TableRow>[
        TableRow(
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: Color(0x334EA6FF))),
          ),
          children: <Widget>[
            _cell(Text('Tipo servicio', style: headerStyle)),
            _cell(Text('Precio USD', style: headerStyle), alignEnd: true),
          ],
        ),
        for (final item in response.items)
          TableRow(
            children: <Widget>[
              _cell(Text(item.tipoServicioNombre, style: cellStyle)),
              _cell(
                Text(item.precioUsdSnapshot.toStringAsFixed(2), style: cellStyle),
                alignEnd: true,
              ),
            ],
          ),
        TableRow(
          decoration: const BoxDecoration(
            border: Border(top: BorderSide(color: Color(0x334EA6FF))),
          ),
          children: <Widget>[
            _cell(
              Text(
                'Subtotal items (${response.meta.totalItems})',
                style: cellStyle?.copyWith(fontWeight: FontWeight.w600),
              ),
            ),
            _cell(
              Text(
                response.meta.subtotalUsdTotal.toStringAsFixed(2),
                style: cellStyle?.copyWith(fontWeight: FontWeight.w600),
              ),
              alignEnd: true,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTotalLine(
    BuildContext context, {
    required double total,
    required bool difiere,
    required double? esperado,
  }) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          'Total liquidacion USD ${total.toStringAsFixed(2)}',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: const Color(0xFFEAF4FF),
            fontWeight: FontWeight.w700,
          ),
        ),
        if (difiere) ...<Widget>[
          SizedBox(height: 6 * _scale),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Icon(Icons.warning_amber_rounded, size: 15 * _scale, color: _warningColor),
              SizedBox(width: 6 * _scale),
              Flexible(
                child: Text(
                  'Revisar: el desglose no coincide con el total informado '
                  '(${esperado!.toStringAsFixed(2)} USD).',
                  style: theme.textTheme.bodySmall?.copyWith(color: _warningColor),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _cell(Widget child, {bool alignEnd = false}) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 5 * _scale, horizontal: 2 * _scale),
      child: Align(
        alignment: alignEnd ? Alignment.centerRight : Alignment.centerLeft,
        child: child,
      ),
    );
  }
}
