import 'package:flutter/material.dart';
import 'package:web_admin_tecnico/core/routing/app_router.dart';
import 'package:web_admin_tecnico/core/routing/app_routes.dart';

void main() {
  runApp(const WebAdminTecnicoApp());
}

class WebAdminTecnicoApp extends StatelessWidget {
  const WebAdminTecnicoApp({super.key});

  @override
  Widget build(BuildContext context) {
    final appRouter = AppRouter();

    return MaterialApp(
      title: 'Web Admin Tecnico',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF0D6E63)),
        useMaterial3: true,
      ),
      initialRoute: AppRoutes.login,
      onGenerateRoute: appRouter.onGenerateRoute,
    );
  }
}
