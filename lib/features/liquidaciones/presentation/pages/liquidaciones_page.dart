import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:web_admin_tecnico/core/error/app_failure.dart';
import 'package:web_admin_tecnico/core/utils/paginated_table_prefs.dart';
import 'package:web_admin_tecnico/core/widgets/module_page_layout.dart';
import 'package:web_admin_tecnico/features/liquidaciones/data/liquidaciones_repository_impl.dart';
import 'package:web_admin_tecnico/features/liquidaciones/domain/liquidacion_pago_calculator.dart';
import 'package:web_admin_tecnico/features/liquidaciones/domain/liquidaciones_repository.dart';
import 'package:web_admin_tecnico/features/liquidaciones/presentation/bloc/liquidaciones_bloc.dart';
import 'package:web_admin_tecnico/features/servicios/presentation/pages/servicio_detalle_page.dart';

enum _LiquidacionesPanelView {
  pendientes,
  creadas,
  tiposSalida,
  tiposServicio,
}

class LiquidacionesPage extends StatelessWidget {
  const LiquidacionesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final liquidacionesRepository = LiquidacionesRepositoryImpl();

    return BlocProvider<LiquidacionesBloc>(
      create: (_) => LiquidacionesBloc(liquidacionesRepository)
        ..add(
          LiquidacionesRequested(
            tecnicoId: null,
            aprobado: null,
            liquidacionesPage: 1,
            liquidacionesLimit: 20,
            pendientesPage: 1,
            pendientesLimit: 20,
          ),
        ),
      child: _LiquidacionesView(
        liquidacionesRepository: liquidacionesRepository,
      ),
    );
  }
}

class _LiquidacionesView extends StatefulWidget {
  const _LiquidacionesView({
    required this.liquidacionesRepository,
  });

  final LiquidacionesRepository liquidacionesRepository;

  @override
  State<_LiquidacionesView> createState() => _LiquidacionesViewState();
}

class _LiquidacionesViewState extends State<_LiquidacionesView> {
  bool? _aprobadoFilter;
  String? _tecnicoFilterId;
  _LiquidacionesPanelView _activeView = _LiquidacionesPanelView.pendientes;

  void _requestDashboard({
    required int liquidacionesPage,
    required int liquidacionesLimit,
    required int pendientesPage,
    required int pendientesLimit,
  }) {
    final approvedFilter =
        _activeView == _LiquidacionesPanelView.creadas ? true : _aprobadoFilter;
    final estadoFilter =
        _activeView == _LiquidacionesPanelView.creadas ? 'aprobada' : null;
    context.read<LiquidacionesBloc>().add(
          LiquidacionesRequested(
            tecnicoId: _tecnicoFilterId,
            aprobado: approvedFilter,
            estado: estadoFilter,
            liquidacionesPage: liquidacionesPage,
            liquidacionesLimit: liquidacionesLimit,
            pendientesPage: pendientesPage,
            pendientesLimit: pendientesLimit,
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

  List<LiquidacionItemDetalle> _cachedItemsForLiquidacion({
    required LiquidacionesBloc bloc,
    required String liquidacionId,
  }) {
    final current = bloc.state;
    if (current is! LiquidacionesLoaded) {
      return const <LiquidacionItemDetalle>[];
    }

    final cached =
        current.itemDetallesByLiquidacion[liquidacionId] ?? const <LiquidacionItemDetalle>[];
    return List<LiquidacionItemDetalle>.from(cached);
  }

  void _updateItemsCache({
    required LiquidacionesBloc bloc,
    required String liquidacionId,
    required List<LiquidacionItemDetalle> items,
  }) {
    bloc.add(
      LiquidacionItemsCacheUpdated(
        liquidacionId: liquidacionId,
        items: List<LiquidacionItemDetalle>.from(items),
      ),
    );
  }

  bool _isCanalCampo(String? canal) {
    return _isCanalCampoValue(canal);
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

  String _formatTecnicoLabel({
    String? tecnicoId,
    String? tecnicoNombre,
    String? tecnicoEmail,
  }) {
    final nombre = (tecnicoNombre ?? '').trim();
    final id = (tecnicoId ?? '').trim();
    final email = (tecnicoEmail ?? '').trim();

    if (nombre.isNotEmpty) {
      return nombre;
    }
    if (id.isNotEmpty) {
      return 'ID $id';
    }
    if (email.isNotEmpty) {
      return email;
    }
    return '-';
  }

  List<_TecnicoOption> _buildTecnicoOptions(LiquidacionesLoaded state) {
    final byId = <String, _TecnicoOption>{};

    void addTecnico({
      String? tecnicoId,
      String? tecnicoNombre,
      String? tecnicoEmail,
    }) {
      final id = (tecnicoId ?? '').trim();
      if (id.isEmpty) {
        return;
      }

      final existing = byId[id];
      if (existing == null) {
        byId[id] = _TecnicoOption(
          id: id,
          nombre: tecnicoNombre,
          email: tecnicoEmail,
        );
        return;
      }

      byId[id] = existing.copyWith(
        nombre: (existing.nombre == null || existing.nombre!.trim().isEmpty)
            ? tecnicoNombre
            : existing.nombre,
        email: (existing.email == null || existing.email!.trim().isEmpty)
            ? tecnicoEmail
            : existing.email,
      );
    }

    for (final item in state.pendientes) {
      addTecnico(
        tecnicoId: item.tecnicoId,
        tecnicoNombre: item.tecnicoNombre,
        tecnicoEmail: item.tecnicoEmail,
      );
    }

    for (final item in state.liquidaciones) {
      addTecnico(
        tecnicoId: item.tecnicoId,
        tecnicoNombre: item.tecnicoNombre,
        tecnicoEmail: item.tecnicoEmail,
      );
    }

    final output = byId.values.toList();
    output.sort(
      (a, b) => a.label.toLowerCase().compareTo(b.label.toLowerCase()),
    );
    return output;
  }

  Future<void> _openCreateLiquidacionDialog(
    LiquidacionesLoaded state,
    LiquidacionPendienteItem pendiente,
  ) async {
    if (!_isCanalCampo(pendiente.servicioCanal)) {
      _showMessage('Solo los servicios de canal campo pueden liquidarse.');
      return;
    }

    final yaCreada = state.liquidaciones
        .any((liquidacion) => liquidacion.servicioId == pendiente.servicioId);
    if (yaCreada) {
      _showMessage('Ya existe una liquidacion para este servicio.');
      return;
    }

    final formKey = GlobalKey<FormState>();
    final manualTipoSalidaController = TextEditingController();
    var kmInput = (pendiente.kmSugerido != null && pendiente.kmSugerido! > 0)
        ? pendiente.kmSugerido.toString()
        : '';
    final tiposSalidaActivos = state.tiposSalida.where((item) => item.activo).toList();
    final tiposSalidaDisponibles =
        tiposSalidaActivos.isNotEmpty ? tiposSalidaActivos : state.tiposSalida;
    final tiposServicioActivos = state.tiposServicio.where((item) => item.activo).toList();
    final tiposServicioDisponibles =
        tiposServicioActivos.isNotEmpty ? tiposServicioActivos : state.tiposServicio;
    String? selectedTipoSalidaId = _firstTipoSalidaId(tiposSalidaDisponibles);
    String? selectedTipoServicioId = _firstTipoServicioId(tiposServicioDisponibles);
    var selectedItems = <TipoServicioCatalogoItem>[];
    var submitting = false;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogBuildContext, setDialogState) {
            Future<void> submitReviewAndApprove() async {
              if (submitting) {
                return;
              }
              if (!(formKey.currentState?.validate() ?? false)) {
                return;
              }

              final km = _parsePositiveInt(kmInput);
              if (km == null) {
                _showMessage('Ingresa un KM mayor a 0');
                return;
              }

              final hasCatalog = tiposSalidaDisponibles.isNotEmpty;
              final tipoSalidaId = hasCatalog
                  ? (selectedTipoSalidaId ?? '').trim()
                  : manualTipoSalidaController.text.trim();

              if (tipoSalidaId.isEmpty) {
                _showMessage('Selecciona un tipo de salida');
                return;
              }

              if (selectedItems.isEmpty) {
                _showMessage('Debes asignar al menos 1 item de tipo de servicio antes de aprobar.');
                return;
              }

              setDialogState(() => submitting = true);
              try {
                await widget.liquidacionesRepository.createLiquidacion(
                  input: CreateLiquidacionInput(
                    servicioId: pendiente.servicioId,
                    km: km,
                  ),
                );

                final createdLookup = await widget.liquidacionesRepository.fetchLiquidaciones(
                  query: const LiquidacionesQuery(
                    aprobado: false,
                    page: 1,
                    limit: 100,
                  ),
                );
                final createdCandidates = createdLookup.items.where(
                  (candidate) => candidate.servicioId == pendiente.servicioId,
                );
                if (createdCandidates.isEmpty) {
                  throw Exception(
                    'No se encontro la liquidacion creada para el servicio ${pendiente.servicioId}.',
                  );
                }
                final created = createdCandidates.first;

                await widget.liquidacionesRepository.updateLiquidacion(
                  input: UpdateLiquidacionInput(
                    liquidacionId: created.id,
                    tipoSalidaId: tipoSalidaId,
                  ),
                );

                for (final item in selectedItems) {
                  await widget.liquidacionesRepository.addLiquidacionItem(
                    input: AddLiquidacionItemInput(
                      liquidacionId: created.id,
                      tipoServicioId: item.id,
                    ),
                  );
                }

                await widget.liquidacionesRepository.approveLiquidacion(created.id);

                if (!mounted) {
                  return;
                }

                Navigator.of(dialogContext).pop();
                _showMessage('Liquidacion revisada y aprobada correctamente.');
                _requestDashboard(
                  liquidacionesPage: state.liquidacionesPage,
                  liquidacionesLimit: state.liquidacionesLimit,
                  pendientesPage: state.pendientesPage,
                  pendientesLimit: state.pendientesLimit,
                );
                setState(() => _activeView = _LiquidacionesPanelView.creadas);
              } catch (error) {
                _showMessage(_errorMessage(error));
              } finally {
                if (dialogBuildContext.mounted) {
                  setDialogState(() => submitting = false);
                }
              }
            }

            final subtotalItems = selectedItems.fold<double>(
              0,
              (sum, item) => sum + item.precioUsd,
            );

            return AlertDialog(
              backgroundColor: const Color(0xFF102845),
              title: const Text('Revisar y aprobar liquidacion'),
              content: SizedBox(
                width: 760,
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      _LiquidacionInfoLine(label: 'Servicio ID', value: pendiente.servicioId),
                      const SizedBox(height: 8),
                      _LiquidacionInfoLine(label: 'Canal', value: pendiente.servicioCanal),
                      const SizedBox(height: 8),
                      _LiquidacionInfoLine(
                        label: 'Cliente',
                        value: (pendiente.clienteNombre ?? '').trim().isEmpty
                            ? '-'
                            : pendiente.clienteNombre!,
                      ),
                      const SizedBox(height: 8),
                      _LiquidacionInfoLine(
                        label: 'Tecnico',
                        value: _formatTecnicoLabel(
                          tecnicoId: pendiente.tecnicoId,
                          tecnicoNombre: pendiente.tecnicoNombre,
                          tecnicoEmail: pendiente.tecnicoEmail,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _LiquidacionInfoLine(
                        label: 'Fecha servicio',
                        value: _formatDate(pendiente.fechaHoraServicio),
                      ),
                      const SizedBox(height: 10),
                      FilledButton.tonalIcon(
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => ServicioDetallePage(
                                servicioId: pendiente.servicioId,
                              ),
                            ),
                          );
                        },
                        icon: const Icon(Icons.visibility_outlined),
                        label: const Text('Ver detalle completo del servicio'),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        initialValue: kmInput,
                        keyboardType: TextInputType.number,
                        style: const TextStyle(color: Color(0xFFEAF3FF)),
                        decoration: const InputDecoration(labelText: 'KM para liquidacion'),
                        onChanged: (value) => kmInput = value,
                        validator: (value) {
                          if (_parsePositiveInt(value ?? '') == null) {
                            return 'Ingresa un KM mayor a 0';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      if (tiposSalidaDisponibles.isNotEmpty)
                        DropdownButtonFormField<String>(
                          initialValue: selectedTipoSalidaId,
                          decoration: const InputDecoration(labelText: 'Tipo salida'),
                          items: tiposSalidaDisponibles
                              .map(
                                (tipo) => DropdownMenuItem<String>(
                                  value: tipo.id,
                                  child: Text(
                                    '${tipo.nombre} - USD ${tipo.precioUsd.toStringAsFixed(2)}${tipo.activo ? '' : ' (inactivo)'}',
                                  ),
                                ),
                              )
                              .toList(),
                          onChanged: submitting
                              ? null
                              : (value) {
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
                      const SizedBox(height: 12),
                      Row(
                        children: <Widget>[
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              initialValue: selectedTipoServicioId,
                              decoration: const InputDecoration(
                                labelText: 'Agregar item de tipo servicio',
                              ),
                              items: tiposServicioDisponibles
                                  .map(
                                    (tipo) => DropdownMenuItem<String>(
                                      value: tipo.id,
                                      child: Text(
                                        '${tipo.nombre} - USD ${tipo.precioUsd.toStringAsFixed(2)}${tipo.activo ? '' : ' (inactivo)'}',
                                      ),
                                    ),
                                  )
                                  .toList(),
                              onChanged: submitting || tiposServicioDisponibles.isEmpty
                                  ? null
                                  : (value) {
                                      setDialogState(() => selectedTipoServicioId = value);
                                    },
                            ),
                          ),
                          const SizedBox(width: 8),
                          FilledButton.icon(
                            onPressed: submitting || tiposServicioDisponibles.isEmpty
                                ? null
                                : () {
                                    final selectedId = (selectedTipoServicioId ?? '').trim();
                                    if (selectedId.isEmpty) {
                                      return;
                                    }
                                    final match = tiposServicioDisponibles.where(
                                      (tipo) => tipo.id == selectedId,
                                    );
                                    if (match.isEmpty) {
                                      return;
                                    }
                                    if (selectedItems.length >= 6) {
                                      _showMessage('Se permite un maximo de 6 items por liquidacion.');
                                      return;
                                    }
                                    setDialogState(() {
                                      selectedItems = <TipoServicioCatalogoItem>[
                                        ...selectedItems,
                                        match.first,
                                      ];
                                    });
                                  },
                            icon: const Icon(Icons.add, size: 18),
                            label: const Text('Agregar'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0x1F122B4A),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0x334EA6FF)),
                        ),
                        child: selectedItems.isEmpty
                            ? const Text('Sin items asignados.')
                            : Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: <Widget>[
                                  ...selectedItems.asMap().entries.map(
                                    (entry) {
                                      final index = entry.key;
                                      final item = entry.value;
                                      return ListTile(
                                        dense: true,
                                        contentPadding: EdgeInsets.zero,
                                        title: Text(item.nombre),
                                        subtitle: Text(
                                          'USD ${item.precioUsd.toStringAsFixed(2)}',
                                        ),
                                        trailing: IconButton(
                                          onPressed: submitting
                                              ? null
                                              : () {
                                                  setDialogState(() {
                                                    selectedItems = <TipoServicioCatalogoItem>[
                                                      ...selectedItems
                                                    ]..removeAt(index);
                                                  });
                                                },
                                          icon: const Icon(Icons.delete_outline),
                                        ),
                                      );
                                    },
                                  ),
                                  const Divider(height: 12),
                                  Text(
                                    'Subtotal items USD ${subtotalItems.toStringAsFixed(2)}',
                                    style: const TextStyle(fontWeight: FontWeight.w600),
                                  ),
                                ],
                              ),
                      ),
                    ],
                  ),
                ),
              ),
              actions: <Widget>[
                TextButton(
                  onPressed: submitting ? null : () => Navigator.of(dialogContext).pop(),
                  child: const Text('Cancelar'),
                ),
                FilledButton.icon(
                  onPressed: submitting ? null : submitReviewAndApprove,
                  icon: const Icon(Icons.verified_outlined, size: 18),
                  label: Text(submitting ? 'Aprobando...' : 'Aprobar liquidacion'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _openEditHeaderDialog(
    LiquidacionesLoaded state,
    LiquidacionItem item,
  ) async {
    final liquidacionesBloc = context.read<LiquidacionesBloc>();

    if (!_isCanalCampo(item.servicioCanal)) {
      _showMessage('Solo las liquidaciones de canal campo permiten editar cabecera.');
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

                    liquidacionesBloc.add(
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

  Future<void> _confirmReopenLiquidacion(LiquidacionItem item) async {
    if (!item.isAprobadaEstado) {
      _showMessage('Solo se puede reabrir una liquidacion aprobada.');
      return;
    }

    final liquidacionesBloc = context.read<LiquidacionesBloc>();
    final formKey = GlobalKey<FormState>();
    final motivoController = TextEditingController();
    var submitting = false;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogBuildContext, setDialogState) {
            return AlertDialog(
              backgroundColor: const Color(0xFF102845),
              title: const Text('Reabrir liquidacion'),
              content: SizedBox(
                width: 540,
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      _LiquidacionInfoLine(label: 'Liquidacion ID', value: item.id),
                      const SizedBox(height: 10),
                      const Text(
                        'Esta accion registra un motivo de reapertura para auditoria sin cambiar el estado visible.',
                        style: TextStyle(color: Color(0xFF9AB1CC)),
                      ),
                      const SizedBox(height: 10),
                      TextFormField(
                        controller: motivoController,
                        maxLines: 3,
                        autofocus: true,
                        decoration: const InputDecoration(
                          labelText: 'Motivo de reapertura',
                          hintText: 'Describe el motivo (obligatorio)',
                        ),
                        validator: (value) {
                          if ((value ?? '').trim().isEmpty) {
                            return 'Ingresa un motivo de reapertura';
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
                  onPressed: submitting ? null : () => Navigator.of(dialogContext).pop(),
                  child: const Text('Cancelar'),
                ),
                FilledButton(
                  onPressed: submitting
                      ? null
                      : () async {
                          if (!(formKey.currentState?.validate() ?? false)) {
                            return;
                          }

                          setDialogState(() => submitting = true);
                          try {
                            await widget.liquidacionesRepository.reopenLiquidacion(
                              input: ReopenLiquidacionInput(
                                liquidacionId: item.id,
                                motivo: motivoController.text.trim(),
                              ),
                            );

                            if (!mounted) {
                              return;
                            }

                            Navigator.of(dialogContext).pop();
                            _showMessage('Motivo de reapertura registrado (auditoria).');

                            final currentState = liquidacionesBloc.state;
                            if (currentState is LiquidacionesLoaded) {
                              _requestDashboard(
                                liquidacionesPage: currentState.liquidacionesPage,
                                liquidacionesLimit: currentState.liquidacionesLimit,
                                pendientesPage: currentState.pendientesPage,
                                pendientesLimit: currentState.pendientesLimit,
                              );
                            }
                          } catch (error) {
                            _showMessage(_errorMessage(error));
                          } finally {
                            if (dialogBuildContext.mounted) {
                              setDialogState(() => submitting = false);
                            }
                          }
                        },
                  child: Text(submitting ? 'Reabriendo...' : 'Reabrir'),
                ),
              ],
            );
          },
        );
      },
    );

    motivoController.dispose();
  }

  Future<void> _openCreateTipoSalidaDialog(LiquidacionesLoaded state) async {
    final formKey = GlobalKey<FormState>();
    final nombreController = TextEditingController();
    final precioController = TextEditingController();
    final kmHastaController = TextEditingController();
    final liquidacionesBloc = context.read<LiquidacionesBloc>();

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: const Color(0xFF102845),
          title: const Text('Nuevo tipo de salida'),
          content: SizedBox(
            width: 520,
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  TextFormField(
                    controller: nombreController,
                    decoration: const InputDecoration(labelText: 'Nombre'),
                    validator: (value) {
                      if ((value ?? '').trim().isEmpty) {
                        return 'Ingresa un nombre';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: kmHastaController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'KM hasta (opcional)',
                      hintText: 'Vacío = sin tope',
                    ),
                    validator: (value) {
                      final raw = (value ?? '').trim();
                      if (raw.isEmpty) {
                        return null;
                      }
                      if (_parsePositiveInt(raw) == null) {
                        return 'Ingresa un entero mayor a 0';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: precioController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(labelText: 'Precio USD fijo'),
                    validator: (value) {
                      if (_parsePositiveDouble(value ?? '') == null) {
                        return 'Ingresa un precio mayor a 0';
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

                final precio = _parsePositiveDouble(precioController.text);
                if (precio == null) {
                  return;
                }

                final kmRaw = kmHastaController.text.trim();
                final kmHasta = kmRaw.isEmpty ? null : _parsePositiveInt(kmRaw);

                liquidacionesBloc.add(
                  LiquidacionesCreateTipoSalidaRequested(
                    input: CreateTipoSalidaInput(
                      nombre: nombreController.text.trim(),
                      kmHasta: kmHasta,
                      precioUsd: precio,
                    ),
                  ),
                );
                Navigator.of(dialogContext).pop();
                if (mounted) {
                  setState(() => _activeView = _LiquidacionesPanelView.tiposSalida);
                }
              },
              child: const Text('Crear'),
            ),
          ],
        );
      },
    );

    nombreController.dispose();
    precioController.dispose();
    kmHastaController.dispose();
  }

  Future<void> _openEditTipoSalidaDialog(
    LiquidacionesLoaded state,
    TipoSalidaCatalogoItem item,
  ) async {
    final formKey = GlobalKey<FormState>();
    final nombreController = TextEditingController(text: item.nombre);
    final precioController = TextEditingController(text: item.precioUsd.toStringAsFixed(2));
    final kmHastaController = TextEditingController(
      text: item.kmHasta?.toString() ?? '',
    );
    var activo = item.activo;
    final liquidacionesBloc = context.read<LiquidacionesBloc>();

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: const Color(0xFF102845),
              title: const Text('Editar tipo de salida'),
              content: SizedBox(
                width: 520,
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      TextFormField(
                        controller: nombreController,
                        decoration: const InputDecoration(labelText: 'Nombre'),
                        validator: (value) {
                          if ((value ?? '').trim().isEmpty) {
                            return 'Ingresa un nombre';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 10),
                      TextFormField(
                        controller: kmHastaController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'KM hasta (opcional)',
                          hintText: 'Vacío = sin tope',
                        ),
                        validator: (value) {
                          final raw = (value ?? '').trim();
                          if (raw.isEmpty) {
                            return null;
                          }
                          if (_parsePositiveInt(raw) == null) {
                            return 'Ingresa un entero mayor a 0';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 10),
                      TextFormField(
                        controller: precioController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: const InputDecoration(labelText: 'Precio USD fijo'),
                        validator: (value) {
                          if (_parsePositiveDouble(value ?? '') == null) {
                            return 'Ingresa un precio mayor a 0';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 10),
                      SwitchListTile.adaptive(
                        value: activo,
                        title: const Text('Activo'),
                        contentPadding: EdgeInsets.zero,
                        onChanged: (value) => setDialogState(() => activo = value),
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

                    final precio = _parsePositiveDouble(precioController.text);
                    if (precio == null) {
                      return;
                    }

                    final kmRaw = kmHastaController.text.trim();
                    final kmHasta = kmRaw.isEmpty ? null : _parsePositiveInt(kmRaw);

                    liquidacionesBloc.add(
                      LiquidacionesUpdateTipoSalidaRequested(
                        input: UpdateTipoSalidaInput(
                          id: item.id,
                          nombre: nombreController.text.trim(),
                          kmHasta: kmHasta,
                          precioUsd: precio,
                          activo: activo,
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

    nombreController.dispose();
    precioController.dispose();
    kmHastaController.dispose();
  }

  Future<void> _openCreateTipoServicioDialog(LiquidacionesLoaded state) async {
    final formKey = GlobalKey<FormState>();
    final nombreController = TextEditingController();
    final precioController = TextEditingController();
    final liquidacionesBloc = context.read<LiquidacionesBloc>();

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: const Color(0xFF102845),
          title: const Text('Nuevo tipo de servicio'),
          content: SizedBox(
            width: 520,
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  TextFormField(
                    controller: nombreController,
                    decoration: const InputDecoration(labelText: 'Nombre'),
                    validator: (value) {
                      if ((value ?? '').trim().isEmpty) {
                        return 'Ingresa un nombre';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: precioController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(labelText: 'Precio USD'),
                    validator: (value) {
                      if (_parsePositiveDouble(value ?? '') == null) {
                        return 'Ingresa un precio mayor a 0';
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

                final precio = _parsePositiveDouble(precioController.text);
                if (precio == null) {
                  return;
                }

                liquidacionesBloc.add(
                  LiquidacionesCreateTipoServicioRequested(
                    input: CreateTipoServicioInput(
                      nombre: nombreController.text.trim(),
                      precioUsd: precio,
                    ),
                  ),
                );
                Navigator.of(dialogContext).pop();
                if (mounted) {
                  setState(() => _activeView = _LiquidacionesPanelView.tiposServicio);
                }
              },
              child: const Text('Crear'),
            ),
          ],
        );
      },
    );

    nombreController.dispose();
    precioController.dispose();
  }

  Future<void> _openEditTipoServicioDialog(
    LiquidacionesLoaded state,
    TipoServicioCatalogoItem item,
  ) async {
    final formKey = GlobalKey<FormState>();
    final nombreController = TextEditingController(text: item.nombre);
    final precioController = TextEditingController(text: item.precioUsd.toStringAsFixed(2));
    var activo = item.activo;
    final liquidacionesBloc = context.read<LiquidacionesBloc>();

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: const Color(0xFF102845),
              title: const Text('Editar tipo de servicio'),
              content: SizedBox(
                width: 520,
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      TextFormField(
                        controller: nombreController,
                        decoration: const InputDecoration(labelText: 'Nombre'),
                        validator: (value) {
                          if ((value ?? '').trim().isEmpty) {
                            return 'Ingresa un nombre';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 10),
                      TextFormField(
                        controller: precioController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: const InputDecoration(labelText: 'Precio USD'),
                        validator: (value) {
                          if (_parsePositiveDouble(value ?? '') == null) {
                            return 'Ingresa un precio mayor a 0';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 10),
                      SwitchListTile.adaptive(
                        value: activo,
                        title: const Text('Activo'),
                        contentPadding: EdgeInsets.zero,
                        onChanged: (value) => setDialogState(() => activo = value),
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

                    final precio = _parsePositiveDouble(precioController.text);
                    if (precio == null) {
                      return;
                    }

                    liquidacionesBloc.add(
                      LiquidacionesUpdateTipoServicioRequested(
                        input: UpdateTipoServicioInput(
                          id: item.id,
                          nombre: nombreController.text.trim(),
                          precioUsd: precio,
                          activo: activo,
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

    nombreController.dispose();
    precioController.dispose();
  }

  Widget _buildTiposSalidaCatalog(LiquidacionesLoaded state) {
    if (state.tiposSalida.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0x1F122B4A),
          border: Border.all(color: const Color(0x334EA6FF)),
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Text('No hay tipos de salida cargados.'),
      );
    }

    return Card(
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SizedBox(
          width: 1200,
          child: SingleChildScrollView(
            child: DataTable(
              columns: const <DataColumn>[
                DataColumn(label: Text('Nombre')),
                DataColumn(label: Text('KM hasta')),
                DataColumn(label: Text('Precio USD fijo')),
                DataColumn(label: Text('Estado')),
                DataColumn(label: Text('Acciones')),
              ],
              rows: state.tiposSalida
                  .map(
                    (item) => DataRow(
                      cells: <DataCell>[
                        DataCell(Text(item.nombre)),
                        DataCell(Text(item.kmHasta?.toString() ?? 'Sin tope')),
                        DataCell(Text(item.precioUsd.toStringAsFixed(2))),
                        DataCell(
                          ModuleStatusChip(
                            label: item.activo ? 'ACTIVO' : 'INACTIVO',
                            backgroundColor: item.activo
                                ? const Color(0x1F0FA960)
                                : const Color(0x1FF4B942),
                            foregroundColor: item.activo
                                ? const Color(0xFF8FF0BC)
                                : const Color(0xFFFFD98B),
                          ),
                        ),
                        DataCell(
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: <Widget>[
                              IconButton(
                                tooltip: 'Editar tipo salida',
                                onPressed: () => _openEditTipoSalidaDialog(state, item),
                                icon: const Icon(Icons.edit_outlined),
                              ),
                              IconButton(
                                tooltip: item.activo ? 'Desactivar' : 'Activar',
                                onPressed: () {
                                  context.read<LiquidacionesBloc>().add(
                                        LiquidacionesUpdateTipoSalidaRequested(
                                          input: UpdateTipoSalidaInput(
                                            id: item.id,
                                            activo: !item.activo,
                                          ),
                                        ),
                                      );
                                },
                                icon: Icon(
                                  item.activo
                                      ? Icons.toggle_on_outlined
                                      : Icons.toggle_off_outlined,
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
      ),
    );
  }

  Widget _buildTiposServicioCatalog(LiquidacionesLoaded state) {
    if (state.tiposServicio.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0x1F122B4A),
          border: Border.all(color: const Color(0x334EA6FF)),
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Text('No hay tipos de servicio cargados.'),
      );
    }

    return Card(
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SizedBox(
          width: 1100,
          child: SingleChildScrollView(
            child: DataTable(
              columns: const <DataColumn>[
                DataColumn(label: Text('Nombre')),
                DataColumn(label: Text('Precio USD')),
                DataColumn(label: Text('Estado')),
                DataColumn(label: Text('Acciones')),
              ],
              rows: state.tiposServicio
                  .map(
                    (item) => DataRow(
                      cells: <DataCell>[
                        DataCell(Text(item.nombre)),
                        DataCell(Text(item.precioUsd.toStringAsFixed(2))),
                        DataCell(
                          ModuleStatusChip(
                            label: item.activo ? 'ACTIVO' : 'INACTIVO',
                            backgroundColor: item.activo
                                ? const Color(0x1F0FA960)
                                : const Color(0x1FF4B942),
                            foregroundColor: item.activo
                                ? const Color(0xFF8FF0BC)
                                : const Color(0xFFFFD98B),
                          ),
                        ),
                        DataCell(
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: <Widget>[
                              IconButton(
                                tooltip: 'Editar tipo servicio',
                                onPressed: () => _openEditTipoServicioDialog(state, item),
                                icon: const Icon(Icons.edit_outlined),
                              ),
                              IconButton(
                                tooltip: item.activo ? 'Desactivar' : 'Activar',
                                onPressed: () {
                                  context.read<LiquidacionesBloc>().add(
                                        LiquidacionesUpdateTipoServicioRequested(
                                          input: UpdateTipoServicioInput(
                                            id: item.id,
                                            activo: !item.activo,
                                          ),
                                        ),
                                      );
                                },
                                icon: Icon(
                                  item.activo
                                      ? Icons.toggle_on_outlined
                                      : Icons.toggle_off_outlined,
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
      ),
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

  Future<void> _openItemsDialog(
    LiquidacionesLoaded state,
    LiquidacionItem liquidacion,
  ) async {
    final liquidacionesBloc = context.read<LiquidacionesBloc>();

    if (!_isCanalCampo(liquidacion.servicioCanal)) {
      _showMessage(
        'Canal no identificado como campo. Se habilita gestion para evitar bloqueo operativo.',
      );
    }

    final tiposServicioActivos = state.tiposServicio.where((item) => item.activo).toList();
    final tiposServicioDisponibles =
      tiposServicioActivos.isNotEmpty ? tiposServicioActivos : state.tiposServicio;

    var selectedTipoServicioId = _firstTipoServicioId(tiposServicioDisponibles);
    var items = _cachedItemsForLiquidacion(
      bloc: liquidacionesBloc,
      liquidacionId: liquidacion.id,
    );
    var meta = _buildItemsMeta(items);
    var remoteMode = false;
    var loading = true;
    var actionInProgress = false;
    String? loadError;
    var reaperturas = const <LiquidacionReaperturaItem>[];
    var reaperturasTotal = 0;
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
                  items = _cachedItemsForLiquidacion(
                    bloc: liquidacionesBloc,
                    liquidacionId: liquidacion.id,
                  );
                  meta = _buildItemsMeta(items);
                } else {
                  remoteMode = response.remoteEnabled;
                  items = List<LiquidacionItemDetalle>.from(response.items);
                  meta = _buildItemsMeta(items);
                  _updateItemsCache(
                    bloc: liquidacionesBloc,
                    liquidacionId: liquidacion.id,
                    items: items,
                  );
                }

                final reaperturasResponse = await widget.liquidacionesRepository
                    .fetchLiquidacionReaperturas(liquidacion.id);
                reaperturas = List<LiquidacionReaperturaItem>.from(
                  reaperturasResponse.reaperturas,
                );
                reaperturasTotal = reaperturasResponse.total;
              } catch (error) {
                remoteMode = false;
                loadError = _errorMessage(error);
                items = _cachedItemsForLiquidacion(
                  bloc: liquidacionesBloc,
                  liquidacionId: liquidacion.id,
                );
                meta = _buildItemsMeta(items);
                if (loadError != null && loadError!.trim().isNotEmpty) {
                  _showMessage(loadError!);
                }
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
              _updateItemsCache(
                bloc: liquidacionesBloc,
                liquidacionId: liquidacion.id,
                items: items,
              );
            }

            Future<void> runItemAction({
              required Future<void> Function() action,
              required String successMessage,
            }) async {
              if (actionInProgress) {
                return;
              }

              setDialogState(() => actionInProgress = true);

              try {
                await action();
                await refreshAfterAction();

                _updateItemsCache(
                  bloc: liquidacionesBloc,
                  liquidacionId: liquidacion.id,
                  items: items,
                );

                final currentState = liquidacionesBloc.state;
                if (currentState is LiquidacionesLoaded) {
                  _requestDashboard(
                    liquidacionesPage: currentState.liquidacionesPage,
                    liquidacionesLimit: currentState.liquidacionesLimit,
                    pendientesPage: currentState.pendientesPage,
                    pendientesLimit: currentState.pendientesLimit,
                  );
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
              if (tiposServicioDisponibles.isEmpty) {
                _showMessage('No hay tipos de servicio disponibles para agregar.');
                return;
              }

              if (items.length >= 6) {
                _showMessage('La liquidacion ya tiene 6 items.');
                return;
              }

              final tipoServicioId = (selectedTipoServicioId ?? '').trim();

              if (tipoServicioId.isEmpty) {
                _showMessage('Selecciona un tipo de servicio.');
                return;
              }

                final fallbackTipo =
                  tiposServicioDisponibles.where((item) => item.id == tipoServicioId);
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
                _updateItemsCache(
                  bloc: liquidacionesBloc,
                  liquidacionId: liquidacion.id,
                  items: items,
                );
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

            final addBlocked = actionInProgress || items.length >= 6;
            final totalTecnicoUsd = calculateLiquidacionTotalTecnicoUsd(
              tipoSalidaPrecioUsd: liquidacion.tipoSalidaPrecioUsd,
              items: items,
            );

            return AlertDialog(
              backgroundColor: const Color(0xFF102845),
              title: const Text('Detalle de liquidacion'),
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
                          const SizedBox(height: 6),
                          _LiquidacionInfoLine(
                            label: 'Servicio',
                            value: liquidacion.servicioId,
                          ),
                          const SizedBox(height: 6),
                          _LiquidacionInfoLine(
                            label: 'Cliente',
                            value: (liquidacion.clienteNombre ?? '').trim().isEmpty
                                ? '-'
                                : liquidacion.clienteNombre!,
                          ),
                          const SizedBox(height: 6),
                          _LiquidacionInfoLine(
                            label: 'Tipo salida',
                            value: (liquidacion.tipoSalidaNombre ?? '').trim().isEmpty
                                ? '-'
                                : liquidacion.tipoSalidaNombre!,
                          ),
                          const SizedBox(height: 6),
                          _LiquidacionInfoLine(
                            label: 'Salida fija USD',
                            value: liquidacion.tipoSalidaPrecioUsd.toStringAsFixed(2),
                          ),
                          const SizedBox(height: 6),
                          _LiquidacionInfoLine(
                            label: 'KM',
                            value: liquidacion.km.toString(),
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
                              ModuleStatusChip(
                                label:
                                    'TOTAL TECNICO USD ${totalTecnicoUsd.toStringAsFixed(2)}',
                                backgroundColor: const Color(0x1F0FA960),
                                foregroundColor: const Color(0xFF8FF0BC),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
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
                                      child: DropdownButtonFormField<String>(
                                        initialValue: selectedTipoServicioId,
                                        decoration: const InputDecoration(
                                          labelText: 'Tipo servicio',
                                        ),
                                        items: tiposServicioDisponibles
                                            .map(
                                              (tipo) => DropdownMenuItem<String>(
                                                value: tipo.id,
                                                child: Text(
                                                  '${tipo.nombre} - USD ${tipo.precioUsd.toStringAsFixed(2)}${tipo.activo ? '' : ' (inactivo)'}',
                                                ),
                                              ),
                                            )
                                            .toList(),
                                        onChanged: addBlocked || tiposServicioDisponibles.isEmpty
                                            ? null
                                            : (value) {
                                                setDialogState(
                                                  () => selectedTipoServicioId = value,
                                                );
                                              },
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    FilledButton.icon(
                                      onPressed: addBlocked || tiposServicioDisponibles.isEmpty
                                          ? null
                                          : addItem,
                                      icon: const Icon(Icons.add, size: 18),
                                      label: const Text('Agregar item'),
                                    ),
                                  ],
                                ),
                                if (tiposServicioDisponibles.isEmpty) ...<Widget>[
                                  const SizedBox(height: 8),
                                  const Text(
                                    'No hay tipos de servicio cargados. Crea uno para poder agregar items.',
                                    style: TextStyle(color: Color(0xFFFFD98B)),
                                  ),
                                ],
                                if (tiposServicioActivos.isEmpty &&
                                    tiposServicioDisponibles.isNotEmpty) ...<Widget>[
                                  const SizedBox(height: 8),
                                  const Text(
                                    'No hay tipos activos; se muestran inactivos para no bloquear el flujo.',
                                    style: TextStyle(color: Color(0xFFFFD98B)),
                                  ),
                                ],
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
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0x1F122B4A),
                              border: Border.all(color: const Color(0x334EA6FF)),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Text(
                                  'Historial de reaperturas (${reaperturasTotal.toString()})',
                                  style: const TextStyle(fontWeight: FontWeight.w600),
                                ),
                                const SizedBox(height: 8),
                                if (reaperturas.isEmpty)
                                  const Text(
                                    'No hay reaperturas registradas para esta liquidacion.',
                                    style: TextStyle(color: Color(0xFF9AB1CC)),
                                  )
                                else
                                  ...reaperturas.take(6).map(
                                    (entry) => Padding(
                                      padding: const EdgeInsets.only(bottom: 6),
                                      child: Text(
                                        '${_formatDate(entry.fecha)} - ${entry.motivo}',
                                      ),
                                    ),
                                  ),
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
                              child: ListView.separated(
                                itemCount: items.length,
                                separatorBuilder: (_, __) => const SizedBox(height: 8),
                                itemBuilder: (context, index) {
                                  final detalle = items[index];
                                  final title =
                                      '${index + 1}. ${detalle.tipoServicioNombre}';
                                  return Container(
                                    decoration: BoxDecoration(
                                      color: const Color(0x1F122B4A),
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(color: const Color(0x334EA6FF)),
                                    ),
                                    child: ExpansionTile(
                                      tilePadding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 2,
                                      ),
                                      childrenPadding: const EdgeInsets.fromLTRB(
                                        12,
                                        0,
                                        12,
                                        12,
                                      ),
                                      title: Text(title),
                                      subtitle: Row(
                                        children: <Widget>[
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
                                          const SizedBox(width: 8),
                                          Text(
                                            'USD ${detalle.precioUsdSnapshot.toStringAsFixed(2)}',
                                          ),
                                        ],
                                      ),
                                      children: <Widget>[
                                        _LiquidacionInfoLine(
                                          label: 'Item ID',
                                          value: detalle.id,
                                        ),
                                        const SizedBox(height: 6),
                                        _LiquidacionInfoLine(
                                          label: 'Aprobacion',
                                          value: _formatDate(detalle.fechaAprobacion),
                                        ),
                                        const SizedBox(height: 6),
                                        _LiquidacionInfoLine(
                                          label: 'Creado',
                                          value: _formatDate(detalle.createdAt),
                                        ),
                                        const SizedBox(height: 8),
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.end,
                                          children: <Widget>[
                                            IconButton(
                                              tooltip: 'Aprobar item',
                                              onPressed: actionInProgress ||
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
                                                      detalle.aprobado
                                                  ? null
                                                  : () => deleteItem(detalle),
                                              icon: const Icon(
                                                Icons.delete_outline,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  );
                                },
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
            final liquidacionesLimit = normalizeRowsPerPage(
              state.liquidacionesLimit > 0 ? state.liquidacionesLimit : 20,
              defaults: const <int>[20, 40, 60],
            );
            final liquidacionesRowsPerPageOptions = buildRowsPerPageOptions(
              liquidacionesLimit,
              defaults: const <int>[20, 40, 60],
            );
            final liquidacionesFirstRowIndex =
                (state.liquidacionesPage - 1) * liquidacionesLimit;

            final pendientesLimit = normalizeRowsPerPage(
              state.pendientesLimit > 0 ? state.pendientesLimit : 20,
              defaults: const <int>[20, 40, 60],
            );
            final pendientesRowsPerPageOptions = buildRowsPerPageOptions(
              pendientesLimit,
              defaults: const <int>[20, 40, 60],
            );
            final pendientesFirstRowIndex =
                (state.pendientesPage - 1) * pendientesLimit;

            final approvedCount =
              state.liquidaciones.where((item) => item.isAprobadaEstado).length;
            final pendingCount = state.liquidaciones.length - approvedCount;
            final pendientesCampoCount =
                state.pendientes.where((item) => _isCanalCampo(item.servicioCanal)).length;

            final tecnicoOptions = _buildTecnicoOptions(state).toList();
            final selectedTecnicoId = (_tecnicoFilterId ?? state.tecnicoId)?.trim();
            if (selectedTecnicoId != null &&
                selectedTecnicoId.isNotEmpty &&
                !tecnicoOptions.any((item) => item.id == selectedTecnicoId)) {
              tecnicoOptions.insert(
                0,
                _TecnicoOption(
                  id: selectedTecnicoId,
                  nombre: 'Tecnico seleccionado',
                  email: null,
                ),
              );
            }

            final tecnicoDropdownValue =
                (selectedTecnicoId == null || selectedTecnicoId.isEmpty)
                    ? '__all__'
                    : selectedTecnicoId;

            final selectedAprobado = true;

            final hasTecnicoFilter =
                selectedTecnicoId != null && selectedTecnicoId.isNotEmpty;
            final createdHasFilters = hasTecnicoFilter;
            final createdEmptyMessage = createdHasFilters
              ? 'No hay liquidaciones aprobadas para el filtro seleccionado.'
              : 'No hay liquidaciones aprobadas para mostrar.';
            final pendientesEmptyMessage = hasTecnicoFilter
                ? 'No hay servicios pendientes para el tecnico seleccionado.'
                : 'No hay servicios pendientes de liquidar.';

            return ModulePageLayout(
              title: 'Liquidaciones',
              subtitle:
                  'Pago tecnico: salida fija + items de tipo servicio. No incluye viaticos comerciales por KM.',
              trailing: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: <Widget>[
                  ModuleStatusChip(
                    label: 'PENDIENTES ${state.pendientesTotal}',
                    backgroundColor: const Color(0x1FF4B942),
                    foregroundColor: const Color(0xFFFFD98B),
                  ),
                  ModuleStatusChip(label: 'PENDIENTES CAMPO $pendientesCampoCount'),
                  ModuleStatusChip(label: 'APROBADAS ${state.liquidacionesTotal}'),
                  ModuleStatusChip(
                    label: 'APROBADAS $approvedCount',
                    backgroundColor: const Color(0x1F0FA960),
                    foregroundColor: const Color(0xFF8FF0BC),
                  ),
                  ModuleStatusChip(
                    label: 'REABIERTAS / NO APROBADAS $pendingCount',
                    backgroundColor: const Color(0x1FF4B942),
                    foregroundColor: const Color(0xFFFFD98B),
                  ),
                ],
              ),
              child: Column(
                children: <Widget>[
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: <Widget>[
                        ChoiceChip(
                          selected: _activeView == _LiquidacionesPanelView.pendientes,
                          label: const Text('Pendientes de liquidar'),
                          onSelected: (selected) {
                            if (!selected) {
                              return;
                            }
                            setState(() {
                              _activeView = _LiquidacionesPanelView.pendientes;
                              _aprobadoFilter = null;
                            });
                            _requestDashboard(
                              liquidacionesPage: 1,
                              liquidacionesLimit: liquidacionesLimit,
                              pendientesPage: 1,
                              pendientesLimit: pendientesLimit,
                            );
                          },
                        ),
                        ChoiceChip(
                          selected: _activeView == _LiquidacionesPanelView.creadas,
                          label: const Text('Liquidaciones aprobadas'),
                          onSelected: (selected) {
                            if (!selected) {
                              return;
                            }
                            setState(() {
                              _activeView = _LiquidacionesPanelView.creadas;
                              _aprobadoFilter = true;
                            });
                            _requestDashboard(
                              liquidacionesPage: 1,
                              liquidacionesLimit: liquidacionesLimit,
                              pendientesPage: state.pendientesPage,
                              pendientesLimit: pendientesLimit,
                            );
                          },
                        ),
                        ChoiceChip(
                          selected: _activeView == _LiquidacionesPanelView.tiposSalida,
                          label: const Text('Tipos de salida'),
                          onSelected: (selected) {
                            if (!selected) {
                              return;
                            }
                            setState(() => _activeView = _LiquidacionesPanelView.tiposSalida);
                          },
                        ),
                        ChoiceChip(
                          selected: _activeView == _LiquidacionesPanelView.tiposServicio,
                          label: const Text('Tipos de servicio'),
                          onSelected: (selected) {
                            if (!selected) {
                              return;
                            }
                            setState(() => _activeView = _LiquidacionesPanelView.tiposServicio);
                          },
                        ),
                        if (_activeView == _LiquidacionesPanelView.pendientes ||
                            _activeView == _LiquidacionesPanelView.creadas)
                          Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          decoration: BoxDecoration(
                            color: const Color(0xFF122B4A),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: const Color(0x334EA6FF)),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: tecnicoDropdownValue,
                              onChanged: (value) {
                                if (value == null) {
                                  return;
                                }
                                final selected = value == '__all__' ? null : value;
                                setState(() => _tecnicoFilterId = selected);
                                _requestDashboard(
                                  liquidacionesPage: 1,
                                  liquidacionesLimit: liquidacionesLimit,
                                  pendientesPage: 1,
                                  pendientesLimit: pendientesLimit,
                                );
                              },
                              items: <DropdownMenuItem<String>>[
                                const DropdownMenuItem<String>(
                                  value: '__all__',
                                  child: Text('TODOS LOS TECNICOS'),
                                ),
                                ...tecnicoOptions.map(
                                  (option) => DropdownMenuItem<String>(
                                    value: option.id,
                                    child: Text(option.label),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        if (_activeView == _LiquidacionesPanelView.tiposSalida)
                          FilledButton.icon(
                            onPressed: () => _openCreateTipoSalidaDialog(state),
                            icon: const Icon(Icons.add, size: 18),
                            label: const Text('Nuevo tipo salida'),
                          ),
                        if (_activeView == _LiquidacionesPanelView.tiposServicio)
                          FilledButton.icon(
                            onPressed: () => _openCreateTipoServicioDialog(state),
                            icon: const Icon(Icons.add, size: 18),
                            label: const Text('Nuevo tipo servicio'),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: _activeView == _LiquidacionesPanelView.tiposSalida
                        ? _buildTiposSalidaCatalog(state)
                        : _activeView == _LiquidacionesPanelView.tiposServicio
                            ? _buildTiposServicioCatalog(state)
                            : _activeView == _LiquidacionesPanelView.pendientes
                        ? (state.pendientes.isEmpty
                            ? Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: const Color(0x1F122B4A),
                                  border: Border.all(color: const Color(0x334EA6FF)),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(pendientesEmptyMessage),
                              )
                            : Card(
                                child: LayoutBuilder(
                                  builder: (context, constraints) {
                                    const minTableWidth = 1500.0;
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
                                              'pendientes_${state.pendientesPage}_${state.pendientesLimit}_${state.pendientesTotal}_${selectedTecnicoId ?? ''}',
                                            ),
                                            initialFirstRowIndex:
                                                pendientesFirstRowIndex < 0
                                                    ? 0
                                                    : pendientesFirstRowIndex,
                                            headingRowColor: WidgetStateProperty.all(
                                              const Color(0x1A4EA6FF),
                                            ),
                                            columns: const <DataColumn>[
                                              DataColumn(label: Text('Servicio ID')),
                                              DataColumn(label: Text('Canal')),
                                              DataColumn(label: Text('Tecnico')),
                                              DataColumn(label: Text('Cliente')),
                                              DataColumn(label: Text('KM sugerido')),
                                              DataColumn(label: Text('Fecha servicio')),
                                              DataColumn(label: Text('Acciones')),
                                            ],
                                            source: _LiquidacionesPendientesTableSource(
                                              items: state.pendientes,
                                              total: state.pendientesTotal,
                                              page: state.pendientesPage,
                                              limit: pendientesLimit,
                                              formatDate: _formatDate,
                                              formatTecnicoLabel: _formatTecnicoLabel,
                                              createdServicioIds: state.liquidaciones
                                                  .map((item) => item.servicioId)
                                                  .toSet(),
                                              onCreateLiquidacion: (item) =>
                                                  _openCreateLiquidacionDialog(
                                                state,
                                                item,
                                              ),
                                            ),
                                            rowsPerPage: pendientesLimit,
                                            availableRowsPerPage:
                                                pendientesRowsPerPageOptions,
                                            showEmptyRows: false,
                                            onRowsPerPageChanged: (value) {
                                              if (value == null) {
                                                return;
                                              }
                                              _requestDashboard(
                                                liquidacionesPage:
                                                    state.liquidacionesPage,
                                                liquidacionesLimit:
                                                    liquidacionesLimit,
                                                pendientesPage: 1,
                                                pendientesLimit: value,
                                              );
                                            },
                                            onPageChanged: (firstRowIndex) {
                                              final nextPage =
                                                  (firstRowIndex ~/ pendientesLimit) +
                                                      1;
                                              if (nextPage != state.pendientesPage) {
                                                _requestDashboard(
                                                  liquidacionesPage:
                                                      state.liquidacionesPage,
                                                  liquidacionesLimit:
                                                      liquidacionesLimit,
                                                  pendientesPage: nextPage,
                                                  pendientesLimit: pendientesLimit,
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
                              ))
                        : (state.liquidaciones.isEmpty
                            ? Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: const Color(0x1F122B4A),
                                  border: Border.all(color: const Color(0x334EA6FF)),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(createdEmptyMessage),
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
                                              'liquidaciones_${state.liquidacionesPage}_${state.liquidacionesLimit}_${state.liquidacionesTotal}_${selectedTecnicoId ?? ''}_${selectedAprobado.toString()}',
                                            ),
                                            initialFirstRowIndex:
                                                liquidacionesFirstRowIndex < 0
                                                    ? 0
                                                    : liquidacionesFirstRowIndex,
                                            headingRowColor: WidgetStateProperty.all(
                                              const Color(0x1A4EA6FF),
                                            ),
                                            columns: const <DataColumn>[
                                              DataColumn(label: Text('Servicio / Cliente')),
                                              DataColumn(label: Text('Canal')),
                                              DataColumn(label: Text('Tecnico')),
                                              DataColumn(label: Text('Estado texto')),
                                              DataColumn(label: Text('Total tecnico USD')),
                                              DataColumn(label: Text('Estado')),
                                              DataColumn(label: Text('Fecha aprobacion')),
                                              DataColumn(label: Text('Acciones')),
                                            ],
                                            source: _LiquidacionesTableSource(
                                              items: state.liquidaciones,
                                              total: state.liquidacionesTotal,
                                              page: state.liquidacionesPage,
                                              limit: liquidacionesLimit,
                                              formatDate: _formatDate,
                                              formatTecnicoLabel:
                                                  _formatTecnicoLabel,
                                              itemDetallesByLiquidacion:
                                                  state.itemDetallesByLiquidacion,
                                              onEditHeader: (item) =>
                                                  _openEditHeaderDialog(state, item),
                                              onReopenLiquidacion:
                                                  _confirmReopenLiquidacion,
                                              onManageItems: (item) =>
                                                  _openItemsDialog(state, item),
                                            ),
                                            rowsPerPage: liquidacionesLimit,
                                            availableRowsPerPage:
                                                liquidacionesRowsPerPageOptions,
                                            showEmptyRows: false,
                                            onRowsPerPageChanged: (value) {
                                              if (value == null) {
                                                return;
                                              }
                                              _requestDashboard(
                                                liquidacionesPage: 1,
                                                liquidacionesLimit: value,
                                                pendientesPage: state.pendientesPage,
                                                pendientesLimit: pendientesLimit,
                                              );
                                            },
                                            onPageChanged: (firstRowIndex) {
                                              final nextPage =
                                                  (firstRowIndex ~/ liquidacionesLimit) +
                                                      1;
                                              if (nextPage !=
                                                  state.liquidacionesPage) {
                                                _requestDashboard(
                                                  liquidacionesPage: nextPage,
                                                  liquidacionesLimit:
                                                      liquidacionesLimit,
                                                  pendientesPage:
                                                      state.pendientesPage,
                                                  pendientesLimit:
                                                      pendientesLimit,
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
                              )),
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
    required this.formatTecnicoLabel,
    required this.itemDetallesByLiquidacion,
    required this.onEditHeader,
    this.onReopenLiquidacion,
    required this.onManageItems,
  });

  final List<LiquidacionItem> items;
  final int total;
  final int page;
  final int limit;
  final String Function(String? raw) formatDate;
  final String Function({
    String? tecnicoId,
    String? tecnicoNombre,
    String? tecnicoEmail,
  }) formatTecnicoLabel;
  final Map<String, List<LiquidacionItemDetalle>> itemDetallesByLiquidacion;
  final ValueChanged<LiquidacionItem> onEditHeader;
  final ValueChanged<LiquidacionItem>? onReopenLiquidacion;
  final ValueChanged<LiquidacionItem> onManageItems;

  @override
  DataRow? getRow(int index) {
    final start = (page - 1) * limit;
    final localIndex = index - start;
    if (localIndex < 0 || localIndex >= items.length) {
      return null;
    }

    final item = items[localIndex];
    final approved = item.isAprobadaEstado;
    final isCanalCampo = _isCanalCampoValue(item.servicioCanal);
    final itemDetalles =
        itemDetallesByLiquidacion[item.id] ?? const <LiquidacionItemDetalle>[];
    final totalTecnicoUsd = calculateLiquidacionTotalTecnicoUsd(
      tipoSalidaPrecioUsd: item.tipoSalidaPrecioUsd,
      items: itemDetalles,
    );

    return DataRow.byIndex(
      index: index,
      cells: <DataCell>[
        DataCell(
          SizedBox(
            width: 280,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'Servicio ${item.servicioId}',
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  'Cliente ${((item.clienteNombre ?? '').trim().isEmpty ? '-' : item.clienteNombre!)}',
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Color(0xFF9AB1CC), fontSize: 12),
                ),
              ],
            ),
          ),
        ),
        DataCell(
          ModuleStatusChip(
            label: item.servicioCanal.toUpperCase(),
          ),
        ),
        DataCell(
          SizedBox(
            width: 240,
            child: Text(
              formatTecnicoLabel(
                tecnicoId: item.tecnicoId,
                tecnicoNombre: item.tecnicoNombre,
                tecnicoEmail: item.tecnicoEmail,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
        DataCell(Text(item.estadoNormalizado.toUpperCase())),
        DataCell(
          ModuleStatusChip(
            label: totalTecnicoUsd.toStringAsFixed(2),
            backgroundColor: const Color(0x1F0FA960),
            foregroundColor: const Color(0xFF8FF0BC),
          ),
        ),
        DataCell(_AprobadaChip(item: item)),
        DataCell(Text(formatDate(item.fechaAprobacion))),
        DataCell(
          SizedBox(
            width: 240,
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: <Widget>[
                OutlinedButton.icon(
                  onPressed: () => onManageItems(item),
                  icon: const Icon(Icons.playlist_add_check),
                  label: const Text('Ver detalle'),
                ),
                PopupMenuButton<String>(
                  tooltip: 'Mas acciones',
                  icon: const Icon(Icons.more_horiz),
                  onSelected: (value) {
                    switch (value) {
                      case 'editar':
                        onEditHeader(item);
                        break;
                      case 'reabrir':
                        onReopenLiquidacion?.call(item);
                        break;
                    }
                  },
                  itemBuilder: (context) => <PopupMenuEntry<String>>[
                    PopupMenuItem<String>(
                      value: 'editar',
                      enabled: isCanalCampo,
                      child: Text(
                        !isCanalCampo
                            ? 'Editar cabecera (solo canal campo)'
                            : 'Editar cabecera',
                      ),
                    ),
                    if (onReopenLiquidacion != null)
                      PopupMenuItem<String>(
                        value: 'reabrir',
                        enabled: approved && isCanalCampo,
                        child: Text(
                          approved
                              ? 'Registrar motivo (auditoria)'
                              : 'Registrar motivo (solo aprobadas)',
                        ),
                      ),
                  ],
                ),
              ],
            ),
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

class _LiquidacionesPendientesTableSource extends DataTableSource {
  _LiquidacionesPendientesTableSource({
    required this.items,
    required this.total,
    required this.page,
    required this.limit,
    required this.formatDate,
    required this.formatTecnicoLabel,
    required this.createdServicioIds,
    required this.onCreateLiquidacion,
  });

  final List<LiquidacionPendienteItem> items;
  final int total;
  final int page;
  final int limit;
  final String Function(String? raw) formatDate;
  final String Function({
    String? tecnicoId,
    String? tecnicoNombre,
    String? tecnicoEmail,
  }) formatTecnicoLabel;
  final Set<String> createdServicioIds;
  final ValueChanged<LiquidacionPendienteItem> onCreateLiquidacion;

  @override
  DataRow? getRow(int index) {
    final start = (page - 1) * limit;
    final localIndex = index - start;
    if (localIndex < 0 || localIndex >= items.length) {
      return null;
    }

    final item = items[localIndex];
    final isCanalCampo = _isCanalCampoValue(item.servicioCanal);
    final alreadyLiquidated = createdServicioIds.contains(item.servicioId);

    return DataRow.byIndex(
      index: index,
      cells: <DataCell>[
        DataCell(Text(item.servicioId)),
        DataCell(
          ModuleStatusChip(
            label: item.servicioCanal.toUpperCase(),
            backgroundColor: isCanalCampo
                ? const Color(0x1F0FA960)
                : const Color(0x1FF4B942),
            foregroundColor: isCanalCampo
                ? const Color(0xFF8FF0BC)
                : const Color(0xFFFFD98B),
          ),
        ),
        DataCell(
          SizedBox(
            width: 260,
            child: Text(
              formatTecnicoLabel(
                tecnicoId: item.tecnicoId,
                tecnicoNombre: item.tecnicoNombre,
                tecnicoEmail: item.tecnicoEmail,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
        DataCell(Text(item.clienteNombre ?? '-')),
        DataCell(Text(item.kmSugerido?.toString() ?? '-')),
        DataCell(Text(formatDate(item.fechaHoraServicio))),
        DataCell(
          FilledButton.tonalIcon(
            onPressed: (!isCanalCampo || alreadyLiquidated)
                ? null
                : () => onCreateLiquidacion(item),
            icon: const Icon(Icons.fact_check_outlined, size: 18),
            label: Text(
              alreadyLiquidated
                  ? 'Ya liquidada'
                  : (isCanalCampo ? 'Revisar' : 'No aplica'),
            ),
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

bool _isCanalCampoValue(String? canal) {
  final normalized = (canal ?? '').trim().toLowerCase();
  if (normalized.isEmpty) {
    return false;
  }
  return normalized == 'campo' ||
      normalized == 'c' ||
      normalized.contains('campo');
}

class _AprobadaChip extends StatelessWidget {
  const _AprobadaChip({required this.item});

  final LiquidacionItem item;

  @override
  Widget build(BuildContext context) {
    final isReabierta = item.isReabierta;
    final aprobada = item.isAprobadaEstado;

    return ModuleStatusChip(
      label: isReabierta
          ? 'REABIERTA'
          : (aprobada ? 'APROBADA PAGO' : 'PENDIENTE'),
      backgroundColor: isReabierta
          ? const Color(0x1F4EA6FF)
          : (aprobada ? const Color(0x1F0FA960) : const Color(0x1FF4B942)),
      foregroundColor: isReabierta
          ? const Color(0xFF9CCDFF)
          : (aprobada ? const Color(0xFF8FF0BC) : const Color(0xFFFFD98B)),
    );
  }
}

class _TecnicoOption {
  const _TecnicoOption({
    required this.id,
    this.nombre,
    this.email,
  });

  final String id;
  final String? nombre;
  final String? email;

  String get label {
    final trimmedName = (nombre ?? '').trim();
    final trimmedEmail = (email ?? '').trim();

    if (trimmedName.isNotEmpty && trimmedEmail.isNotEmpty) {
      return '$trimmedName <$trimmedEmail>';
    }
    if (trimmedName.isNotEmpty) {
      return trimmedName;
    }
    if (trimmedEmail.isNotEmpty) {
      return trimmedEmail;
    }
    return 'ID $id';
  }

  _TecnicoOption copyWith({
    String? nombre,
    String? email,
  }) {
    return _TecnicoOption(
      id: id,
      nombre: nombre ?? this.nombre,
      email: email ?? this.email,
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
