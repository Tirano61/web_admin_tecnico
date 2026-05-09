import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:web_admin_tecnico/core/error/app_failure.dart';
import 'package:web_admin_tecnico/core/utils/paginated_table_prefs.dart';
import 'package:web_admin_tecnico/core/widgets/module_page_layout.dart';
import 'package:web_admin_tecnico/features/liquidaciones/data/liquidaciones_repository_impl.dart';
import 'package:web_admin_tecnico/features/liquidaciones/domain/liquidaciones_repository.dart';
import 'package:web_admin_tecnico/features/liquidaciones/presentation/bloc/liquidaciones_bloc.dart';
import 'package:web_admin_tecnico/features/servicios/data/servicios_repository_impl.dart';
import 'package:web_admin_tecnico/features/servicios/domain/servicios_repository.dart';

class LiquidacionesPage extends StatelessWidget {
  const LiquidacionesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final liquidacionesRepository = LiquidacionesRepositoryImpl();
    final serviciosRepository = ServiciosRepositoryImpl();

    return BlocProvider<LiquidacionesBloc>(
      create: (_) => LiquidacionesBloc(liquidacionesRepository)
        ..add(
          LiquidacionesRequested(
            aprobado: null,
            page: 1,
            limit: 20,
          ),
        ),
      child: _LiquidacionesView(
        liquidacionesRepository: liquidacionesRepository,
        serviciosRepository: serviciosRepository,
      ),
    );
  }
}

class _LiquidacionesView extends StatefulWidget {
  const _LiquidacionesView({
    required this.liquidacionesRepository,
    required this.serviciosRepository,
  });

  final LiquidacionesRepository liquidacionesRepository;
  final ServiciosRepository serviciosRepository;

  @override
  State<_LiquidacionesView> createState() => _LiquidacionesViewState();
}

class _LiquidacionesViewState extends State<_LiquidacionesView> {
  bool? _aprobadoFilter;

  final Map<String, List<LiquidacionItemDetalle>> _localItemsByLiquidacion =
      <String, List<LiquidacionItemDetalle>>{};

  void _requestPage({int page = 1, int? limit}) {
    context.read<LiquidacionesBloc>().add(
          LiquidacionesRequested(
            aprobado: _aprobadoFilter,
            page: page,
            limit: limit ?? 20,
          ),
        );
  }

  String _errorMessage(Object error) {
    if (error is AppFailure) {
      return error.message;
    }

    final text = error.toString().trim();
    if (text.startsWith('Exception: ')) {
      return text.replaceFirst('Exception: ', '').trim();
    }
    return text;
  }

  void _showMessage(String message) {
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  int? _parsePositiveInt(String raw) {
    final value = int.tryParse(raw.trim());
    if (value == null || value <= 0) {
      return null;
    }
    return value;
  }

  double? _parsePositiveDouble(String raw) {
    final normalized = raw.trim().replaceAll(',', '.');
    final value = double.tryParse(normalized);
    if (value == null || value <= 0) {
      return null;
    }
    return value;
  }

  String _formatDate(String? raw) {
    if (raw == null || raw.trim().isEmpty) {
      return '-';
    }

    final parsed = DateTime.tryParse(raw);
    if (parsed == null) {
      return raw;
    }

    String twoDigits(int value) => value.toString().padLeft(2, '0');
    final day = twoDigits(parsed.day);
    final month = twoDigits(parsed.month);
    final year = parsed.year.toString();
    final hour = twoDigits(parsed.hour);
    final minute = twoDigits(parsed.minute);
    return '$day/$month/$year $hour:$minute';
  }

  LiquidacionItemsMeta _buildItemsMeta(List<LiquidacionItemDetalle> items) {
    final total = items.length;
    final aprobados = items.where((item) => item.aprobado).length;
    final subtotal = items.fold<double>(
      0,
      (sum, item) => sum + item.precioUsdSnapshot,
    );

    return LiquidacionItemsMeta(
      totalItems: total,
      aprobados: aprobados,
      pendientes: total - aprobados,
      subtotalUsdTotal: subtotal,
    );
  }

  String? _firstTipoServicioId(List<TipoServicioCatalogoItem> tiposServicio) {
    for (final item in tiposServicio) {
      if (item.activo) {
        return item.id;
      }
    }
    if (tiposServicio.isEmpty) {
      return null;
    }
    return tiposServicio.first.id;
  }

  String? _firstTipoSalidaId(List<TipoSalidaCatalogoItem> tiposSalida) {
    for (final item in tiposSalida) {
      if (item.activo) {
        return item.id;
      }
    }
    if (tiposSalida.isEmpty) {
      return null;
    }
    return tiposSalida.first.id;
  }

  Future<List<ServicioItem>> _loadServiciosCanalCampo() async {
    final output = <ServicioItem>[];
    final seenIds = <String>{};

    var page = 1;
    const limit = 50;
    var total = 0;

    while (page <= 10) {
      final response = await widget.serviciosRepository.fetchServicios(
        query: ServiciosQuery(
          canal: 'campo',
          estado: 'todos',
          page: page,
          limit: limit,
        ),
      );

      total = response.total;
      for (final item in response.items) {
        if (seenIds.add(item.id)) {
          output.add(item);
        }
      }

      if (response.items.isEmpty || output.length >= total) {
        break;
      }

      page += 1;
    }

    return output;
  }

  Future<void> _openCreateDialog(LiquidacionesLoaded state) async {
    List<ServicioItem> serviciosCampo;
    try {
      serviciosCampo = await _loadServiciosCanalCampo();
    } catch (error) {
      _showMessage(_errorMessage(error));
      return;
    }

    if (!mounted) {
      return;
    }

    if (serviciosCampo.isEmpty) {
      _showMessage('No hay servicios de canal campo disponibles para liquidar.');
      return;
    }

    final formKey = GlobalKey<FormState>();
    var selectedServicioId = serviciosCampo.first.id;
    final kmController = TextEditingController();

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: const Color(0xFF102845),
              title: const Text('Nueva liquidacion (canal campo)'),
              content: SizedBox(
                width: 560,
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      DropdownButtonFormField<String>(
                        initialValue: selectedServicioId,
                        decoration: const InputDecoration(
                          labelText: 'Servicio',
                          hintText: 'Selecciona servicio de canal campo',
                        ),
                        items: serviciosCampo
                            .map(
                              (servicio) => DropdownMenuItem<String>(
                                value: servicio.id,
                                child: Text(
                                  '${servicio.id} - ${servicio.descripcion}',
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            )
                            .toList(),
                        onChanged: (value) {
                          if (value == null) {
                            return;
                          }
                          setDialogState(() => selectedServicioId = value);
                        },
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Selecciona un servicio canal campo';
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
                              servicioId: selectedServicioId,
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
      },
    );

    kmController.dispose();
  }

  Future<void> _openEditHeaderDialog(
    LiquidacionesLoaded state,
    LiquidacionItem item,
  ) async {
    if (item.aprobada) {
      _showMessage('La liquidacion aprobada no permite editar cabecera.');
      return;
    }

    final formKey = GlobalKey<FormState>();
    final manualTipoSalidaController = TextEditingController();
    String? selectedTipoSalidaId = item.tipoSalidaId ?? _firstTipoSalidaId(state.tiposSalida);

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
                child: SizedBox(
                  width: 520,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      _LiquidacionInfoLine(label: 'Liquidacion ID', value: item.id),
                      const SizedBox(height: 10),
                      if (hasCatalog)
                        DropdownButtonFormField<String>(
                          initialValue: selectedTipoSalidaId,
                          decoration: const InputDecoration(
                            labelText: 'Tipo salida',
                          ),
                          items: state.tiposSalida
                              .map(
                                (tipo) => DropdownMenuItem<String>(
                                  value: tipo.id,
                                  child: Text(
                                    '${tipo.nombre} - USD ${tipo.precioUsd.toStringAsFixed(2)}',
                                  ),
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
    if (item.aprobada) {
      _showMessage('La liquidacion ya se encuentra aprobada.');
      return;
    }

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

  Future<void> _openTipoSalidaFormDialog({
    TipoSalidaCatalogoItem? initialItem,
  }) async {
    final isEdit = initialItem != null;
    final formKey = GlobalKey<FormState>();
    final nombreController = TextEditingController(text: initialItem?.nombre ?? '');
    final precioController = TextEditingController(
      text: initialItem == null ? '' : initialItem.precioUsd.toStringAsFixed(2),
    );
    final kmHastaController = TextEditingController(
      text: initialItem?.kmHasta?.toString() ?? '',
    );
    var activo = initialItem?.activo ?? true;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: const Color(0xFF102845),
              title: Text(isEdit ? 'Editar tipo salida' : 'Nuevo tipo salida'),
              content: SizedBox(
                width: 500,
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      TextFormField(
                        controller: nombreController,
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
                        controller: precioController,
                        keyboardType:
                            const TextInputType.numberWithOptions(decimal: true),
                        style: const TextStyle(color: Color(0xFFEAF3FF)),
                        decoration: const InputDecoration(labelText: 'Precio USD'),
                        validator: (value) {
                          if (_parsePositiveDouble(value ?? '') == null) {
                            return 'Ingresa un precio USD mayor a 0';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 10),
                      TextFormField(
                        controller: kmHastaController,
                        keyboardType: TextInputType.number,
                        style: const TextStyle(color: Color(0xFFEAF3FF)),
                        decoration: const InputDecoration(
                          labelText: 'KM hasta (opcional)',
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return null;
                          }
                          if (_parsePositiveInt(value) == null) {
                            return 'Ingresa un numero mayor a 0';
                          }
                          return null;
                        },
                      ),
                      if (isEdit) ...<Widget>[
                        const SizedBox(height: 10),
                        SwitchListTile.adaptive(
                          value: activo,
                          onChanged: (value) => setDialogState(() => activo = value),
                          title: const Text('Activo'),
                          contentPadding: EdgeInsets.zero,
                        ),
                      ],
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
                    if (!(formKey.currentState?.validate() ?? false)) {
                      return;
                    }

                    final precio = _parsePositiveDouble(precioController.text);
                    if (precio == null) {
                      return;
                    }

                    final kmRaw = kmHastaController.text.trim();
                    final kmHasta = kmRaw.isEmpty ? null : _parsePositiveInt(kmRaw);

                    if (isEdit) {
                      context.read<LiquidacionesBloc>().add(
                            LiquidacionesUpdateTipoSalidaRequested(
                              input: UpdateTipoSalidaInput(
                                id: initialItem.id,
                                nombre: nombreController.text.trim(),
                                precioUsd: precio,
                                kmHasta: kmHasta,
                                activo: activo,
                              ),
                            ),
                          );
                    } else {
                      context.read<LiquidacionesBloc>().add(
                            LiquidacionesCreateTipoSalidaRequested(
                              input: CreateTipoSalidaInput(
                                nombre: nombreController.text.trim(),
                                precioUsd: precio,
                                kmHasta: kmHasta,
                              ),
                            ),
                          );
                    }

                    Navigator.of(dialogContext).pop();
                  },
                  child: Text(isEdit ? 'Guardar' : 'Crear'),
                ),
              ],
            );
          },
        );
      },
    );

    nombreController.dispose();
    precioController.dispose();
    kmHastaController.dispose();
  }

  Future<void> _openTipoServicioFormDialog({
    TipoServicioCatalogoItem? initialItem,
  }) async {
    final isEdit = initialItem != null;
    final formKey = GlobalKey<FormState>();
    final nombreController = TextEditingController(text: initialItem?.nombre ?? '');
    final precioController = TextEditingController(
      text: initialItem == null ? '' : initialItem.precioUsd.toStringAsFixed(2),
    );
    var activo = initialItem?.activo ?? true;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: const Color(0xFF102845),
              title: Text(isEdit ? 'Editar tipo servicio' : 'Nuevo tipo servicio'),
              content: SizedBox(
                width: 460,
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      TextFormField(
                        controller: nombreController,
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
                        controller: precioController,
                        keyboardType:
                            const TextInputType.numberWithOptions(decimal: true),
                        style: const TextStyle(color: Color(0xFFEAF3FF)),
                        decoration: const InputDecoration(labelText: 'Precio USD'),
                        validator: (value) {
                          if (_parsePositiveDouble(value ?? '') == null) {
                            return 'Ingresa un precio USD mayor a 0';
                          }
                          return null;
                        },
                      ),
                      if (isEdit) ...<Widget>[
                        const SizedBox(height: 10),
                        SwitchListTile.adaptive(
                          value: activo,
                          onChanged: (value) => setDialogState(() => activo = value),
                          title: const Text('Activo'),
                          contentPadding: EdgeInsets.zero,
                        ),
                      ],
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
                    if (!(formKey.currentState?.validate() ?? false)) {
                      return;
                    }

                    final precio = _parsePositiveDouble(precioController.text);
                    if (precio == null) {
                      return;
                    }

                    if (isEdit) {
                      context.read<LiquidacionesBloc>().add(
                            LiquidacionesUpdateTipoServicioRequested(
                              input: UpdateTipoServicioInput(
                                id: initialItem.id,
                                nombre: nombreController.text.trim(),
                                precioUsd: precio,
                                activo: activo,
                              ),
                            ),
                          );
                    } else {
                      context.read<LiquidacionesBloc>().add(
                            LiquidacionesCreateTipoServicioRequested(
                              input: CreateTipoServicioInput(
                                nombre: nombreController.text.trim(),
                                precioUsd: precio,
                              ),
                            ),
                          );
                    }

                    Navigator.of(dialogContext).pop();
                  },
                  child: Text(isEdit ? 'Guardar' : 'Crear'),
                ),
              ],
            );
          },
        );
      },
    );

    nombreController.dispose();
    precioController.dispose();
  }

  Future<void> _openTiposSalidaDialog(LiquidacionesLoaded fallbackState) async {
    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return Dialog(
          backgroundColor: const Color(0xFF102845),
          child: SizedBox(
            width: 820,
            height: 520,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: BlocBuilder<LiquidacionesBloc, LiquidacionesState>(
                builder: (context, state) {
                  final loadedState =
                      state is LiquidacionesLoaded ? state : fallbackState;
                  final tiposSalida = loadedState.tiposSalida;

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Row(
                        children: <Widget>[
                          Text(
                            'Tipos de salida',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(fontWeight: FontWeight.w700),
                          ),
                          const Spacer(),
                          OutlinedButton.icon(
                            onPressed: () => _openTipoSalidaFormDialog(),
                            icon: const Icon(Icons.add, size: 18),
                            label: const Text('Nuevo tipo'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Expanded(
                        child: tiposSalida.isEmpty
                            ? const Center(
                                child: Text('No hay tipos de salida cargados.'),
                              )
                            : ListView.separated(
                                itemCount: tiposSalida.length,
                              separatorBuilder: (_, index) => const SizedBox(height: 8),
                                itemBuilder: (context, index) {
                                  final item = tiposSalida[index];
                                  return Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: const Color(0x1F122B4A),
                                      border: Border.all(
                                        color: const Color(0x334EA6FF),
                                      ),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Row(
                                      children: <Widget>[
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: <Widget>[
                                              Text(
                                                item.nombre,
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.w700,
                                                ),
                                              ),
                                              const SizedBox(height: 6),
                                              Wrap(
                                                spacing: 8,
                                                runSpacing: 8,
                                                children: <Widget>[
                                                  ModuleStatusChip(
                                                    label:
                                                        'USD ${item.precioUsd.toStringAsFixed(2)}',
                                                  ),
                                                  ModuleStatusChip(
                                                    label: item.kmHasta == null
                                                        ? 'KM hasta: sin limite'
                                                        : 'KM hasta: ${item.kmHasta}',
                                                  ),
                                                  ModuleStatusChip(
                                                    label: item.activo
                                                        ? 'ACTIVO'
                                                        : 'INACTIVO',
                                                    backgroundColor: item.activo
                                                        ? const Color(0x1F0FA960)
                                                        : const Color(0x1FF4B942),
                                                    foregroundColor: item.activo
                                                        ? const Color(0xFF8FF0BC)
                                                        : const Color(0xFFFFD98B),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                        IconButton(
                                          tooltip: 'Editar tipo salida',
                                          onPressed: () =>
                                              _openTipoSalidaFormDialog(
                                            initialItem: item,
                                          ),
                                          icon: const Icon(Icons.edit_outlined),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                      ),
                      const SizedBox(height: 10),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () => Navigator.of(dialogContext).pop(),
                          child: const Text('Cerrar'),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _openTiposServicioDialog(LiquidacionesLoaded fallbackState) async {
    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return Dialog(
          backgroundColor: const Color(0xFF102845),
          child: SizedBox(
            width: 760,
            height: 500,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: BlocBuilder<LiquidacionesBloc, LiquidacionesState>(
                builder: (context, state) {
                  final loadedState =
                      state is LiquidacionesLoaded ? state : fallbackState;
                  final tiposServicio = loadedState.tiposServicio;

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Row(
                        children: <Widget>[
                          Text(
                            'Tipos de servicio',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(fontWeight: FontWeight.w700),
                          ),
                          const Spacer(),
                          OutlinedButton.icon(
                            onPressed: () => _openTipoServicioFormDialog(),
                            icon: const Icon(Icons.add, size: 18),
                            label: const Text('Nuevo tipo'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Expanded(
                        child: tiposServicio.isEmpty
                            ? const Center(
                                child: Text('No hay tipos de servicio cargados.'),
                              )
                            : ListView.separated(
                                itemCount: tiposServicio.length,
                              separatorBuilder: (_, index) => const SizedBox(height: 8),
                                itemBuilder: (context, index) {
                                  final item = tiposServicio[index];
                                  return Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: const Color(0x1F122B4A),
                                      border: Border.all(
                                        color: const Color(0x334EA6FF),
                                      ),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Row(
                                      children: <Widget>[
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: <Widget>[
                                              Text(
                                                item.nombre,
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.w700,
                                                ),
                                              ),
                                              const SizedBox(height: 6),
                                              Wrap(
                                                spacing: 8,
                                                runSpacing: 8,
                                                children: <Widget>[
                                                  ModuleStatusChip(
                                                    label:
                                                        'USD ${item.precioUsd.toStringAsFixed(2)}',
                                                  ),
                                                  ModuleStatusChip(
                                                    label: item.activo
                                                        ? 'ACTIVO'
                                                        : 'INACTIVO',
                                                    backgroundColor: item.activo
                                                        ? const Color(0x1F0FA960)
                                                        : const Color(0x1FF4B942),
                                                    foregroundColor: item.activo
                                                        ? const Color(0xFF8FF0BC)
                                                        : const Color(0xFFFFD98B),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                        IconButton(
                                          tooltip: 'Editar tipo servicio',
                                          onPressed: () =>
                                              _openTipoServicioFormDialog(
                                            initialItem: item,
                                          ),
                                          icon: const Icon(Icons.edit_outlined),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                      ),
                      const SizedBox(height: 10),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () => Navigator.of(dialogContext).pop(),
                          child: const Text('Cerrar'),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _openItemsDialog(
    LiquidacionesLoaded state,
    LiquidacionItem liquidacion,
  ) async {
    final manualTipoServicioController = TextEditingController();
    final tiposServicioActivos = state.tiposServicio.where((item) => item.activo).toList();

    var selectedTipoServicioId = _firstTipoServicioId(tiposServicioActivos);
    var items = List<LiquidacionItemDetalle>.from(
      _localItemsByLiquidacion[liquidacion.id] ?? const <LiquidacionItemDetalle>[],
    );
    var meta = _buildItemsMeta(items);
    var remoteMode = false;
    var loading = true;
    var actionInProgress = false;
    String? loadError;
    var initialLoadTriggered = false;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogBuildContext, setDialogState) {
            Future<void> loadItems() async {
              setDialogState(() {
                loading = true;
                loadError = null;
              });

              try {
                final response = await widget.liquidacionesRepository
                    .fetchLiquidacionItems(liquidacion.id);

                if (response == null) {
                  remoteMode = false;
                  items = List<LiquidacionItemDetalle>.from(
                    _localItemsByLiquidacion[liquidacion.id] ??
                        const <LiquidacionItemDetalle>[],
                  );
                  meta = _buildItemsMeta(items);
                } else {
                  remoteMode = true;
                  items = List<LiquidacionItemDetalle>.from(response.items);
                  meta = _buildItemsMeta(items);
                  _localItemsByLiquidacion[liquidacion.id] =
                      List<LiquidacionItemDetalle>.from(items);
                }
              } catch (error) {
                remoteMode = false;
                loadError = _errorMessage(error);
                items = List<LiquidacionItemDetalle>.from(
                  _localItemsByLiquidacion[liquidacion.id] ??
                      const <LiquidacionItemDetalle>[],
                );
                meta = _buildItemsMeta(items);
              } finally {
                if (dialogBuildContext.mounted) {
                  setDialogState(() => loading = false);
                }
              }
            }

            Future<void> refreshAfterAction() async {
              if (!remoteMode) {
                return;
              }

              final refreshed = await widget.liquidacionesRepository
                  .fetchLiquidacionItems(liquidacion.id);
              if (refreshed == null) {
                remoteMode = false;
                return;
              }

              items = List<LiquidacionItemDetalle>.from(refreshed.items);
              meta = _buildItemsMeta(items);
              _localItemsByLiquidacion[liquidacion.id] =
                  List<LiquidacionItemDetalle>.from(items);
            }

            Future<void> runItemAction({
              required Future<void> Function() action,
              required String successMessage,
            }) async {
              if (actionInProgress) {
                return;
              }

              final liquidacionesBloc = context.read<LiquidacionesBloc>();

              setDialogState(() => actionInProgress = true);

              try {
                await action();
                await refreshAfterAction();

                _localItemsByLiquidacion[liquidacion.id] =
                    List<LiquidacionItemDetalle>.from(items);

                final currentState = liquidacionesBloc.state;
                if (currentState is LiquidacionesLoaded) {
                  _requestPage(page: currentState.page, limit: currentState.limit);
                }

                _showMessage(successMessage);
              } catch (error) {
                _showMessage(_errorMessage(error));
              } finally {
                if (dialogBuildContext.mounted) {
                  setDialogState(() => actionInProgress = false);
                }
              }
            }

            Future<void> addItem() async {
              if (liquidacion.aprobada) {
                _showMessage('La liquidacion aprobada no permite alta de items.');
                return;
              }

              if (items.length >= 6) {
                _showMessage('La liquidacion ya tiene 6 items.');
                return;
              }

              final hasCatalog = tiposServicioActivos.isNotEmpty;
              final tipoServicioId = hasCatalog
                  ? (selectedTipoServicioId ?? '').trim()
                  : manualTipoServicioController.text.trim();

              if (tipoServicioId.isEmpty) {
                _showMessage('Selecciona un tipo de servicio.');
                return;
              }

              final fallbackTipo = tiposServicioActivos.where((item) => item.id == tipoServicioId);
              final fallbackNombre = fallbackTipo.isEmpty ? '-' : fallbackTipo.first.nombre;
              final fallbackPrecio =
                  fallbackTipo.isEmpty ? 0.0 : fallbackTipo.first.precioUsd;

              await runItemAction(
                action: () async {
                  final created = await widget.liquidacionesRepository.addLiquidacionItem(
                    input: AddLiquidacionItemInput(
                      liquidacionId: liquidacion.id,
                      tipoServicioId: tipoServicioId,
                    ),
                  );

                  final resolved = created ??
                      LiquidacionItemDetalle(
                        id: 'tmp-${DateTime.now().millisecondsSinceEpoch}',
                        tipoServicioId: tipoServicioId,
                        tipoServicioNombre: fallbackNombre,
                        precioUsdSnapshot: fallbackPrecio,
                        aprobado: false,
                        isPersisted: false,
                        createdAt: DateTime.now().toIso8601String(),
                      );

                  items = <LiquidacionItemDetalle>[...items, resolved];
                  meta = _buildItemsMeta(items);
                },
                successMessage: 'Item agregado correctamente',
              );
            }

            Future<void> approveItem(LiquidacionItemDetalle item) async {
              if (liquidacion.aprobada) {
                _showMessage('La liquidacion aprobada no permite aprobar items.');
                return;
              }

              if (item.aprobado) {
                return;
              }

              if (!item.isPersisted) {
                _showMessage('Este item es local y no puede aprobarse aun.');
                return;
              }

              await runItemAction(
                action: () async {
                  await widget.liquidacionesRepository.approveLiquidacionItem(
                    input: ApproveLiquidacionItemInput(
                      liquidacionId: liquidacion.id,
                      itemId: item.id,
                    ),
                  );

                  items = items
                      .map(
                        (candidate) => candidate.id == item.id
                            ? candidate.copyWith(
                                aprobado: true,
                                fechaAprobacion: DateTime.now().toIso8601String(),
                              )
                            : candidate,
                      )
                      .toList();
                  meta = _buildItemsMeta(items);
                },
                successMessage: 'Item aprobado correctamente',
              );
            }

            Future<void> deleteItem(LiquidacionItemDetalle item) async {
              if (liquidacion.aprobada) {
                _showMessage('La liquidacion aprobada no permite eliminar items.');
                return;
              }

              if (item.aprobado) {
                _showMessage('No se puede eliminar un item aprobado.');
                return;
              }

              final accepted = await _confirmDeleteLiquidacionItem(
                dialogContext: dialogBuildContext,
                liquidacionId: liquidacion.id,
                itemId: item.id,
              );
              if (!accepted || !dialogBuildContext.mounted) {
                return;
              }

              if (!item.isPersisted) {
                setDialogState(() {
                  items = items.where((candidate) => candidate.id != item.id).toList();
                  meta = _buildItemsMeta(items);
                });
                _localItemsByLiquidacion[liquidacion.id] =
                    List<LiquidacionItemDetalle>.from(items);
                _showMessage('Item local eliminado correctamente');
                return;
              }

              await runItemAction(
                action: () async {
                  await widget.liquidacionesRepository.deleteLiquidacionItem(
                    input: DeleteLiquidacionItemInput(
                      liquidacionId: liquidacion.id,
                      itemId: item.id,
                    ),
                  );

                  items = items.where((candidate) => candidate.id != item.id).toList();
                  meta = _buildItemsMeta(items);
                },
                successMessage: 'Item eliminado correctamente',
              );
            }

            if (!initialLoadTriggered) {
              initialLoadTriggered = true;
              Future<void>.microtask(loadItems);
            }

            final hasCatalog = tiposServicioActivos.isNotEmpty;
            final addBlocked = liquidacion.aprobada || actionInProgress || items.length >= 6;

            return AlertDialog(
              backgroundColor: const Color(0xFF102845),
              title: const Text('Items de liquidacion'),
              content: SizedBox(
                width: 960,
                child: loading
                    ? const Padding(
                        padding: EdgeInsets.all(28),
                        child: Center(child: CircularProgressIndicator()),
                      )
                    : Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          if (actionInProgress)
                            const Padding(
                              padding: EdgeInsets.only(bottom: 8),
                              child: LinearProgressIndicator(minHeight: 2),
                            ),
                          _LiquidacionInfoLine(
                            label: 'Liquidacion ID',
                            value: liquidacion.id,
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: <Widget>[
                              ModuleStatusChip(
                                label: remoteMode ? 'MODO REMOTO' : 'MODO LOCAL',
                                backgroundColor: remoteMode
                                    ? const Color(0x1F0FA960)
                                    : const Color(0x1FF4B942),
                                foregroundColor: remoteMode
                                    ? const Color(0xFF8FF0BC)
                                    : const Color(0xFFFFD98B),
                              ),
                              ModuleStatusChip(label: 'TOTAL ${meta.totalItems}'),
                              ModuleStatusChip(
                                label: 'APROBADOS ${meta.aprobados}',
                                backgroundColor: const Color(0x1F0FA960),
                                foregroundColor: const Color(0xFF8FF0BC),
                              ),
                              ModuleStatusChip(
                                label: 'PENDIENTES ${meta.pendientes}',
                                backgroundColor: const Color(0x1FF4B942),
                                foregroundColor: const Color(0xFFFFD98B),
                              ),
                              ModuleStatusChip(
                                label:
                                    'SUBTOTAL USD ${meta.subtotalUsdTotal.toStringAsFixed(2)}',
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          if (liquidacion.aprobada)
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: const Color(0x1F0FA960),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: const Color(0x660FA960)),
                              ),
                              child: const Text(
                                'Liquidacion aprobada: cabecera e items en modo solo lectura.',
                              ),
                            )
                          else
                            Container(
                              width: double.infinity,
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
                                    children: <Widget>[
                                      Expanded(
                                        child: hasCatalog
                                            ? DropdownButtonFormField<String>(
                                                initialValue: selectedTipoServicioId,
                                                decoration: const InputDecoration(
                                                  labelText: 'Tipo servicio',
                                                ),
                                                items: tiposServicioActivos
                                                    .map(
                                                      (tipo) =>
                                                          DropdownMenuItem<String>(
                                                        value: tipo.id,
                                                        child: Text(
                                                          '${tipo.nombre} - USD ${tipo.precioUsd.toStringAsFixed(2)}',
                                                        ),
                                                      ),
                                                    )
                                                    .toList(),
                                                onChanged: addBlocked
                                                    ? null
                                                    : (value) {
                                                        setDialogState(
                                                          () => selectedTipoServicioId = value,
                                                        );
                                                      },
                                              )
                                            : TextFormField(
                                                controller:
                                                    manualTipoServicioController,
                                                style: const TextStyle(
                                                  color: Color(0xFFEAF3FF),
                                                ),
                                                decoration: const InputDecoration(
                                                  labelText: 'Tipo servicio ID',
                                                  hintText: 'UUID tipo-servicio',
                                                ),
                                              ),
                                      ),
                                      const SizedBox(width: 8),
                                      FilledButton.icon(
                                        onPressed: addBlocked ? null : addItem,
                                        icon: const Icon(Icons.add, size: 18),
                                        label: const Text('Agregar item'),
                                      ),
                                    ],
                                  ),
                                  if (items.length >= 6) ...<Widget>[
                                    const SizedBox(height: 8),
                                    const Text(
                                      'Se alcanzo el limite de 6 items por liquidacion.',
                                      style: TextStyle(color: Color(0xFFFFD98B)),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          const SizedBox(height: 10),
                          if (loadError != null)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Text(
                                loadError!,
                                style: const TextStyle(color: Color(0xFFFFD98B)),
                              ),
                            ),
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
                                'Esta liquidacion no tiene items cargados todavia.',
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
                                            DataCell(Text(
                                              detalle.precioUsdSnapshot
                                                  .toStringAsFixed(2),
                                            )),
                                            DataCell(
                                              ModuleStatusChip(
                                                label: detalle.aprobado
                                                    ? 'APROBADO'
                                                    : 'PENDIENTE',
                                                backgroundColor: detalle.aprobado
                                                    ? const Color(0x1F0FA960)
                                                    : const Color(0x1FF4B942),
                                                foregroundColor: detalle.aprobado
                                                    ? const Color(0xFF8FF0BC)
                                                    : const Color(0xFFFFD98B),
                                              ),
                                            ),
                                            DataCell(Text(
                                              _formatDate(detalle.fechaAprobacion),
                                            )),
                                            DataCell(Text(
                                              _formatDate(detalle.createdAt),
                                            )),
                                            DataCell(
                                              Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: <Widget>[
                                                  IconButton(
                                                    tooltip: 'Aprobar item',
                                                    onPressed: actionInProgress ||
                                                            liquidacion.aprobada ||
                                                            detalle.aprobado ||
                                                            !detalle.isPersisted
                                                        ? null
                                                        : () => approveItem(detalle),
                                                    icon: const Icon(
                                                      Icons.check_circle_outline,
                                                    ),
                                                  ),
                                                  IconButton(
                                                    tooltip: 'Eliminar item',
                                                    onPressed: actionInProgress ||
                                                            liquidacion.aprobada ||
                                                            detalle.aprobado
                                                        ? null
                                                        : () => deleteItem(detalle),
                                                    icon: const Icon(
                                                      Icons.delete_outline,
                                                    ),
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

    manualTipoServicioController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<LiquidacionesBloc, LiquidacionesState>(
      listenWhen: (previous, current) {
        return current is LiquidacionesFailure ||
            (current is LiquidacionesLoaded &&
                current.message != null &&
                current.message!.trim().isNotEmpty);
      },
      listener: (context, state) {
        if (state is LiquidacionesFailure) {
          _showMessage(state.message);
        }
        if (state is LiquidacionesLoaded && state.message != null) {
          _showMessage(state.message!);
        }
      },
      child: BlocBuilder<LiquidacionesBloc, LiquidacionesState>(
        builder: (context, state) {
          if (state is LiquidacionesLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is LiquidacionesFailure) {
            return Center(child: Text(state.message));
          }

          if (state is LiquidacionesLoaded) {
            final effectiveLimit = state.limit > 0 ? state.limit : 20;
            final rowsPerPage = normalizeRowsPerPage(
              effectiveLimit,
              defaults: const <int>[20, 40, 60],
            );
            final rowsPerPageOptions = buildRowsPerPageOptions(
              effectiveLimit,
              defaults: const <int>[20, 40, 60],
            );
            final initialFirstRowIndex = (state.page - 1) * effectiveLimit;
            final hasFilters = state.aprobado != null;
            final emptyMessage = hasFilters
                ? 'No hay liquidaciones para el filtro seleccionado.'
                : 'No hay liquidaciones disponibles para mostrar.';

            final approvedFilterValue = state.aprobado == null
                ? 'todos'
                : (state.aprobado! ? 'aprobadas' : 'pendientes');

            return ModulePageLayout(
              title: 'Liquidaciones',
              subtitle: 'Gestion de liquidaciones, catalogos e items con control operativo.',
              trailing: Wrap(
                spacing: 8,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: <Widget>[
                  OutlinedButton.icon(
                    onPressed: () => _openCreateDialog(state),
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Nueva liquidacion'),
                  ),
                  OutlinedButton.icon(
                    onPressed: () => _openTiposSalidaDialog(state),
                    icon: const Icon(Icons.outbound_outlined, size: 18),
                    label: const Text('Tipos salida'),
                  ),
                  OutlinedButton.icon(
                    onPressed: () => _openTiposServicioDialog(state),
                    icon: const Icon(Icons.build_outlined, size: 18),
                    label: const Text('Tipos servicio'),
                  ),
                  ModuleStatusChip(label: '${state.total} total'),
                ],
              ),
              child: Column(
                children: <Widget>[
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
                              value: approvedFilterValue,
                              onChanged: (value) {
                                if (value == null) {
                                  return;
                                }

                                bool? approved;
                                if (value == 'aprobadas') {
                                  approved = true;
                                } else if (value == 'pendientes') {
                                  approved = false;
                                } else {
                                  approved = null;
                                }

                                setState(() => _aprobadoFilter = approved);
                                _requestPage(page: 1, limit: effectiveLimit);
                              },
                              items: const <DropdownMenuItem<String>>[
                                DropdownMenuItem(
                                  value: 'todos',
                                  child: Text('TODAS'),
                                ),
                                DropdownMenuItem(
                                  value: 'aprobadas',
                                  child: Text('APROBADAS'),
                                ),
                                DropdownMenuItem(
                                  value: 'pendientes',
                                  child: Text('PENDIENTES'),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: state.items.isEmpty
                        ? Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0x1F122B4A),
                              border: Border.all(color: const Color(0x334EA6FF)),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(emptyMessage),
                          )
                        : Card(
                            child: LayoutBuilder(
                              builder: (context, constraints) {
                                const minTableWidth = 1750.0;
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
                                          'liquidaciones_${state.page}_${state.limit}_${state.total}_${state.aprobado}',
                                        ),
                                        initialFirstRowIndex: initialFirstRowIndex < 0
                                            ? 0
                                            : initialFirstRowIndex,
                                        headingRowColor: WidgetStateProperty.all(
                                          const Color(0x1A4EA6FF),
                                        ),
                                        columns: const <DataColumn>[
                                          DataColumn(label: Text('ID')),
                                          DataColumn(label: Text('Servicio')),
                                          DataColumn(label: Text('Canal')),
                                          DataColumn(label: Text('Tecnico')),
                                          DataColumn(label: Text('Tipo salida')),
                                          DataColumn(label: Text('Tipo salida USD')),
                                          DataColumn(label: Text('KM')),
                                          DataColumn(label: Text('KM USD snapshot')),
                                          DataColumn(label: Text('Subtotal estimado USD')),
                                          DataColumn(label: Text('Estado')),
                                          DataColumn(label: Text('Fecha aprobacion')),
                                          DataColumn(label: Text('Acciones')),
                                        ],
                                        source: _LiquidacionesTableSource(
                                          items: state.items,
                                          total: state.total,
                                          page: state.page,
                                          limit: effectiveLimit,
                                          formatDate: _formatDate,
                                          onEditHeader: (item) =>
                                              _openEditHeaderDialog(state, item),
                                          onApproveLiquidacion:
                                              _confirmApproveLiquidacion,
                                          onManageItems: (item) =>
                                              _openItemsDialog(state, item),
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
                                          final nextPage =
                                              (firstRowIndex ~/ effectiveLimit) + 1;
                                          if (nextPage != state.page) {
                                            _requestPage(
                                              page: nextPage,
                                              limit: effectiveLimit,
                                            );
                                          }
                                        },
                                        showFirstLastButtons: true,
                                      ),
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

class _LiquidacionesTableSource extends DataTableSource {
  _LiquidacionesTableSource({
    required this.items,
    required this.total,
    required this.page,
    required this.limit,
    required this.formatDate,
    required this.onEditHeader,
    required this.onApproveLiquidacion,
    required this.onManageItems,
  });

  final List<LiquidacionItem> items;
  final int total;
  final int page;
  final int limit;
  final String Function(String? raw) formatDate;
  final ValueChanged<LiquidacionItem> onEditHeader;
  final ValueChanged<LiquidacionItem> onApproveLiquidacion;
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
            label: item.servicioCanal.toUpperCase(),
          ),
        ),
        DataCell(Text(item.tecnicoNombre ?? item.tecnicoEmail ?? '-')),
        DataCell(Text(item.tipoSalidaNombre ?? '-')),
        DataCell(Text(item.tipoSalidaPrecioUsd.toStringAsFixed(2))),
        DataCell(Text(item.km.toString())),
        DataCell(Text(item.precioKmUsdSnapshot.toStringAsFixed(4))),
        DataCell(
          ModuleStatusChip(
            label: item.subtotalEstimadoUsd.toStringAsFixed(2),
            backgroundColor: const Color(0x1F0FA960),
            foregroundColor: const Color(0xFF8FF0BC),
          ),
        ),
        DataCell(_AprobadaChip(aprobada: approved)),
        DataCell(Text(formatDate(item.fechaAprobacion))),
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
                case 'items':
                  onManageItems(item);
                  break;
              }
            },
            itemBuilder: (context) => <PopupMenuEntry<String>>[
              PopupMenuItem<String>(
                value: 'editar',
                enabled: !approved,
                child: Text(
                  approved
                      ? 'Editar cabecera (bloqueado)'
                      : 'Editar cabecera',
                ),
              ),
              PopupMenuItem<String>(
                value: 'aprobar',
                enabled: !approved,
                child: Text(
                  approved
                      ? 'Aprobar liquidacion (ya aprobada)'
                      : 'Aprobar liquidacion',
                ),
              ),
              const PopupMenuDivider(),
              const PopupMenuItem<String>(
                value: 'items',
                child: Text('Gestionar items'),
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

class _AprobadaChip extends StatelessWidget {
  const _AprobadaChip({required this.aprobada});

  final bool aprobada;

  @override
  Widget build(BuildContext context) {
    return ModuleStatusChip(
      label: aprobada ? 'APROBADA' : 'PENDIENTE',
      backgroundColor:
          aprobada ? const Color(0x1F0FA960) : const Color(0x1FF4B942),
      foregroundColor:
          aprobada ? const Color(0xFF8FF0BC) : const Color(0xFFFFD98B),
    );
  }
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
