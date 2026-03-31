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
  });

  final List<LiquidacionItem> items;
  final int total;
  final int page;
  final int limit;
  final String search;
  final String estado;
}

class LiquidacionesFailure extends LiquidacionesState {
  LiquidacionesFailure(this.message);

  final String message;
}

class LiquidacionesBloc extends Bloc<LiquidacionesEvent, LiquidacionesState> {
  LiquidacionesBloc(this._repository) : super(LiquidacionesInitial()) {
    on<LiquidacionesRequested>(_onRequested);
  }

  final LiquidacionesRepository _repository;

  Future<void> _onRequested(
    LiquidacionesRequested event,
    Emitter<LiquidacionesState> emit,
  ) async {
    emit(LiquidacionesLoading());
    try {
      final result = await _repository.fetchLiquidaciones(
        query: LiquidacionesQuery(
          search: event.search,
          estado: event.estado,
          page: event.page,
          limit: event.limit,
        ),
      );
      emit(
        LiquidacionesLoaded(
          items: result.items,
          total: result.total,
          page: result.page,
          limit: result.limit,
          search: event.search,
          estado: event.estado,
        ),
      );
    } catch (error) {
      emit(LiquidacionesFailure(error.toString()));
    }
  }
}
