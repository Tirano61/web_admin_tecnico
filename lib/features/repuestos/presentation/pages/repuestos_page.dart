import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:web_admin_tecnico/core/utils/paginated_table_prefs.dart';
import 'package:web_admin_tecnico/core/widgets/module_page_layout.dart';
import 'package:web_admin_tecnico/features/catalogos/data/catalogos_repository_impl.dart';
import 'package:web_admin_tecnico/features/catalogos/domain/catalogos_repository.dart';
import 'package:web_admin_tecnico/features/catalogos/presentation/bloc/catalogos_bloc.dart';

class RepuestosPage extends StatelessWidget {
  const RepuestosPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<CatalogosBloc>(
      create: (_) => CatalogosBloc(CatalogosRepositoryImpl())
        ..add(
          CatalogosRequested(
            tipo: 'repuesto',
            limit: 20,
          ),
        ),
      child: const _RepuestosView(),
    );
  }
}

class _RepuestosView extends StatefulWidget {
  const _RepuestosView();

  @override
  State<_RepuestosView> createState() => _RepuestosViewState();
}

class _RepuestosViewState extends State<_RepuestosView> {
  final TextEditingController _searchController = TextEditingController();
  String _estadoFilter = 'todos';
  static const List<int> _rowsPerPageDefaults = <int>[20, 40, 60];

  double? _parsePrecioUsd(String raw) {
    return double.tryParse(raw.trim().replaceAll(',', '.'));
  }

  bool? get _activoFilter {
    switch (_estadoFilter) {
      case 'activos':
        return true;
      case 'inactivos':
        return false;
      default:
        return null;
    }
  }

  void _requestPage({int page = 1, int? limit}) {
    context.read<CatalogosBloc>().add(
          CatalogosRequested(
            search: _searchController.text.trim(),
            tipo: 'repuesto',
            page: page,
            limit: limit ?? 20,
            activo: _activoFilter,
          ),
        );
  }

  Future<void> _openCreateDialog(BuildContext context) async {
    final formKey = GlobalKey<FormState>();
    var codigoValue = '';
    var nombreValue = '';
    var precioValue = '';

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: const Color(0xFF102845),
          title: const Text('Nuevo repuesto'),
          content: SizedBox(
            width: 520,
            child: SingleChildScrollView(
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    TextFormField(
                      initialValue: codigoValue,
                      onChanged: (value) => codigoValue = value,
                      autofocus: true,
                      style: const TextStyle(color: Color(0xFFEAF3FF)),
                      decoration: const InputDecoration(
                        labelText: 'Codigo',
                        hintText: 'Ej: 05-01-CZAP-20000',
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'El codigo es obligatorio';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      initialValue: nombreValue,
                      onChanged: (value) => nombreValue = value,
                      style: const TextStyle(color: Color(0xFFEAF3FF)),
                      decoration: const InputDecoration(
                        labelText: 'Nombre',
                        hintText: 'Ej: Celda CZAP 20000',
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'El nombre es obligatorio';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      initialValue: precioValue,
                      onChanged: (value) => precioValue = value,
                      style: const TextStyle(color: Color(0xFFEAF3FF)),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(
                        labelText: 'Precio USD',
                        hintText: 'Ej: 120.75',
                      ),
                      validator: (value) {
                        final parsed = _parsePrecioUsd(value ?? '');
                        if (parsed == null) {
                          return 'Ingresa un precio valido';
                        }
                        if (parsed < 0) {
                          return 'El precio no puede ser negativo';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () {
                if (formKey.currentState?.validate() ?? false) {
                  final precio = _parsePrecioUsd(precioValue);
                  if (precio == null) {
                    return;
                  }
                  context.read<CatalogosBloc>().add(
                        CatalogosCreateRequested(
                          input: CreateCatalogoInput(
                            tipo: 'repuesto',
                            codigo: codigoValue.trim(),
                            nombre: nombreValue.trim(),
                            precioUsd: precio,
                          ),
                        ),
                      );
                  Navigator.of(dialogContext).pop();
                }
              },
              child: const Text('Crear'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _openEditDialog(BuildContext context, CatalogoItem item) async {
    final formKey = GlobalKey<FormState>();
    var codigoValue = item.codigo ?? '';
    var nombreValue = item.nombre;
    var precioValue = item.precioUsd == null ? '' : item.precioUsd!.toStringAsFixed(2);
    var activo = item.activo;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            return AlertDialog(
              backgroundColor: const Color(0xFF102845),
              title: const Text('Editar repuesto'),
              content: SizedBox(
                width: 520,
                child: SingleChildScrollView(
                  child: Form(
                    key: formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        TextFormField(
                          initialValue: codigoValue,
                          onChanged: (value) => codigoValue = value,
                          autofocus: true,
                          style: const TextStyle(color: Color(0xFFEAF3FF)),
                          decoration: const InputDecoration(labelText: 'Codigo'),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'El codigo es obligatorio';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 10),
                        TextFormField(
                          initialValue: nombreValue,
                          onChanged: (value) => nombreValue = value,
                          style: const TextStyle(color: Color(0xFFEAF3FF)),
                          decoration: const InputDecoration(labelText: 'Nombre'),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'El nombre es obligatorio';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 10),
                        TextFormField(
                          initialValue: precioValue,
                          onChanged: (value) => precioValue = value,
                          style: const TextStyle(color: Color(0xFFEAF3FF)),
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: const InputDecoration(labelText: 'Precio USD'),
                          validator: (value) {
                            final parsed = _parsePrecioUsd(value ?? '');
                            if (parsed == null) {
                              return 'Ingresa un precio valido';
                            }
                            if (parsed < 0) {
                              return 'El precio no puede ser negativo';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 10),
                        SwitchListTile.adaptive(
                          value: activo,
                          onChanged: (value) => setDialogState(() => activo = value),
                          title: const Text('Activo'),
                          contentPadding: EdgeInsets.zero,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              actions: <Widget>[
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text('Cancelar'),
                ),
                FilledButton(
                  onPressed: () {
                    if (formKey.currentState?.validate() ?? false) {
                      final precio = _parsePrecioUsd(precioValue);
                      if (precio == null) {
                        return;
                      }
                      context.read<CatalogosBloc>().add(
                            CatalogosUpdateRequested(
                              input: UpdateCatalogoInput(
                                id: item.id,
                                tipo: 'repuesto',
                                codigo: codigoValue.trim(),
                                nombre: nombreValue.trim(),
                                precioUsd: precio,
                                activo: activo,
                              ),
                            ),
                          );
                      Navigator.of(dialogContext).pop();
                    }
                  },
                  child: const Text('Guardar'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<CatalogosBloc, CatalogosState>(
      listenWhen: (previous, current) {
        return current is CatalogosFailure ||
            (current is CatalogosLoaded && current.message != null && current.message!.isNotEmpty);
      },
      listener: (context, state) {
        if (state is CatalogosFailure) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: ${state.message}')),
          );
        }
        if (state is CatalogosLoaded && state.message != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message!)),
          );
        }
      },
      child: BlocBuilder<CatalogosBloc, CatalogosState>(
        builder: (context, state) {
          if (state is CatalogosLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is CatalogosFailure) {
            return Center(child: Text('Error: ${state.message}'));
          }

          if (state is CatalogosLoaded) {
            final effectiveLimit = state.limit > 0 ? state.limit : 20;
            final rowsPerPage = normalizeRowsPerPage(
              effectiveLimit,
              defaults: _rowsPerPageDefaults,
            );
            final rowsPerPageOptions = buildRowsPerPageOptions(
              effectiveLimit,
              defaults: _rowsPerPageDefaults,
            );
            final initialFirstRowIndex = (state.page - 1) * effectiveLimit;

            return ModulePageLayout(
              title: 'Repuestos',
              subtitle: 'Listado y mantenimiento operativo de repuestos.',
              trailing: Wrap(
                spacing: 8,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: <Widget>[
                  OutlinedButton.icon(
                    onPressed: () => _openCreateDialog(context),
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Nuevo repuesto'),
                  ),
                  ModuleStatusChip(label: '${state.total} total'),
                ],
              ),
              child: Column(
                children: <Widget>[
                  TextField(
                    controller: _searchController,
                    onChanged: (_) => _requestPage(page: 1, limit: effectiveLimit),
                    style: const TextStyle(color: Color(0xFFEAF3FF)),
                    decoration: InputDecoration(
                      hintText: 'Buscar repuesto por ID o nombre...',
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
                                _requestPage(page: 1, limit: effectiveLimit);
                              },
                              items: const <DropdownMenuItem<String>>[
                                DropdownMenuItem<String>(value: 'todos', child: Text('TODOS')),
                                DropdownMenuItem<String>(value: 'activos', child: Text('ACTIVOS')),
                                DropdownMenuItem<String>(
                                  value: 'inactivos',
                                  child: Text('INACTIVOS'),
                                ),
                              ],
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
                          return const SizedBox.shrink();
                        }

                        final useCompactLayout = bodyConstraints.maxWidth < 1080;

                        if (useCompactLayout) {
                          return _RepuestosCompactList(
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
                            onEdit: (item) => _openEditDialog(context, item),
                          );
                        }

                        return Card(
                          child: LayoutBuilder(
                            builder: (context, constraints) {
                              const minTableWidth = 1040.0;
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
                                        'repuestos_${state.page}_${state.limit}_${state.total}_$_estadoFilter',
                                      ),
                                      initialFirstRowIndex: initialFirstRowIndex < 0
                                          ? 0
                                          : initialFirstRowIndex,
                                      headingRowColor: WidgetStateProperty.all(const Color(0x1A4EA6FF)),
                                      columnSpacing: 22,
                                      horizontalMargin: 16,
                                      columns: const <DataColumn>[
                                        DataColumn(label: Text('ID')),
                                        DataColumn(label: Text('Codigo')),
                                        DataColumn(label: Text('Nombre')),
                                        DataColumn(label: Text('Precio USD')),
                                        DataColumn(label: Text('Estado')),
                                        DataColumn(label: Text('Accion')),
                                      ],
                                      source: _RepuestosTableSource(
                                        items: state.items,
                                        total: state.total,
                                        page: state.page,
                                        limit: effectiveLimit,
                                        onEdit: (item) => _openEditDialog(context, item),
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
      ),
    );
  }
}

class _RepuestosTableSource extends DataTableSource {
  _RepuestosTableSource({
    required this.items,
    required this.total,
    required this.page,
    required this.limit,
    required this.onEdit,
  });

  final List<CatalogoItem> items;
  final int total;
  final int page;
  final int limit;
  final ValueChanged<CatalogoItem> onEdit;

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
        DataCell(Text(item.id)),
        DataCell(Text(item.codigo ?? '-')),
        DataCell(Text(item.nombre)),
        DataCell(Text(item.precioUsd == null ? '-' : item.precioUsd!.toStringAsFixed(2))),
        DataCell(_RepuestoEstadoChip(activo: item.activo)),
        DataCell(
          IconButton(
            tooltip: 'Editar repuesto',
            onPressed: () => onEdit(item),
            icon: const Icon(Icons.edit_outlined, size: 18),
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

class _RepuestoEstadoChip extends StatelessWidget {
  const _RepuestoEstadoChip({required this.activo});

  final bool activo;

  @override
  Widget build(BuildContext context) {
    return ModuleStatusChip(
      label: activo ? 'ACTIVO' : 'INACTIVO',
      backgroundColor: activo ? const Color(0x1F0FA960) : const Color(0x1FF4B942),
      foregroundColor: activo ? const Color(0xFF8FF0BC) : const Color(0xFFFFD98B),
    );
  }
}

class _RepuestosCompactList extends StatelessWidget {
  const _RepuestosCompactList({
    required this.items,
    required this.total,
    required this.page,
    required this.limit,
    required this.rowsPerPage,
    required this.rowsPerPageOptions,
    required this.onRowsPerPageChanged,
    required this.onPageChanged,
    required this.onEdit,
  });

  final List<CatalogoItem> items;
  final int total;
  final int page;
  final int limit;
  final int rowsPerPage;
  final List<int> rowsPerPageOptions;
  final ValueChanged<int> onRowsPerPageChanged;
  final ValueChanged<int> onPageChanged;
  final ValueChanged<CatalogoItem> onEdit;

  @override
  Widget build(BuildContext context) {
    final totalPages = limit <= 0 ? 1 : math.max(1, (total / limit).ceil());
    final clampedPage = page.clamp(1, totalPages);
    final firstVisible = total == 0 ? 0 : ((clampedPage - 1) * limit) + 1;
    final lastVisible = total == 0 ? 0 : math.min(total, firstVisible + items.length - 1);
    final canGoPrev = clampedPage > 1;
    final canGoNext = clampedPage < totalPages;

    return Card(
      child: Column(
        children: <Widget>[
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.all(12),
              itemCount: items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final item = items[index];
                return _RepuestoCompactCard(item: item, onEdit: onEdit);
              },
            ),
          ),
          const Divider(color: Color(0x334EA6FF), height: 1),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final compactFooter = constraints.maxWidth < 760;

                final rowsSelector = _RepuestosRowsPerPageDropdown(
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

class _RepuestosRowsPerPageDropdown extends StatelessWidget {
  const _RepuestosRowsPerPageDropdown({
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

class _RepuestoCompactCard extends StatelessWidget {
  const _RepuestoCompactCard({
    required this.item,
    required this.onEdit,
  });

  final CatalogoItem item;
  final ValueChanged<CatalogoItem> onEdit;

  @override
  Widget build(BuildContext context) {
    final precio = item.precioUsd == null ? '-' : item.precioUsd!.toStringAsFixed(2);

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
                  item.nombre,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: const Color(0xFFEAF3FF),
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ),
              const SizedBox(width: 8),
              _RepuestoEstadoChip(activo: item.activo),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'ID: ${item.id}',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: const Color(0xFFCAE0F5),
                ),
          ),
          const SizedBox(height: 2),
          Text(
            'Codigo: ${item.codigo ?? '-'}',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: const Color(0xFFCAE0F5),
                ),
          ),
          const SizedBox(height: 2),
          Text(
            'Precio USD: $precio',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: const Color(0xFFCAE0F5),
                ),
          ),
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: () => onEdit(item),
              icon: const Icon(Icons.edit_outlined, size: 16),
              label: const Text('Editar'),
            ),
          ),
        ],
      ),
    );
  }
}
