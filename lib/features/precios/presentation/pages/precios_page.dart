import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:web_admin_tecnico/core/widgets/module_page_layout.dart';
import 'package:web_admin_tecnico/features/precios/data/precios_repository_impl.dart';
import 'package:web_admin_tecnico/features/precios/domain/precios_repository.dart';
import 'package:web_admin_tecnico/features/precios/presentation/bloc/precios_bloc.dart';

class PreciosPage extends StatelessWidget {
  const PreciosPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<PreciosBloc>(
      create: (_) => PreciosBloc(PreciosRepositoryImpl())..add(PreciosRequested()),
      child: const _PreciosView(),
    );
  }
}

class _PreciosView extends StatefulWidget {
  const _PreciosView();

  @override
  State<_PreciosView> createState() => _PreciosViewState();
}

class _PreciosViewState extends State<_PreciosView> {
  final TextEditingController _searchController = TextEditingController();

  void _requestPage({int page = 1, int? limit}) {
    context.read<PreciosBloc>().add(
          PreciosRequested(
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
    return BlocBuilder<PreciosBloc, PreciosState>(
      builder: (context, state) {
        if (state is PreciosLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (state is PreciosFailure) {
          return Center(child: Text('Error: ${state.message}'));
        }

        if (state is PreciosLoaded) {
          return ModulePageLayout(
            title: 'Precios',
            subtitle: 'Cotizacion y tarifas activas para calculo operativo.',
            trailing: ModuleStatusChip(label: '${state.total} total'),
            child: Column(
              children: <Widget>[
                TextField(
                  controller: _searchController,
                  onChanged: (_) => _requestPage(page: 1, limit: state.limit),
                  style: const TextStyle(color: Color(0xFFEAF3FF)),
                  decoration: InputDecoration(
                    hintText: 'Buscar por ID o concepto...',
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
                        DataColumn(label: Text('Concepto')),
                        DataColumn(label: Text('Valor USD')),
                        DataColumn(label: Text('Accion')),
                      ],
                      source: _PreciosTableSource(
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

class _PreciosTableSource extends DataTableSource {
  _PreciosTableSource({
    required this.items,
    required this.total,
    required this.page,
    required this.limit,
  });

  final List<PrecioItem> items;
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
        DataCell(Text(item.descripcion)),
        DataCell(
          ModuleStatusChip(
            label: item.valor.toStringAsFixed(2),
            backgroundColor: const Color(0x1F0FA960),
            foregroundColor: const Color(0xFF8FF0BC),
          ),
        ),
        DataCell(
          IconButton(
            tooltip: 'Actualizar valor',
            onPressed: () {},
            icon: const Icon(Icons.update, size: 18),
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
