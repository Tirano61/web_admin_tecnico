import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:web_admin_tecnico/features/servicios/domain/servicios_repository.dart';

abstract class ServiciosEvent {}

class ServiciosRequested extends ServiciosEvent {
  ServiciosRequested({
    this.search = '',
    this.estado = 'todos',
    this.canal = 'todos',
    this.page = 1,
    this.limit = 6,
  });

  final String search;
  final String estado;
  final String canal;
  final int page;
  final int limit;
}

abstract class ServiciosState {}

class ServiciosInitial extends ServiciosState {}

class ServiciosLoading extends ServiciosState {}

class ServiciosLoaded extends ServiciosState {
  ServiciosLoaded({
    required this.items,
    required this.total,
    required this.page,
    required this.limit,
    required this.search,
    required this.estado,
    required this.canal,
  });

  final List<ServicioItem> items;
  final int total;
  final int page;
  final int limit;
  final String search;
  final String estado;
  final String canal;
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
      final result = await _repository.fetchServicios(
        query: ServiciosQuery(
          search: event.search,
          estado: event.estado,
          canal: event.canal,
          page: event.page,
          limit: event.limit,
        ),
      );
      emit(
        ServiciosLoaded(
          items: result.items,
          total: result.total,
          page: result.page,
          limit: result.limit,
          search: event.search,
          estado: event.estado,
          canal: event.canal,
        ),
      );
    } catch (error) {
      emit(ServiciosFailure(error.toString()));
    }
  }
}
