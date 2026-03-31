import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:web_admin_tecnico/features/app_shell/domain/app_module.dart';

abstract class AppShellEvent {}

class AppShellModuleChanged extends AppShellEvent {
  AppShellModuleChanged(this.module);

  final AppModule module;
}

class AppShellState {
  const AppShellState({required this.currentModule});

  final AppModule currentModule;

  AppShellState copyWith({AppModule? currentModule}) {
    return AppShellState(currentModule: currentModule ?? this.currentModule);
  }
}

class AppShellBloc extends Bloc<AppShellEvent, AppShellState> {
  AppShellBloc({required AppModule initialModule})
      : super(AppShellState(currentModule: initialModule)) {
    on<AppShellModuleChanged>(_onModuleChanged);
  }

  void _onModuleChanged(AppShellModuleChanged event, Emitter<AppShellState> emit) {
    emit(state.copyWith(currentModule: event.module));
  }
}
