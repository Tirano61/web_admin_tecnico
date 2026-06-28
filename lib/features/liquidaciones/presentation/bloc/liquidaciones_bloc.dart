import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:web_admin_tecnico/core/error/app_failure.dart';
import 'package:web_admin_tecnico/features/liquidaciones/domain/liquidaciones_repository.dart';

abstract class LiquidacionesEvent {}

class LiquidacionesRequested extends LiquidacionesEvent {
  LiquidacionesRequested({
    this.tecnicoId,
    this.aprobado,
    this.estado,
    this.liquidacionesPage = 1,
    this.liquidacionesLimit = 20,
    this.pendientesPage = 1,
    this.pendientesLimit = 20,
  });

  final String? tecnicoId;
  final bool? aprobado;
  final String? estado;
  final int liquidacionesPage;
  final int liquidacionesLimit;
  final int pendientesPage;
  final int pendientesLimit;
}

class LiquidacionesCreateRequested extends LiquidacionesEvent {
  LiquidacionesCreateRequested({required this.input});

  final CreateLiquidacionInput input;
}

class LiquidacionesUpdateRequested extends LiquidacionesEvent {
  LiquidacionesUpdateRequested({required this.input});

  final UpdateLiquidacionInput input;
}

class LiquidacionesApproveRequested extends LiquidacionesEvent {
  LiquidacionesApproveRequested(this.liquidacionId);

  final String liquidacionId;
}

class LiquidacionesReopenRequested extends LiquidacionesEvent {
  LiquidacionesReopenRequested({required this.input});

  final ReopenLiquidacionInput input;
}

class LiquidacionesCreateTipoSalidaRequested extends LiquidacionesEvent {
  LiquidacionesCreateTipoSalidaRequested({required this.input});

  final CreateTipoSalidaInput input;
}

class LiquidacionesUpdateTipoSalidaRequested extends LiquidacionesEvent {
  LiquidacionesUpdateTipoSalidaRequested({required this.input});

  final UpdateTipoSalidaInput input;
}

class LiquidacionesCreateTipoServicioRequested extends LiquidacionesEvent {
  LiquidacionesCreateTipoServicioRequested({required this.input});

  final CreateTipoServicioInput input;
}

class LiquidacionesUpdateTipoServicioRequested extends LiquidacionesEvent {
  LiquidacionesUpdateTipoServicioRequested({required this.input});

  final UpdateTipoServicioInput input;
}

class LiquidacionItemsCacheUpdated extends LiquidacionesEvent {
  LiquidacionItemsCacheUpdated({
    required this.liquidacionId,
    required this.items,
  });

  final String liquidacionId;
  final List<LiquidacionItemDetalle> items;
}

abstract class LiquidacionesState {}

class LiquidacionesInitial extends LiquidacionesState {}

class LiquidacionesLoading extends LiquidacionesState {}

class LiquidacionesLoaded extends LiquidacionesState {
  LiquidacionesLoaded({
    required this.liquidaciones,
    required this.liquidacionesTotal,
    required this.liquidacionesPage,
    required this.liquidacionesLimit,
    required this.pendientes,
    required this.pendientesTotal,
    required this.pendientesPage,
    required this.pendientesLimit,
    required this.tecnicoId,
    required this.aprobado,
    required this.tiposSalida,
    required this.tiposServicio,
    required this.itemDetallesByLiquidacion,
    this.message,
  });

  final List<LiquidacionItem> liquidaciones;
  final int liquidacionesTotal;
  final int liquidacionesPage;
  final int liquidacionesLimit;
  final List<LiquidacionPendienteItem> pendientes;
  final int pendientesTotal;
  final int pendientesPage;
  final int pendientesLimit;
  final String? tecnicoId;
  final bool? aprobado;
  final List<TipoSalidaCatalogoItem> tiposSalida;
  final List<TipoServicioCatalogoItem> tiposServicio;
  final Map<String, List<LiquidacionItemDetalle>> itemDetallesByLiquidacion;
  final String? message;

  LiquidacionesLoaded copyWith({
    List<LiquidacionItem>? liquidaciones,
    int? liquidacionesTotal,
    int? liquidacionesPage,
    int? liquidacionesLimit,
    List<LiquidacionPendienteItem>? pendientes,
    int? pendientesTotal,
    int? pendientesPage,
    int? pendientesLimit,
    String? tecnicoId,
    Object? aprobado = _aprobadoNoChange,
    List<TipoSalidaCatalogoItem>? tiposSalida,
    List<TipoServicioCatalogoItem>? tiposServicio,
    Map<String, List<LiquidacionItemDetalle>>? itemDetallesByLiquidacion,
    Object? message = _messageNoChange,
  }) {
    return LiquidacionesLoaded(
      liquidaciones: liquidaciones ?? this.liquidaciones,
      liquidacionesTotal: liquidacionesTotal ?? this.liquidacionesTotal,
      liquidacionesPage: liquidacionesPage ?? this.liquidacionesPage,
      liquidacionesLimit: liquidacionesLimit ?? this.liquidacionesLimit,
      pendientes: pendientes ?? this.pendientes,
      pendientesTotal: pendientesTotal ?? this.pendientesTotal,
      pendientesPage: pendientesPage ?? this.pendientesPage,
      pendientesLimit: pendientesLimit ?? this.pendientesLimit,
      tecnicoId: tecnicoId ?? this.tecnicoId,
      aprobado: identical(aprobado, _aprobadoNoChange)
          ? this.aprobado
          : aprobado as bool?,
      tiposSalida: tiposSalida ?? this.tiposSalida,
      tiposServicio: tiposServicio ?? this.tiposServicio,
      itemDetallesByLiquidacion:
          itemDetallesByLiquidacion ?? this.itemDetallesByLiquidacion,
      message: identical(message, _messageNoChange)
          ? this.message
          : message as String?,
    );
  }
}

const Object _aprobadoNoChange = Object();
const Object _messageNoChange = Object();

class LiquidacionesFailure extends LiquidacionesState {
  LiquidacionesFailure(this.message);

  final String message;
}

class LiquidacionesBloc extends Bloc<LiquidacionesEvent, LiquidacionesState> {
  LiquidacionesBloc(this._repository) : super(LiquidacionesInitial()) {
    on<LiquidacionesRequested>(_onRequested);
    on<LiquidacionesCreateRequested>(_onCreateRequested);
    on<LiquidacionesUpdateRequested>(_onUpdateRequested);
    on<LiquidacionesApproveRequested>(_onApproveRequested);
    on<LiquidacionesReopenRequested>(_onReopenRequested);
    on<LiquidacionesCreateTipoSalidaRequested>(_onCreateTipoSalidaRequested);
    on<LiquidacionesUpdateTipoSalidaRequested>(_onUpdateTipoSalidaRequested);
    on<LiquidacionesCreateTipoServicioRequested>(_onCreateTipoServicioRequested);
    on<LiquidacionesUpdateTipoServicioRequested>(_onUpdateTipoServicioRequested);
    on<LiquidacionItemsCacheUpdated>(_onItemsCacheUpdated);
  }

  final LiquidacionesRepository _repository;
  LiquidacionesQuery _lastLiquidacionesQuery = const LiquidacionesQuery();
  LiquidacionesPendientesQuery _lastPendientesQuery =
      const LiquidacionesPendientesQuery();
  final Map<String, List<LiquidacionItemDetalle>> _itemsCacheByLiquidacion =
      <String, List<LiquidacionItemDetalle>>{};

  Future<void> _onRequested(
    LiquidacionesRequested event,
    Emitter<LiquidacionesState> emit,
  ) async {
    _lastLiquidacionesQuery = LiquidacionesQuery(
      tecnicoId: event.tecnicoId,
      aprobado: event.aprobado,
      estado: event.estado,
      page: event.liquidacionesPage,
      limit: event.liquidacionesLimit,
    );
    _lastPendientesQuery = LiquidacionesPendientesQuery(
      tecnicoId: event.tecnicoId,
      page: event.pendientesPage,
      limit: event.pendientesLimit,
    );
    await _loadAndEmit(emit: emit, showLoading: true);
  }

  Future<void> _onCreateRequested(
    LiquidacionesCreateRequested event,
    Emitter<LiquidacionesState> emit,
  ) async {
    try {
      await _repository.createLiquidacion(input: event.input);
      await _loadAndEmit(
        emit: emit,
        successMessage: 'Liquidacion creada correctamente',
      );
    } catch (error) {
      emit(LiquidacionesFailure(_errorMessage(error)));
    }
  }

  Future<void> _onUpdateRequested(
    LiquidacionesUpdateRequested event,
    Emitter<LiquidacionesState> emit,
  ) async {
    try {
      await _repository.updateLiquidacion(input: event.input);
      await _loadAndEmit(
        emit: emit,
        successMessage: 'Cabecera de liquidacion actualizada',
      );
    } catch (error) {
      emit(LiquidacionesFailure(_errorMessage(error)));
    }
  }

  Future<void> _onApproveRequested(
    LiquidacionesApproveRequested event,
    Emitter<LiquidacionesState> emit,
  ) async {
    try {
      await _repository.approveLiquidacion(event.liquidacionId);
      await _loadAndEmit(
        emit: emit,
        successMessage: 'Liquidacion aprobada correctamente',
      );
    } catch (error) {
      emit(LiquidacionesFailure(_errorMessage(error)));
    }
  }

  Future<void> _onReopenRequested(
    LiquidacionesReopenRequested event,
    Emitter<LiquidacionesState> emit,
  ) async {
    try {
      await _repository.reopenLiquidacion(input: event.input);
      await _loadAndEmit(
        emit: emit,
        successMessage: 'Liquidacion reabierta correctamente',
      );
    } catch (error) {
      emit(LiquidacionesFailure(_errorMessage(error)));
    }
  }

  Future<void> _onCreateTipoSalidaRequested(
    LiquidacionesCreateTipoSalidaRequested event,
    Emitter<LiquidacionesState> emit,
  ) async {
    try {
      await _repository.createTipoSalida(input: event.input);
      await _loadAndEmit(
        emit: emit,
        successMessage: 'Tipo salida creado correctamente',
      );
    } catch (error) {
      emit(LiquidacionesFailure(_errorMessage(error)));
    }
  }

  Future<void> _onUpdateTipoSalidaRequested(
    LiquidacionesUpdateTipoSalidaRequested event,
    Emitter<LiquidacionesState> emit,
  ) async {
    try {
      await _repository.updateTipoSalida(input: event.input);
      await _loadAndEmit(
        emit: emit,
        successMessage: 'Tipo salida actualizado correctamente',
      );
    } catch (error) {
      emit(LiquidacionesFailure(_errorMessage(error)));
    }
  }

  Future<void> _onCreateTipoServicioRequested(
    LiquidacionesCreateTipoServicioRequested event,
    Emitter<LiquidacionesState> emit,
  ) async {
    try {
      await _repository.createTipoServicio(input: event.input);
      await _loadAndEmit(
        emit: emit,
        successMessage: 'Tipo servicio creado correctamente',
      );
    } catch (error) {
      emit(LiquidacionesFailure(_errorMessage(error)));
    }
  }

  Future<void> _onUpdateTipoServicioRequested(
    LiquidacionesUpdateTipoServicioRequested event,
    Emitter<LiquidacionesState> emit,
  ) async {
    try {
      await _repository.updateTipoServicio(input: event.input);
      await _loadAndEmit(
        emit: emit,
        successMessage: 'Tipo servicio actualizado correctamente',
      );
    } catch (error) {
      emit(LiquidacionesFailure(_errorMessage(error)));
    }
  }

  Future<void> _loadAndEmit({
    required Emitter<LiquidacionesState> emit,
    bool showLoading = false,
    String? successMessage,
  }) async {
    if (showLoading) {
      emit(LiquidacionesLoading());
    }

    try {
      final liquidacionesFuture =
          _repository.fetchLiquidaciones(query: _lastLiquidacionesQuery);
      final pendientesFuture =
          _repository.fetchLiquidacionesPendientes(query: _lastPendientesQuery);
      final tiposSalidaFuture = _repository.fetchTiposSalida();
      final tiposServicioFuture = _repository.fetchTiposServicio();

      final liquidacionesResult = await liquidacionesFuture;
      final pendientesResult = await pendientesFuture;
      final tiposSalida = await tiposSalidaFuture;
      final tiposServicio = await tiposServicioFuture;

      emit(
        LiquidacionesLoaded(
          liquidaciones: liquidacionesResult.items,
          liquidacionesTotal: liquidacionesResult.total,
          liquidacionesPage: liquidacionesResult.page,
          liquidacionesLimit: liquidacionesResult.limit,
          pendientes: pendientesResult.items,
          pendientesTotal: pendientesResult.total,
          pendientesPage: pendientesResult.page,
          pendientesLimit: pendientesResult.limit,
          tecnicoId: _lastLiquidacionesQuery.tecnicoId,
          aprobado: _lastLiquidacionesQuery.aprobado,
          tiposSalida: tiposSalida,
          tiposServicio: tiposServicio,
          itemDetallesByLiquidacion: _snapshotItemCache(),
          message: successMessage,
        ),
      );
    } catch (error) {
      emit(LiquidacionesFailure(_errorMessage(error)));
    }
  }

  Future<void> _onItemsCacheUpdated(
    LiquidacionItemsCacheUpdated event,
    Emitter<LiquidacionesState> emit,
  ) async {
    _itemsCacheByLiquidacion[event.liquidacionId] =
        List<LiquidacionItemDetalle>.from(event.items);

    final current = state;
    if (current is LiquidacionesLoaded) {
      emit(
        current.copyWith(
          itemDetallesByLiquidacion: _snapshotItemCache(),
          message: null,
        ),
      );
    }
  }

  Map<String, List<LiquidacionItemDetalle>> _snapshotItemCache() {
    final snapshot = <String, List<LiquidacionItemDetalle>>{};

    _itemsCacheByLiquidacion.forEach((key, value) {
      snapshot[key] = List<LiquidacionItemDetalle>.from(value);
    });

    return snapshot;
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
}
