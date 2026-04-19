import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:web_admin_tecnico/core/error/app_failure.dart';
import 'package:web_admin_tecnico/core/utils/paginated_table_prefs.dart';
import 'package:web_admin_tecnico/core/widgets/module_page_layout.dart';
import 'package:web_admin_tecnico/features/liquidaciones/data/liquidaciones_repository_impl.dart';
import 'package:web_admin_tecnico/features/liquidaciones/domain/liquidaciones_repository.dart';
import 'package:web_admin_tecnico/features/liquidaciones/presentation/bloc/liquidaciones_bloc.dart';

class LiquidacionesPage extends StatelessWidget {
  const LiquidacionesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final repository = LiquidacionesRepositoryImpl();

    return BlocProvider<LiquidacionesBloc>(
      create: (_) => LiquidacionesBloc(repository)..add(LiquidacionesRequested()),
      child: _LiquidacionesView(repository: repository),
    );
  }
}

class _LiquidacionesView extends StatefulWidget {
  const _LiquidacionesView({required this.repository});

  final LiquidacionesRepository repository;

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

  int? _parsePositiveInt(String raw) {
    final value = int.tryParse(raw.trim());
    if (value == null || value <= 0) {
      return null;
    }
    return value;
  }

  String _resolveApiErrorMessage(
    Object error, {
    required String fallback,
  }) {
    if (error is AppFailure) {
      final statusCode = error.statusCode;
      if (statusCode == 401) {
        return 'Sesion expirada. Inicia sesion nuevamente.';
      }
      if (statusCode == 403) {
        return 'No tienes permisos para realizar esta accion.';
      }
      if (statusCode == 404) {
        return 'No se encontro el recurso solicitado.';
      }
      if (statusCode != null && statusCode >= 500) {
        return 'Error del servidor. Intenta nuevamente en unos segundos.';
      }
      if (error.message.trim().isNotEmpty) {
        return error.message;
      }
      return fallback;
    }

    final text = error.toString().trim();
    if (text.isEmpty) {
      return fallback;
    }
    return text;
  }

  Future<bool> _confirmDeleteLiquidacionItem({
    required BuildContext dialogContext,
    required String liquidacionId,
    required String itemId,
  }) async {
    final accepted = await showDialog<bool>(
      context: dialogContext,
      builder: (confirmContext) {
        return AlertDialog(
          backgroundColor: const Color(0xFF102845),
          title: const Text('Eliminar item'),
          content: Text(
            'Se eliminara el item $itemId de la liquidacion $liquidacionId. Esta accion no se puede deshacer.\n\nDeseas continuar?',
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(confirmContext).pop(false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(confirmContext).pop(true),
              child: const Text('Eliminar'),
            ),
          ],
        );
      },
    );

    return accepted ?? false;
  }

  Future<void> _openCreateDialog() async {
    final formKey = GlobalKey<FormState>();
    final servicioIdController = TextEditingController();
    final kmController = TextEditingController();

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: const Color(0xFF102845),
          title: const Text('Nueva liquidacion'),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                TextFormField(
                  controller: servicioIdController,
                  autofocus: true,
                  style: const TextStyle(color: Color(0xFFEAF3FF)),
                  decoration: const InputDecoration(
                    labelText: 'Servicio ID',
                    hintText: 'UUID del servicio (canal campo)',
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'El servicio ID es obligatorio';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: kmController,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(color: Color(0xFFEAF3FF)),
                  decoration: const InputDecoration(
                    labelText: 'KM',
                    hintText: 'Ej: 140',
                  ),
                  validator: (value) {
                    if (_parsePositiveInt(value ?? '') == null) {
                      return 'Ingresa un numero mayor a 0';
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
                if (!(formKey.currentState?.validate() ?? false)) {
                  return;
                }
                final km = _parsePositiveInt(kmController.text);
                if (km == null) {
                  return;
                }

                context.read<LiquidacionesBloc>().add(
                      LiquidacionesCreateRequested(
                        input: CreateLiquidacionInput(
                          servicioId: servicioIdController.text,
                          km: km,
                        ),
                      ),
                    );
                Navigator.of(dialogContext).pop();
              },
              child: const Text('Crear'),
            ),
          ],
        );
      },
    );

    servicioIdController.dispose();
    kmController.dispose();
  }

  Future<void> _openEditHeaderDialog(
    LiquidacionesLoaded state,
    LiquidacionItem item,
  ) async {
    final formKey = GlobalKey<FormState>();
    final manualTipoSalidaController = TextEditingController();
    String? selectedTipoSalidaId = state.tiposSalida.isNotEmpty ? state.tiposSalida.first.id : null;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final hasCatalog = state.tiposSalida.isNotEmpty;
            return AlertDialog(
              backgroundColor: const Color(0xFF102845),
              title: const Text('Editar cabecera de liquidacion'),
              content: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    _LiquidacionInfoLine(label: 'Liquidacion ID', value: item.id),
                    const SizedBox(height: 10),
                    if (hasCatalog)
                      DropdownButtonFormField<String>(
                        initialValue: selectedTipoSalidaId,
                        decoration: const InputDecoration(labelText: 'Tipo salida'),
                        items: state.tiposSalida
                            .map(
                              (tipo) => DropdownMenuItem<String>(
                                value: tipo.id,
                                child: Text(tipo.nombre),
                              ),
                            )
                            .toList(),
                        onChanged: (value) {
                          setDialogState(() => selectedTipoSalidaId = value);
                        },
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Selecciona un tipo salida';
                          }
                          return null;
                        },
                      )
                    else
                      TextFormField(
                        controller: manualTipoSalidaController,
                        autofocus: true,
                        style: const TextStyle(color: Color(0xFFEAF3FF)),
                        decoration: const InputDecoration(
                          labelText: 'Tipo salida ID',
                          hintText: 'UUID tipo-salida',
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Ingresa un tipo salida ID';
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
                    if (!(formKey.currentState?.validate() ?? false)) {
                      return;
                    }

                    final tipoSalidaId = hasCatalog
                        ? (selectedTipoSalidaId ?? '').trim()
                        : manualTipoSalidaController.text.trim();
                    if (tipoSalidaId.isEmpty) {
                      return;
                    }

                    context.read<LiquidacionesBloc>().add(
                          LiquidacionesUpdateRequested(
                            input: UpdateLiquidacionInput(
                              liquidacionId: item.id,
                              tipoSalidaId: tipoSalidaId,
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
      },
    );

    manualTipoSalidaController.dispose();
  }

  Future<void> _confirmApproveLiquidacion(LiquidacionItem item) async {
    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: const Color(0xFF102845),
          title: const Text('Aprobar liquidacion'),
          content: Text('Confirma aprobar la liquidacion ${item.id}?'),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () {
                context.read<LiquidacionesBloc>().add(
                      LiquidacionesApproveRequested(item.id),
                    );
                Navigator.of(dialogContext).pop();
              },
              child: const Text('Aprobar'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _openAddItemDialog(
    LiquidacionesLoaded state,
    LiquidacionItem item,
  ) async {
    final formKey = GlobalKey<FormState>();
    final manualTipoServicioController = TextEditingController();
    String? selectedTipoServicioId =
        state.tiposServicio.isNotEmpty ? state.tiposServicio.first.id : null;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final hasCatalog = state.tiposServicio.isNotEmpty;
            return AlertDialog(
              backgroundColor: const Color(0xFF102845),
              title: const Text('Agregar item a liquidacion'),
              content: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    _LiquidacionInfoLine(label: 'Liquidacion ID', value: item.id),
                    const SizedBox(height: 10),
                    if (hasCatalog)
                      DropdownButtonFormField<String>(
                        initialValue: selectedTipoServicioId,
                        decoration: const InputDecoration(labelText: 'Tipo servicio'),
                        items: state.tiposServicio
                            .map(
                              (tipo) => DropdownMenuItem<String>(
                                value: tipo.id,
                                child: Text(tipo.nombre),
                              ),
                            )
                            .toList(),
                        onChanged: (value) {
                          setDialogState(() => selectedTipoServicioId = value);
                        },
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Selecciona un tipo servicio';
                          }
                          return null;
                        },
                      )
                    else
                      TextFormField(
                        controller: manualTipoServicioController,
                        autofocus: true,
                        style: const TextStyle(color: Color(0xFFEAF3FF)),
                        decoration: const InputDecoration(
                          labelText: 'Tipo servicio ID',
                          hintText: 'UUID tipo-servicio',
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Ingresa un tipo servicio ID';
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
                    if (!(formKey.currentState?.validate() ?? false)) {
                      return;
                    }

                    final tipoServicioId = hasCatalog
                        ? (selectedTipoServicioId ?? '').trim()
                        : manualTipoServicioController.text.trim();
                    if (tipoServicioId.isEmpty) {
                      return;
                    }

                    context.read<LiquidacionesBloc>().add(
                          LiquidacionesAddItemRequested(
                            input: AddLiquidacionItemInput(
                              liquidacionId: item.id,
                              tipoServicioId: tipoServicioId,
                            ),
                          ),
                        );
                    Navigator.of(dialogContext).pop();
                  },
                  child: const Text('Agregar'),
                ),
              ],
            );
          },
        );
      },
    );

    manualTipoServicioController.dispose();
  }

  Future<void> _openItemsDialog(LiquidacionItem liquidacion) async {
    Future<LiquidacionItemsResponse> itemsFuture =
        widget.repository.fetchLiquidacionItems(liquidacion.id);
    bool actionInProgress = false;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogBuildContext, setDialogState) {
            Future<void> runItemAction({
              required Future<void> Function() action,
              required String successMessage,
              required String errorFallback,
            }) async {
              if (actionInProgress) {
                return;
              }

              setDialogState(() => actionInProgress = true);

              try {
                await action();
                if (!mounted) {
                  return;
                }

                final currentState = context.read<LiquidacionesBloc>().state;
                if (currentState is LiquidacionesLoaded) {
                  _requestPage(page: currentState.page, limit: currentState.limit);
                } else {
                  _requestPage();
                }

                setDialogState(() {
                  itemsFuture = widget.repository.fetchLiquidacionItems(liquidacion.id);
                });

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(successMessage)),
                );
              } catch (error) {
                if (!mounted) {
                  return;
                }
                final message = _resolveApiErrorMessage(
                  error,
                  fallback: errorFallback,
                );
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(message)),
                );
              } finally {
                if (dialogBuildContext.mounted) {
                  setDialogState(() => actionInProgress = false);
                }
              }
            }

            return AlertDialog(
              backgroundColor: const Color(0xFF102845),
              title: const Text('Items de liquidacion'),
              content: SizedBox(
                width: 920,
                child: FutureBuilder<LiquidacionItemsResponse>(
                  future: itemsFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Padding(
                        padding: EdgeInsets.all(28),
                        child: Center(child: CircularProgressIndicator()),
                      );
                    }

                    if (snapshot.hasError || !snapshot.hasData) {
                      final loadError = _resolveApiErrorMessage(
                        snapshot.error ?? Exception('Error desconocido'),
                        fallback: 'No se pudieron cargar los items de la liquidacion.',
                      );
                      return Text(
                        loadError,
                        style: Theme.of(context).textTheme.bodyMedium,
                      );
                    }

                    final response = snapshot.data!;
                    final items = response.items;

                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        if (actionInProgress) const LinearProgressIndicator(minHeight: 2),
                        _LiquidacionInfoLine(label: 'Liquidacion ID', value: response.liquidacionId),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: <Widget>[
                            ModuleStatusChip(label: 'TOTAL ${response.meta.totalItems}'),
                            ModuleStatusChip(
                              label: 'APROBADOS ${response.meta.aprobados}',
                              backgroundColor: const Color(0x1F0FA960),
                              foregroundColor: const Color(0xFF8FF0BC),
                            ),
                            ModuleStatusChip(
                              label: 'PENDIENTES ${response.meta.pendientes}',
                              backgroundColor: const Color(0x1FF4B942),
                              foregroundColor: const Color(0xFFFFD98B),
                            ),
                            ModuleStatusChip(
                              label: 'SUBTOTAL USD ${response.meta.subtotalUsdTotal.toStringAsFixed(2)}',
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        if (items.isEmpty)
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: const Color(0x1F122B4A),
                              border: Border.all(color: const Color(0x334EA6FF)),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Text(
                              'Esta liquidacion no tiene items cargados todavia. Agrega items desde Acciones > Agregar item.',
                            ),
                          )
                        else
                          SizedBox(
                            height: 320,
                            child: SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: DataTable(
                                columns: const <DataColumn>[
                                  DataColumn(label: Text('Item ID')),
                                  DataColumn(label: Text('Tipo servicio')),
                                  DataColumn(label: Text('Precio USD')),
                                  DataColumn(label: Text('Estado')),
                                  DataColumn(label: Text('Aprobacion')),
                                  DataColumn(label: Text('Creado')),
                                  DataColumn(label: Text('Acciones')),
                                ],
                                rows: items
                                    .map(
                                      (detalle) => DataRow(
                                        cells: <DataCell>[
                                          DataCell(Text(detalle.id)),
                                          DataCell(Text(detalle.tipoServicioNombre)),
                                          DataCell(Text(detalle.precioUsdSnapshot.toStringAsFixed(2))),
                                          DataCell(
                                            ModuleStatusChip(
                                              label: detalle.aprobado ? 'APROBADO' : 'PENDIENTE',
                                              backgroundColor: detalle.aprobado
                                                  ? const Color(0x1F0FA960)
                                                  : const Color(0x1FF4B942),
                                              foregroundColor: detalle.aprobado
                                                  ? const Color(0xFF8FF0BC)
                                                  : const Color(0xFFFFD98B),
                                            ),
                                          ),
                                          DataCell(Text(detalle.fechaAprobacion ?? '-')),
                                          DataCell(Text(detalle.createdAt ?? '-')),
                                          DataCell(
                                            Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: <Widget>[
                                                IconButton(
                                                  tooltip: 'Aprobar item',
                                                  onPressed: actionInProgress || detalle.aprobado
                                                      ? null
                                                      : () {
                                                          runItemAction(
                                                            action: () =>
                                                                widget.repository.approveLiquidacionItem(
                                                              input: ApproveLiquidacionItemInput(
                                                                liquidacionId: response.liquidacionId,
                                                                itemId: detalle.id,
                                                              ),
                                                            ),
                                                            successMessage:
                                                                'Item aprobado correctamente',
                                                            errorFallback:
                                                                'No se pudo aprobar el item de liquidacion.',
                                                          );
                                                        },
                                                  icon: const Icon(Icons.check_circle_outline),
                                                ),
                                                IconButton(
                                                  tooltip: 'Eliminar item',
                                                  onPressed: actionInProgress
                                                      ? null
                                                      : () async {
                                                          final accepted = await _confirmDeleteLiquidacionItem(
                                                            dialogContext: dialogBuildContext,
                                                            liquidacionId: response.liquidacionId,
                                                            itemId: detalle.id,
                                                          );
                                                          if (!accepted || !dialogBuildContext.mounted) {
                                                            return;
                                                          }

                                                          await runItemAction(
                                                            action: () =>
                                                                widget.repository.deleteLiquidacionItem(
                                                              input: DeleteLiquidacionItemInput(
                                                                liquidacionId: response.liquidacionId,
                                                                itemId: detalle.id,
                                                              ),
                                                            ),
                                                            successMessage:
                                                                'Item eliminado correctamente',
                                                            errorFallback:
                                                                'No se pudo eliminar el item de liquidacion.',
                                                          );
                                                        },
                                                  icon: const Icon(Icons.delete_outline),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    )
                                    .toList(),
                              ),
                            ),
                          ),
                      ],
                    );
                  },
                ),
              ),
              actions: <Widget>[
                TextButton(
                  onPressed: actionInProgress ? null : () => Navigator.of(dialogContext).pop(),
                  child: const Text('Cerrar'),
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
    return BlocListener<LiquidacionesBloc, LiquidacionesState>(
      listenWhen: (previous, current) {
        return current is LiquidacionesFailure ||
            (current is LiquidacionesLoaded &&
                current.message != null &&
                current.message!.isNotEmpty);
      },
      listener: (context, state) {
        if (state is LiquidacionesFailure) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: ${state.message}')),
          );
        }
        if (state is LiquidacionesLoaded && state.message != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message!)),
          );
        }
      },
      child: BlocBuilder<LiquidacionesBloc, LiquidacionesState>(
        builder: (context, state) {
          if (state is LiquidacionesLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is LiquidacionesFailure) {
            return Center(child: Text('Error: ${state.message}'));
          }

          if (state is LiquidacionesLoaded) {
            final rowsPerPage = normalizeRowsPerPage(state.limit);
            final rowsPerPageOptions = buildRowsPerPageOptions(state.limit);
            return ModulePageLayout(
              title: 'Liquidaciones',
              subtitle: 'Alta, aprobacion y gestion de items de liquidacion tecnica.',
              trailing: Wrap(
                spacing: 8,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: <Widget>[
                  OutlinedButton.icon(
                    onPressed: _openCreateDialog,
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Nueva liquidacion'),
                  ),
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
                          DataColumn(label: Text('Acciones')),
                        ],
                        source: _LiquidacionesTableSource(
                          items: state.items,
                          total: state.total,
                          page: state.page,
                          limit: state.limit,
                          onEditHeader: (item) => _openEditHeaderDialog(state, item),
                          onApproveLiquidacion: _confirmApproveLiquidacion,
                          onAddItem: (item) => _openAddItemDialog(state, item),
                          onManageItems: _openItemsDialog,
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

class _LiquidacionesTableSource extends DataTableSource {
  _LiquidacionesTableSource({
    required this.items,
    required this.total,
    required this.page,
    required this.limit,
    required this.onEditHeader,
    required this.onApproveLiquidacion,
    required this.onAddItem,
    required this.onManageItems,
  });

  final List<LiquidacionItem> items;
  final int total;
  final int page;
  final int limit;
  final ValueChanged<LiquidacionItem> onEditHeader;
  final ValueChanged<LiquidacionItem> onApproveLiquidacion;
  final ValueChanged<LiquidacionItem> onAddItem;
  final ValueChanged<LiquidacionItem> onManageItems;

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
            label: item.estado?.toUpperCase() ?? (approved ? 'APROBADA' : 'PENDIENTE'),
            backgroundColor: approved ? const Color(0x1F0FA960) : const Color(0x1FF4B942),
            foregroundColor: approved ? const Color(0xFF8FF0BC) : const Color(0xFFFFD98B),
          ),
        ),
        DataCell(
          PopupMenuButton<String>(
            tooltip: 'Acciones',
            icon: const Icon(Icons.more_horiz),
            onSelected: (value) {
              switch (value) {
                case 'editar':
                  onEditHeader(item);
                  break;
                case 'aprobar':
                  onApproveLiquidacion(item);
                  break;
                case 'agregar_item':
                  onAddItem(item);
                  break;
                case 'ver_items':
                  onManageItems(item);
                  break;
              }
            },
            itemBuilder: (context) => const <PopupMenuEntry<String>>[
              PopupMenuItem<String>(
                value: 'editar',
                child: Text('Editar cabecera'),
              ),
              PopupMenuItem<String>(
                value: 'aprobar',
                child: Text('Aprobar liquidacion'),
              ),
              PopupMenuDivider(),
              PopupMenuItem<String>(
                value: 'agregar_item',
                child: Text('Agregar item'),
              ),
              PopupMenuItem<String>(
                value: 'ver_items',
                child: Text('Ver items'),
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

class _LiquidacionInfoLine extends StatelessWidget {
  const _LiquidacionInfoLine({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Text(
          '$label: ',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: const Color(0xFF9AB1CC),
                fontWeight: FontWeight.w600,
              ),
        ),
        Expanded(
          child: Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: const Color(0xFFEAF3FF),
                ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}