import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:web_admin_tecnico/core/widgets/module_page_layout.dart';
import 'package:web_admin_tecnico/features/liquidaciones/data/liquidaciones_repository_impl.dart';
import 'package:web_admin_tecnico/features/liquidaciones/domain/liquidaciones_repository.dart';
import 'package:web_admin_tecnico/features/liquidaciones/presentation/bloc/liquidacion_items_cache.dart';
import 'package:web_admin_tecnico/features/liquidaciones/presentation/bloc/liquidaciones_pagos_cubit.dart';
import 'package:web_admin_tecnico/features/liquidaciones/presentation/widgets/liquidacion_estado_badge.dart';
import 'package:web_admin_tecnico/features/liquidaciones/presentation/widgets/liquidacion_items_breakdown.dart';
import 'package:web_admin_tecnico/features/liquidaciones/presentation/widgets/resumen_pago_preview_table.dart';

const Duration _argentinaUtcOffset = Duration(hours: -3);

String _twoDigits(int value) => value.toString().padLeft(2, '0');

String _formatDateOnlyAr(String? raw) {
  final value = (raw ?? '').trim();
  if (value.isEmpty || value == '-') {
    return '-';
  }

  final parsed = DateTime.tryParse(value);
  if (parsed == null) {
    return value;
  }

  final day = _twoDigits(parsed.day);
  final month = _twoDigits(parsed.month);
  final year = parsed.year.toString().padLeft(4, '0');
  return '$day/$month/$year';
}

String _formatDateTimeAr(String? raw) {
  final value = (raw ?? '').trim();
  if (value.isEmpty || value == '-') {
    return '-';
  }

  final parsed = DateTime.tryParse(value);
  if (parsed == null) {
    return value;
  }

  final hasTime = value.contains('T') || RegExp(r'\d{2}:\d{2}').hasMatch(value);
  if (!hasTime) {
    return _formatDateOnlyAr(value);
  }

  final argentina = parsed.toUtc().add(_argentinaUtcOffset);
  final day = _twoDigits(argentina.day);
  final month = _twoDigits(argentina.month);
  final year = argentina.year.toString().padLeft(4, '0');
  final hour = _twoDigits(argentina.hour);
  final minute = _twoDigits(argentina.minute);
  return '$day/$month/$year $hour:$minute';
}

class LiquidacionesPagosPage extends StatelessWidget {
  const LiquidacionesPagosPage({
    super.key,
    this.repository,
  });

  final LiquidacionesRepository? repository;

  @override
  Widget build(BuildContext context) {
    final resolvedRepository = repository ?? LiquidacionesRepositoryImpl();
    return BlocProvider<LiquidacionesPagosCubit>(
      create: (_) => LiquidacionesPagosCubit(resolvedRepository)
        ..loadTecnicos()
        ..loadHistory(),
      child: _LiquidacionesPagosView(repository: resolvedRepository),
    );
  }
}

class _LiquidacionesPagosView extends StatefulWidget {
  const _LiquidacionesPagosView({required this.repository});

  final LiquidacionesRepository repository;

  @override
  State<_LiquidacionesPagosView> createState() => _LiquidacionesPagosViewState();
}

class _LiquidacionesPagosViewState extends State<_LiquidacionesPagosView>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;
  final TextEditingController _tecnicoController = TextEditingController();
  final TextEditingController _desdeController = TextEditingController();
  final TextEditingController _hastaController = TextEditingController();
  String? _selectedTecnicoId;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    _tecnicoController.dispose();
    _desdeController.dispose();
    _hastaController.dispose();
    super.dispose();
  }

  void _syncFiltersToState(BuildContext context) {
    final cubit = context.read<LiquidacionesPagosCubit>();
    final tecnicoId = (_selectedTecnicoId ?? _tecnicoController.text).trim();
    cubit.updateFilters(
      tecnicoId: tecnicoId,
      desde: _desdeController.text,
      hasta: _hastaController.text,
    );
  }

  DateTime? _parseIsoDate(String raw) {
    final value = raw.trim();
    if (value.isEmpty) {
      return null;
    }
    return DateTime.tryParse(value);
  }

  String _formatIsoDate(DateTime date) {
    final y = date.year.toString().padLeft(4, '0');
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  Future<void> _pickDate({
    required TextEditingController controller,
  }) async {
    final now = DateTime.now();
    final initial = _parseIsoDate(controller.text) ?? now;
    final selected = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2020),
      lastDate: DateTime(now.year + 2, 12, 31),
      helpText: 'Seleccionar fecha',
      cancelText: 'Cancelar',
      confirmText: 'Aceptar',
    );

    if (!mounted || selected == null) {
      return;
    }

    controller.text = _formatIsoDate(selected);
    _syncFiltersToState(context);
  }

  Widget _buildDateField({
    required TextEditingController controller,
    required String label,
  }) {
    return SizedBox(
      width: 190,
      child: TextField(
        controller: controller,
        readOnly: true,
        decoration: InputDecoration(
          labelText: label,
          suffixIcon: IconButton(
            tooltip: 'Seleccionar fecha',
            onPressed: () => _pickDate(controller: controller),
            icon: const Icon(Icons.calendar_today_outlined, size: 18),
          ),
        ),
        onTap: () => _pickDate(controller: controller),
      ),
    );
  }

  Future<void> _onPreview(BuildContext context) async {
    _syncFiltersToState(context);
    final cubit = context.read<LiquidacionesPagosCubit>();
    await cubit.loadUltimoResumen((_selectedTecnicoId ?? _tecnicoController.text).trim());
    await cubit.previewResumen();
  }

  Future<void> _onConfirm() async {
    final cubit = context.read<LiquidacionesPagosCubit>();
    final resumenId = await cubit.confirmarResumen();
    if (!mounted) {
      return;
    }

    if (resumenId != null && resumenId.trim().isNotEmpty) {
      await cubit.loadHistoryDetail(resumenId);
      if (!mounted) {
        return;
      }
      _openDetailScreen(context);
      return;
    }

    _tabs.animateTo(1);
    await cubit.loadHistory(page: 1, limit: 20);
  }

  Future<void> _onHistorySearch(BuildContext context) async {
    _syncFiltersToState(context);
    await context.read<LiquidacionesPagosCubit>().loadHistory(page: 1, limit: 20);
  }

  Widget _buildTecnicoField(
    BuildContext context,
    LiquidacionesPagosState state,
  ) {
    final options = state.tecnicoOptions;
    if (options.isEmpty) {
      return SizedBox(
        width: 220,
        child: TextField(
          controller: _tecnicoController,
          decoration: const InputDecoration(
            labelText: 'Tecnico ID (obligatorio)',
          ),
        ),
      );
    }

    final selectedStillValid = options.any((option) => option.id == _selectedTecnicoId);
    if (!selectedStillValid) {
      _selectedTecnicoId = null;
    }

    return SizedBox(
      width: 320,
      child: DropdownButtonFormField<String>(
        initialValue: _selectedTecnicoId,
        decoration: const InputDecoration(
          labelText: 'Tecnico',
          hintText: 'Seleccionar tecnico',
        ),
        items: options
            .map(
              (option) => DropdownMenuItem<String>(
                value: option.id,
                child: Text(option.label),
              ),
            )
            .toList(),
        onChanged: (value) {
          setState(() {
            _selectedTecnicoId = value;
            if ((value ?? '').trim().isNotEmpty) {
              _tecnicoController.text = value!.trim();
            }
          });
          _syncFiltersToState(context);
        },
      ),
    );
  }

  void _openDetailScreen(BuildContext context) {
    final state = context.read<LiquidacionesPagosCubit>().state;
    final detail = state.historyDetail;
    if (detail == null) {
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => _ResumenPagoDetallePage(
          detail: detail,
          repository: widget.repository,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<LiquidacionesPagosCubit, LiquidacionesPagosState>(
      listener: (context, state) {
        if (state.message != null && state.message!.trim().isNotEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message!)),
          );
        }
        if (state.error != null && state.error!.trim().isNotEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.error!)),
          );
        }
      },
      builder: (context, state) {
        final selectedCount = state.selectedLiquidacionIds.length;
        final previewItems = state.preview?.items ?? const <ResumenPagoPreviewItem>[];
        final history = state.history;
        final historyTotal = history?.total ?? 0;
        final historyPage = history?.page ?? state.historyPage;
        final historyLimit = history?.limit ?? state.historyLimit;
        final historyFirstRow = (historyPage - 1) * historyLimit;
        final historyHasPrevious = historyPage > 1;
        final historyHasNext = historyFirstRow + (history?.items.length ?? 0) < historyTotal;

        return ModulePageLayout(
          title: 'Liquidaciones para pago',
          subtitle: 'Previsualizacion, confirmacion e historial de resumenes por tecnico.',
          trailing: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: <Widget>[
              if (state.preview != null)
                ModuleStatusChip(
                  label: 'Elegibles ${state.preview!.meta.totalLiquidaciones}',
                ),
              if (state.reabiertas.isNotEmpty)
                ModuleStatusChip(
                  label: 'Reabiertas ${state.reabiertas.length}',
                  backgroundColor: LiquidacionEstadoColores.reabiertaFondo,
                  foregroundColor: LiquidacionEstadoColores.reabiertaTexto,
                ),
              ModuleStatusChip(label: 'Seleccionadas $selectedCount'),
              ModuleStatusChip(
                label: 'Total seleccionado USD ${state.totalSeleccionadoUsd.toStringAsFixed(2)}',
              ),
              if (state.ultimoResumen != null)
                ModuleStatusChip(
                  label: 'Ultimo: ${_formatDateOnlyAr(state.ultimoResumen!.desde)} a ${_formatDateOnlyAr(state.ultimoResumen!.hasta)}',
                ),
            ],
          ),
          child: Column(
            children: <Widget>[
              Wrap(
                spacing: 10,
                runSpacing: 10,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: <Widget>[
                  _buildTecnicoField(context, state),
                  FilledButton.tonalIcon(
                    onPressed: state.loadingTecnicos
                        ? null
                        : () => context.read<LiquidacionesPagosCubit>().loadTecnicos(),
                    icon: const Icon(Icons.refresh, size: 18),
                    label: const Text('Recargar tecnicos'),
                  ),
                  _buildDateField(
                    controller: _desdeController,
                    label: 'Desde',
                  ),
                  _buildDateField(
                    controller: _hastaController,
                    label: 'Hasta',
                  ),
                  FilledButton.icon(
                    onPressed: state.loadingPreview ? null : () => _onPreview(context),
                    icon: const Icon(Icons.preview_outlined, size: 18),
                    label: const Text('Previsualizar resumen'),
                  ),
                  FilledButton.icon(
                    onPressed: state.confirming || selectedCount == 0
                        ? null
                        : _onConfirm,
                    icon: const Icon(Icons.done_all_outlined, size: 18),
                    label: const Text('Confirmar resumen de pago'),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TabBar(
                controller: _tabs,
                tabs: const <Tab>[
                  Tab(text: 'Para pago'),
                  Tab(text: 'Historial de resumenes'),
                ],
              ),
              const SizedBox(height: 12),
              Expanded(
                child: TabBarView(
                  controller: _tabs,
                  children: <Widget>[
                    state.loadingPreview
                        ? const Center(child: CircularProgressIndicator())
                        : Column(
                            children: <Widget>[
                              if (state.reabiertas.isNotEmpty) ...<Widget>[
                                _ReabiertasFueraDePagoAviso(
                                  items: state.reabiertas,
                                ),
                                const SizedBox(height: 10),
                              ],
                              Expanded(
                                child: previewItems.isEmpty
                                    ? _EmptyState(
                                        text: state.reabiertas.isEmpty
                                            ? 'Sin liquidaciones elegibles para el tecnico y periodo seleccionado.'
                                            : 'Sin liquidaciones elegibles en el periodo: las reabiertas listadas arriba no entran hasta volver a aprobarse.',
                                      )
                                    : ResumenPagoPreviewTable(
                                        items: previewItems,
                                        selectedIds: state.selectedLiquidacionIds,
                                        expandedIds: state.expandedLiquidacionIds,
                                        itemsCache: state.itemsByLiquidacion,
                                        allSelected: state.allPreviewSelected,
                                        someSelected: state.somePreviewSelected,
                                        onToggleSelected: (id, selected) => context
                                            .read<LiquidacionesPagosCubit>()
                                            .toggleSelected(id, selected),
                                        onToggleSelectAll: (selected) => context
                                            .read<LiquidacionesPagosCubit>()
                                            .toggleSelectAll(selected),
                                        onToggleExpanded: (id, expanded) => context
                                            .read<LiquidacionesPagosCubit>()
                                            .toggleExpanded(id, expanded),
                                        onRetryItems: (id) => context
                                            .read<LiquidacionesPagosCubit>()
                                            .ensureLiquidacionItems(id, force: true),
                                      ),
                              ),
                              if (previewItems.isNotEmpty)
                                _PreviewTotalsBar(
                                  seleccionadas: selectedCount,
                                  elegibles: state.preview?.meta.totalLiquidaciones ??
                                      previewItems.length,
                                  totalSeleccionadoUsd: state.totalSeleccionadoUsd,
                                  totalResumenUsd:
                                      state.preview?.meta.totalResumenUsd ?? 0,
                                ),
                            ],
                          ),
                    Column(
                      children: <Widget>[
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: <Widget>[
                            FilledButton.tonalIcon(
                              onPressed: state.loadingHistory
                                  ? null
                                  : () => _onHistorySearch(context),
                              icon: const Icon(Icons.search, size: 18),
                              label: const Text('Buscar historial'),
                            ),
                            FilledButton.tonalIcon(
                              onPressed: state.loadingHistory || !historyHasPrevious
                                  ? null
                                  : () {
                                      context.read<LiquidacionesPagosCubit>().loadHistory(
                                            page: historyPage - 1,
                                            limit: historyLimit,
                                          );
                                    },
                              icon: const Icon(Icons.chevron_left, size: 18),
                              label: const Text('Anterior'),
                            ),
                            FilledButton.tonalIcon(
                              onPressed: state.loadingHistory || !historyHasNext
                                  ? null
                                  : () {
                                      context.read<LiquidacionesPagosCubit>().loadHistory(
                                            page: historyPage + 1,
                                            limit: historyLimit,
                                          );
                                    },
                              icon: const Icon(Icons.chevron_right, size: 18),
                              label: const Text('Siguiente'),
                            ),
                            ModuleStatusChip(
                              label: 'Pagina $historyPage',
                            ),
                            ModuleStatusChip(
                              label: 'Total resumenes $historyTotal',
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Expanded(
                          child: state.loadingHistory
                              ? const Center(child: CircularProgressIndicator())
                              : (state.history?.items.isEmpty ?? true)
                                  ? const _EmptyState(
                                      text: 'No hay resumenes en historial para los filtros aplicados.',
                                    )
                                  : SingleChildScrollView(
                                      scrollDirection: Axis.horizontal,
                                      child: SizedBox(
                                        width: 1100,
                                        child: SingleChildScrollView(
                                          child: DataTable(
                                            columns: const <DataColumn>[
                                              DataColumn(label: Text('Tecnico')),
                                              DataColumn(label: Text('Periodo')),
                                              DataColumn(label: Text('Tot. liq.')),
                                              DataColumn(label: Text('Total USD')),
                                              DataColumn(label: Text('F. creacion')),
                                              DataColumn(
                                                label: Tooltip(
                                                  message: 'Accion',
                                                  child: Icon(Icons.visibility_outlined, size: 14),
                                                ),
                                              ),
                                            ],
                                            rows: (state.history?.items ?? const <ResumenPagoHistorialItem>[])
                                                .map(
                                                  (row) => DataRow(
                                                    cells: <DataCell>[
                                                      DataCell(
                                                        SizedBox(
                                                          width: 170,
                                                          child: Text(
                                                            row.tecnicoNombre,
                                                            maxLines: 1,
                                                            overflow: TextOverflow.ellipsis,
                                                          ),
                                                        ),
                                                      ),
                                                      DataCell(
                                                        SizedBox(
                                                          width: 180,
                                                          child: Text(
                                                            '${_formatDateOnlyAr(row.desde)} a ${_formatDateOnlyAr(row.hasta)}',
                                                            maxLines: 1,
                                                            overflow: TextOverflow.ellipsis,
                                                          ),
                                                        ),
                                                      ),
                                                      DataCell(Text(row.totalLiquidaciones.toString())),
                                                      DataCell(Text(row.totalUsdSnapshot.toStringAsFixed(2))),
                                                      DataCell(
                                                        SizedBox(
                                                          width: 150,
                                                          child: Text(
                                                            _formatDateTimeAr(row.createdAt),
                                                            maxLines: 1,
                                                            overflow: TextOverflow.ellipsis,
                                                          ),
                                                        ),
                                                      ),
                                                      DataCell(
                                                        IconButton(
                                                          tooltip: 'Ver detalle',
                                                          iconSize: 16,
                                                          visualDensity: VisualDensity.compact,
                                                          padding: EdgeInsets.zero,
                                                          constraints: const BoxConstraints(
                                                            minWidth: 24,
                                                            minHeight: 24,
                                                          ),
                                                          onPressed: () async {
                                                            await context
                                                                .read<LiquidacionesPagosCubit>()
                                                                .loadHistoryDetail(row.id);
                                                            if (!context.mounted) {
                                                              return;
                                                            }
                                                            _openDetailScreen(context);
                                                          },
                                                          icon: const Icon(Icons.visibility_outlined),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                )
                                                .toList(),
                                          ),
                                        ),
                                      ),
                                    ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0x1F122B4A),
        border: Border.all(color: const Color(0x334EA6FF)),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(text),
    );
  }
}

/// Aviso de las liquidaciones que quedaron fuera del resumen por estar
/// reabiertas.
///
/// Sin esto el admin solo ve que la fila desaparecio: el backend las excluye de
/// `para-pago`, del preview y de `marcar-pagadas` mientras `estado=reabierta`.
class _ReabiertasFueraDePagoAviso extends StatelessWidget {
  const _ReabiertasFueraDePagoAviso({required this.items});

  final List<LiquidacionItem> items;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const ValueKey<String>('aviso-reabiertas-fuera-de-pago'),
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: LiquidacionEstadoColores.reabiertaFondo,
        border: Border.all(color: LiquidacionEstadoColores.reabiertaBorde),
        borderRadius: BorderRadius.circular(10),
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
                  '${items.length} liquidacion(es) reabiertas fuera del circuito de pago',
                  style: const TextStyle(
                    color: LiquidacionEstadoColores.reabiertaTexto,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            'No entran en este resumen ni se pueden marcar como pagadas hasta '
            'volver a aprobarlas desde Liquidaciones. Se listan sin filtrar por '
            'periodo porque al reabrirse pierden la fecha de aprobacion.',
            style: TextStyle(color: Color(0xFFEAF3FF)),
          ),
          const SizedBox(height: 8),
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 132),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: items
                    .map(
                      (item) => Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Text(
                          _describeReabierta(item),
                          style: const TextStyle(color: Color(0xFF9AB1CC)),
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _describeReabierta(LiquidacionItem item) {
    final cliente = (item.clienteNombre ?? '').trim();
    final salida = (item.tipoSalidaNombre ?? '').trim();
    final motivo = (item.motivoReapertura ?? '').trim();
    final fecha = _formatDateTimeAr(item.fechaReapertura);

    final encabezado = <String>[
      if (cliente.isNotEmpty) cliente,
      if (salida.isNotEmpty) salida,
      if (fecha != '-') fecha,
    ].join(' - ');

    final prefijo = encabezado.isEmpty ? 'Liquidacion reabierta' : encabezado;
    return motivo.isEmpty ? '$prefijo: sin motivo registrado' : '$prefijo: $motivo';
  }
}

/// Totales al pie de la grilla: el trailing del layout queda lejos del listado
/// en pantallas anchas, y este es el numero contra el que se aprueba.
class _PreviewTotalsBar extends StatelessWidget {
  const _PreviewTotalsBar({
    required this.seleccionadas,
    required this.elegibles,
    required this.totalSeleccionadoUsd,
    required this.totalResumenUsd,
  });

  final int seleccionadas;
  final int elegibles;
  final double totalSeleccionadoUsd;
  final double totalResumenUsd;

  static const double _scale = 0.8;

  @override
  Widget build(BuildContext context) {
    final haySeleccion = seleccionadas > 0;

    return Container(
      width: double.infinity,
      margin: EdgeInsets.only(top: 10 * _scale),
      padding: EdgeInsets.symmetric(
        horizontal: 12 * _scale,
        vertical: 10 * _scale,
      ),
      decoration: BoxDecoration(
        color: const Color(0x1F122B4A),
        border: Border.all(color: const Color(0x334EA6FF)),
        borderRadius: BorderRadius.circular(10 * _scale),
      ),
      child: Wrap(
        spacing: 8 * _scale,
        runSpacing: 8 * _scale,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: <Widget>[
          ModuleStatusChip(label: 'Seleccionadas $seleccionadas de $elegibles'),
          ModuleStatusChip(
            label: 'Total seleccionado USD ${totalSeleccionadoUsd.toStringAsFixed(2)}',
            backgroundColor: haySeleccion
                ? const Color(0x1F0FA960)
                : const Color(0x1F4EA6FF),
            foregroundColor: haySeleccion
                ? const Color(0xFF8FF0BC)
                : const Color(0xFFCDE4FF),
          ),
          ModuleStatusChip(
            label: 'Total resumen USD ${totalResumenUsd.toStringAsFixed(2)}',
          ),
        ],
      ),
    );
  }
}

class _ResumenPagoDetallePage extends StatefulWidget {
  const _ResumenPagoDetallePage({
    required this.detail,
    required this.repository,
  });

  final ResumenPagoDetalleResponse detail;
  final LiquidacionesRepository repository;

  @override
  State<_ResumenPagoDetallePage> createState() => _ResumenPagoDetallePageState();
}

class _ResumenPagoDetallePageState extends State<_ResumenPagoDetallePage> {
  final Map<String, LiquidacionItemsEntry> _itemsByLiquidacion =
      <String, LiquidacionItemsEntry>{};
  final Set<String> _expandedLiquidaciones = <String>{};

  /// Misma regla que el cubit: una respuesta null significa que el endpoint no
  /// esta disponible, no que la liquidacion no tenga items, asi que reintentar
  /// tiene sentido.
  Future<void> _loadItems(String liquidacionId, {bool force = false}) async {
    final current = _itemsByLiquidacion[liquidacionId];
    if (current != null && current.isLoading) {
      return;
    }
    if (!force && current != null && current.isLoaded) {
      return;
    }

    setState(() {
      _itemsByLiquidacion[liquidacionId] = const LiquidacionItemsEntry.loading();
    });

    try {
      final response =
          await widget.repository.fetchLiquidacionItems(liquidacionId);
      if (!mounted) {
        return;
      }
      setState(() {
        _itemsByLiquidacion[liquidacionId] = response == null
            ? const LiquidacionItemsEntry.unavailable()
            : LiquidacionItemsEntry.loaded(response);
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _itemsByLiquidacion[liquidacionId] =
            LiquidacionItemsEntry.failed(error.toString());
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final detail = widget.detail;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalle de resumen de pago'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: <Widget>[
                  ModuleStatusChip(label: 'Tecnico ${detail.tecnicoNombre}'),
                  ModuleStatusChip(
                    label:
                        'Periodo ${_formatDateOnlyAr(detail.desde)} a ${_formatDateOnlyAr(detail.hasta)}',
                  ),
                  ModuleStatusChip(
                    label:
                        'Total USD ${detail.totalUsdSnapshot.toStringAsFixed(2)}',
                  ),
                  ModuleStatusChip(
                    label: 'Liquidaciones ${detail.totalLiquidaciones}',
                  ),
                  ModuleStatusChip(
                    label: 'Creado ${_formatDateTimeAr(detail.createdAt)}',
                  ),
                  ModuleStatusChip(label: 'Por ${detail.createdByNombre}'),
                ],
              ),
              const SizedBox(height: 12),
              Expanded(
                child: ListView.separated(
                  itemCount: detail.detalles.length,
                  separatorBuilder: (_, index) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final row = detail.detalles[index];
                    final entry = _itemsByLiquidacion[row.liquidacionId];
                    final cliente = (row.clienteNombre ?? '').trim();
                    final clienteLabel = cliente.isEmpty ? 'Sin dato' : cliente;
                    final salida = (row.tipoSalidaNombre ?? '').trim();
                    final salidaLabel = salida.isEmpty ? 'Sin dato' : salida;

                    return Card(
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: <Widget>[
                                ModuleStatusChip(
                                  label: 'Cliente $clienteLabel',
                                ),
                                ModuleStatusChip(
                                  label: 'Salida $salidaLabel',
                                ),
                                ModuleStatusChip(
                                  label:
                                      'Fec ${_formatDateTimeAr(row.fechaAprobacionSnapshot)}',
                                ),
                                ModuleStatusChip(
                                  label:
                                      'Salida ${(row.subtotalSalidaUsdSnapshot ?? 0).toStringAsFixed(2)} USD',
                                ),
                                ModuleStatusChip(
                                  label:
                                      'Items ${(row.subtotalItemsUsdSnapshot ?? 0).toStringAsFixed(2)} USD',
                                ),
                                ModuleStatusChip(
                                  label:
                                      'Total ${row.totalLiquidacionUsdSnapshot.toStringAsFixed(2)} USD',
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Theme(
                              data: Theme.of(context).copyWith(
                                dividerColor: Colors.transparent,
                              ),
                              child: ExpansionTile(
                                tilePadding: EdgeInsets.zero,
                                childrenPadding:
                                    const EdgeInsets.only(bottom: 4),
                                initiallyExpanded: _expandedLiquidaciones
                                    .contains(row.liquidacionId),
                                onExpansionChanged: (expanded) async {
                                  setState(() {
                                    if (expanded) {
                                      _expandedLiquidaciones
                                          .add(row.liquidacionId);
                                    } else {
                                      _expandedLiquidaciones
                                          .remove(row.liquidacionId);
                                    }
                                  });

                                  if (expanded) {
                                    await _loadItems(row.liquidacionId);
                                  }
                                },
                                title: Row(
                                  children: <Widget>[
                                    const Icon(Icons.list_alt_outlined, size: 18),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Detalle de items de liquidacion',
                                      style:
                                          Theme.of(context).textTheme.bodyMedium,
                                    ),
                                  ],
                                ),
                                children: <Widget>[
                                  LiquidacionItemsBreakdown(
                                    entry: entry,
                                    tipoSalidaNombre: row.tipoSalidaNombre,
                                    subtotalSalidaUsd:
                                        row.subtotalSalidaUsdSnapshot,
                                    expectedTotalUsd:
                                        row.totalLiquidacionUsdSnapshot,
                                    onRetry: () => _loadItems(
                                      row.liquidacionId,
                                      force: true,
                                    ),
                                    header: PreviewRowIdsLine(
                                      liquidacionId: row.liquidacionId,
                                      servicioId: row.servicioId,
                                      fechaHoraServicio: row.fechaHoraServicio,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
