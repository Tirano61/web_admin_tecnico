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
import 'package:web_admin_tecnico/features/liquidaciones/presentation/pages/liquidaciones_pagos_page.dart';
import 'package:web_admin_tecnico/features/precios/presentation/pages/precios_page.dart';
import 'package:web_admin_tecnico/features/repuestos/presentation/pages/repuestos_page.dart';
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

  static const double _drawerNavigationBreakpoint = 980;

  void _onModuleSelected(BuildContext context, AppModule module) {
    context.read<AppShellBloc>().add(AppShellModuleChanged(module));
  }

  void _onLogout(BuildContext context) {
    SessionStore.clear();
    Navigator.of(context).pushReplacementNamed(AppRoutes.login);
  }

  @override
  Widget build(BuildContext context) {
    final modules = AppModule.values;

    return BlocBuilder<AppShellBloc, AppShellState>(
      builder: (context, state) {
        return LayoutBuilder(
          builder: (context, constraints) {
            final useDrawerNavigation = constraints.maxWidth < _drawerNavigationBreakpoint;

            return Scaffold(
              drawer: useDrawerNavigation
                  ? _MobileNavigationDrawer(
                      modules: modules,
                      currentModule: state.currentModule,
                      onModuleSelected: (module) => _onModuleSelected(context, module),
                      onLogout: () => _onLogout(context),
                    )
                  : null,
              body: TechAdminBackground(
                child: SafeArea(
                  child: Column(
                    children: <Widget>[
                      if (useDrawerNavigation)
                        Builder(
                          builder: (scaffoldContext) {
                            return _CompactShellHeader(
                              currentModule: state.currentModule,
                              onOpenMenu: () => Scaffold.of(scaffoldContext).openDrawer(),
                              onLogout: () => _onLogout(context),
                            );
                          },
                        )
                      else
                        _TopShellNavigation(
                          modules: modules,
                          currentModule: state.currentModule,
                          onModuleSelected: (module) => _onModuleSelected(context, module),
                          onLogout: () => _onLogout(context),
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
      case AppModule.repuestos:
        return const RepuestosPage();
      case AppModule.precios:
        return const PreciosPage();
      case AppModule.liquidaciones:
        return const LiquidacionesPage();
      case AppModule.liquidacionesPagos:
        return const LiquidacionesPagosPage();
    }
  }
}

class _CompactShellHeader extends StatelessWidget {
  const _CompactShellHeader({
    required this.currentModule,
    required this.onOpenMenu,
    required this.onLogout,
  });

  final AppModule currentModule;
  final VoidCallback onOpenMenu;
  final VoidCallback onLogout;

  static const double _scale = 0.8;

  @override
  Widget build(BuildContext context) {
    final titleStyle = Theme.of(context).textTheme.titleMedium?.copyWith(
          color: const Color(0xFFF2F8FF),
          fontWeight: FontWeight.w700,
        );

    final subtitleStyle = Theme.of(context).textTheme.bodySmall?.copyWith(
          color: const Color(0xFF9FB9D5),
        );

    return Container(
      margin: EdgeInsets.fromLTRB(
        14 * _scale,
        14 * _scale,
        14 * _scale,
        0,
      ),
      padding: EdgeInsets.fromLTRB(
        12 * _scale,
        10 * _scale,
        12 * _scale,
        10 * _scale,
      ),
      decoration: BoxDecoration(
        color: const Color(0xCC0B223E),
        borderRadius: BorderRadius.circular(14 * _scale),
        border: Border.all(color: const Color(0x335CA8E8)),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: const Color(0xFF04111F).withValues(alpha: 0.35),
            blurRadius: 18 * _scale,
            offset: Offset(0, 8 * _scale),
          ),
        ],
      ),
      child: Row(
        children: <Widget>[
          _CompactHeaderIconAction(
            icon: Icons.menu_rounded,
            tooltip: 'Abrir menu',
            onPressed: onOpenMenu,
          ),
          SizedBox(width: 10 * _scale),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(
                  currentModule.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: titleStyle,
                ),
                SizedBox(height: 2 * _scale),
                Text(
                  currentModule.shortDescription,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: subtitleStyle,
                ),
              ],
            ),
          ),
          SizedBox(width: 8 * _scale),
          _CompactHeaderIconAction(
            icon: Icons.logout_rounded,
            tooltip: 'Salir',
            onPressed: onLogout,
          ),
        ],
      ),
    );
  }
}

class _CompactHeaderIconAction extends StatelessWidget {
  const _CompactHeaderIconAction({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  static const double _scale = 0.8;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF153857),
        borderRadius: BorderRadius.circular(10 * _scale),
        border: Border.all(color: const Color(0x5568B7EE)),
      ),
      child: IconButton(
        tooltip: tooltip,
        onPressed: onPressed,
        icon: Icon(icon, color: const Color(0xFFD8EBFF), size: 20 * _scale),
      ),
    );
  }
}

class _MobileNavigationDrawer extends StatelessWidget {
  const _MobileNavigationDrawer({
    required this.modules,
    required this.currentModule,
    required this.onModuleSelected,
    required this.onLogout,
  });

  final List<AppModule> modules;
  final AppModule currentModule;
  final ValueChanged<AppModule> onModuleSelected;
  final VoidCallback onLogout;

  static const double _scale = 0.8;

  @override
  Widget build(BuildContext context) {
    return Drawer(
      width: 320 * _scale,
      backgroundColor: const Color(0xFF0B223E),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Padding(
              padding: EdgeInsets.fromLTRB(
                14 * _scale,
                14 * _scale,
                14 * _scale,
                10 * _scale,
              ),
              child: Row(
                children: <Widget>[
                  Container(
                    height: 34 * _scale,
                    width: 34 * _scale,
                    decoration: BoxDecoration(
                      color: const Color(0x194FC2FF),
                      borderRadius: BorderRadius.circular(10 * _scale),
                      border: Border.all(color: const Color(0x555FB7ED)),
                    ),
                    child: Icon(
                      Icons.memory_rounded,
                      color: const Color(0xFF9BD5FF),
                      size: 18 * _scale,
                    ),
                  ),
                  SizedBox(width: 10 * _scale),
                  Expanded(
                    child: Text(
                      'TechAdmin Operativo',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            color: const Color(0xFFF2F8FF),
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(color: Color(0x334EA6FF), height: 1),
            Expanded(
              child: ListView.builder(
                padding: EdgeInsets.symmetric(vertical: 8 * _scale),
                itemCount: modules.length,
                itemBuilder: (context, index) {
                  final module = modules[index];
                  final selected = module == currentModule;
                  final iconColor = selected ? const Color(0xFFEAF5FF) : const Color(0xFFB3C8DF);
                  final textColor = selected ? const Color(0xFFEAF5FF) : const Color(0xFFBFD3E8);

                  return Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8 * _scale, vertical: 2 * _scale),
                    child: ListTile(
                      selected: selected,
                      selectedTileColor: const Color(0x333873A8),
                      tileColor: const Color(0x1A163352),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10 * _scale),
                        side: BorderSide(
                          color: selected ? const Color(0xAA6CC8FF) : const Color(0x334F89BE),
                        ),
                      ),
                      leading: Icon(module.icon, color: iconColor),
                      title: Text(
                        module.label,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: textColor,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                      subtitle: Text(
                        module.shortDescription,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: const Color(0xFF9FB9D5),
                            ),
                      ),
                      onTap: () {
                        onModuleSelected(module);
                        Navigator.of(context).pop();
                      },
                    ),
                  );
                },
              ),
            ),
            const Divider(color: Color(0x334EA6FF), height: 1),
            Padding(
              padding: EdgeInsets.all(12 * _scale),
              child: FilledButton.icon(
                onPressed: () {
                  Navigator.of(context).pop();
                  onLogout();
                },
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF14365A),
                  foregroundColor: const Color(0xFFD8EBFF),
                ),
                icon: Icon(Icons.logout, size: 18 * _scale),
                label: const Text('Salir'),
              ),
            ),
          ],
        ),
      ),
    );
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

  static const double _scale = 0.8;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 860;

        final brand = Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Container(
              height: 42 * _scale,
              width: 42 * _scale,
              decoration: BoxDecoration(
                color: const Color(0x194FC2FF),
                borderRadius: BorderRadius.circular(12 * _scale),
                border: Border.all(color: const Color(0x555FB7ED)),
              ),
              child: Icon(
                Icons.memory_rounded,
                color: const Color(0xFF9BD5FF),
                size: 24 * _scale,
              ),
            ),
            SizedBox(width: 12 * _scale),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    'TechAdmin Operativo',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: const Color(0xFFF2F8FF),
                          fontWeight: FontWeight.w700,
                          fontSize: (compact ? 18 : 20) * _scale,
                        ),
                  ),
                  SizedBox(height: 2 * _scale),
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
            padding: EdgeInsets.symmetric(
              horizontal: 14 * _scale,
              vertical: 10 * _scale,
            ),
          ),
          icon: Icon(Icons.logout, size: 18 * _scale),
          label: const Text('Salir'),
        );

        return Container(
          margin: EdgeInsets.fromLTRB(
            18 * _scale,
            18 * _scale,
            18 * _scale,
            0,
          ),
          padding: EdgeInsets.fromLTRB(
            16 * _scale,
            14 * _scale,
            16 * _scale,
            14 * _scale,
          ),
          decoration: BoxDecoration(
            color: const Color(0xCC0B223E),
            borderRadius: BorderRadius.circular(16 * _scale),
            border: Border.all(color: const Color(0x335CA8E8)),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: const Color(0xFF04111F).withValues(alpha: 0.35),
                blurRadius: 24 * _scale,
                offset: Offset(0, 10 * _scale),
              ),
            ],
          ),
          child: Column(
            children: <Widget>[
              if (compact) ...<Widget>[
                brand,
                SizedBox(height: 10 * _scale),
                Align(alignment: Alignment.centerRight, child: logoutButton),
              ] else ...<Widget>[
                Row(
                  children: <Widget>[
                    Expanded(child: brand),
                    SizedBox(width: 12 * _scale),
                    logoutButton,
                  ],
                ),
              ],
              SizedBox(height: 14 * _scale),
              SizedBox(
                width: double.infinity,
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: modules
                        .map(
                          (module) => Padding(
                            padding: EdgeInsets.only(right: 8 * _scale),
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

  static const double _scale = 0.8;

  @override
  Widget build(BuildContext context) {
    final backgroundColor = selected ? const Color(0xFF1C4A74) : const Color(0x33163352);
    final borderColor = selected ? const Color(0xAA6CC8FF) : const Color(0x334F89BE);
    final textColor = selected ? const Color(0xFFEAF5FF) : const Color(0xFFB3C8DF);

    return InkWell(
      borderRadius: BorderRadius.circular(12 * _scale),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: EdgeInsets.symmetric(
          horizontal: 12 * _scale,
          vertical: 10 * _scale,
        ),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(12 * _scale),
          border: Border.all(color: borderColor),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(module.icon, size: 18 * _scale, color: textColor),
            SizedBox(width: 8 * _scale),
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
