import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:web_admin_tecnico/features/catalogos/domain/catalogos_repository.dart';

abstract class CatalogosEvent {}

class CatalogosRequested extends CatalogosEvent {
  CatalogosRequested({
    this.search = '',
    this.tipo = 'todos',
    this.page = 1,
    this.limit = 6,
  });

  final String search;
  final String tipo;
  final int page;
  final int limit;
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
  });

  final List<CatalogoItem> items;
  final int total;
  final int page;
  final int limit;
  final String search;
  final String tipo;
}

class CatalogosFailure extends CatalogosState {
  CatalogosFailure(this.message);

  final String message;
}

class CatalogosBloc extends Bloc<CatalogosEvent, CatalogosState> {
  CatalogosBloc(this._repository) : super(CatalogosInitial()) {
    on<CatalogosRequested>(_onRequested);
  }

  final CatalogosRepository _repository;

  Future<void> _onRequested(
    CatalogosRequested event,
    Emitter<CatalogosState> emit,
  ) async {
    emit(CatalogosLoading());
    try {
      final result = await _repository.fetchCatalogos(
        query: CatalogosQuery(
          search: event.search,
          tipo: event.tipo,
          page: event.page,
          limit: event.limit,
        ),
      );
      emit(
        CatalogosLoaded(
          items: result.items,
          total: result.total,
          page: result.page,
          limit: result.limit,
          search: event.search,
          tipo: event.tipo,
        ),
      );
    } catch (error) {
      emit(CatalogosFailure(error.toString()));
    }
  }
}
