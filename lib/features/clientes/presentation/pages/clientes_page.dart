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
    return BlocProvider<ClientesBloc>(
      create: (_) => ClientesBloc(ClientesRepositoryImpl())..add(ClientesRequested()),
      child: const _ClientesView(),
    );
  }
}

class _ClientesView extends StatefulWidget {
  const _ClientesView();

  @override
  State<_ClientesView> createState() => _ClientesViewState();
}

class _ClientesViewState extends State<_ClientesView> {
  final TextEditingController _searchController = TextEditingController();

  void _requestPage({int page = 1, int? limit}) {
    context.read<ClientesBloc>().add(
          ClientesRequested(
            search: _searchController.text.trim(),
            page: page,
            limit: limit ?? 6,
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
            final rowsPerPage = normalizeRowsPerPage(state.limit);
            final rowsPerPageOptions = buildRowsPerPageOptions(state.limit);
            return ModulePageLayout(
              title: 'Clientes',
              subtitle: 'Base operativa de clientes para ordenes y seguimiento.',
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  OutlinedButton.icon(
                    onPressed: () => _openCreateDialog(context),
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Nuevo cliente'),
                  ),
                  const SizedBox(width: 8),
                  ModuleStatusChip(label: '${state.total} total'),
                ],
              ),
              child: Column(
                children: <Widget>[
                  TextField(
                    controller: _searchController,
                    onChanged: (_) => _requestPage(page: 1, limit: state.limit),
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
                  const SizedBox(height: 12),
                  Expanded(
                    child: Card(
                      child: PaginatedDataTable(
                        headingRowColor: WidgetStateProperty.all(const Color(0x1A4EA6FF)),
                        columns: const <DataColumn>[
                          DataColumn(label: Text('ID')),
                          DataColumn(label: Text('Nombre')),
                          DataColumn(label: Text('Estado')),
                          DataColumn(label: Text('Accion')),
                        ],
                        source: _ClientesTableSource(
                          items: state.items,
                          total: state.total,
                          page: state.page,
                          limit: state.limit,
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
    final formKey = GlobalKey<FormState>();

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: const Color(0xFF102845),
          title: const Text('Crear cliente'),
          content: Form(
            key: formKey,
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
                  context.read<ClientesBloc>().add(
                        ClientesCreateRequested(
                          input: CreateClienteInput(
                            nombre: nameController.text,
                            cuit: cuitController.text,
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
  }
}

class _ClientesTableSource extends DataTableSource {
  _ClientesTableSource({
    required this.items,
    required this.total,
    required this.page,
    required this.limit,
  });

  final List<ClienteItem> items;
  final int total;
  final int page;
  final int limit;

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
        const DataCell(ModuleStatusChip(label: 'OPERATIVO')),
        DataCell(
          IconButton(
            tooltip: 'Editar cliente',
            onPressed: () {},
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