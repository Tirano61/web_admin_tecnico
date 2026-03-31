import 'package:web_admin_tecnico/features/app_shell/domain/app_module.dart';

class AppShellData {
  const AppShellData();

  List<AppModule> availableModules() {
    return AppModule.values;
  }
}
