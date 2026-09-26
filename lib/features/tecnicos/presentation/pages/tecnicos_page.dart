import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:web_admin_tecnico/core/utils/paginated_table_prefs.dart';
import 'package:web_admin_tecnico/core/widgets/module_page_layout.dart';
import 'package:web_admin_tecnico/features/tecnicos/data/tecnicos_repository_impl.dart';
import 'package:web_admin_tecnico/features/tecnicos/domain/tecnicos_repository.dart';
import 'package:web_admin_tecnico/features/tecnicos/presentation/bloc/tecnicos_bloc.dart';

class TecnicosPage extends StatelessWidget {
  const TecnicosPage({super.key, this.repository});

  /// Inyectable para tests; en la app real pega contra `/auth/tecnicos`.
  final TecnicosRepository? repository;

  @override
  Widget build(BuildContext context) {
    final resolvedRepository = repository ?? TecnicosRepositoryImpl();

    return BlocProvider<TecnicosBloc>(
      create: (_) => TecnicosBloc(resolvedRepository)..add(TecnicosRequested()),
      child: _TecnicosView(repository: resolvedRepository),
    );
  }
}

class _TecnicosView extends StatefulWidget {
  const _TecnicosView({required this.repository});

  final TecnicosRepository repository;

  @override
  State<_TecnicosView> createState() => _TecnicosViewState();
}

class _TecnicosViewState extends State<_TecnicosView> {
  final TextEditingController _searchController = TextEditingController();
  Timer? _searchDebounce;
  FiltroEstadoTecnicos _activosFilter = FiltroEstadoTecnicos.activos;

  static const Duration _searchDebounceDuration = Duration(milliseconds: 350);
  static const List<int> _rowsPerPageDefaults = <int>[10, 20, 50];

  /// Misma regla que `CreateTecnicoDto` del backend: mayuscula, minuscula y un
  /// digito o un simbolo. Se valida en el panel para no mandar un alta que el
  /// backend ya sabe que va a rechazar con 400.
  static final RegExp _passwordPattern =
      RegExp(r'(?:(?=.*\d)|(?=.*\W+))(?![.\n])(?=.*[A-Z])(?=.*[a-z]).*$');

  static final RegExp _emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  void _requestPage({int page = 1, int? limit}) {
    context.read<TecnicosBloc>().add(
          TecnicosRequested(
            search: _searchController.text.trim(),
            activos: _activosFilter,
            page: page,
            limit: limit ?? 20,
          ),
        );
  }

  void _onSearchChanged({required int limit}) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(_searchDebounceDuration, () {
      if (!mounted) {
        return;
      }
      _requestPage(page: 1, limit: limit);
    });
  }

  String? _validarNombre(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'El nombre es obligatorio';
    }
    return null;
  }

  String? _validarEmail(String? value) {
    final email = (value ?? '').trim();
    if (email.isEmpty) {
      return 'El email es obligatorio';
    }
    if (!_emailPattern.hasMatch(email)) {
      return 'Ingresa un email valido';
    }
    return null;
  }

  String? _validarPassword(String? value) {
    final password = value ?? '';
    if (password.isEmpty) {
      return 'La contrasena es obligatoria';
    }
    if (password.length < 6) {
      return 'Minimo 6 caracteres';
    }
    if (password.length > 50) {
      return 'Maximo 50 caracteres';
    }
    if (!_passwordPattern.hasMatch(password)) {
      return 'Debe tener mayuscula, minuscula y un numero o simbolo';
    }
    return null;
  }

  Future<void> _openDetalleDialog(TecnicoItem item) async {
    final detalleFuture = widget.repository.fetchTecnicoDetalle(item.id);

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: const Color(0xFF102845),
          title: const Text('Detalle de tecnico'),
          content: SizedBox(
            width: 440,
            child: FutureBuilder<TecnicoDetalle>(
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
                    'No se pudo cargar el detalle del tecnico.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  );
                }

                final detalle = snapshot.data!;
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    _TecnicoDetalleLine(label: 'ID', value: detalle.id),
                    _TecnicoDetalleLine(label: 'Nombre', value: detalle.fullName),
                    _TecnicoDetalleLine(label: 'Email', value: detalle.email),
                    _TecnicoDetalleLine(
                      label: 'Roles',
                      value: detalle.roles.isEmpty ? '-' : detalle.roles.join(', '),
                    ),
                    _TecnicoDetalleLine(
                      label: 'Estado',
                      value: detalle.isActive ? 'ACTIVO' : 'INACTIVO',
                    ),
                    _TecnicoDetalleLine(label: 'Alta', value: detalle.createdAt ?? '-'),
                    _TecnicoDetalleLine(
                      label: 'Ultima modificacion',
                      value: detalle.updatedAt ?? '-',
                    ),
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

  Future<void> _openCreateDialog(BuildContext context) async {
    final formKey = GlobalKey<FormState>();
    final nombreController = TextEditingController();
    final emailController = TextEditingController();
    final passwordController = TextEditingController();
    var activo = true;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            return AlertDialog(
              backgroundColor: const Color(0xFF102845),
              title: const Text('Nuevo tecnico'),
              content: SizedBox(
                width: 520,
                child: SingleChildScrollView(
                  child: Form(
                    key: formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        TextFormField(
                          controller: nombreController,
                          autofocus: true,
                          style: const TextStyle(color: Color(0xFFEAF3FF)),
                          decoration: const InputDecoration(
                            labelText: 'Nombre completo',
                            hintText: 'Ej: Juan Perez',
                          ),
                          validator: _validarNombre,
                        ),
                        const SizedBox(height: 10),
                        TextFormField(
                          controller: emailController,
                          style: const TextStyle(color: Color(0xFFEAF3FF)),
                          keyboardType: TextInputType.emailAddress,
                          decoration: const InputDecoration(
                            labelText: 'Email',
                            hintText: 'Ej: juan@example.com',
                          ),
                          validator: _validarEmail,
                        ),
                        const SizedBox(height: 10),
                        TextFormField(
                          controller: passwordController,
                          obscureText: true,
                          style: const TextStyle(color: Color(0xFFEAF3FF)),
                          decoration: const InputDecoration(
                            labelText: 'Contrasena',
                            helperText: 'Mayuscula, minuscula y un numero o simbolo',
                            helperStyle: TextStyle(color: Color(0xFF9AB1CC)),
                          ),
                          validator: _validarPassword,
                        ),
                        const SizedBox(height: 10),
                        SwitchListTile.adaptive(
                          value: activo,
                          onChanged: (value) => setDialogState(() => activo = value),
                          title: const Text('Activo'),
                          contentPadding: EdgeInsets.zero,
                        ),
                        const SizedBox(height: 4),
                        const Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'El alta crea el usuario con rol tecnico para la app de '
                            'carga de servicios.',
                            style: TextStyle(color: Color(0xFF9AB1CC), fontSize: 12),
                          ),
                        ),
                      ],
                    ),
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
                      context.read<TecnicosBloc>().add(
                            TecnicosCreateRequested(
                              input: CreateTecnicoInput(
                                email: emailController.text,
                                password: passwordController.text,
                                fullName: nombreController.text,
                                isActive: activo,
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
      },
    );

    nombreController.dispose();
    emailController.dispose();
    passwordController.dispose();
  }

  Future<void> _openEditDialog(BuildContext context, TecnicoItem item) async {
    final formKey = GlobalKey<FormState>();
    final nombreController = TextEditingController(text: item.fullName);
    final emailController = TextEditingController(text: item.email);

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: const Color(0xFF102845),
          title: const Text('Editar tecnico'),
          content: SizedBox(
            width: 520,
            child: SingleChildScrollView(
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    TextFormField(
                      controller: nombreController,
                      autofocus: true,
                      style: const TextStyle(color: Color(0xFFEAF3FF)),
                      decoration: const InputDecoration(labelText: 'Nombre completo'),
                      validator: _validarNombre,
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: emailController,
                      style: const TextStyle(color: Color(0xFFEAF3FF)),
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(labelText: 'Email'),
                      validator: _validarEmail,
                    ),
                    const SizedBox(height: 10),
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'La contrasena y el estado no se editan desde aca: el estado '
                        'se cambia con la accion activar o desactivar.',
                        style: TextStyle(color: Color(0xFF9AB1CC), fontSize: 12),
                      ),
                    ),
                  ],
                ),
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
                  context.read<TecnicosBloc>().add(
                        TecnicosUpdateRequested(
                          input: UpdateTecnicoInput(
                            id: item.id,
                            fullName: nombreController.text,
                            email: emailController.text,
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

    nombreController.dispose();
    emailController.dispose();
  }

  Future<void> _confirmarCambioEstado(BuildContext context, TecnicoItem item) async {
    final activar = !item.isActive;

    final confirmado = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: const Color(0xFF102845),
          title: Text(activar ? 'Activar tecnico' : 'Desactivar tecnico'),
          content: SizedBox(
            width: 420,
            child: Text(
              activar
                  ? '${item.fullName} vuelve a poder iniciar sesion en la app de '
                      'carga de servicios.'
                  : '${item.fullName} deja de poder iniciar sesion en la app de '
                      'carga de servicios. Sus servicios y liquidaciones no se tocan.',
              style: const TextStyle(color: Color(0xFFCAE0F5)),
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: Text(activar ? 'Activar' : 'Desactivar'),
            ),
          ],
        );
      },
    );

    if (confirmado != true || !context.mounted) {
      return;
    }

    context.read<TecnicosBloc>().add(
          TecnicosEstadoChangeRequested(tecnicoId: item.id, isActive: activar),
        );
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<TecnicosBloc, TecnicosState>(
      listenWhen: (previous, current) {
        return current is TecnicosFailure || current is TecnicosLoaded;
      },
      listener: (context, state) {
        if (state is TecnicosFailure) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: ${state.message}')),
          );
        }
        if (state is TecnicosLoaded) {
          // El alta puede saltar de filtro para dejar a la vista al tecnico
          // recien creado: el selector acompana ese salto.
          if (state.activos != _activosFilter) {
            setState(() => _activosFilter = state.activos);
          }
          if (state.message != null && state.message!.isNotEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message!)),
            );
          }
        }
      },
      child: BlocBuilder<TecnicosBloc, TecnicosState>(
        builder: (context, state) {
          if (state is TecnicosLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is TecnicosFailure) {
            return Center(child: Text('Error: ${state.message}'));
          }

          if (state is TecnicosLoaded) {
            final effectiveLimit = state.limit > 0 ? state.limit : 20;
            final rowsPerPage = normalizeRowsPerPage(
              effectiveLimit,
              defaults: _rowsPerPageDefaults,
            );
            final rowsPerPageOptions = buildRowsPerPageOptions(
              effectiveLimit,
              defaults: _rowsPerPageDefaults,
            );
            final initialFirstRowIndex = (state.page - 1) * effectiveLimit;
            final hasActiveSearch = state.search.trim().isNotEmpty;
            final estadoTexto = state.activos == FiltroEstadoTecnicos.todos
                ? ''
                : ' ${state.activos.etiqueta.toLowerCase()}';
            final emptyMessage = hasActiveSearch
                ? 'No se encontraron tecnicos$estadoTexto para "${state.search}".'
                : 'No hay tecnicos$estadoTexto para mostrar.';

            return ModulePageLayout(
              title: 'Tecnicos',
              subtitle: 'Alta, edicion y estado de los tecnicos que cargan servicios.',
              trailing: Wrap(
                spacing: 8,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: <Widget>[
                  OutlinedButton.icon(
                    onPressed: () => _openCreateDialog(context),
                    icon: const Icon(Icons.person_add_alt_1_outlined, size: 18),
                    label: const Text('Nuevo tecnico'),
                  ),
                  ModuleStatusChip(label: '${state.total} ${state.activos.etiqueta}'),
                ],
              ),
              child: Column(
                children: <Widget>[
                  TextField(
                    controller: _searchController,
                    onChanged: (_) => _onSearchChanged(limit: effectiveLimit),
                    style: const TextStyle(color: Color(0xFFEAF3FF)),
                    decoration: InputDecoration(
                      hintText: 'Buscar por nombre o email...',
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
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: <Widget>[
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          decoration: BoxDecoration(
                            color: const Color(0xFF122B4A),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: const Color(0x334EA6FF)),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<FiltroEstadoTecnicos>(
                              value: state.activos,
                              onChanged: (value) {
                                if (value == null || value == state.activos) {
                                  return;
                                }
                                setState(() => _activosFilter = value);
                                _requestPage(page: 1, limit: effectiveLimit);
                              },
                              items: FiltroEstadoTecnicos.values
                                  .map(
                                    (filtro) => DropdownMenuItem<FiltroEstadoTecnicos>(
                                      value: filtro,
                                      child: Text(filtro.etiqueta),
                                    ),
                                  )
                                  .toList(),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
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
                          return _TecnicosCompactList(
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
                            onEdit: (item) => _openEditDialog(context, item),
                            onToggleEstado: (item) => _confirmarCambioEstado(context, item),
                          );
                        }

                        return Card(
                          child: LayoutBuilder(
                            builder: (context, constraints) {
                              const minTableWidth = 1000.0;
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
                                        'tecnicos_${state.page}_${state.limit}_'
                                        '${state.total}_${state.activos}',
                                      ),
                                      initialFirstRowIndex:
                                          initialFirstRowIndex < 0 ? 0 : initialFirstRowIndex,
                                      headingRowColor:
                                          WidgetStateProperty.all(const Color(0x1A4EA6FF)),
                                      columnSpacing: 22,
                                      horizontalMargin: 16,
                                      columns: const <DataColumn>[
                                        DataColumn(label: Text('Nombre')),
                                        DataColumn(label: Text('Email')),
                                        DataColumn(label: Text('Roles')),
                                        DataColumn(label: Text('Estado')),
                                        DataColumn(label: Text('Accion')),
                                      ],
                                      source: _TecnicosTableSource(
                                        items: state.items,
                                        total: state.total,
                                        page: state.page,
                                        limit: effectiveLimit,
                                        onView: _openDetalleDialog,
                                        onEdit: (item) => _openEditDialog(context, item),
                                        onToggleEstado: (item) =>
                                            _confirmarCambioEstado(context, item),
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
}

class _TecnicosTableSource extends DataTableSource {
  _TecnicosTableSource({
    required this.items,
    required this.total,
    required this.page,
    required this.limit,
    required this.onView,
    required this.onEdit,
    required this.onToggleEstado,
  });

  final List<TecnicoItem> items;
  final int total;
  final int page;
  final int limit;
  final ValueChanged<TecnicoItem> onView;
  final ValueChanged<TecnicoItem> onEdit;
  final ValueChanged<TecnicoItem> onToggleEstado;

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
        DataCell(Text(item.fullName)),
        DataCell(Text(item.email)),
        DataCell(_TecnicoRolesChips(roles: item.roles)),
        DataCell(_TecnicoEstadoChip(activo: item.isActive)),
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
                tooltip: 'Editar tecnico',
                onPressed: () => onEdit(item),
                icon: const Icon(Icons.edit_outlined, size: 18),
              ),
              IconButton(
                tooltip: item.isActive ? 'Desactivar tecnico' : 'Activar tecnico',
                onPressed: () => onToggleEstado(item),
                icon: Icon(
                  item.isActive ? Icons.person_off_outlined : Icons.person_outline,
                  size: 18,
                ),
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

class _TecnicoEstadoChip extends StatelessWidget {
  const _TecnicoEstadoChip({required this.activo});

  final bool activo;

  @override
  Widget build(BuildContext context) {
    return ModuleStatusChip(
      label: activo ? 'ACTIVO' : 'INACTIVO',
      backgroundColor: activo ? const Color(0x1F0FA960) : const Color(0x1FF4B942),
      foregroundColor: activo ? const Color(0xFF8FF0BC) : const Color(0xFFFFD98B),
    );
  }
}

class _TecnicoRolesChips extends StatelessWidget {
  const _TecnicoRolesChips({required this.roles});

  final List<String> roles;

  @override
  Widget build(BuildContext context) {
    if (roles.isEmpty) {
      return const Text('-');
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        for (final rol in roles)
          Padding(
            padding: const EdgeInsets.only(right: 6),
            child: ModuleStatusChip(label: rol.toUpperCase()),
          ),
      ],
    );
  }
}

class _TecnicosCompactList extends StatelessWidget {
  const _TecnicosCompactList({
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
    required this.onToggleEstado,
  });

  final List<TecnicoItem> items;
  final int total;
  final int page;
  final int limit;
  final int rowsPerPage;
  final List<int> rowsPerPageOptions;
  final ValueChanged<int> onRowsPerPageChanged;
  final ValueChanged<int> onPageChanged;
  final ValueChanged<TecnicoItem> onView;
  final ValueChanged<TecnicoItem> onEdit;
  final ValueChanged<TecnicoItem> onToggleEstado;

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
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                return _TecnicoCompactCard(
                  item: items[index],
                  onView: onView,
                  onEdit: onEdit,
                  onToggleEstado: onToggleEstado,
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

                final rowsSelector = _TecnicosRowsPerPageDropdown(
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

class _TecnicosRowsPerPageDropdown extends StatelessWidget {
  const _TecnicosRowsPerPageDropdown({
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

class _TecnicoCompactCard extends StatelessWidget {
  const _TecnicoCompactCard({
    required this.item,
    required this.onView,
    required this.onEdit,
    required this.onToggleEstado,
  });

  final TecnicoItem item;
  final ValueChanged<TecnicoItem> onView;
  final ValueChanged<TecnicoItem> onEdit;
  final ValueChanged<TecnicoItem> onToggleEstado;

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
                  item.fullName,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: const Color(0xFFEAF3FF),
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ),
              const SizedBox(width: 8),
              _TecnicoEstadoChip(activo: item.isActive),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            item.email,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: const Color(0xFFCAE0F5),
                ),
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: <Widget>[
              if (item.roles.isEmpty)
                const ModuleStatusChip(label: 'SIN ROLES')
              else
                for (final rol in item.roles) ModuleStatusChip(label: rol.toUpperCase()),
            ],
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
              TextButton.icon(
                onPressed: () => onToggleEstado(item),
                icon: Icon(
                  item.isActive ? Icons.person_off_outlined : Icons.person_outline,
                  size: 16,
                ),
                label: Text(item.isActive ? 'Desactivar' : 'Activar'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TecnicoDetalleLine extends StatelessWidget {
  const _TecnicoDetalleLine({required this.label, required this.value});

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
