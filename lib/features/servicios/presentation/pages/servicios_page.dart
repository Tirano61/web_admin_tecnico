import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
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

  void _requestPage({int page = 1, int? limit}) {
    context.read<ServiciosBloc>().add(
          ServiciosRequested(
            search: _searchController.text.trim(),
            estado: _estadoFilter,
            canal: _canalFilter,
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
          final currentLimit = state.limit;

          return ModulePageLayout(
            title: 'Servicios',
            subtitle: 'Ordenes tecnicas con estado operativo y trazabilidad.',
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
                  ],
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: Card(
                    child: PaginatedDataTable(
                      headingRowColor: WidgetStateProperty.all(const Color(0x1A4EA6FF)),
                      columns: const <DataColumn>[
                        DataColumn(label: Text('ID')),
                        DataColumn(label: Text('Descripcion')),
                        DataColumn(label: Text('Estado')),
                        DataColumn(label: Text('Accion')),
                      ],
                      source: _ServiciosTableSource(
                        items: state.items,
                        total: state.total,
                        page: state.page,
                        limit: state.limit,
                        onOpen: _openDetalle,
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
        DataCell(Text(item.id)),
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
