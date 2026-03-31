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
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF081728),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF3FA8FF),
          secondary: Color(0xFF0FA960),
          surface: Color(0xFF0F2844),
          onSurface: Color(0xFFEAF3FF),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF0A1D35),
          foregroundColor: Color(0xFFF2F7FF),
          elevation: 0,
          centerTitle: false,
        ),
        cardTheme: CardThemeData(
          color: const Color(0xFF0F2844).withOpacity(0.86),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: Color(0x333FA8FF)),
          ),
        ),
        navigationRailTheme: const NavigationRailThemeData(
          backgroundColor: Color(0xFF0B203C),
          selectedIconTheme: IconThemeData(color: Color(0xFF62BCFF)),
          unselectedIconTheme: IconThemeData(color: Color(0xFF8EA5C0)),
          selectedLabelTextStyle: TextStyle(
            color: Color(0xFFEAF3FF),
            fontWeight: FontWeight.w600,
          ),
          unselectedLabelTextStyle: TextStyle(color: Color(0xFF9AB1CC)),
        ),
        listTileTheme: const ListTileThemeData(
          textColor: Color(0xFFEAF3FF),
          iconColor: Color(0xFF9AB1CC),
        ),
        textTheme: const TextTheme(
          headlineSmall: TextStyle(color: Color(0xFFF2F7FF), fontWeight: FontWeight.w600),
          titleMedium: TextStyle(color: Color(0xFFD8E6F8)),
          bodyMedium: TextStyle(color: Color(0xFFB6C8DD)),
        ),
        useMaterial3: true,
      ),
      initialRoute: AppRoutes.login,
      onGenerateRoute: appRouter.onGenerateRoute,
    );
  }
}
