import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:web_admin_tecnico/features/servicios/domain/servicios_repository.dart';

abstract class ServiciosEvent {}

class ServiciosRequested extends ServiciosEvent {
  ServiciosRequested({
    this.search = '',
    this.estado = 'todos',
    this.canal = 'todos',
    this.tecnicoId = 'todos',
    this.page = 1,
    this.limit = 6,
  });

  final String search;
  final String estado;
  final String canal;
  final String tecnicoId;
  final int page;
  final int limit;
}

abstract class ServiciosState {}

class ServiciosInitial extends ServiciosState {}

class ServiciosLoading extends ServiciosState {}

class ServiciosLoaded extends ServiciosState {
  ServiciosLoaded({
    required this.items,
    required this.tecnicos,
    required this.total,
    required this.page,
    required this.limit,
    required this.search,
    required this.estado,
    required this.canal,
    required this.tecnicoId,
  });

  final List<ServicioItem> items;
  final List<ServicioTecnicoOption> tecnicos;
  final int total;
  final int page;
  final int limit;
  final String search;
  final String estado;
  final String canal;
  final String tecnicoId;
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
  List<ServicioTecnicoOption> _cachedTecnicos = const <ServicioTecnicoOption>[];

  Future<void> _ensureTecnicosLoaded() async {
    if (_cachedTecnicos.isNotEmpty) {
      return;
    }

    try {
      final tecnicos = await _repository.fetchTecnicosFiltro();
      _cachedTecnicos = tecnicos;
    } catch (_) {
      _cachedTecnicos = const <ServicioTecnicoOption>[];
    }
  }

  Future<void> _onRequested(
    ServiciosRequested event,
    Emitter<ServiciosState> emit,
  ) async {
    emit(ServiciosLoading());
    try {
      await _ensureTecnicosLoaded();
      final result = await _repository.fetchServicios(
        query: ServiciosQuery(
          search: event.search,
          estado: event.estado,
          canal: event.canal,
          tecnicoId: event.tecnicoId,
          page: event.page,
          limit: event.limit,
        ),
      );
      emit(
        ServiciosLoaded(
          items: result.items,
          tecnicos: _cachedTecnicos,
          total: result.total,
          page: result.page,
          limit: result.limit,
          search: event.search,
          estado: event.estado,
          canal: event.canal,
          tecnicoId: event.tecnicoId,
        ),
      );
    } catch (error) {
      emit(ServiciosFailure(error.toString()));
    }
  }
}
