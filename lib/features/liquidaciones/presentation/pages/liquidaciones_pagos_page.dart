import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:web_admin_tecnico/core/widgets/module_page_layout.dart';
import 'package:web_admin_tecnico/features/liquidaciones/data/liquidaciones_repository_impl.dart';
import 'package:web_admin_tecnico/features/liquidaciones/domain/liquidaciones_repository.dart';
import 'package:web_admin_tecnico/features/liquidaciones/presentation/bloc/liquidaciones_pagos_cubit.dart';

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
              ModuleStatusChip(label: 'Seleccionadas $selectedCount'),
              ModuleStatusChip(
                label: 'Total seleccionado USD ${state.totalSeleccionadoUsd.toStringAsFixed(2)}',
              ),
              if (state.ultimoResumen != null)
                ModuleStatusChip(
                  label:
                      'Ultimo: ${state.ultimoResumen!.desde} a ${state.ultimoResumen!.hasta}',
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
                        : previewItems.isEmpty
                            ? const _EmptyState(
                                text:
                                    'Sin liquidaciones elegibles para el tecnico y periodo seleccionado.',
                              )
                            : SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: SizedBox(
                                  width: 1080,
                                  child: SingleChildScrollView(
                                    child: DataTable(
                                      columns: const <DataColumn>[
                                        DataColumn(label: Text('Sel')),
                                        DataColumn(label: Text('Liq')),
                                        DataColumn(label: Text('Srv')),
                                        DataColumn(label: Text('Fec')),
                                        DataColumn(label: Text('Sal')),
                                        DataColumn(label: Text('Ite')),
                                        DataColumn(label: Text('Tot')),
                                      ],
                                      rows: previewItems
                                          .map(
                                            (row) => DataRow(
                                              cells: <DataCell>[
                                                DataCell(
                                                  Checkbox(
                                                    value: state.selectedLiquidacionIds
                                                        .contains(row.id),
                                                    onChanged: (selected) {
                                                      context
                                                          .read<LiquidacionesPagosCubit>()
                                                          .toggleSelected(
                                                            row.id,
                                                            selected ?? false,
                                                          );
                                                    },
                                                  ),
                                                ),
                                                DataCell(Text(row.id)),
                                                DataCell(Text(row.servicioId)),
                                                DataCell(Text(row.fechaAprobacion ?? '-')),
                                                DataCell(Text((row.subtotalSalidaUsd ?? 0).toStringAsFixed(2))),
                                                DataCell(Text((row.subtotalItemsUsd ?? 0).toStringAsFixed(2))),
                                                DataCell(Text(row.totalLiquidacionUsd.toStringAsFixed(2))),
                                              ],
                                            ),
                                          )
                                          .toList(),
                                    ),
                                  ),
                                ),
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
                                                            '${row.desde} a ${row.hasta}',
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
                                                            row.createdAt,
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
  final Map<String, LiquidacionItemsResponse?> _itemsByLiquidacion =
      <String, LiquidacionItemsResponse?>{};
  final Set<String> _loadingLiquidaciones = <String>{};
  final Map<String, String> _errorByLiquidacion = <String, String>{};

  Future<void> _loadItems(String liquidacionId) async {
    if (_loadingLiquidaciones.contains(liquidacionId)) {
      return;
    }
    setState(() {
      _loadingLiquidaciones.add(liquidacionId);
      _errorByLiquidacion.remove(liquidacionId);
    });

    try {
      final response = await widget.repository.fetchLiquidacionItems(liquidacionId);
      if (!mounted) {
        return;
      }
      setState(() {
        _itemsByLiquidacion[liquidacionId] = response;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _errorByLiquidacion[liquidacionId] = error.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _loadingLiquidaciones.remove(liquidacionId);
        });
      }
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
                  ModuleStatusChip(label: 'Periodo ${detail.desde} a ${detail.hasta}'),
                  ModuleStatusChip(label: 'Total USD ${detail.totalUsdSnapshot.toStringAsFixed(2)}'),
                  ModuleStatusChip(label: 'Liquidaciones ${detail.totalLiquidaciones}'),
                  ModuleStatusChip(label: 'Creado ${detail.createdAt}'),
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
                    final loading = _loadingLiquidaciones.contains(row.liquidacionId);
                    final error = _errorByLiquidacion[row.liquidacionId];
                    final itemsResponse = _itemsByLiquidacion[row.liquidacionId];

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
                                ModuleStatusChip(label: 'Liq ${row.liquidacionId}'),
                                ModuleStatusChip(label: 'Srv ${row.servicioId}'),
                                ModuleStatusChip(label: 'Fec ${row.fechaAprobacionSnapshot ?? '-'}'),
                                ModuleStatusChip(
                                  label:
                                      'Salida ${((row.subtotalSalidaUsdSnapshot ?? 0).toStringAsFixed(2))} USD',
                                ),
                                ModuleStatusChip(
                                  label:
                                      'Items ${((row.subtotalItemsUsdSnapshot ?? 0).toStringAsFixed(2))} USD',
                                ),
                                ModuleStatusChip(
                                  label: 'Total ${row.totalLiquidacionUsdSnapshot.toStringAsFixed(2)} USD',
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Align(
                              alignment: Alignment.centerLeft,
                              child: FilledButton.tonalIcon(
                                onPressed: loading
                                    ? null
                                    : () => _loadItems(row.liquidacionId),
                                icon: loading
                                    ? const SizedBox(
                                        width: 14,
                                        height: 14,
                                        child: CircularProgressIndicator(strokeWidth: 2),
                                      )
                                    : const Icon(Icons.list_alt_outlined, size: 18),
                                label: const Text('Ver detalle de items de liquidacion'),
                              ),
                            ),
                            if (error != null && error.trim().isNotEmpty) ...<Widget>[
                              const SizedBox(height: 8),
                              Text(
                                error,
                                style: const TextStyle(color: Colors.redAccent),
                              ),
                            ],
                            if (itemsResponse != null) ...<Widget>[
                              const SizedBox(height: 8),
                              Text(
                                'Items: ${itemsResponse.meta.totalItems} | Subtotal USD ${itemsResponse.meta.subtotalUsdTotal.toStringAsFixed(2)}',
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                              const SizedBox(height: 6),
                              if (itemsResponse.items.isEmpty)
                                const Text('Sin items registrados para esta liquidacion.')
                              else
                                SingleChildScrollView(
                                  scrollDirection: Axis.horizontal,
                                  child: DataTable(
                                    columns: const <DataColumn>[
                                      DataColumn(label: Text('Tipo servicio')),
                                      DataColumn(label: Text('Precio USD')),
                                      DataColumn(label: Text('Aprobado')),
                                      DataColumn(label: Text('Fecha aprobacion')),
                                    ],
                                    rows: itemsResponse.items
                                        .map(
                                          (item) => DataRow(
                                            cells: <DataCell>[
                                              DataCell(Text(item.tipoServicioNombre)),
                                              DataCell(Text(item.precioUsdSnapshot.toStringAsFixed(2))),
                                              DataCell(Text(item.aprobado ? 'Si' : 'No')),
                                              DataCell(Text(item.fechaAprobacion ?? '-')),
                                            ],
                                          ),
                                        )
                                        .toList(),
                                  ),
                                ),
                            ],
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
