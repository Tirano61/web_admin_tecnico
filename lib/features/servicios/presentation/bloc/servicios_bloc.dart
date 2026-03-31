import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:web_admin_tecnico/features/servicios/domain/servicios_repository.dart';

abstract class ServiciosEvent {}

class ServiciosRequested extends ServiciosEvent {}

abstract class ServiciosState {}

class ServiciosInitial extends ServiciosState {}

class ServiciosLoading extends ServiciosState {}

class ServiciosLoaded extends ServiciosState {
  ServiciosLoaded(this.items);

  final List<ServicioItem> items;
}

class ServiciosFailure extends ServiciosState {
  ServiciosFailure(this.message);

  final String message;
}

class ServiciosBloc extends Bloc<ServiciosEvent, ServiciosState> {
  ServiciosBloc(this._repository) : super(ServiciosInitial()) {
    on<ServiciosRequested>(_onRequested);
  }

  final ServiciosRepository _repository;

  Future<void> _onRequested(
    ServiciosRequested event,
    Emitter<ServiciosState> emit,
  ) async {
    emit(ServiciosLoading());
    try {
      final items = await _repository.fetchServicios();
      emit(ServiciosLoaded(items));
    } catch (error) {
      emit(ServiciosFailure(error.toString()));
    }
  }
}
