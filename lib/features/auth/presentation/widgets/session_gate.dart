import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:web_admin_tecnico/features/app_shell/domain/app_module.dart';
import 'package:web_admin_tecnico/features/app_shell/presentation/pages/app_shell_page.dart';
import 'package:web_admin_tecnico/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:web_admin_tecnico/features/auth/presentation/pages/login_page.dart';
import 'package:web_admin_tecnico/features/auth/presentation/pages/splash_page.dart';

/// Guard de cada ruta del panel segun el estado de la sesion: splash mientras
/// se lee el storage, el modulo pedido si la sesion es valida, y el login en
/// cualquier otro caso (sin sesion, token vencido, 401 o rol sin acceso).
class SessionGate extends StatelessWidget {
  const SessionGate({super.key, required this.modulo});

  final AppModule modulo;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        if (state is AuthInitial || state is AuthRestoringSession) {
          return const SplashPage();
        }
        if (state is AuthAuthenticated) {
          return AppShellPage(initialModule: modulo);
        }
        return const LoginPage();
      },
    );
  }
}
