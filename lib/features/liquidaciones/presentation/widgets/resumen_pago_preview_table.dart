import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:web_admin_tecnico/core/widgets/module_page_layout.dart';
import 'package:web_admin_tecnico/features/liquidaciones/domain/liquidaciones_repository.dart';
import 'package:web_admin_tecnico/features/liquidaciones/presentation/bloc/liquidacion_items_cache.dart';
import 'package:web_admin_tecnico/features/liquidaciones/presentation/widgets/liquidacion_items_breakdown.dart';

class PreviewColumn {
  const PreviewColumn(this.label, this.width, {this.alignEnd = false});

  final String label;
  final double width;
  final bool alignEnd;
}

/// Los ids (Liq / Srv) no ocupan columna: son UUIDs ilegibles de un vistazo y
/// se muestran dentro del panel expandido, con boton de copiar.
const List<PreviewColumn> kPreviewColumns = <PreviewColumn>[
  PreviewColumn('', 34),
  PreviewColumn('Sel', 50),
  PreviewColumn('Cliente', 250),
  PreviewColumn('Fecha aprob.', 145),
  PreviewColumn('Tipo salida', 175),
  PreviewColumn('Salida USD', 105, alignEnd: true),
  PreviewColumn('Items USD', 105, alignEnd: true),
  PreviewColumn('Total USD', 115, alignEnd: true),
];

double get kPreviewColumnsWidth =>
    kPreviewColumns.fold<double>(0, (sum, column) => sum + column.width);

/// Holgura para el overhead del ListTile que ExpansionTile usa por dentro: sin
/// esto el Row del title recibe menos ancho que la suma de columnas y desborda.
const double _kTileOverhead = 48;

double get kPreviewTableWidth => kPreviewColumnsWidth + _kTileOverhead;

/// Debajo de este ancho la grilla no entra ni con scroll comodo, asi que cada
/// liquidacion pasa a ser una tarjeta apilada y el scroll lateral desaparece.
const double kPreviewCardsBreakpoint = 900;

/// En web el arrastre con mouse esta deshabilitado por defecto, asi que una
/// tabla mas ancha que la pantalla solo se podia mover con shift+rueda. Esto
/// habilita el arrastre y hace usable la barra.
class _DragScrollBehavior extends MaterialScrollBehavior {
  const _DragScrollBehavior();

  @override
  Set<PointerDeviceKind> get dragDevices => <PointerDeviceKind>{
        PointerDeviceKind.touch,
        PointerDeviceKind.mouse,
        PointerDeviceKind.trackpad,
        PointerDeviceKind.stylus,
      };
}

/// Resumen de pago con el desglose de cada liquidacion a un clic.
///
/// En pantallas anchas es una grilla donde el header y cada fila recorren la
/// misma lista de anchos, asi que la alineacion se preserva por construccion
/// (DataTable no admite filas expandibles). En pantallas chicas son tarjetas.
class ResumenPagoPreviewTable extends StatefulWidget {
  const ResumenPagoPreviewTable({
    super.key,
    required this.items,
    required this.selectedIds,
    required this.expandedIds,
    required this.itemsCache,
    required this.allSelected,
    required this.someSelected,
    required this.onToggleSelected,
    required this.onToggleSelectAll,
    required this.onToggleExpanded,
    required this.onRetryItems,
  });

  final List<ResumenPagoPreviewItem> items;
  final Set<String> selectedIds;
  final Set<String> expandedIds;
  final Map<String, LiquidacionItemsEntry> itemsCache;
  final bool allSelected;
  final bool someSelected;
  final void Function(String liquidacionId, bool selected) onToggleSelected;
  final void Function(bool selected) onToggleSelectAll;
  final void Function(String liquidacionId, bool expanded) onToggleExpanded;
  final void Function(String liquidacionId) onRetryItems;

  @override
  State<ResumenPagoPreviewTable> createState() =>
      _ResumenPagoPreviewTableState();
}

class _ResumenPagoPreviewTableState extends State<ResumenPagoPreviewTable> {
  // Explicito: sin controller el Scrollbar se engancha al scroll vertical de
  // la lista y la barra horizontal nunca aparece.
  final ScrollController _horizontal = ScrollController();

  static const double _scale = 0.8;
  static const Color _headerColor = Color(0xFF9FB9D5);
  static const Color _textColor = Color(0xFFBFD3E8);
  static const Color _mutedColor = Color(0xFF7D9ABA);

  @override
  void dispose() {
    _horizontal.dispose();
    super.dispose();
  }

  String _clienteLabel(ResumenPagoPreviewItem row) {
    final cliente = (row.clienteNombre ?? '').trim();
    return cliente.isEmpty ? 'Sin dato' : cliente;
  }

  /// El nombre resuelto por la capa data manda; lo que traiga el endpoint de
  /// items queda como respaldo.
  String _tipoSalidaLabel(ResumenPagoPreviewItem row) {
    final desdeFila = (row.tipoSalidaNombre ?? '').trim();
    if (desdeFila.isNotEmpty) {
      return desdeFila;
    }
    return (widget.itemsCache[row.id]?.response?.tipoSalidaNombre ?? '').trim();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < kPreviewCardsBreakpoint) {
          return ListView.separated(
            padding: EdgeInsets.only(bottom: 4 * _scale),
            itemCount: widget.items.length,
            separatorBuilder: (_, index) => SizedBox(height: 8 * _scale),
            itemBuilder: (context, index) =>
                _buildCard(context, widget.items[index]),
          );
        }

        return ScrollConfiguration(
          behavior: const _DragScrollBehavior(),
          child: Scrollbar(
            controller: _horizontal,
            thumbVisibility: true,
            child: SingleChildScrollView(
              controller: _horizontal,
              scrollDirection: Axis.horizontal,
              child: SizedBox(
                width: kPreviewTableWidth,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    _buildHeader(context),
                    const Divider(color: Color(0x334EA6FF), height: 1),
                    Expanded(
                      child: ListView.builder(
                        // No debe robarle el controller primario al scroll
                        // horizontal que envuelve a la grilla.
                        primary: false,
                        itemCount: widget.items.length,
                        itemBuilder: (context, index) =>
                            _buildRow(context, widget.items[index]),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // --- Layout ancho: grilla -------------------------------------------------

  Widget _buildHeader(BuildContext context) {
    final style = Theme.of(context).textTheme.labelMedium?.copyWith(
          color: _headerColor,
          fontWeight: FontWeight.w700,
        );

    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8 * _scale),
      child: Row(
        children: <Widget>[
          _cell(0, const SizedBox.shrink()),
          _cell(1, _buildSelectAllCheckbox()),
          for (var index = 2; index < kPreviewColumns.length; index++)
            _cell(index, Text(kPreviewColumns[index].label, style: style)),
        ],
      ),
    );
  }

  Widget _buildRow(BuildContext context, ResumenPagoPreviewItem row) {
    final theme = Theme.of(context);
    final expanded = widget.expandedIds.contains(row.id);
    final tipoSalida = _tipoSalidaLabel(row);
    final cliente = (row.clienteNombre ?? '').trim();
    final cellStyle = theme.textTheme.bodySmall?.copyWith(color: _textColor);

    return Theme(
      data: theme.copyWith(dividerColor: Colors.transparent),
      child: ListTileTheme.merge(
        contentPadding: EdgeInsets.zero,
        horizontalTitleGap: 0,
        minVerticalPadding: 0,
        child: ExpansionTile(
          key: ValueKey<String>('preview-row-${row.id}'),
          initiallyExpanded: expanded,
          onExpansionChanged: (value) => widget.onToggleExpanded(row.id, value),
          tilePadding: EdgeInsets.zero,
          childrenPadding: EdgeInsets.fromLTRB(
            38 * _scale,
            0,
            10 * _scale,
            12 * _scale,
          ),
          // La flecha propia va en la primera celda para no romper el ancho.
          trailing: const SizedBox.shrink(),
          shape: const Border(),
          collapsedShape: const Border(),
          title: Row(
            children: <Widget>[
              _cell(0, _buildArrow(expanded)),
              _cell(1, _buildRowCheckbox(row)),
              _cell(
                2,
                Text(
                  _clienteLabel(row),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: cliente.isEmpty
                      ? cellStyle?.copyWith(color: _mutedColor)
                      : cellStyle?.copyWith(fontWeight: FontWeight.w600),
                ),
              ),
              _cell(
                3,
                Text(formatDateTimeAr(row.fechaAprobacion), style: cellStyle),
              ),
              _cell(
                4,
                Text(
                  tipoSalida.isEmpty ? '-' : tipoSalida,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: tipoSalida.isEmpty
                      ? cellStyle?.copyWith(color: _mutedColor)
                      : cellStyle,
                ),
              ),
              _cell(
                5,
                Text(
                  (row.subtotalSalidaUsd ?? 0).toStringAsFixed(2),
                  style: cellStyle,
                ),
              ),
              _cell(
                6,
                Text(
                  (row.subtotalItemsUsd ?? 0).toStringAsFixed(2),
                  style: cellStyle,
                ),
              ),
              _cell(
                7,
                Text(
                  row.totalLiquidacionUsd.toStringAsFixed(2),
                  style: cellStyle?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFFEAF4FF),
                  ),
                ),
              ),
            ],
          ),
          children: <Widget>[_buildBreakdown(row, tipoSalida)],
        ),
      ),
    );
  }

  Widget _cell(int index, Widget child) {
    final column = kPreviewColumns[index];
    return SizedBox(
      width: column.width,
      child: Align(
        alignment:
            column.alignEnd ? Alignment.centerRight : Alignment.centerLeft,
        child: child,
      ),
    );
  }

  // --- Layout chico: tarjetas ----------------------------------------------

  Widget _buildCard(BuildContext context, ResumenPagoPreviewItem row) {
    final theme = Theme.of(context);
    final expanded = widget.expandedIds.contains(row.id);
    final tipoSalida = _tipoSalidaLabel(row);
    final cliente = (row.clienteNombre ?? '').trim();

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: EdgeInsets.all(10 * _scale),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                _buildRowCheckbox(row),
                SizedBox(width: 4 * _scale),
                Expanded(
                  child: Text(
                    _clienteLabel(row),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: cliente.isEmpty
                          ? _mutedColor
                          : const Color(0xFFEAF4FF),
                      fontWeight:
                          cliente.isEmpty ? FontWeight.w400 : FontWeight.w700,
                    ),
                  ),
                ),
                SizedBox(width: 6 * _scale),
                Text(
                  '${row.totalLiquidacionUsd.toStringAsFixed(2)} USD',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: const Color(0xFFEAF4FF),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            SizedBox(height: 6 * _scale),
            Wrap(
              spacing: 6 * _scale,
              runSpacing: 6 * _scale,
              children: <Widget>[
                ModuleStatusChip(
                  label:
                      'Salida ${tipoSalida.isEmpty ? 'sin dato' : tipoSalida}',
                ),
                ModuleStatusChip(
                  label: 'Aprobada ${formatDateTimeAr(row.fechaAprobacion)}',
                ),
                ModuleStatusChip(
                  label:
                      'Salida USD ${(row.subtotalSalidaUsd ?? 0).toStringAsFixed(2)}',
                ),
                ModuleStatusChip(
                  label:
                      'Items USD ${(row.subtotalItemsUsd ?? 0).toStringAsFixed(2)}',
                ),
              ],
            ),
            Theme(
              data: theme.copyWith(dividerColor: Colors.transparent),
              child: ListTileTheme.merge(
                contentPadding: EdgeInsets.zero,
                horizontalTitleGap: 0,
                minVerticalPadding: 0,
                child: ExpansionTile(
                  key: ValueKey<String>('preview-row-${row.id}'),
                  initiallyExpanded: expanded,
                  onExpansionChanged: (value) =>
                      widget.onToggleExpanded(row.id, value),
                  tilePadding: EdgeInsets.zero,
                  childrenPadding: EdgeInsets.only(bottom: 4 * _scale),
                  shape: const Border(),
                  collapsedShape: const Border(),
                  title: Text(
                    'Detalle de items',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: _headerColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  children: <Widget>[_buildBreakdown(row, tipoSalida)],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- Compartido -----------------------------------------------------------

  Widget _buildArrow(bool expanded) {
    return AnimatedRotation(
      turns: expanded ? 0.5 : 0,
      duration: const Duration(milliseconds: 180),
      child: Icon(Icons.expand_more, size: 18 * _scale, color: _headerColor),
    );
  }

  Widget _buildSelectAllCheckbox() {
    return Checkbox(
      key: const ValueKey<String>('preview-check-all'),
      tristate: true,
      value: widget.allSelected ? true : (widget.someSelected ? null : false),
      onChanged: (value) => widget.onToggleSelectAll(value ?? false),
    );
  }

  Widget _buildRowCheckbox(ResumenPagoPreviewItem row) {
    return Checkbox(
      key: ValueKey<String>('preview-check-${row.id}'),
      value: widget.selectedIds.contains(row.id),
      onChanged: (value) => widget.onToggleSelected(row.id, value ?? false),
    );
  }

  Widget _buildBreakdown(ResumenPagoPreviewItem row, String tipoSalida) {
    return LiquidacionItemsBreakdown(
      entry: widget.itemsCache[row.id],
      tipoSalidaNombre: tipoSalida,
      subtotalSalidaUsd: row.subtotalSalidaUsd,
      expectedTotalUsd: row.totalLiquidacionUsd,
      onRetry: () => widget.onRetryItems(row.id),
      header: PreviewRowIdsLine(
        liquidacionId: row.id,
        servicioId: row.servicioId,
        fechaHoraServicio: row.fechaHoraServicio,
      ),
    );
  }
}

/// Linea de identificadores del panel expandido: los UUIDs que se sacaron de
/// la grilla siguen accesibles y se pueden copiar.
class PreviewRowIdsLine extends StatelessWidget {
  const PreviewRowIdsLine({
    super.key,
    required this.liquidacionId,
    required this.servicioId,
    this.fechaHoraServicio,
  });

  final String liquidacionId;
  final String servicioId;
  final String? fechaHoraServicio;

  static const double _scale = 0.8;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.bodySmall?.copyWith(
          color: const Color(0xFF7D9ABA),
        );
    final fecha = (fechaHoraServicio ?? '').trim();

    return Wrap(
      spacing: 12 * _scale,
      runSpacing: 4 * _scale,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: <Widget>[
        _IdChip(label: 'Liq', value: liquidacionId),
        _IdChip(label: 'Srv', value: servicioId),
        if (fecha.isNotEmpty)
          Text('Servicio ${formatDateTimeAr(fecha)}', style: style),
      ],
    );
  }
}

class _IdChip extends StatelessWidget {
  const _IdChip({required this.label, required this.value});

  final String label;
  final String value;

  static const double _scale = 0.8;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.bodySmall?.copyWith(
          color: const Color(0xFF7D9ABA),
        );

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Flexible(
          child: Text(
            '$label $value',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: style,
          ),
        ),
        SizedBox(width: 4 * _scale),
        InkWell(
          onTap: () async {
            await Clipboard.setData(ClipboardData(text: value));
            if (!context.mounted) {
              return;
            }
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('$label copiado')),
            );
          },
          child: Padding(
            padding: EdgeInsets.all(2 * _scale),
            child: Icon(
              Icons.copy_rounded,
              size: 13 * _scale,
              color: const Color(0xFF7D9ABA),
            ),
          ),
        ),
      ],
    );
  }
}

const Duration _argentinaUtcOffset = Duration(hours: -3);

String _twoDigits(int value) => value.toString().padLeft(2, '0');

/// Formato AR compartido por la grilla y el panel expandido.
String formatDateTimeAr(String? raw) {
  final value = (raw ?? '').trim();
  if (value.isEmpty || value == '-') {
    return '-';
  }

  final parsed = DateTime.tryParse(value);
  if (parsed == null) {
    return value;
  }

  final hasTime = value.contains('T') || RegExp(r'\d{2}:\d{2}').hasMatch(value);
  final day = _twoDigits(parsed.day);
  final month = _twoDigits(parsed.month);
  final year = parsed.year.toString().padLeft(4, '0');

  if (!hasTime) {
    return '$day/$month/$year';
  }

  final argentina = parsed.toUtc().add(_argentinaUtcOffset);
  return '${_twoDigits(argentina.day)}/${_twoDigits(argentina.month)}/'
      '${argentina.year.toString().padLeft(4, '0')} '
      '${_twoDigits(argentina.hour)}:${_twoDigits(argentina.minute)}';
}
