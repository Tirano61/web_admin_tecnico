import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:web_admin_tecnico/features/catalogos/domain/catalogos_repository.dart';

abstract class CatalogosEvent {}

class CatalogosRequested extends CatalogosEvent {}

abstract class CatalogosState {}

class CatalogosInitial extends CatalogosState {}

class CatalogosLoading extends CatalogosState {}

class CatalogosLoaded extends CatalogosState {
  CatalogosLoaded(this.items);

  final List<CatalogoItem> items;
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
      final items = await _repository.fetchCatalogos();
      emit(CatalogosLoaded(items));
    } catch (error) {
      emit(CatalogosFailure(error.toString()));
    }
  }
}
