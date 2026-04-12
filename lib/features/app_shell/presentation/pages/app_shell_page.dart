import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:web_admin_tecnico/core/auth/session_store.dart';
import 'package:web_admin_tecnico/core/routing/app_routes.dart';
import 'package:web_admin_tecnico/core/widgets/tech_admin_background.dart';
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
        return Scaffold(
          body: TechAdminBackground(
            child: SafeArea(
              child: Column(
                children: <Widget>[
                  _TopShellNavigation(
                    modules: modules,
                    currentModule: state.currentModule,
                    onModuleSelected: (module) {
                      context.read<AppShellBloc>().add(AppShellModuleChanged(module));
                    },
                    onLogout: () {
                      SessionStore.clear();
                      Navigator.of(context).pushReplacementNamed(AppRoutes.login);
                    },
                  ),
                  Expanded(
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 220),
                      switchInCurve: Curves.easeOutCubic,
                      switchOutCurve: Curves.easeInCubic,
                      child: KeyedSubtree(
                        key: ValueKey<AppModule>(state.currentModule),
                        child: _modulePage(state.currentModule),
                      ),
                    ),
                  ),
                ],
              ),
            ),
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

class _TopShellNavigation extends StatelessWidget {
  const _TopShellNavigation({
    required this.modules,
    required this.currentModule,
    required this.onModuleSelected,
    required this.onLogout,
  });

  final List<AppModule> modules;
  final AppModule currentModule;
  final ValueChanged<AppModule> onModuleSelected;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 860;

        final brand = Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Container(
              height: 42,
              width: 42,
              decoration: BoxDecoration(
                color: const Color(0x194FC2FF),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0x555FB7ED)),
              ),
              child: const Icon(Icons.memory_rounded, color: Color(0xFF9BD5FF)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    'TechAdmin Operativo',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: const Color(0xFFF2F8FF),
                          fontWeight: FontWeight.w700,
                          fontSize: compact ? 18 : 20,
                        ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    currentModule.shortDescription,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: const Color(0xFF9FB9D5),
                        ),
                  ),
                ],
              ),
            ),
          ],
        );

        final logoutButton = FilledButton.icon(
          onPressed: onLogout,
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFF14365A),
            foregroundColor: const Color(0xFFD8EBFF),
          ),
          icon: const Icon(Icons.logout, size: 18),
          label: const Text('Salir'),
        );

        return Container(
          margin: const EdgeInsets.fromLTRB(18, 18, 18, 0),
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
          decoration: BoxDecoration(
            color: const Color(0xCC0B223E),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0x335CA8E8)),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: const Color(0xFF04111F).withOpacity(0.35),
                blurRadius: 24,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            children: <Widget>[
              if (compact) ...<Widget>[
                brand,
                const SizedBox(height: 10),
                Align(alignment: Alignment.centerRight, child: logoutButton),
              ] else ...<Widget>[
                Row(
                  children: <Widget>[
                    Expanded(child: brand),
                    const SizedBox(width: 12),
                    logoutButton,
                  ],
                ),
              ],
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: modules
                        .map(
                          (module) => Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: _TopNavItem(
                              module: module,
                              selected: module == currentModule,
                              onTap: () => onModuleSelected(module),
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _TopNavItem extends StatelessWidget {
  const _TopNavItem({
    required this.module,
    required this.selected,
    required this.onTap,
  });

  final AppModule module;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final backgroundColor = selected ? const Color(0xFF1C4A74) : const Color(0x33163352);
    final borderColor = selected ? const Color(0xAA6CC8FF) : const Color(0x334F89BE);
    final textColor = selected ? const Color(0xFFEAF5FF) : const Color(0xFFB3C8DF);

    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: borderColor),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(module.icon, size: 18, color: textColor),
            const SizedBox(width: 8),
            Text(
              module.label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: textColor,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
