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

class PreciosCreateCotizacionRequested extends PreciosEvent {
  PreciosCreateCotizacionRequested({required this.input});

  final CreateCotizacionInput input;
}

class PreciosCreateTarifaKmRequested extends PreciosEvent {
  PreciosCreateTarifaKmRequested({required this.input});

  final CreateTarifaKmInput input;
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
    required this.actuales,
    this.message,
  });

  final List<PrecioItem> items;
  final int total;
  final int page;
  final int limit;
  final String search;
  final PreciosActuales actuales;
  final String? message;
}

class PreciosFailure extends PreciosState {
  PreciosFailure(this.message);

  final String message;
}

class PreciosBloc extends Bloc<PreciosEvent, PreciosState> {
  PreciosBloc(this._repository) : super(PreciosInitial()) {
    on<PreciosRequested>(_onRequested);
    on<PreciosCreateCotizacionRequested>(_onCreateCotizacionRequested);
    on<PreciosCreateTarifaKmRequested>(_onCreateTarifaKmRequested);
  }

  final PreciosRepository _repository;
  PreciosQuery _lastQuery = const PreciosQuery();

  Future<void> _onRequested(
    PreciosRequested event,
    Emitter<PreciosState> emit,
  ) async {
    _lastQuery = PreciosQuery(
      search: event.search,
      page: event.page,
      limit: event.limit,
    );
    await _loadAndEmit(emit: emit, showLoading: true);
  }

  Future<void> _onCreateCotizacionRequested(
    PreciosCreateCotizacionRequested event,
    Emitter<PreciosState> emit,
  ) async {
    try {
      await _repository.createCotizacion(input: event.input);
      _lastQuery = _lastQuery.copyWith(page: 1);
      await _loadAndEmit(
        emit: emit,
        successMessage: 'Cotizacion registrada correctamente',
      );
    } catch (error) {
      emit(PreciosFailure(error.toString()));
    }
  }

  Future<void> _onCreateTarifaKmRequested(
    PreciosCreateTarifaKmRequested event,
    Emitter<PreciosState> emit,
  ) async {
    try {
      await _repository.createTarifaKm(input: event.input);
      _lastQuery = _lastQuery.copyWith(page: 1);
      await _loadAndEmit(
        emit: emit,
        successMessage: 'Tarifa km registrada correctamente',
      );
    } catch (error) {
      emit(PreciosFailure(error.toString()));
    }
  }

  Future<void> _loadAndEmit({
    required Emitter<PreciosState> emit,
    bool showLoading = false,
    String? successMessage,
  }) async {
    if (showLoading) {
      emit(PreciosLoading());
    }

    try {
      final resultFuture = _repository.fetchPrecios(query: _lastQuery);
      final actualesFuture = _repository.fetchPreciosActuales();
      final result = await resultFuture;
      final actuales = await actualesFuture;

      emit(
        PreciosLoaded(
          items: result.items,
          total: result.total,
          page: result.page,
          limit: result.limit,
          search: _lastQuery.search,
          actuales: actuales,
          message: successMessage,
        ),
      );
    } catch (error) {
      emit(PreciosFailure(error.toString()));
    }
  }
}
