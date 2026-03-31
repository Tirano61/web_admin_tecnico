import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:web_admin_tecnico/features/precios/domain/precios_repository.dart';

abstract class PreciosEvent {}

class PreciosRequested extends PreciosEvent {}

abstract class PreciosState {}

class PreciosInitial extends PreciosState {}

class PreciosLoading extends PreciosState {}

class PreciosLoaded extends PreciosState {
  PreciosLoaded(this.items);

  final List<PrecioItem> items;
}

class PreciosFailure extends PreciosState {
  PreciosFailure(this.message);

  final String message;
}

class PreciosBloc extends Bloc<PreciosEvent, PreciosState> {
  PreciosBloc(this._repository) : super(PreciosInitial()) {
    on<PreciosRequested>(_onRequested);
  }

  final PreciosRepository _repository;

  Future<void> _onRequested(
    PreciosRequested event,
    Emitter<PreciosState> emit,
  ) async {
    emit(PreciosLoading());
    try {
      final items = await _repository.fetchPrecios();
      emit(PreciosLoaded(items));
    } catch (error) {
      emit(PreciosFailure(error.toString()));
    }
  }
}
