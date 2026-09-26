import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:web_admin_tecnico/features/tecnicos/domain/tecnicos_repository.dart';

abstract class TecnicosEvent {}

class TecnicosRequested extends TecnicosEvent {
  TecnicosRequested({
    this.search = '',
    this.activos = FiltroEstadoTecnicos.activos,
    this.page = 1,
    this.limit = 20,
  });

  final String search;
  final FiltroEstadoTecnicos activos;
  final int page;
  final int limit;
}

class TecnicosCreateRequested extends TecnicosEvent {
  TecnicosCreateRequested({required this.input});

  final CreateTecnicoInput input;
}

class TecnicosUpdateRequested extends TecnicosEvent {
  TecnicosUpdateRequested({required this.input});

  final UpdateTecnicoInput input;
}

class TecnicosEstadoChangeRequested extends TecnicosEvent {
  TecnicosEstadoChangeRequested({
    required this.tecnicoId,
    required this.isActive,
  });

  final String tecnicoId;
  final bool isActive;
}

abstract class TecnicosState {}

class TecnicosInitial extends TecnicosState {}

class TecnicosLoading extends TecnicosState {}

class TecnicosLoaded extends TecnicosState {
  TecnicosLoaded({
    required this.items,
    required this.total,
    required this.page,
    required this.limit,
    required this.search,
    required this.activos,
    this.message,
  });

  final List<TecnicoItem> items;
  final int total;
  final int page;
  final int limit;
  final String search;
  final FiltroEstadoTecnicos activos;
  final String? message;
}

class TecnicosFailure extends TecnicosState {
  TecnicosFailure(this.message);

  final String message;
}

class TecnicosBloc extends Bloc<TecnicosEvent, TecnicosState> {
  TecnicosBloc(this._repository) : super(TecnicosInitial()) {
    on<TecnicosRequested>(_onRequested);
    on<TecnicosCreateRequested>(_onCreateRequested);
    on<TecnicosUpdateRequested>(_onUpdateRequested);
    on<TecnicosEstadoChangeRequested>(_onEstadoChangeRequested);
  }

  final TecnicosRepository _repository;
  TecnicosQuery _lastQuery = const TecnicosQuery();

  Future<void> _onRequested(
    TecnicosRequested event,
    Emitter<TecnicosState> emit,
  ) async {
    _lastQuery = TecnicosQuery(
      search: event.search,
      activos: event.activos,
      page: event.page,
      limit: event.limit,
    );
    emit(TecnicosLoading());
    await _emitListado(emit, _lastQuery);
  }

  Future<void> _onCreateRequested(
    TecnicosCreateRequested event,
    Emitter<TecnicosState> emit,
  ) async {
    try {
      await _repository.createTecnico(input: event.input);
    } catch (error) {
      emit(TecnicosFailure(error.toString()));
      return;
    }

    // Si el alta quedo inactiva y se esta viendo activos (o al reves), el
    // tecnico recien creado no se veria. Se salta al filtro que lo contiene
    // para que el alta quede a la vista; con TODOS ya se ve.
    final filtroConElAlta = _lastQuery.activos.incluye(isActive: event.input.isActive)
        ? _lastQuery.activos
        : (event.input.isActive ? FiltroEstadoTecnicos.activos : FiltroEstadoTecnicos.inactivos);
    await _emitListado(
      emit,
      _lastQuery.copyWith(page: 1, activos: filtroConElAlta),
      message: 'Tecnico creado correctamente',
    );
  }

  Future<void> _onUpdateRequested(
    TecnicosUpdateRequested event,
    Emitter<TecnicosState> emit,
  ) async {
    try {
      await _repository.updateTecnico(input: event.input);
    } catch (error) {
      emit(TecnicosFailure(error.toString()));
      return;
    }

    await _emitListado(emit, _lastQuery, message: 'Tecnico actualizado correctamente');
  }

  Future<void> _onEstadoChangeRequested(
    TecnicosEstadoChangeRequested event,
    Emitter<TecnicosState> emit,
  ) async {
    try {
      await _repository.updateEstadoTecnico(
        tecnicoId: event.tecnicoId,
        isActive: event.isActive,
      );
    } catch (error) {
      emit(TecnicosFailure(error.toString()));
      return;
    }

    // Con ACTIVOS o INACTIVOS el cambio saca al tecnico del filtro actual: se
    // refresca sobre el mismo filtro y el aviso explica a donde se fue la fila.
    // Con TODOS la fila se queda y solo cambia su estado.
    final String mensaje;
    if (_lastQuery.activos == FiltroEstadoTecnicos.todos) {
      mensaje = event.isActive ? 'Tecnico activado' : 'Tecnico desactivado';
    } else {
      mensaje = event.isActive
          ? 'Tecnico activado: ahora aparece en el filtro ACTIVOS'
          : 'Tecnico desactivado: ahora aparece en el filtro INACTIVOS';
    }

    await _emitListado(emit, _lastQuery, message: mensaje);
  }

  /// Consulta el listado y emite el estado cargado.
  ///
  /// Si la pagina quedo vacia porque las filas se movieron de filtro (un alta o
  /// un cambio de estado), retrocede una pagina en vez de mostrar el vacio.
  Future<void> _emitListado(
    Emitter<TecnicosState> emit,
    TecnicosQuery query, {
    String? message,
  }) async {
    try {
      var queryEfectiva = query;
      var result = await _repository.fetchTecnicos(query: queryEfectiva);

      if (result.items.isEmpty && queryEfectiva.page > 1 && result.total > 0) {
        final ultimaPagina = _ultimaPagina(total: result.total, limit: queryEfectiva.limit);
        if (ultimaPagina < queryEfectiva.page) {
          queryEfectiva = queryEfectiva.copyWith(page: ultimaPagina);
          result = await _repository.fetchTecnicos(query: queryEfectiva);
        }
      }

      _lastQuery = queryEfectiva.copyWith(page: result.page, limit: result.limit);

      emit(
        TecnicosLoaded(
          items: result.items,
          total: result.total,
          page: result.page,
          limit: result.limit,
          search: _lastQuery.search,
          activos: _lastQuery.activos,
          message: message,
        ),
      );
    } catch (error) {
      emit(TecnicosFailure(error.toString()));
    }
  }

  int _ultimaPagina({required int total, required int limit}) {
    if (limit <= 0 || total <= 0) {
      return 1;
    }
    final paginas = (total / limit).ceil();
    return paginas < 1 ? 1 : paginas;
  }
}
