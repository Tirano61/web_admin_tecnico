import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:web_admin_tecnico/features/clientes/domain/clientes_repository.dart';

abstract class ClientesEvent {}

class ClientesRequested extends ClientesEvent {}

abstract class ClientesState {}

class ClientesInitial extends ClientesState {}

class ClientesLoading extends ClientesState {}

class ClientesLoaded extends ClientesState {
  ClientesLoaded(this.items);

  final List<ClienteItem> items;
}

class ClientesFailure extends ClientesState {
  ClientesFailure(this.message);

  final String message;
}

class ClientesBloc extends Bloc<ClientesEvent, ClientesState> {
  ClientesBloc(this._repository) : super(ClientesInitial()) {
    on<ClientesRequested>(_onRequested);
  }

  final ClientesRepository _repository;

  Future<void> _onRequested(
    ClientesRequested event,
    Emitter<ClientesState> emit,
  ) async {
    emit(ClientesLoading());
    try {
      final items = await _repository.fetchClientes();
      emit(ClientesLoaded(items));
    } catch (error) {
      emit(ClientesFailure(error.toString()));
    }
  }
}
