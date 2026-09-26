import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:web_admin_tecnico/core/api/paged_result.dart';
import 'package:web_admin_tecnico/features/tecnicos/domain/tecnicos_repository.dart';
import 'package:web_admin_tecnico/features/tecnicos/presentation/pages/tecnicos_page.dart';

void main() {
  group('TecnicosPage listado', () {
    testWidgets('muestra nombre, email, roles y estado de cada tecnico', (tester) async {
      await _setDesktopSurface(tester);
      final repository = _FakeTecnicosRepository();

      await tester.pumpWidget(_testApp(repository));
      await tester.pumpAndSettle();

      expect(find.text('Juan Perez'), findsOneWidget);
      expect(find.text('juan@example.com'), findsOneWidget);
      expect(find.text('TECNICO'), findsWidgets);
      expect(find.text('ACTIVO'), findsWidgets);
      expect(repository.queries.single.activos, FiltroEstadoTecnicos.activos);
    });

    testWidgets('el filtro INACTIVOS consulta activos=false', (tester) async {
      await _setDesktopSurface(tester);
      final repository = _FakeTecnicosRepository();

      await tester.pumpWidget(_testApp(repository));
      await tester.pumpAndSettle();

      await tester.tap(find.byType(DropdownButton<FiltroEstadoTecnicos>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('INACTIVOS').last);
      await tester.pumpAndSettle();

      expect(repository.queries.last.activos, FiltroEstadoTecnicos.inactivos);
      expect(find.text('INACTIVO'), findsWidgets);
    });

    testWidgets('el filtro TODOS muestra activos e inactivos juntos', (tester) async {
      await _setDesktopSurface(tester);
      final repository = _FakeTecnicosRepository();

      await tester.pumpWidget(_testApp(repository));
      await tester.pumpAndSettle();

      await tester.tap(find.byType(DropdownButton<FiltroEstadoTecnicos>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('TODOS').last);
      await tester.pumpAndSettle();

      expect(repository.queries.last.activos, FiltroEstadoTecnicos.todos);
      expect(find.text('Juan Perez'), findsOneWidget);
      expect(find.text('Ana Gomez'), findsOneWidget);
    });
  });

  group('TecnicosPage estado', () {
    testWidgets('desactivar pide confirmacion antes de pegarle al backend', (tester) async {
      await _setDesktopSurface(tester);
      final repository = _FakeTecnicosRepository();

      await tester.pumpWidget(_testApp(repository));
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithIcon(IconButton, Icons.person_off_outlined));
      await tester.pumpAndSettle();

      expect(find.text('Desactivar tecnico'), findsOneWidget);
      expect(repository.cambiosDeEstado, isEmpty);

      await tester.tap(find.widgetWithText(TextButton, 'Cancelar'));
      await tester.pumpAndSettle();

      expect(repository.cambiosDeEstado, isEmpty);
    });

    testWidgets('confirmar el cambio manda isActive y avisa donde quedo', (tester) async {
      await _setDesktopSurface(tester);
      final repository = _FakeTecnicosRepository();

      await tester.pumpWidget(_testApp(repository));
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithIcon(IconButton, Icons.person_off_outlined));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Desactivar'));
      await tester.pumpAndSettle();

      expect(repository.cambiosDeEstado.single.$1, 'tec-1');
      expect(repository.cambiosDeEstado.single.$2, isFalse);
      expect(find.textContaining('filtro INACTIVOS'), findsOneWidget);
    });
  });
}

Future<void> _setDesktopSurface(WidgetTester tester) =>
    _setSurface(tester, const Size(1800, 1200));

Future<void> _setSurface(WidgetTester tester, Size size) async {
  await tester.binding.setSurfaceSize(size);
  addTearDown(() async {
    await tester.binding.setSurfaceSize(null);
  });
}

Widget _testApp(
  TecnicosRepository repository, {
  Size size = const Size(1800, 1200),
}) {
  return MediaQuery(
    data: MediaQueryData(
      size: size,
      textScaler: const TextScaler.linear(1),
    ),
    child: MaterialApp(
      home: Scaffold(
        body: TecnicosPage(repository: repository),
      ),
    ),
  );
}

class _FakeTecnicosRepository implements TecnicosRepository {
  final List<TecnicosQuery> queries = <TecnicosQuery>[];
  final List<(String, bool)> cambiosDeEstado = <(String, bool)>[];

  @override
  Future<PagedResult<TecnicoItem>> fetchTecnicos({required TecnicosQuery query}) async {
    queries.add(query);

    const todos = <TecnicoItem>[
      TecnicoItem(
        id: 'tec-1',
        fullName: 'Juan Perez',
        email: 'juan@example.com',
        isActive: true,
        roles: <String>['tecnico'],
      ),
      TecnicoItem(
        id: 'tec-2',
        fullName: 'Ana Gomez',
        email: 'ana@example.com',
        isActive: false,
        roles: <String>['tecnico'],
      ),
    ];
    final items = todos.where((item) => query.activos.incluye(isActive: item.isActive)).toList();

    return PagedResult<TecnicoItem>(
      items: items,
      total: items.length,
      page: query.page,
      limit: query.limit,
    );
  }

  @override
  Future<TecnicoDetalle> fetchTecnicoDetalle(String tecnicoId) async {
    return TecnicoDetalle(
      id: tecnicoId,
      fullName: 'Juan Perez',
      email: 'juan@example.com',
      isActive: true,
      roles: const <String>['tecnico'],
    );
  }

  @override
  Future<void> createTecnico({required CreateTecnicoInput input}) async {}

  @override
  Future<void> updateTecnico({required UpdateTecnicoInput input}) async {}

  @override
  Future<void> updateEstadoTecnico({
    required String tecnicoId,
    required bool isActive,
  }) async {
    cambiosDeEstado.add((tecnicoId, isActive));
  }
}
