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
    final codigoController = TextEditingController();
    final nombreController = TextEditingController();
    final precioController = TextEditingController();

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: const Color(0xFF102845),
          title: const Text('Nuevo repuesto'),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                TextFormField(
                  controller: codigoController,
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
                  controller: nombreController,
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
                  controller: precioController,
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
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () {
                if (formKey.currentState?.validate() ?? false) {
                  final precio = _parsePrecioUsd(precioController.text);
                  if (precio == null) {
                    return;
                  }
                  context.read<CatalogosBloc>().add(
                        CatalogosCreateRequested(
                          input: CreateCatalogoInput(
                            tipo: 'repuesto',
                            codigo: codigoController.text,
                            nombre: nombreController.text,
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

    codigoController.dispose();
    nombreController.dispose();
    precioController.dispose();
  }

  Future<void> _openEditDialog(BuildContext context, CatalogoItem item) async {
    final formKey = GlobalKey<FormState>();
    final codigoController = TextEditingController(text: item.codigo ?? '');
    final nombreController = TextEditingController(text: item.nombre);
    final precioController = TextEditingController(
      text: item.precioUsd == null ? '' : item.precioUsd!.toStringAsFixed(2),
    );
    var activo = item.activo;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            return AlertDialog(
              backgroundColor: const Color(0xFF102845),
              title: const Text('Editar repuesto'),
              content: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    TextFormField(
                      controller: codigoController,
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
                      controller: nombreController,
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
                      controller: precioController,
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
              actions: <Widget>[
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text('Cancelar'),
                ),
                FilledButton(
                  onPressed: () {
                    if (formKey.currentState?.validate() ?? false) {
                      final precio = _parsePrecioUsd(precioController.text);
                      if (precio == null) {
                        return;
                      }
                      context.read<CatalogosBloc>().add(
                            CatalogosUpdateRequested(
                              input: UpdateCatalogoInput(
                                id: item.id,
                                tipo: 'repuesto',
                                codigo: codigoController.text,
                                nombre: nombreController.text,
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

    codigoController.dispose();
    nombreController.dispose();
    precioController.dispose();
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
            final rowsPerPage = normalizeRowsPerPage(
              state.limit,
              defaults: _rowsPerPageDefaults,
            );
            final rowsPerPageOptions = buildRowsPerPageOptions(
              state.limit,
              defaults: _rowsPerPageDefaults,
            );

            return ModulePageLayout(
              title: 'Repuestos',
              subtitle: 'Listado y mantenimiento operativo de repuestos.',
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  OutlinedButton.icon(
                    onPressed: () => _openCreateDialog(context),
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Nuevo repuesto'),
                  ),
                  const SizedBox(width: 8),
                  ModuleStatusChip(label: '${state.total} total'),
                ],
              ),
              child: Column(
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          onChanged: (_) => _requestPage(page: 1, limit: state.limit),
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
                      ),
                      const SizedBox(width: 10),
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
                              _requestPage(page: 1, limit: state.limit);
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
                  const SizedBox(height: 12),
                  Expanded(
                    child: Card(
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          return SingleChildScrollView(
                            child: ConstrainedBox(
                              constraints: BoxConstraints(minWidth: constraints.maxWidth),
                              child: PaginatedDataTable(
                                headingRowColor: WidgetStateProperty.all(const Color(0x1A4EA6FF)),
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
                                  limit: state.limit,
                                  onEdit: (item) => _openEditDialog(context, item),
                                ),
                                rowsPerPage: rowsPerPage,
                                availableRowsPerPage: rowsPerPageOptions,
                                onRowsPerPageChanged: (value) {
                                  if (value == null) {
                                    return;
                                  }
                                  _requestPage(page: 1, limit: value);
                                },
                                onPageChanged: (firstRowIndex) {
                                  final nextPage = (firstRowIndex ~/ rowsPerPage) + 1;
                                  if (nextPage != state.page) {
                                    _requestPage(page: nextPage, limit: rowsPerPage);
                                  }
                                },
                                showFirstLastButtons: true,
                              ),
                            ),
                          );
                        },
                      ),
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
        DataCell(
          ModuleStatusChip(
            label: item.activo ? 'ACTIVO' : 'INACTIVO',
            backgroundColor: item.activo ? const Color(0x1F0FA960) : const Color(0x1FF4B942),
            foregroundColor: item.activo ? const Color(0xFF8FF0BC) : const Color(0xFFFFD98B),
          ),
        ),
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
