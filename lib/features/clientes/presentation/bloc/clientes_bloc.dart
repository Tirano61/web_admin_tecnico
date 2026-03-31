import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:web_admin_tecnico/features/clientes/domain/clientes_repository.dart';

abstract class ClientesEvent {}

class ClientesRequested extends ClientesEvent {
  ClientesRequested({
    this.search = '',
    this.page = 1,
    this.limit = 6,
  });

  final String search;
  final int page;
  final int limit;
}

class ClientesCreateRequested extends ClientesEvent {
  ClientesCreateRequested({required this.input});

  final CreateClienteInput input;
}

abstract class ClientesState {}

class ClientesInitial extends ClientesState {}

class ClientesLoading extends ClientesState {}

class ClientesLoaded extends ClientesState {
  ClientesLoaded({
    required this.items,
    required this.total,
    required this.page,
    required this.limit,
    required this.search,
    this.message,
  });

  final List<ClienteItem> items;
  final int total;
  final int page;
  final int limit;
  final String search;
  final String? message;
}

class ClientesFailure extends ClientesState {
  ClientesFailure(this.message);

  final String message;
}

class ClientesBloc extends Bloc<ClientesEvent, ClientesState> {
  ClientesBloc(this._repository) : super(ClientesInitial()) {
    on<ClientesRequested>(_onRequested);
    on<ClientesCreateRequested>(_onCreateRequested);
  }

  final ClientesRepository _repository;
  ClientesQuery _lastQuery = const ClientesQuery();

  Future<void> _onRequested(
    ClientesRequested event,
    Emitter<ClientesState> emit,
  ) async {
    _lastQuery = ClientesQuery(
      search: event.search,
      page: event.page,
      limit: event.limit,
    );
    emit(ClientesLoading());
    try {
      final result = await _repository.fetchClientes(query: _lastQuery);
      emit(
        ClientesLoaded(
          items: result.items,
          total: result.total,
          page: result.page,
          limit: result.limit,
          search: _lastQuery.search,
        ),
      );
    } catch (error) {
      emit(ClientesFailure(error.toString()));
    }
  }

  Future<void> _onCreateRequested(
    ClientesCreateRequested event,
    Emitter<ClientesState> emit,
  ) async {
    try {
      await _repository.createCliente(input: event.input);
      final result = await _repository.fetchClientes(query: _lastQuery.copyWith(page: 1));
      _lastQuery = _lastQuery.copyWith(page: 1);
      emit(
        ClientesLoaded(
          items: result.items,
          total: result.total,
          page: result.page,
          limit: result.limit,
          search: _lastQuery.search,
          message: 'Cliente creado correctamente',
        ),
      );
    } catch (error) {
      emit(ClientesFailure(error.toString()));
    }
  }
}
