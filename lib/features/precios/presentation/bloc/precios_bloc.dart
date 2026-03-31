import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:web_admin_tecnico/features/precios/domain/precios_repository.dart';

abstract class PreciosEvent {}

class PreciosRequested extends PreciosEvent {
  PreciosRequested({
    this.search = '',
    this.page = 1,
    this.limit = 6,
  });

  final String search;
  final int page;
  final int limit;
}

abstract class PreciosState {}

class PreciosInitial extends PreciosState {}

class PreciosLoading extends PreciosState {}

class PreciosLoaded extends PreciosState {
  PreciosLoaded({
    required this.items,
    required this.total,
    required this.page,
    required this.limit,
    required this.search,
  });

  final List<PrecioItem> items;
  final int total;
  final int page;
  final int limit;
  final String search;
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
      final result = await _repository.fetchPrecios(
        query: PreciosQuery(
          search: event.search,
          page: event.page,
          limit: event.limit,
        ),
      );
      emit(
        PreciosLoaded(
          items: result.items,
          total: result.total,
          page: result.page,
          limit: result.limit,
          search: event.search,
        ),
      );
    } catch (error) {
      emit(PreciosFailure(error.toString()));
    }
  }
}
