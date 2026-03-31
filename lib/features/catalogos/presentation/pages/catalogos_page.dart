import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:web_admin_tecnico/core/widgets/module_page_layout.dart';
import 'package:web_admin_tecnico/features/catalogos/data/catalogos_repository_impl.dart';
import 'package:web_admin_tecnico/features/catalogos/domain/catalogos_repository.dart';
import 'package:web_admin_tecnico/features/catalogos/presentation/bloc/catalogos_bloc.dart';

class CatalogosPage extends StatelessWidget {
  const CatalogosPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<CatalogosBloc>(
      create: (_) => CatalogosBloc(CatalogosRepositoryImpl())..add(CatalogosRequested()),
      child: const _CatalogosView(),
    );
  }
}

class _CatalogosView extends StatefulWidget {
  const _CatalogosView();

  @override
  State<_CatalogosView> createState() => _CatalogosViewState();
}

class _CatalogosViewState extends State<_CatalogosView> {
  final TextEditingController _searchController = TextEditingController();
  String _tipoFilter = 'todos';

  void _requestPage({int page = 1, int? limit}) {
    context.read<CatalogosBloc>().add(
          CatalogosRequested(
            search: _searchController.text.trim(),
            tipo: _tipoFilter,
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
    return BlocBuilder<CatalogosBloc, CatalogosState>(
      builder: (context, state) {
        if (state is CatalogosLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (state is CatalogosFailure) {
          return Center(child: Text('Error: ${state.message}'));
        }

        if (state is CatalogosLoaded) {
          final tipos = <String>{'todos', 'zona', 'categoria', 'producto', 'repuesto'};
          final currentLimit = state.limit;

          return ModulePageLayout(
            title: 'Catalogos',
            subtitle: 'Parametros operativos para productos, zonas y repuestos.',
            trailing: ModuleStatusChip(label: '${state.total} total'),
            child: Column(
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        onChanged: (_) => _requestPage(page: 1, limit: currentLimit),
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
                          value: _tipoFilter,
                          onChanged: (value) {
                            if (value == null) {
                              return;
                            }
                            setState(() => _tipoFilter = value);
                            _requestPage(page: 1, limit: currentLimit);
                          },
                          items: tipos
                              .map(
                                (tipo) => DropdownMenuItem<String>(
                                  value: tipo,
                                  child: Text(tipo.toUpperCase()),
                                ),
                              )
                              .toList(),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: Card(
                    child: PaginatedDataTable(
                      headingRowColor: WidgetStateProperty.all(const Color(0x1A4EA6FF)),
                      columns: const <DataColumn>[
                        DataColumn(label: Text('ID')),
                        DataColumn(label: Text('Nombre')),
                        DataColumn(label: Text('Tipo')),
                        DataColumn(label: Text('Accion')),
                      ],
                      source: _CatalogosTableSource(
                        items: state.items,
                        total: state.total,
                        page: state.page,
                        limit: state.limit,
                      ),
                      rowsPerPage: state.limit,
                      availableRowsPerPage: const <int>[6, 12, 24],
                      onRowsPerPageChanged: (value) {
                        if (value == null) {
                          return;
                        }
                        _requestPage(page: 1, limit: value);
                      },
                      onPageChanged: (firstRowIndex) {
                        final nextPage = (firstRowIndex ~/ state.limit) + 1;
                        if (nextPage != state.page) {
                          _requestPage(page: nextPage, limit: state.limit);
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
    );
  }
}

class _CatalogosTableSource extends DataTableSource {
  _CatalogosTableSource({
    required this.items,
    required this.total,
    required this.page,
    required this.limit,
  });

  final List<CatalogoItem> items;
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
        DataCell(ModuleStatusChip(label: item.tipo.toUpperCase())),
        DataCell(
          IconButton(
            tooltip: 'Editar catalogo',
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
