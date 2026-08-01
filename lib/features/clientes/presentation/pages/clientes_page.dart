import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:web_admin_tecnico/core/utils/paginated_table_prefs.dart';
import 'package:web_admin_tecnico/core/widgets/module_page_layout.dart';
import 'package:web_admin_tecnico/features/clientes/data/clientes_repository_impl.dart';
import 'package:web_admin_tecnico/features/clientes/domain/clientes_repository.dart';
import 'package:web_admin_tecnico/features/clientes/presentation/bloc/clientes_bloc.dart';

class ClientesPage extends StatelessWidget {
  const ClientesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final repository = ClientesRepositoryImpl();

    return BlocProvider<ClientesBloc>(
      create: (_) => ClientesBloc(repository)..add(ClientesRequested()),
      child: _ClientesView(repository: repository),
    );
  }
}

class _ClientesView extends StatefulWidget {
  const _ClientesView({required this.repository});

  final ClientesRepository repository;

  @override
  State<_ClientesView> createState() => _ClientesViewState();
}

class _ClientesViewState extends State<_ClientesView> {
  final TextEditingController _searchController = TextEditingController();
  Timer? _searchDebounce;
  String? _searchHintMessage;

  static const Duration _searchDebounceDuration = Duration(milliseconds: 350);

  void _requestPage({int page = 1, int? limit}) {
    final search = _searchController.text.trim();
    if (search.isNotEmpty && search.length < 3) {
      if (_searchHintMessage != 'Ingresa al menos 3 caracteres para buscar clientes.') {
        setState(() {
          _searchHintMessage = 'Ingresa al menos 3 caracteres para buscar clientes.';
        });
      }
      return;
    }

    context.read<ClientesBloc>().add(
          ClientesRequested(
            search: search,
            page: page,
            limit: limit ?? 6,
          ),
        );
  }

  void _onSearchChanged({required int limit}) {
    final search = _searchController.text.trim();
    _searchDebounce?.cancel();

    if (search.isNotEmpty && search.length < 3) {
      if (_searchHintMessage != 'Ingresa al menos 3 caracteres para buscar clientes.') {
        setState(() {
          _searchHintMessage = 'Ingresa al menos 3 caracteres para buscar clientes.';
        });
      }
      return;
    }

    if (_searchHintMessage != null) {
      setState(() => _searchHintMessage = null);
    }

    _searchDebounce = Timer(_searchDebounceDuration, () {
      if (!mounted) {
        return;
      }
      _requestPage(page: 1, limit: limit);
    });
  }

  Future<void> _openDetalleDialog(ClienteItem item) async {
    final detalleFuture = widget.repository.fetchClienteDetalle(item.id);

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: const Color(0xFF102845),
          title: const Text('Detalle de cliente'),
          content: SizedBox(
            width: 440,
            child: FutureBuilder<ClienteDetalle>(
              future: detalleFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Padding(
                    padding: EdgeInsets.all(24),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }

                if (snapshot.hasError || !snapshot.hasData) {
                  return Text(
                    'No se pudo cargar el detalle del cliente.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  );
                }

                final detalle = snapshot.data!;
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    _ClienteDetalleLine(label: 'ID', value: detalle.id),
                    _ClienteDetalleLine(label: 'Nombre', value: detalle.nombre),
                    _ClienteDetalleLine(label: 'CUIT', value: detalle.cuit ?? '-'),
                    _ClienteDetalleLine(label: 'Contacto', value: detalle.contacto ?? '-'),
                    _ClienteDetalleLine(label: 'Telefono', value: detalle.telefono ?? '-'),
                    _ClienteDetalleLine(label: 'Localidad', value: detalle.localidad ?? '-'),
                  ],
                );
              },
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cerrar'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _openEditDialog(ClienteItem item) async {
    ClienteDetalle detalle;
    try {
      detalle = await widget.repository.fetchClienteDetalle(item.id);
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo cargar el cliente: $error')),
      );
      return;
    }

    if (!mounted) {
      return;
    }

    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController(text: detalle.nombre);
    final cuitController = TextEditingController(text: detalle.cuit ?? '');
    final contactoController = TextEditingController(text: detalle.contacto ?? '');
    final telefonoController = TextEditingController(text: detalle.telefono ?? '');
    final localidadController = TextEditingController(text: detalle.localidad ?? '');

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: const Color(0xFF102845),
          title: const Text('Editar cliente'),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  TextFormField(
                    controller: nameController,
                    autofocus: true,
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
                    controller: cuitController,
                    style: const TextStyle(color: Color(0xFFEAF3FF)),
                    decoration: const InputDecoration(labelText: 'CUIT'),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'El CUIT es obligatorio';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: contactoController,
                    style: const TextStyle(color: Color(0xFFEAF3FF)),
                    decoration: const InputDecoration(labelText: 'Contacto (opcional)'),
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: telefonoController,
                    style: const TextStyle(color: Color(0xFFEAF3FF)),
                    decoration: const InputDecoration(labelText: 'Telefono (opcional)'),
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: localidadController,
                    style: const TextStyle(color: Color(0xFFEAF3FF)),
                    decoration: const InputDecoration(labelText: 'Localidad (opcional)'),
                  ),
                ],
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
                  context.read<ClientesBloc>().add(
                        ClientesUpdateRequested(
                          input: UpdateClienteInput(
                            id: detalle.id,
                            nombre: nameController.text,
                            cuit: cuitController.text,
                            contacto: contactoController.text,
                            telefono: telefonoController.text,
                            localidad: localidadController.text,
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

    nameController.dispose();
    cuitController.dispose();
    contactoController.dispose();
    telefonoController.dispose();
    localidadController.dispose();
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<ClientesBloc, ClientesState>(
      listenWhen: (previous, current) {
        return current is ClientesFailure ||
            (current is ClientesLoaded && current.message != null && current.message!.isNotEmpty);
      },
      listener: (context, state) {
        if (state is ClientesFailure) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: ${state.message}')),
          );
        }
        if (state is ClientesLoaded && state.message != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message!)),
          );
        }
      },
      child: BlocBuilder<ClientesBloc, ClientesState>(
        builder: (context, state) {
          if (state is ClientesLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is ClientesFailure) {
            return Center(child: Text('Error: ${state.message}'));
          }

          if (state is ClientesLoaded) {
            final effectiveLimit = state.limit > 0 ? state.limit : 6;
            final rowsPerPage = normalizeRowsPerPage(effectiveLimit);
            final rowsPerPageOptions = buildRowsPerPageOptions(effectiveLimit);
            final initialFirstRowIndex = (state.page - 1) * effectiveLimit;
            final hasActiveSearch = state.search.trim().isNotEmpty;
            final emptyMessage = hasActiveSearch
                ? 'No se encontraron clientes para "${state.search}".'
              : 'No hay clientes cargados para mostrar en esta pagina.';
            return ModulePageLayout(
              title: 'Clientes',
              subtitle: 'Base operativa de clientes para ordenes y seguimiento.',
              trailing: Wrap(
                spacing: 8,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: <Widget>[
                  OutlinedButton.icon(
                    onPressed: () => _openCreateDialog(context),
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Nuevo cliente'),
                  ),
                  ModuleStatusChip(label: '${state.total} total'),
                ],
              ),
              child: Column(
                children: <Widget>[
                  TextField(
                    controller: _searchController,
                    onChanged: (_) => _onSearchChanged(limit: effectiveLimit),
                    style: const TextStyle(color: Color(0xFFEAF3FF)),
                    decoration: InputDecoration(
                      hintText: 'Buscar por ID o nombre...',
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
                  if (_searchHintMessage != null) ...<Widget>[
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        _searchHintMessage!,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: const Color(0xFFFFD98B),
                            ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                  if (state.items.isEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0x1F122B4A),
                        border: Border.all(color: const Color(0x334EA6FF)),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(emptyMessage),
                    ),
                  Expanded(
                    child: LayoutBuilder(
                      builder: (context, bodyConstraints) {
                        if (state.items.isEmpty) {
                          return const SizedBox.shrink();
                        }

                        final useCompactLayout = bodyConstraints.maxWidth < 1040;

                        if (useCompactLayout) {
                          return _ClientesCompactList(
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
                            onView: _openDetalleDialog,
                            onEdit: _openEditDialog,
                          );
                        }

                        return Card(
                          child: LayoutBuilder(
                            builder: (context, constraints) {
                              const minTableWidth = 980.0;
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
                                        'clientes_${state.page}_${state.limit}_${state.total}',
                                      ),
                                      initialFirstRowIndex: initialFirstRowIndex < 0
                                          ? 0
                                          : initialFirstRowIndex,
                                      headingRowColor: WidgetStateProperty.all(const Color(0x1A4EA6FF)),
                                      columnSpacing: 22,
                                      horizontalMargin: 16,
                                      columns: const <DataColumn>[
                                        DataColumn(label: Text('ID')),
                                        DataColumn(label: Text('Nombre')),
                                        DataColumn(label: Text('CUIT')),
                                        DataColumn(label: Text('Estado')),
                                        DataColumn(label: Text('Accion')),
                                      ],
                                      source: _ClientesTableSource(
                                        items: state.items,
                                        total: state.total,
                                        page: state.page,
                                        limit: effectiveLimit,
                                        onView: _openDetalleDialog,
                                        onEdit: _openEditDialog,
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

  Future<void> _openCreateDialog(BuildContext context) async {
    final nameController = TextEditingController();
    final cuitController = TextEditingController();
    final contactoController = TextEditingController();
    final telefonoController = TextEditingController();
    final localidadController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: const Color(0xFF102845),
          title: const Text('Crear cliente'),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  TextFormField(
                    controller: nameController,
                    autofocus: true,
                    style: const TextStyle(color: Color(0xFFEAF3FF)),
                    decoration: const InputDecoration(
                      labelText: 'Nombre',
                      hintText: 'Ej: Agro SRL',
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
                    controller: cuitController,
                    style: const TextStyle(color: Color(0xFFEAF3FF)),
                    decoration: const InputDecoration(
                      labelText: 'CUIT',
                      hintText: 'Ej: 30-12345678-9',
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'El CUIT es obligatorio';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: contactoController,
                    style: const TextStyle(color: Color(0xFFEAF3FF)),
                    decoration: const InputDecoration(
                      labelText: 'Contacto (opcional)',
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: telefonoController,
                    style: const TextStyle(color: Color(0xFFEAF3FF)),
                    decoration: const InputDecoration(
                      labelText: 'Telefono (opcional)',
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: localidadController,
                    style: const TextStyle(color: Color(0xFFEAF3FF)),
                    decoration: const InputDecoration(
                      labelText: 'Localidad (opcional)',
                    ),
                  ),
                ],
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
                  context.read<ClientesBloc>().add(
                        ClientesCreateRequested(
                          input: CreateClienteInput(
                            nombre: nameController.text,
                            cuit: cuitController.text,
                            contacto: contactoController.text,
                            telefono: telefonoController.text,
                            localidad: localidadController.text,
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

    nameController.dispose();
    cuitController.dispose();
    contactoController.dispose();
    telefonoController.dispose();
    localidadController.dispose();
  }
}

class _ClientesTableSource extends DataTableSource {
  _ClientesTableSource({
    required this.items,
    required this.total,
    required this.page,
    required this.limit,
    required this.onView,
    required this.onEdit,
  });

  final List<ClienteItem> items;
  final int total;
  final int page;
  final int limit;
  final ValueChanged<ClienteItem> onView;
  final ValueChanged<ClienteItem> onEdit;

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
        DataCell(Text(item.nombre)),
        DataCell(Text(item.cuit ?? '-')),
        const DataCell(ModuleStatusChip(label: 'OPERATIVO')),
        DataCell(
          Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              IconButton(
                tooltip: 'Ver detalle',
                onPressed: () => onView(item),
                icon: const Icon(Icons.visibility_outlined, size: 18),
              ),
              IconButton(
                tooltip: 'Editar cliente',
                onPressed: () => onEdit(item),
                icon: const Icon(Icons.edit_outlined, size: 18),
              ),
            ],
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

class _ClientesCompactList extends StatelessWidget {
  const _ClientesCompactList({
    required this.items,
    required this.total,
    required this.page,
    required this.limit,
    required this.rowsPerPage,
    required this.rowsPerPageOptions,
    required this.onRowsPerPageChanged,
    required this.onPageChanged,
    required this.onView,
    required this.onEdit,
  });

  final List<ClienteItem> items;
  final int total;
  final int page;
  final int limit;
  final int rowsPerPage;
  final List<int> rowsPerPageOptions;
  final ValueChanged<int> onRowsPerPageChanged;
  final ValueChanged<int> onPageChanged;
  final ValueChanged<ClienteItem> onView;
  final ValueChanged<ClienteItem> onEdit;

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
                return _ClienteCompactCard(
                  item: item,
                  onView: onView,
                  onEdit: onEdit,
                );
              },
            ),
          ),
          const Divider(color: Color(0x334EA6FF), height: 1),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final compactFooter = constraints.maxWidth < 760;

                final rowsSelector = _ClientesRowsPerPageDropdown(
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

class _ClientesRowsPerPageDropdown extends StatelessWidget {
  const _ClientesRowsPerPageDropdown({
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

class _ClienteCompactCard extends StatelessWidget {
  const _ClienteCompactCard({
    required this.item,
    required this.onView,
    required this.onEdit,
  });

  final ClienteItem item;
  final ValueChanged<ClienteItem> onView;
  final ValueChanged<ClienteItem> onEdit;

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
              const ModuleStatusChip(label: 'OPERATIVO'),
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
            'CUIT: ${item.cuit ?? '-'}',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: const Color(0xFFCAE0F5),
                ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: <Widget>[
              TextButton.icon(
                onPressed: () => onView(item),
                icon: const Icon(Icons.visibility_outlined, size: 16),
                label: const Text('Detalle'),
              ),
              TextButton.icon(
                onPressed: () => onEdit(item),
                icon: const Icon(Icons.edit_outlined, size: 16),
                label: const Text('Editar'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ClienteDetalleLine extends StatelessWidget {
  const _ClienteDetalleLine({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: const Color(0xFF9AB1CC),
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: const Color(0xFFEAF3FF),
                ),
          ),
        ],
      ),
    );
  }
}