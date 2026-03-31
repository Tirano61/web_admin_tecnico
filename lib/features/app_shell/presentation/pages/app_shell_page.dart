import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:web_admin_tecnico/core/auth/session_store.dart';
import 'package:web_admin_tecnico/core/routing/app_routes.dart';
import 'package:web_admin_tecnico/features/app_shell/domain/app_module.dart';
import 'package:web_admin_tecnico/features/app_shell/presentation/bloc/app_shell_bloc.dart';
import 'package:web_admin_tecnico/features/catalogos/presentation/pages/catalogos_page.dart';
import 'package:web_admin_tecnico/features/clientes/presentation/pages/clientes_page.dart';
import 'package:web_admin_tecnico/features/liquidaciones/presentation/pages/liquidaciones_page.dart';
import 'package:web_admin_tecnico/features/precios/presentation/pages/precios_page.dart';
import 'package:web_admin_tecnico/features/servicios/presentation/pages/servicios_page.dart';

class AppShellPage extends StatelessWidget {
  const AppShellPage({super.key, required this.initialModule});

  final AppModule initialModule;

  @override
  Widget build(BuildContext context) {
    return BlocProvider<AppShellBloc>(
      create: (_) => AppShellBloc(initialModule: initialModule),
      child: const _AppShellView(),
    );
  }
}

class _AppShellView extends StatelessWidget {
  const _AppShellView();

  @override
  Widget build(BuildContext context) {
    final modules = AppModule.values;

    return BlocBuilder<AppShellBloc, AppShellState>(
      builder: (context, state) {
        final index = modules.indexOf(state.currentModule);

        return Scaffold(
          appBar: AppBar(
            title: Text('Panel Admin Tecnico - ${state.currentModule.label}'),
            actions: <Widget>[
              TextButton.icon(
                onPressed: () {
                  SessionStore.clear();
                  Navigator.of(context).pushReplacementNamed(AppRoutes.login);
                },
                icon: const Icon(Icons.logout),
                label: const Text('Salir'),
              ),
            ],
          ),
          body: Row(
            children: <Widget>[
              NavigationRail(
                selectedIndex: index,
                labelType: NavigationRailLabelType.all,
                onDestinationSelected: (selectedIndex) {
                  context.read<AppShellBloc>().add(
                        AppShellModuleChanged(modules[selectedIndex]),
                      );
                },
                destinations: modules
                    .map(
                      (module) => NavigationRailDestination(
                        icon: const Icon(Icons.circle_outlined),
                        selectedIcon: const Icon(Icons.circle),
                        label: Text(module.label),
                      ),
                    )
                    .toList(),
              ),
              const VerticalDivider(width: 1),
              Expanded(child: _modulePage(state.currentModule)),
            ],
          ),
        );
      },
    );
  }

  Widget _modulePage(AppModule module) {
    switch (module) {
      case AppModule.servicios:
        return const ServiciosPage();
      case AppModule.clientes:
        return const ClientesPage();
      case AppModule.catalogos:
        return const CatalogosPage();
      case AppModule.precios:
        return const PreciosPage();
      case AppModule.liquidaciones:
        return const LiquidacionesPage();
    }
  }
}
