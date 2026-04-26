import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:web_admin_tecnico/core/utils/paginated_table_prefs.dart';
import 'package:web_admin_tecnico/core/widgets/module_page_layout.dart';
import 'package:web_admin_tecnico/features/catalogos/data/catalogos_repository_impl.dart';
import 'package:web_admin_tecnico/features/catalogos/domain/catalogos_repository.dart';
import 'package:web_admin_tecnico/features/catalogos/presentation/bloc/catalogos_bloc.dart';

class CatalogosPage extends StatelessWidget {
  const CatalogosPage({super.key});

  @override
  Widget build(BuildContext context) {
    final repository = CatalogosRepositoryImpl();

    return BlocProvider<CatalogosBloc>(
      create: (_) => CatalogosBloc(repository)..add(CatalogosRequested(tipo: 'zona')),
      child: _CatalogosView(repository: repository),
    );
  }
}

class _CatalogosView extends StatefulWidget {
  const _CatalogosView({required this.repository});

  final CatalogosRepository repository;

  @override
  State<_CatalogosView> createState() => _CatalogosViewState();
}

class _CatalogosViewState extends State<_CatalogosView> {
  final TextEditingController _searchController = TextEditingController();
  String _tipoFilter = 'zona';
  static const List<String> _tipos = <String>['zona', 'categoria', 'producto'];
  static const List<int> _rowsPerPageDefaults = <int>[20, 40, 60];

  String _tipoLabel(String tipo) {
    switch (tipo) {
      case 'zona':
        return 'ZONAS';
      case 'categoria':
        return 'CATEGORIAS';
      case 'producto':
        return 'PRODUCTOS';
      default:
        return tipo.toUpperCase();
    }
  }

  String _tipoLegend(String tipo) {
    switch (tipo) {
      case 'categoria':
        return 'Categorias: Categoria de los productos para seleccionar en el diagnostico de la orden de servicio.';
      case 'producto':
        return 'Productos: Estos productos estan asociados a una categoria; se seleccionan en la orden de servicio para marcar que estaba fallando.';
      case 'zona':
      default:
        return 'Zonas: Se utiliza en la orden de servicio para cargar la zona donde se realiza el servicio a campo.';
    }
  }

  void _requestPage({int page = 1, int? limit}) {
    context.read<CatalogosBloc>().add(
          CatalogosRequested(
            search: _searchController.text.trim(),
            tipo: _tipoFilter,
            page: page,
            limit: limit ?? 20,
          ),
        );
  }

  Future<void> _openCreateDialog() async {
    final formKey = GlobalKey<FormState>();
    var nombre = '';
    var selectedTipo = _tipoFilter;
    String? selectedCategoriaId;
    List<CatalogoItem> categorias = const <CatalogoItem>[];
    Object? categoriasError;

    Future<void> loadCategorias() async {
      if (categorias.isNotEmpty || categoriasError != null) {
        return;
      }

      try {
        categorias = await widget.repository.fetchCategorias();
      } catch (error) {
        categoriasError = error;
      }
    }

    if (selectedTipo == 'producto') {
      await loadCategorias();
      if (!mounted) {
        return;
      }
    }

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            return AlertDialog(
              backgroundColor: const Color(0xFF102845),
              title: const Text('Nuevo registro de catalogo'),
              content: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    DropdownButtonFormField<String>(
                      initialValue: selectedTipo,
                      decoration: const InputDecoration(labelText: 'Tipo'),
                      items: _tipos
                          .map(
                            (tipo) => DropdownMenuItem<String>(
                              value: tipo,
                              child: Text(tipo.toUpperCase()),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        if (value == null) {
                          return;
                        }
                        setDialogState(() {
                          selectedTipo = value;
                          if (selectedTipo != 'producto') {
                            selectedCategoriaId = null;
                          }
                        });
                        if (value == 'producto' && categorias.isEmpty && categoriasError == null) {
                          loadCategorias().then((_) {
                            if (dialogContext.mounted) {
                              setDialogState(() {});
                            }
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      initialValue: nombre,
                      onChanged: (value) => nombre = value,
                      autofocus: true,
                      style: const TextStyle(color: Color(0xFFEAF3FF)),
                      decoration: const InputDecoration(
                        labelText: 'Nombre',
                        hintText: 'Ej: Zona Norte / Producto A / Repuesto X',
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'El nombre es obligatorio';
                        }
                        return null;
                      },
                    ),
                    if (selectedTipo == 'producto') ...<Widget>[
                      const SizedBox(height: 10),
                      if (categoriasError != null)
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'No se pudieron cargar las categorias. Cerra y reintenta.',
                            style: Theme.of(dialogContext).textTheme.bodySmall?.copyWith(
                                  color: const Color(0xFFFFD98B),
                                ),
                          ),
                        )
                      else if (categorias.isEmpty)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 8),
                          child: LinearProgressIndicator(minHeight: 3),
                        )
                      else
                        DropdownButtonFormField<String>(
                          initialValue: selectedCategoriaId,
                          decoration: const InputDecoration(
                            labelText: 'Categoria',
                            hintText: 'Seleccionar categoria',
                          ),
                          items: categorias
                              .map(
                                (categoria) => DropdownMenuItem<String>(
                                  value: categoria.id,
                                  child: Text(categoria.nombre),
                                ),
                              )
                              .toList(),
                          onChanged: (value) => setDialogState(() => selectedCategoriaId = value),
                          validator: (value) {
                            if (selectedTipo == 'producto' && (value == null || value.trim().isEmpty)) {
                              return 'Selecciona una categoria';
                            }
                            return null;
                          },
                        ),
                    ],
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
                      context.read<CatalogosBloc>().add(
                            CatalogosCreateRequested(
                              input: CreateCatalogoInput(
                                tipo: selectedTipo,
                                nombre: nombre,
                                categoriaId: selectedCategoriaId,
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
      },
    );

  }

  Future<void> _openEditDialog(BuildContext context, CatalogoItem item) async {
    final formKey = GlobalKey<FormState>();
    var nombre = item.nombre;
    var categoriaId = '';
    var activo = item.activo;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            return AlertDialog(
              backgroundColor: const Color(0xFF102845),
              title: const Text('Editar registro de catalogo'),
              content: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Align(
                      alignment: Alignment.centerLeft,
                      child: ModuleStatusChip(label: item.tipo.toUpperCase()),
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      initialValue: nombre,
                      onChanged: (value) => nombre = value,
                      autofocus: true,
                      style: const TextStyle(color: Color(0xFFEAF3FF)),
                      decoration: const InputDecoration(
                        labelText: 'Nombre',
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'El nombre es obligatorio';
                        }
                        return null;
                      },
                    ),
                    if (item.tipo == 'producto') ...<Widget>[
                      const SizedBox(height: 10),
                      TextFormField(
                        initialValue: categoriaId,
                        onChanged: (value) => categoriaId = value,
                        style: const TextStyle(color: Color(0xFFEAF3FF)),
                        decoration: const InputDecoration(
                          labelText: 'Categoria ID (opcional)',
                          hintText: 'Completar solo si vas a reasignar categoria',
                        ),
                      ),
                    ],
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
                      context.read<CatalogosBloc>().add(
                            CatalogosUpdateRequested(
                              input: UpdateCatalogoInput(
                                id: item.id,
                                tipo: item.tipo,
                                nombre: nombre,
                                categoriaId: categoriaId,
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
            final currentLimit = state.limit;
            final rowsPerPage = normalizeRowsPerPage(
              state.limit,
              defaults: _rowsPerPageDefaults,
            );
            final rowsPerPageOptions = buildRowsPerPageOptions(
              state.limit,
              defaults: _rowsPerPageDefaults,
            );

            return ModulePageLayout(
              title: 'Catalogos',
              subtitle: 'Parametros operativos para zonas, categorias y productos por categoria.',
              trailing: Wrap(
                spacing: 8,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: <Widget>[
                  OutlinedButton.icon(
                    onPressed: _openCreateDialog,
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Nuevo registro'),
                  ),
                  ModuleStatusChip(label: '${state.total} total'),
                ],
              ),
              child: Column(
                children: <Widget>[
                  TextField(
                    controller: _searchController,
                    onChanged: (_) => _requestPage(page: 1, limit: currentLimit),
                    style: const TextStyle(color: Color(0xFFEAF3FF)),
                    decoration: InputDecoration(
                      hintText: 'Buscar por nombre...',
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
                      spacing: 8,
                      runSpacing: 8,
                      children: _tipos.map((tipo) {
                        final isSelected = _tipoFilter == tipo;
                        return ChoiceChip(
                          label: Text(_tipoLabel(tipo)),
                          selected: isSelected,
                          showCheckmark: false,
                          selectedColor: const Color(0x334EA6FF),
                          backgroundColor: const Color(0xFF122B4A),
                          side: BorderSide(
                            color: isSelected ? const Color(0xFF5BA8FF) : const Color(0x334EA6FF),
                          ),
                          labelStyle: TextStyle(
                            color: isSelected ? const Color(0xFFEAF3FF) : const Color(0xFFB8CCE8),
                            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                            letterSpacing: 0.2,
                          ),
                          onSelected: (_) {
                            if (_tipoFilter == tipo) {
                              return;
                            }
                            setState(() => _tipoFilter = tipo);
                            _requestPage(page: 1, limit: currentLimit);
                          },
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: const Color(0x1A4EA6FF),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0x334EA6FF)),
                    ),
                    child: Text(
                      _tipoLegend(_tipoFilter),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: const Color(0xFFB8CCE8),
                            height: 1.35,
                          ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: _tipoFilter == 'producto'
                        ? _ProductosPorCategoriaView(
                            groups: state.productosPorCategoria,
                            onEdit: (item) => _openEditDialog(context, item),
                          )
                        : Card(
                            child: LayoutBuilder(
                              builder: (context, constraints) {
                                return SingleChildScrollView(
                                  child: ConstrainedBox(
                                    constraints: BoxConstraints(minWidth: constraints.maxWidth),
                                    child: PaginatedDataTable(
                                      headingRowColor: WidgetStateProperty.all(const Color(0x1A4EA6FF)),
                                      columns: const <DataColumn>[
                                        DataColumn(label: Text('Nombre')),
                                        DataColumn(label: Text('Tipo')),
                                        DataColumn(label: Text('Estado')),
                                        DataColumn(label: Text('Accion')),
                                      ],
                                      source: _CatalogosTableSource(
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

class _ProductosPorCategoriaView extends StatelessWidget {
  const _ProductosPorCategoriaView({
    required this.groups,
    required this.onEdit,
  });

  final List<ProductosPorCategoria> groups;
  final ValueChanged<CatalogoItem> onEdit;

  @override
  Widget build(BuildContext context) {
    if (groups.isEmpty) {
      return const Card(
        child: Center(
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Text('No hay productos para mostrar con los filtros actuales.'),
          ),
        ),
      );
    }

    return Card(
      child: ListView.separated(
        padding: const EdgeInsets.all(12),
        itemCount: groups.length,
        separatorBuilder: (_, index) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          final group = groups[index];
          return _CategoriaProductosCard(group: group, onEdit: onEdit);
        },
      ),
    );
  }
}

class _CategoriaProductosCard extends StatelessWidget {
  const _CategoriaProductosCard({
    required this.group,
    required this.onEdit,
  });

  final ProductosPorCategoria group;
  final ValueChanged<CatalogoItem> onEdit;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF122B4A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0x334EA6FF)),
      ),
      child: ExpansionTile(
        initiallyExpanded: true,
        collapsedIconColor: const Color(0xFFB8CCE8),
        iconColor: const Color(0xFFEAF3FF),
        title: Text(
          group.categoriaNombre,
          style: const TextStyle(
            color: Color(0xFFEAF3FF),
            fontWeight: FontWeight.w700,
          ),
        ),
        subtitle: Text(
          '${group.productos.length} producto(s)',
          style: const TextStyle(color: Color(0xFFB8CCE8)),
        ),
        childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        children: <Widget>[
          Align(
            alignment: Alignment.centerLeft,
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: group.productos
                  .map(
                    (item) => ActionChip(
                      backgroundColor: const Color(0x1A4EA6FF),
                      side: const BorderSide(color: Color(0x334EA6FF)),
                      avatar: Icon(
                        item.activo ? Icons.inventory_2_outlined : Icons.inventory_2,
                        size: 16,
                        color: item.activo ? const Color(0xFF8FF0BC) : const Color(0xFFFFD98B),
                      ),
                      label: Text(item.nombre),
                      onPressed: () => onEdit(item),
                    ),
                  )
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class _CatalogosTableSource extends DataTableSource {
  _CatalogosTableSource({
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
        DataCell(Text(item.nombre)),
        DataCell(ModuleStatusChip(label: item.tipo.toUpperCase())),
        DataCell(
          ModuleStatusChip(
            label: item.activo ? 'ACTIVO' : 'INACTIVO',
            backgroundColor: item.activo ? const Color(0x1F0FA960) : const Color(0x1FF4B942),
            foregroundColor: item.activo ? const Color(0xFF8FF0BC) : const Color(0xFFFFD98B),
          ),
        ),
        DataCell(
          IconButton(
            tooltip: 'Editar catalogo',
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
