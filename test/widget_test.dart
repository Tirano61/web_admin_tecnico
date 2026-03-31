import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:web_admin_tecnico/main.dart';

void main() {
  testWidgets('Login screen smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const WebAdminTecnicoApp());

    expect(find.byIcon(Icons.memory_rounded), findsOneWidget);
    expect(find.text('>- TERMINAL SEGURA'), findsOneWidget);
    expect(find.text('Acceso Interno'), findsOneWidget);
    expect(find.text('Iniciar sesion'), findsOneWidget);
  });
}
