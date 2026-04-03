import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:web_admin_tecnico/core/utils/paginated_table_prefs.dart';
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

  String? _validateDate(String? value) {
    final text = (value ?? '').trim();
    if (text.isEmpty) {
      return null;
    }
    final pattern = RegExp(r'^\d{4}-\d{2}-\d{2}$');
    if (!pattern.hasMatch(text)) {
      return 'Usa formato YYYY-MM-DD';
    }
    return null;
  }

  double? _parseDecimal(String value) {
    final normalized = value.trim().replaceAll(',', '.');
    return double.tryParse(normalized);
  }

  Future<void> _openCreateCotizacionDialog(BuildContext context) async {
    final formKey = GlobalKey<FormState>();
    final valorController = TextEditingController();
    final fechaController = TextEditingController();

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: const Color(0xFF102845),
          title: const Text('Registrar cotizacion'),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                TextFormField(
                  controller: valorController,
                  autofocus: true,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  style: const TextStyle(color: Color(0xFFEAF3FF)),
                  decoration: const InputDecoration(
                    labelText: 'Valor USD',
                    hintText: 'Ej: 1120.50',
                  ),
                  validator: (value) {
                    final parsed = _parseDecimal(value ?? '');
                    if (parsed == null || parsed <= 0) {
                      return 'Ingresa un valor numerico mayor a 0';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: fechaController,
                  style: const TextStyle(color: Color(0xFFEAF3FF)),
                  decoration: const InputDecoration(
                    labelText: 'Fecha (opcional)',
                    hintText: 'YYYY-MM-DD',
                  ),
                  validator: _validateDate,
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
                if (!(formKey.currentState?.validate() ?? false)) {
                  return;
                }
                final valor = _parseDecimal(valorController.text);
                if (valor == null) {
                  return;
                }

                context.read<PreciosBloc>().add(
                      PreciosCreateCotizacionRequested(
                        input: CreateCotizacionInput(
                          valorUsd: valor,
                          fecha: fechaController.text.trim(),
                        ),
                      ),
                    );
                Navigator.of(dialogContext).pop();
              },
              child: const Text('Guardar'),
            ),
          ],
        );
      },
    );

    valorController.dispose();
    fechaController.dispose();
  }

  Future<void> _openCreateTarifaKmDialog(BuildContext context) async {
    final formKey = GlobalKey<FormState>();
    final valorController = TextEditingController();
    final fechaController = TextEditingController();

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: const Color(0xFF102845),
          title: const Text('Registrar tarifa km'),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                TextFormField(
                  controller: valorController,
                  autofocus: true,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  style: const TextStyle(color: Color(0xFFEAF3FF)),
                  decoration: const InputDecoration(
                    labelText: 'Valor km USD',
                    hintText: 'Ej: 0.75',
                  ),
                  validator: (value) {
                    final parsed = _parseDecimal(value ?? '');
                    if (parsed == null || parsed <= 0) {
                      return 'Ingresa un valor numerico mayor a 0';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: fechaController,
                  style: const TextStyle(color: Color(0xFFEAF3FF)),
                  decoration: const InputDecoration(
                    labelText: 'Fecha (opcional)',
                    hintText: 'YYYY-MM-DD',
                  ),
                  validator: _validateDate,
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
                if (!(formKey.currentState?.validate() ?? false)) {
                  return;
                }
                final valor = _parseDecimal(valorController.text);
                if (valor == null) {
                  return;
                }

                context.read<PreciosBloc>().add(
                      PreciosCreateTarifaKmRequested(
                        input: CreateTarifaKmInput(
                          valorKmUsd: valor,
                          fecha: fechaController.text.trim(),
                        ),
                      ),
                    );
                Navigator.of(dialogContext).pop();
              },
              child: const Text('Guardar'),
            ),
          ],
        );
      },
    );

    valorController.dispose();
    fechaController.dispose();
  }

  void _openUpdateDialogByType(BuildContext context, PrecioTipo tipo) {
    if (tipo == PrecioTipo.cotizacion) {
      _openCreateCotizacionDialog(context);
      return;
    }
    _openCreateTarifaKmDialog(context);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<PreciosBloc, PreciosState>(
      listenWhen: (previous, current) {
        return current is PreciosFailure ||
            (current is PreciosLoaded && current.message != null && current.message!.isNotEmpty);
      },
      listener: (context, state) {
        if (state is PreciosFailure) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: ${state.message}')),
          );
        }
        if (state is PreciosLoaded && state.message != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message!)),
          );
        }
      },
      child: BlocBuilder<PreciosBloc, PreciosState>(
        builder: (context, state) {
          if (state is PreciosLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is PreciosFailure) {
            return Center(child: Text('Error: ${state.message}'));
          }

          if (state is PreciosLoaded) {
            final rowsPerPage = normalizeRowsPerPage(state.limit);
            final rowsPerPageOptions = buildRowsPerPageOptions(state.limit);
            return ModulePageLayout(
              title: 'Precios',
              subtitle: 'Cotizacion y tarifas activas para calculo operativo.',
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  OutlinedButton.icon(
                    onPressed: () => _openCreateCotizacionDialog(context),
                    icon: const Icon(Icons.add_chart, size: 18),
                    label: const Text('Nueva cotizacion'),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton.icon(
                    onPressed: () => _openCreateTarifaKmDialog(context),
                    icon: const Icon(Icons.alt_route, size: 18),
                    label: const Text('Nueva tarifa km'),
                  ),
                  const SizedBox(width: 8),
                  ModuleStatusChip(label: '${state.total} total'),
                ],
              ),
              child: Column(
                children: <Widget>[
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: <Widget>[
                      _ActualPrecioTile(
                        label: 'Cotizacion actual USD',
                        value: state.actuales.cotizacionUsd,
                      ),
                      _ActualPrecioTile(
                        label: 'Tarifa km actual USD',
                        value: state.actuales.tarifaKmUsd,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _searchController,
                    onChanged: (_) => _requestPage(page: 1, limit: state.limit),
                    style: const TextStyle(color: Color(0xFFEAF3FF)),
                    decoration: InputDecoration(
                      hintText: 'Buscar por ID, tipo o fecha...',
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
                          DataColumn(label: Text('Tipo')),
                          DataColumn(label: Text('Fecha')),
                          DataColumn(label: Text('Valor USD')),
                          DataColumn(label: Text('Accion')),
                        ],
                        source: _PreciosTableSource(
                          items: state.items,
                          total: state.total,
                          page: state.page,
                          limit: state.limit,
                          onUpdate: (item) => _openUpdateDialogByType(context, item.tipo),
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
}

class _ActualPrecioTile extends StatelessWidget {
  const _ActualPrecioTile({
    required this.label,
    required this.value,
  });

  final String label;
  final double? value;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 260,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0x1F122B4A),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0x334EA6FF)),
      ),
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
          const SizedBox(height: 4),
          Text(
            value == null ? '-' : value!.toStringAsFixed(2),
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: const Color(0xFFEAF3FF),
                  fontWeight: FontWeight.w600,
                ),
          ),
        ],
      ),
    );
  }
}

class _PreciosTableSource extends DataTableSource {
  _PreciosTableSource({
    required this.items,
    required this.total,
    required this.page,
    required this.limit,
    required this.onUpdate,
  });

  final List<PrecioItem> items;
  final int total;
  final int page;
  final int limit;
  final ValueChanged<PrecioItem> onUpdate;

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
        DataCell(Text(item.tipo.label)),
        DataCell(Text(item.fecha ?? '-')),
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
            onPressed: () => onUpdate(item),
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
