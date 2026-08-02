import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:web_admin_tecnico/core/utils/paginated_table_prefs.dart';
import 'package:web_admin_tecnico/core/widgets/module_page_layout.dart';
import 'package:web_admin_tecnico/features/servicios/domain/servicios_repository.dart';
import 'package:web_admin_tecnico/features/servicios/data/servicios_repository_impl.dart';
import 'package:web_admin_tecnico/features/servicios/presentation/bloc/servicios_bloc.dart';
import 'package:web_admin_tecnico/features/servicios/presentation/pages/servicio_detalle_page.dart';

class ServiciosPage extends StatelessWidget {
  const ServiciosPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<ServiciosBloc>(
      create: (_) => ServiciosBloc(ServiciosRepositoryImpl())..add(ServiciosRequested()),
      child: const _ServiciosView(),
    );
  }
}

class _ServiciosView extends StatefulWidget {
  const _ServiciosView();

  @override
  State<_ServiciosView> createState() => _ServiciosViewState();
}

class _ServiciosViewState extends State<_ServiciosView> {
  final TextEditingController _searchController = TextEditingController();
  String _estadoFilter = 'todos';
  String _canalFilter = 'todos';
  String _tecnicoFilterId = 'todos';

  List<_TecnicoFilterItem> _buildTecnicoFilterItems(List<ServicioTecnicoOption> tecnicos) {
    final byId = <String, _TecnicoFilterItem>{};
    for (final tecnico in tecnicos) {
      final id = tecnico.id.trim();
      if (id.isEmpty) {
        continue;
      }

      final label = _formatTecnicoFilterLabel(tecnico);
      byId[id] = _TecnicoFilterItem(id: id, label: label);
    }

    final items = byId.values.toList()
      ..sort((a, b) => a.label.toLowerCase().compareTo(b.label.toLowerCase()));

    if (_tecnicoFilterId != 'todos' && !byId.containsKey(_tecnicoFilterId)) {
      items.add(
        _TecnicoFilterItem(
          id: _tecnicoFilterId,
          label: 'ID $_tecnicoFilterId',
        ),
      );
    }

    return <_TecnicoFilterItem>[
      const _TecnicoFilterItem(id: 'todos', label: 'TODOS LOS TECNICOS'),
      ...items,
    ];
  }

  String _formatTecnicoFilterLabel(ServicioTecnicoOption tecnico) {
    final fullName = tecnico.fullName.trim();
    final email = tecnico.email.trim();

    if (fullName.isNotEmpty && email.isNotEmpty) {
      return '$fullName <$email>';
    }
    if (fullName.isNotEmpty) {
      return fullName;
    }
    if (email.isNotEmpty) {
      return email;
    }
    return 'ID ${tecnico.id}';
  }

  void _requestPage({int page = 1, int? limit}) {
    context.read<ServiciosBloc>().add(
          ServiciosRequested(
            search: _searchController.text.trim(),
            estado: _estadoFilter,
            canal: _canalFilter,
            tecnicoId: _tecnicoFilterId,
            page: page,
            limit: limit ?? 6,
          ),
        );
  }

  void _openDetalle(ServicioItem item) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ServicioDetallePage(servicioId: item.id),
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ServiciosBloc, ServiciosState>(
      builder: (context, state) {
        if (state is ServiciosLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (state is ServiciosFailure) {
          return Center(child: Text('Error: ${state.message}'));
        }

        if (state is ServiciosLoaded) {
          final estados = <String>{'todos', 'abierta', 'cerrada', 'firmada'};
          final canales = <String>{'todos', 'campo', 'remoto', 'fabrica'};
          final tecnicoFilterItems = _buildTecnicoFilterItems(state.tecnicos);
          final effectiveLimit = state.limit > 0 ? state.limit : 6;
          final currentLimit = effectiveLimit;
          final rowsPerPage = normalizeRowsPerPage(effectiveLimit);
          final rowsPerPageOptions = buildRowsPerPageOptions(effectiveLimit);
          final initialFirstRowIndex = (state.page - 1) * effectiveLimit;
          final hasFilters =
            state.search.trim().isNotEmpty ||
            state.estado != 'todos' ||
            state.canal != 'todos' ||
            state.tecnicoId != 'todos';
          final emptyMessage = hasFilters
            ? 'No hay servicios para los filtros seleccionados.'
            : 'No hay servicios disponibles para mostrar.';

          return ModulePageLayout(
            title: 'Servicios',
            subtitle: 'Ordenes tecnicas con estado operativo y trazabilidad.',
            trailing: ModuleStatusChip(label: '${state.total} total'),
            child: Column(
              children: <Widget>[
                TextField(
                  controller: _searchController,
                  onChanged: (_) => _requestPage(page: 1, limit: currentLimit),
                  style: const TextStyle(color: Color(0xFFEAF3FF)),
                  decoration: InputDecoration(
                    hintText: 'Buscar por ID o descripcion...',
                    prefixIcon: const Icon(Icons.search),
                    isDense: true,
                    filled: true,
                    fillColor: const Color(0xFF122B4A),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Color(0x334EA6FF)),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: <Widget>[
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        decoration: BoxDecoration(
                          color: const Color(0xFF122B4A),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0x334EA6FF)),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _estadoFilter,
                            onChanged: (value) {
                              if (value == null) {
                                return;
                              }
                              setState(() => _estadoFilter = value);
                              _requestPage(page: 1, limit: currentLimit);
                            },
                            items: estados
                                .map(
                                  (estado) => DropdownMenuItem<String>(
                                    value: estado,
                                    child: Text(estado.toUpperCase()),
                                  ),
                                )
                                .toList(),
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        decoration: BoxDecoration(
                          color: const Color(0xFF122B4A),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0x334EA6FF)),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _canalFilter,
                            onChanged: (value) {
                              if (value == null) {
                                return;
                              }
                              setState(() => _canalFilter = value);
                              _requestPage(page: 1, limit: currentLimit);
                            },
                            items: canales
                                .map(
                                  (canal) => DropdownMenuItem<String>(
                                    value: canal,
                                    child: Text(canal.toUpperCase()),
                                  ),
                                )
                                .toList(),
                          ),
                        ),
                      ),
                      SizedBox(
                        width: 320,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          decoration: BoxDecoration(
                            color: const Color(0xFF122B4A),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: const Color(0x334EA6FF)),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              isExpanded: true,
                              value: _tecnicoFilterId,
                              onChanged: (value) {
                                if (value == null || value == _tecnicoFilterId) {
                                  return;
                                }
                                setState(() => _tecnicoFilterId = value);
                                _requestPage(page: 1, limit: currentLimit);
                              },
                              selectedItemBuilder: (_) {
                                return tecnicoFilterItems
                                    .map(
                                      (item) => Align(
                                        alignment: Alignment.centerLeft,
                                        child: Text(
                                          item.label,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    )
                                    .toList();
                              },
                              items: tecnicoFilterItems
                                  .map(
                                    (tecnicoItem) => DropdownMenuItem<String>(
                                      value: tecnicoItem.id,
                                      child: Text(
                                        tecnicoItem.label,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  )
                                  .toList(),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, bodyConstraints) {
                      if (state.items.isEmpty) {
                        return Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0x1F122B4A),
                            border: Border.all(color: const Color(0x334EA6FF)),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(emptyMessage),
                        );
                      }

                      final useCompactLayout = bodyConstraints.maxWidth < 1080;

                      if (useCompactLayout) {
                        return _ServiciosCompactList(
                          items: state.items,
                          total: state.total,
                          page: state.page,
                          limit: effectiveLimit,
                          rowsPerPage: rowsPerPage,
                          rowsPerPageOptions: rowsPerPageOptions,
                          onRowsPerPageChanged: (value) {
                            _requestPage(page: 1, limit: value);
                          },
                          onPageChanged: (nextPage) {
                            if (nextPage != state.page) {
                              _requestPage(page: nextPage, limit: effectiveLimit);
                            }
                          },
                          onOpen: _openDetalle,
                        );
                      }

                      return Card(
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            const minTableWidth = 1100.0;
                            final availableWidth = constraints.maxWidth.isFinite
                                ? constraints.maxWidth
                                : minTableWidth;
                            final tableWidth = availableWidth < minTableWidth
                                ? minTableWidth
                                : availableWidth;

                            return SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: SizedBox(
                                width: tableWidth,
                                child: SingleChildScrollView(
                                  child: PaginatedDataTable(
                                    key: ValueKey<String>(
                                      'servicios_${state.page}_${state.limit}_${state.total}_${state.estado}_${state.canal}_${state.tecnicoId}',
                                    ),
                                    initialFirstRowIndex: initialFirstRowIndex < 0
                                        ? 0
                                        : initialFirstRowIndex,
                                    headingRowColor: WidgetStateProperty.all(const Color(0x1A4EA6FF)),
                                    columnSpacing: 24,
                                    horizontalMargin: 16,
                                    columns: const <DataColumn>[
                                      DataColumn(label: Text('Fecha')),
                                      DataColumn(label: Text('Numero indicador')),
                                      DataColumn(label: Text('Modelo indicador')),
                                      DataColumn(label: Text('Descripcion')),
                                      DataColumn(label: Text('Estado')),
                                      DataColumn(label: Text('Accion')),
                                    ],
                                    source: _ServiciosTableSource(
                                      items: state.items,
                                      total: state.total,
                                      page: state.page,
                                      limit: effectiveLimit,
                                      onOpen: _openDetalle,
                                    ),
                                    rowsPerPage: rowsPerPage,
                                    availableRowsPerPage: rowsPerPageOptions,
                                    showEmptyRows: false,
                                    onRowsPerPageChanged: (value) {
                                      if (value == null) {
                                        return;
                                      }
                                      _requestPage(page: 1, limit: value);
                                    },
                                    onPageChanged: (firstRowIndex) {
                                      final nextPage = (firstRowIndex ~/ effectiveLimit) + 1;
                                      if (nextPage != state.page) {
                                        _requestPage(page: nextPage, limit: effectiveLimit);
                                      }
                                    },
                                    showFirstLastButtons: true,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        }

        return const SizedBox.shrink();
      },
    );
  }
}

class _EstadoChip extends StatelessWidget {
  const _EstadoChip({required this.estado});

  final String estado;

  @override
  Widget build(BuildContext context) {
    Color bg = const Color(0x1F4EA6FF);
    Color fg = const Color(0xFFCDE4FF);
    final normalizado = estado.toLowerCase();

    if (normalizado.contains('cerrada')) {
      bg = const Color(0x1F0FA960);
      fg = const Color(0xFF8FF0BC);
    } else if (normalizado.contains('abierta')) {
      bg = const Color(0x1FF4B942);
      fg = const Color(0xFFFFD98B);
    } else if (normalizado.contains('firmada')) {
      bg = const Color(0x1F5A7CFF);
      fg = const Color(0xFFC3D4FF);
    }

    return ModuleStatusChip(label: estado.toUpperCase(), backgroundColor: bg, foregroundColor: fg);
  }
}

class _ServiciosCompactList extends StatelessWidget {
  const _ServiciosCompactList({
    required this.items,
    required this.total,
    required this.page,
    required this.limit,
    required this.rowsPerPage,
    required this.rowsPerPageOptions,
    required this.onRowsPerPageChanged,
    required this.onPageChanged,
    required this.onOpen,
  });

  final List<ServicioItem> items;
  final int total;
  final int page;
  final int limit;
  final int rowsPerPage;
  final List<int> rowsPerPageOptions;
  final ValueChanged<int> onRowsPerPageChanged;
  final ValueChanged<int> onPageChanged;
  final ValueChanged<ServicioItem> onOpen;

  @override
  Widget build(BuildContext context) {
    final totalPages = limit <= 0 ? 1 : math.max(1, (total / limit).ceil());
    final clampedPage = page.clamp(1, totalPages);
    final firstVisible = total == 0 ? 0 : ((clampedPage - 1) * limit) + 1;
    final lastVisible = total == 0
        ? 0
        : math.min(total, firstVisible + items.length - 1);
    final canGoPrev = clampedPage > 1;
    final canGoNext = clampedPage < totalPages;

    return Card(
      child: Column(
        children: <Widget>[
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.all(12),
              itemCount: items.length,
              separatorBuilder: (context, index) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final item = items[index];
                return _ServicioCompactCard(item: item, onOpen: onOpen);
              },
            ),
          ),
          const Divider(color: Color(0x334EA6FF), height: 1),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final compactFooter = constraints.maxWidth < 760;

                final rowsSelector = _RowsPerPageDropdown(
                  value: rowsPerPage,
                  options: rowsPerPageOptions,
                  onChanged: onRowsPerPageChanged,
                );

                final pagerActions = Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    IconButton(
                      tooltip: 'Primera pagina',
                      onPressed: canGoPrev ? () => onPageChanged(1) : null,
                      icon: const Icon(Icons.first_page),
                    ),
                    IconButton(
                      tooltip: 'Pagina anterior',
                      onPressed: canGoPrev ? () => onPageChanged(clampedPage - 1) : null,
                      icon: const Icon(Icons.chevron_left),
                    ),
                    IconButton(
                      tooltip: 'Pagina siguiente',
                      onPressed: canGoNext ? () => onPageChanged(clampedPage + 1) : null,
                      icon: const Icon(Icons.chevron_right),
                    ),
                    IconButton(
                      tooltip: 'Ultima pagina',
                      onPressed: canGoNext ? () => onPageChanged(totalPages) : null,
                      icon: const Icon(Icons.last_page),
                    ),
                  ],
                );

                if (compactFooter) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      const Text('Filas por pagina'),
                      const SizedBox(height: 6),
                      rowsSelector,
                      const SizedBox(height: 10),
                      Text('$firstVisible-$lastVisible de $total'),
                      const SizedBox(height: 4),
                      pagerActions,
                    ],
                  );
                }

                return Row(
                  children: <Widget>[
                    const Text('Filas por pagina:'),
                    const SizedBox(width: 8),
                    rowsSelector,
                    const Spacer(),
                    Text('$firstVisible-$lastVisible de $total'),
                    const SizedBox(width: 8),
                    pagerActions,
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _RowsPerPageDropdown extends StatelessWidget {
  const _RowsPerPageDropdown({
    required this.value,
    required this.options,
    required this.onChanged,
  });

  final int value;
  final List<int> options;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF122B4A),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0x334EA6FF)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<int>(
          value: value,
          onChanged: (nextValue) {
            if (nextValue == null || nextValue == value) {
              return;
            }
            onChanged(nextValue);
          },
          items: options
              .map(
                (option) => DropdownMenuItem<int>(
                  value: option,
                  child: Text('$option'),
                ),
              )
              .toList(),
        ),
      ),
    );
  }
}

class _TecnicoFilterItem {
  const _TecnicoFilterItem({
    required this.id,
    required this.label,
  });

  final String id;
  final String label;
}

class _ServicioCompactCard extends StatelessWidget {
  const _ServicioCompactCard({
    required this.item,
    required this.onOpen,
  });

  final ServicioItem item;
  final ValueChanged<ServicioItem> onOpen;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0x1F122B4A),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0x334EA6FF)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Expanded(
                child: Text(
                  _formatServicioFecha(item.fechaHoraServicio),
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: const Color(0xFFEAF3FF),
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ),
              const SizedBox(width: 8),
              _EstadoChip(estado: item.estadoOrden),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Numero indicador: ${item.equipoSerie ?? '-'}',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: const Color(0xFFCAE0F5),
                ),
          ),
          const SizedBox(height: 2),
          Text(
            'Modelo indicador: ${item.equipoModelo ?? '-'}',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: const Color(0xFFCAE0F5),
                ),
          ),
          const SizedBox(height: 8),
          Text(
            item.descripcion,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 6),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: () => onOpen(item),
              icon: const Icon(Icons.open_in_new, size: 16),
              label: const Text('Ver detalle'),
            ),
          ),
        ],
      ),
    );
  }
}

class _ServiciosTableSource extends DataTableSource {
  _ServiciosTableSource({
    required this.items,
    required this.total,
    required this.page,
    required this.limit,
    required this.onOpen,
  });

  final List<ServicioItem> items;
  final int total;
  final int page;
  final int limit;
  final ValueChanged<ServicioItem> onOpen;

  @override
  DataRow? getRow(int index) {
    final start = (page - 1) * limit;
    final localIndex = index - start;
    if (localIndex < 0 || localIndex >= items.length) {
      return null;
    }

    final item = items[localIndex];
    return DataRow.byIndex(
      index: index,
      cells: <DataCell>[
        DataCell(Text(_formatServicioFecha(item.fechaHoraServicio))),
        DataCell(Text(item.equipoSerie ?? '-')),
        DataCell(Text(item.equipoModelo ?? '-')),
        DataCell(Text(item.descripcion)),
        DataCell(_EstadoChip(estado: item.estadoOrden)),
        DataCell(
          IconButton(
            tooltip: 'Ver detalle',
            onPressed: () => onOpen(item),
            icon: const Icon(Icons.open_in_new, size: 18),
          ),
        ),
      ],
    );
  }

  @override
  bool get isRowCountApproximate => false;

  @override
  int get rowCount => total;

  @override
  int get selectedRowCount => 0;
}

String _formatServicioFecha(String? raw) {
  if (raw == null || raw.trim().isEmpty) {
    return '-';
  }

  final parsed = DateTime.tryParse(raw);
  if (parsed == null) {
    return raw;
  }

  String twoDigits(int value) => value.toString().padLeft(2, '0');
  final day = twoDigits(parsed.day);
  final month = twoDigits(parsed.month);
  final year = parsed.year.toString();
  final hour = twoDigits(parsed.hour);
  final minute = twoDigits(parsed.minute);
  return '$day/$month/$year $hour:$minute';
}
