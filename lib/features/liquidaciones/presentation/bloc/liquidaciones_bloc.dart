import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:web_admin_tecnico/features/liquidaciones/domain/liquidaciones_repository.dart';

abstract class LiquidacionesEvent {}

class LiquidacionesRequested extends LiquidacionesEvent {
  LiquidacionesRequested({
    this.search = '',
    this.estado = 'todos',
    this.page = 1,
    this.limit = 6,
  });

  final String search;
  final String estado;
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

class LiquidacionesAddItemRequested extends LiquidacionesEvent {
  LiquidacionesAddItemRequested({required this.input});

  final AddLiquidacionItemInput input;
}

class LiquidacionesApproveItemRequested extends LiquidacionesEvent {
  LiquidacionesApproveItemRequested({required this.input});

  final ApproveLiquidacionItemInput input;
}

class LiquidacionesDeleteItemRequested extends LiquidacionesEvent {
  LiquidacionesDeleteItemRequested({required this.input});

  final DeleteLiquidacionItemInput input;
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
    required this.search,
    required this.estado,
    required this.tiposSalida,
    required this.tiposServicio,
    this.message,
  });

  final List<LiquidacionItem> items;
  final int total;
  final int page;
  final int limit;
  final String search;
  final String estado;
  final List<LiquidacionCatalogoItem> tiposSalida;
  final List<LiquidacionCatalogoItem> tiposServicio;
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
    on<LiquidacionesAddItemRequested>(_onAddItemRequested);
    on<LiquidacionesApproveItemRequested>(_onApproveItemRequested);
    on<LiquidacionesDeleteItemRequested>(_onDeleteItemRequested);
  }

  final LiquidacionesRepository _repository;
  LiquidacionesQuery _lastQuery = const LiquidacionesQuery();

  Future<void> _onRequested(
    LiquidacionesRequested event,
    Emitter<LiquidacionesState> emit,
  ) async {
    _lastQuery = LiquidacionesQuery(
      search: event.search,
      estado: event.estado,
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
      emit(LiquidacionesFailure(error.toString()));
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
      emit(LiquidacionesFailure(error.toString()));
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
      emit(LiquidacionesFailure(error.toString()));
    }
  }

  Future<void> _onAddItemRequested(
    LiquidacionesAddItemRequested event,
    Emitter<LiquidacionesState> emit,
  ) async {
    try {
      await _repository.addLiquidacionItem(input: event.input);
      await _loadAndEmit(
        emit: emit,
        successMessage: 'Item agregado a liquidacion',
      );
    } catch (error) {
      emit(LiquidacionesFailure(error.toString()));
    }
  }

  Future<void> _onApproveItemRequested(
    LiquidacionesApproveItemRequested event,
    Emitter<LiquidacionesState> emit,
  ) async {
    try {
      await _repository.approveLiquidacionItem(input: event.input);
      await _loadAndEmit(
        emit: emit,
        successMessage: 'Item aprobado correctamente',
      );
    } catch (error) {
      emit(LiquidacionesFailure(error.toString()));
    }
  }

  Future<void> _onDeleteItemRequested(
    LiquidacionesDeleteItemRequested event,
    Emitter<LiquidacionesState> emit,
  ) async {
    try {
      await _repository.deleteLiquidacionItem(input: event.input);
      await _loadAndEmit(
        emit: emit,
        successMessage: 'Item eliminado correctamente',
      );
    } catch (error) {
      emit(LiquidacionesFailure(error.toString()));
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
          search: _lastQuery.search,
          estado: _lastQuery.estado,
          tiposSalida: tiposSalida,
          tiposServicio: tiposServicio,
          message: successMessage,
        ),
      );
    } catch (error) {
      emit(LiquidacionesFailure(error.toString()));
    }
  }
}
