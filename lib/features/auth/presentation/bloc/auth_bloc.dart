import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:web_admin_tecnico/core/auth/auth_session.dart';
import 'package:web_admin_tecnico/features/auth/domain/auth_repository.dart';

abstract class AuthEvent {}

class AuthSubmitted extends AuthEvent {
  AuthSubmitted({required this.email, required this.password});

  final String email;
  final String password;
}

class AuthLogoutRequested extends AuthEvent {}

abstract class AuthState {}

class AuthInitial extends AuthState {}

class AuthLoading extends AuthState {}

class AuthAuthenticated extends AuthState {
  AuthAuthenticated(this.session);

  final AuthSession session;
}

class AuthFailureState extends AuthState {
  AuthFailureState(this.message);

  final String message;
}

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  AuthBloc(this._repository) : super(AuthInitial()) {
    on<AuthSubmitted>(_onSubmitted);
    on<AuthLogoutRequested>(_onLogoutRequested);
  }

  final AuthRepository _repository;

  Future<void> _onSubmitted(AuthSubmitted event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    try {
      final session = await _repository.login(
        LoginInput(email: event.email, password: event.password),
      );
      emit(AuthAuthenticated(session));
    } catch (error) {
      emit(AuthFailureState(error.toString()));
    }
  }

  Future<void> _onLogoutRequested(
    AuthLogoutRequested event,
    Emitter<AuthState> emit,
  ) async {
    await _repository.logout();
    emit(AuthInitial());
  }
}
