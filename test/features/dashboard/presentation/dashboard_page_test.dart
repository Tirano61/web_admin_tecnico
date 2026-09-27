import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:web_admin_tecnico/features/app_shell/domain/app_module.dart';
import 'package:web_admin_tecnico/features/app_shell/presentation/bloc/app_shell_bloc.dart';
import 'package:web_admin_tecnico/features/dashboard/domain/dashboard_repository.dart';
import 'package:web_admin_tecnico/features/dashboard/presentation/pages/dashboard_page.dart';

void main() {
  Future<AppShellBloc> pumpDashboard(WidgetTester tester, DashboardMetricas metricas) async {
    tester.view.physicalSize = const Size(1400, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final shell = AppShellBloc(initialModule: AppModule.dashboard);
    addTearDown(shell.close);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: BlocProvider<AppShellBloc>.value(
            value: shell,
            child: DashboardPage(repository: _FakeDashboardRepository(metricas)),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return shell;
  }

  testWidgets('muestra las metricas y el desglose por canal', (tester) async {
    await pumpDashboard(
      tester,
      const DashboardMetricas(
        diasAlertaPendientes: 7,
        serviciosMes: ServiciosMesMetrica(total: 9, campo: 5, remoto: 3, fabrica: 1),
        liquidacionesPendientes: LiquidacionesPendientesMetrica(total: 4, antiguas: 0),
        liquidacionesReabiertas: 0,
        liquidacionesParaPago: 2,
        tecnicosActivos: 6,
      ),
    );

    expect(find.text('Servicios del mes'), findsOneWidget);
    expect(find.text('9'), findsOneWidget);
    expect(find.text('Campo 5 · Remoto 3 · Fabrica 1'), findsOneWidget);
    expect(find.text('Tecnicos activos'), findsOneWidget);
    expect(find.text('Requiere atencion'), findsNothing);
  });

  testWidgets('avisa reabiertas y pendientes viejas, y lleva a liquidaciones', (tester) async {
    final shell = await pumpDashboard(
      tester,
      const DashboardMetricas(
        diasAlertaPendientes: 7,
        liquidacionesPendientes: LiquidacionesPendientesMetrica(total: 4, antiguas: 3),
        liquidacionesReabiertas: 1,
      ),
    );

    expect(find.text('Requiere atencion'), findsOneWidget);
    expect(find.text('1 liquidacion reabierta espera volver a aprobarse.'), findsOneWidget);
    expect(find.text('3 liquidaciones llevan mas de 7 dias pendientes.'), findsOneWidget);
    // Metricas que fallaron se muestran sin dato.
    expect(find.text('—'), findsNWidgets(3));

    await tester.tap(find.text('Ver liquidaciones'));
    await tester.pump();
    expect(shell.state.currentModule, AppModule.liquidaciones);
  });

  testWidgets('el acceso rapido de pagos cambia de modulo', (tester) async {
    final shell = await pumpDashboard(
      tester,
      const DashboardMetricas(diasAlertaPendientes: 7, tecnicosActivos: 1),
    );

    await tester.tap(find.text('Pagos a tecnicos'));
    await tester.pump();
    expect(shell.state.currentModule, AppModule.liquidacionesPagos);
  });
}

class _FakeDashboardRepository implements DashboardRepository {
  _FakeDashboardRepository(this._metricas);

  final DashboardMetricas _metricas;

  @override
  Future<DashboardMetricas> fetchMetricas({required DashboardQuery query}) async => _metricas;
}
