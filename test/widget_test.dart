import 'package:flutter_test/flutter_test.dart';
import 'package:web_admin_tecnico/main.dart';

void main() {
  testWidgets('Login screen smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const WebAdminTecnicoApp());

    expect(find.text('Admin Tecnico'), findsOneWidget);
    expect(find.text('Ingresar'), findsOneWidget);
  });
}
