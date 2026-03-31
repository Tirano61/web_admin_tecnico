import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:web_admin_tecnico/core/widgets/module_page_layout.dart';
import 'package:web_admin_tecnico/features/liquidaciones/data/liquidaciones_repository_impl.dart';
import 'package:web_admin_tecnico/features/liquidaciones/domain/liquidaciones_repository.dart';
import 'package:web_admin_tecnico/features/liquidaciones/presentation/bloc/liquidaciones_bloc.dart';

class LiquidacionesPage extends StatelessWidget {
  const LiquidacionesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<LiquidacionesBloc>(
      create: (_) =>
          LiquidacionesBloc(LiquidacionesRepositoryImpl())..add(LiquidacionesRequested()),
      child: const _LiquidacionesView(),
    );
  }
}

class _LiquidacionesView extends StatefulWidget {
  const _LiquidacionesView();

  @override
  State<_LiquidacionesView> createState() => _LiquidacionesViewState();
}

class _LiquidacionesViewState extends State<_LiquidacionesView> {
  final TextEditingController _searchController = TextEditingController();
  String _estadoFilter = 'todos';

  void _requestPage({int page = 1, int? limit}) {
    context.read<LiquidacionesBloc>().add(
          LiquidacionesRequested(
            search: _searchController.text.trim(),
            estado: _estadoFilter,
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
    return BlocBuilder<LiquidacionesBloc, LiquidacionesState>(
      builder: (context, state) {
        if (state is LiquidacionesLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (state is LiquidacionesFailure) {
          return Center(child: Text('Error: ${state.message}'));
        }

        if (state is LiquidacionesLoaded) {
          return ModulePageLayout(
            title: 'Liquidaciones',
            subtitle: 'Seguimiento de aprobaciones tecnicas y montos USD.',
            trailing: ModuleStatusChip(label: '${state.total} total'),
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
                          hintText: 'Buscar por ID de liquidacion o servicio...',
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
                            DropdownMenuItem(value: 'todos', child: Text('TODOS')),
                            DropdownMenuItem(value: 'aprobada', child: Text('APROBADAS')),
                            DropdownMenuItem(value: 'pendiente', child: Text('PENDIENTES')),
                          ],
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
                        DataColumn(label: Text('Servicio')),
                        DataColumn(label: Text('Monto USD')),
                        DataColumn(label: Text('Estado')),
                      ],
                      source: _LiquidacionesTableSource(
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

class _LiquidacionesTableSource extends DataTableSource {
  _LiquidacionesTableSource({
    required this.items,
    required this.total,
    required this.page,
    required this.limit,
  });

  final List<LiquidacionItem> items;
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
    final approved = item.aprobada;
    return DataRow.byIndex(
      index: index,
      cells: <DataCell>[
        DataCell(Text(item.id)),
        DataCell(Text(item.servicioId)),
        DataCell(
          ModuleStatusChip(
            label: item.montoUsd.toStringAsFixed(2),
            backgroundColor: const Color(0x1F0FA960),
            foregroundColor: const Color(0xFF8FF0BC),
          ),
        ),
        DataCell(
          ModuleStatusChip(
            label: approved ? 'APROBADA' : 'PENDIENTE',
            backgroundColor: approved ? const Color(0x1F0FA960) : const Color(0x1FF4B942),
            foregroundColor: approved ? const Color(0xFF8FF0BC) : const Color(0xFFFFD98B),
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