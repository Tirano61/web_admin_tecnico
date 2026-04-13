import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:web_admin_tecnico/features/catalogos/domain/catalogos_repository.dart';

abstract class CatalogosEvent {}

class CatalogosRequested extends CatalogosEvent {
  CatalogosRequested({
    this.search = '',
    this.tipo = 'todos',
    this.page = 1,
    this.limit = 20,
    this.activo,
  });

  final String search;
  final String tipo;
  final int page;
  final int limit;
  final bool? activo;
}

class CatalogosCreateRequested extends CatalogosEvent {
  CatalogosCreateRequested({required this.input});

  final CreateCatalogoInput input;
}

class CatalogosUpdateRequested extends CatalogosEvent {
  CatalogosUpdateRequested({required this.input});

  final UpdateCatalogoInput input;
}

abstract class CatalogosState {}

class CatalogosInitial extends CatalogosState {}

class CatalogosLoading extends CatalogosState {}

class CatalogosLoaded extends CatalogosState {
  CatalogosLoaded({
    required this.items,
    required this.total,
    required this.page,
    required this.limit,
    required this.search,
    required this.tipo,
    this.message,
  });

  final List<CatalogoItem> items;
  final int total;
  final int page;
  final int limit;
  final String search;
  final String tipo;
  final String? message;
}

class CatalogosFailure extends CatalogosState {
  CatalogosFailure(this.message);

  final String message;
}

class CatalogosBloc extends Bloc<CatalogosEvent, CatalogosState> {
  CatalogosBloc(this._repository) : super(CatalogosInitial()) {
    on<CatalogosRequested>(_onRequested);
    on<CatalogosCreateRequested>(_onCreateRequested);
    on<CatalogosUpdateRequested>(_onUpdateRequested);
  }

  final CatalogosRepository _repository;
  CatalogosQuery _lastQuery = const CatalogosQuery();

  Future<void> _onRequested(
    CatalogosRequested event,
    Emitter<CatalogosState> emit,
  ) async {
    _lastQuery = CatalogosQuery(
      search: event.search,
      tipo: event.tipo,
      page: event.page,
      limit: event.limit,
      activo: event.activo,
    );
    emit(CatalogosLoading());
    try {
      final result = await _repository.fetchCatalogos(query: _lastQuery);
      emit(
        CatalogosLoaded(
          items: result.items,
          total: result.total,
          page: result.page,
          limit: result.limit,
          search: _lastQuery.search,
          tipo: _lastQuery.tipo,
        ),
      );
    } catch (error) {
      emit(CatalogosFailure(error.toString()));
    }
  }

  Future<void> _onCreateRequested(
    CatalogosCreateRequested event,
    Emitter<CatalogosState> emit,
  ) async {
    try {
      await _repository.createCatalogo(input: event.input);
      final result = await _repository.fetchCatalogos(query: _lastQuery.copyWith(page: 1));
      _lastQuery = _lastQuery.copyWith(page: 1);
      emit(
        CatalogosLoaded(
          items: result.items,
          total: result.total,
          page: result.page,
          limit: result.limit,
          search: _lastQuery.search,
          tipo: _lastQuery.tipo,
          message: 'Registro creado correctamente',
        ),
      );
    } catch (error) {
      emit(CatalogosFailure(error.toString()));
    }
  }

  Future<void> _onUpdateRequested(
    CatalogosUpdateRequested event,
    Emitter<CatalogosState> emit,
  ) async {
    try {
      await _repository.updateCatalogo(input: event.input);
      final result = await _repository.fetchCatalogos(query: _lastQuery);
      emit(
        CatalogosLoaded(
          items: result.items,
          total: result.total,
          page: result.page,
          limit: result.limit,
          search: _lastQuery.search,
          tipo: _lastQuery.tipo,
          message: 'Registro actualizado correctamente',
        ),
      );
    } catch (error) {
      emit(CatalogosFailure(error.toString()));
    }
  }
}
