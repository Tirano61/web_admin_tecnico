import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:web_admin_tecnico/features/liquidaciones/domain/liquidaciones_repository.dart';

abstract class LiquidacionesEvent {}

class LiquidacionesRequested extends LiquidacionesEvent {}

abstract class LiquidacionesState {}

class LiquidacionesInitial extends LiquidacionesState {}

class LiquidacionesLoading extends LiquidacionesState {}

class LiquidacionesLoaded extends LiquidacionesState {
  LiquidacionesLoaded(this.items);

  final List<LiquidacionItem> items;
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
      final items = await _repository.fetchLiquidaciones();
      emit(LiquidacionesLoaded(items));
    } catch (error) {
      emit(LiquidacionesFailure(error.toString()));
    }
  }
}
