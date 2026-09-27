import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:web_admin_tecnico/features/dashboard/domain/dashboard_repository.dart';

abstract class DashboardEvent {}

class DashboardRequested extends DashboardEvent {}

abstract class DashboardState {}

class DashboardInitial extends DashboardState {}

class DashboardLoading extends DashboardState {}

class DashboardLoaded extends DashboardState {
  DashboardLoaded({
    required this.metricas,
    required this.inicioMes,
    required this.actualizadoEn,
  });

  final DashboardMetricas metricas;
  final DateTime inicioMes;
  final DateTime actualizadoEn;
}

class DashboardFailure extends DashboardState {
  DashboardFailure(this.message);

  final String message;
}

class DashboardBloc extends Bloc<DashboardEvent, DashboardState> {
  DashboardBloc(this._repository, {DateTime Function()? reloj})
      : _reloj = reloj ?? DateTime.now,
        super(DashboardInitial()) {
    on<DashboardRequested>(_onRequested);
  }

  final DashboardRepository _repository;

  /// Inyectable para tests: el periodo y la antiguedad dependen de "hoy".
  final DateTime Function() _reloj;

  Future<void> _onRequested(
    DashboardRequested event,
    Emitter<DashboardState> emit,
  ) async {
    emit(DashboardLoading());
    try {
      final ahora = _reloj();
      final query = DashboardQuery.paraFecha(ahora);
      final metricas = await _repository.fetchMetricas(query: query);
      if (metricas.sinDatos) {
        emit(DashboardFailure('No se pudieron cargar las metricas del panel.'));
        return;
      }
      emit(
        DashboardLoaded(
          metricas: metricas,
          inicioMes: query.inicioMes,
          actualizadoEn: ahora,
        ),
      );
    } catch (error) {
      emit(DashboardFailure(error.toString()));
    }
  }
}
