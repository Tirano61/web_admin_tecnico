import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:web_admin_tecnico/core/error/app_failure.dart';
import 'package:web_admin_tecnico/features/liquidaciones/domain/liquidaciones_repository.dart';

abstract class LiquidacionesEvent {}

class LiquidacionesRequested extends LiquidacionesEvent {
  LiquidacionesRequested({
    this.tecnicoId,
    this.aprobado,
    this.page = 1,
    this.limit = 20,
  });

  final String? tecnicoId;
  final bool? aprobado;
  final int page;
  final int limit;
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

abstract class LiquidacionesState {}

class LiquidacionesInitial extends LiquidacionesState {}

class LiquidacionesLoading extends LiquidacionesState {}

class LiquidacionesLoaded extends LiquidacionesState {
  LiquidacionesLoaded({
    required this.items,
    required this.total,
    required this.page,
    required this.limit,
    required this.tecnicoId,
    required this.aprobado,
    required this.tiposSalida,
    required this.tiposServicio,
    this.message,
  });

  final List<LiquidacionItem> items;
  final int total;
  final int page;
  final int limit;
  final String? tecnicoId;
  final bool? aprobado;
  final List<TipoSalidaCatalogoItem> tiposSalida;
  final List<TipoServicioCatalogoItem> tiposServicio;
  final String? message;
}

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
    on<LiquidacionesCreateTipoSalidaRequested>(_onCreateTipoSalidaRequested);
    on<LiquidacionesUpdateTipoSalidaRequested>(_onUpdateTipoSalidaRequested);
    on<LiquidacionesCreateTipoServicioRequested>(_onCreateTipoServicioRequested);
    on<LiquidacionesUpdateTipoServicioRequested>(_onUpdateTipoServicioRequested);
  }

  final LiquidacionesRepository _repository;
  LiquidacionesQuery _lastQuery = const LiquidacionesQuery();

  Future<void> _onRequested(
    LiquidacionesRequested event,
    Emitter<LiquidacionesState> emit,
  ) async {
    _lastQuery = LiquidacionesQuery(
      tecnicoId: event.tecnicoId,
      aprobado: event.aprobado,
      page: event.page,
      limit: event.limit,
    );
    await _loadAndEmit(emit: emit, showLoading: true);
  }

  Future<void> _onCreateRequested(
    LiquidacionesCreateRequested event,
    Emitter<LiquidacionesState> emit,
  ) async {
    try {
      await _repository.createLiquidacion(input: event.input);
      _lastQuery = _lastQuery.copyWith(page: 1);
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
      final resultFuture = _repository.fetchLiquidaciones(query: _lastQuery);
      final tiposSalidaFuture = _repository.fetchTiposSalida();
      final tiposServicioFuture = _repository.fetchTiposServicio();

      final result = await resultFuture;
      final tiposSalida = await tiposSalidaFuture;
      final tiposServicio = await tiposServicioFuture;

      emit(
        LiquidacionesLoaded(
          items: result.items,
          total: result.total,
          page: result.page,
          limit: result.limit,
          tecnicoId: _lastQuery.tecnicoId,
          aprobado: _lastQuery.aprobado,
          tiposSalida: tiposSalida,
          tiposServicio: tiposServicio,
          message: successMessage,
        ),
      );
    } catch (error) {
      emit(LiquidacionesFailure(_errorMessage(error)));
    }
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
