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
        fontFamily: 'Segoe UI',
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF081B30),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF69C3FF),
          secondary: Color(0xFF16B98A),
          surface: Color(0xFF102C4A),
          onSurface: Color(0xFFEAF3FF),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF0C2642),
          foregroundColor: Color(0xFFF2F7FF),
          elevation: 0,
          centerTitle: false,
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFF1A567F),
            foregroundColor: const Color(0xFFEAF4FF),
            textStyle: const TextStyle(fontWeight: FontWeight.w600),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(11)),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: const Color(0xFFD2E8FF),
            side: const BorderSide(color: Color(0x5565B4EF)),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(11)),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          isDense: true,
          filled: true,
          fillColor: const Color(0xFF133352),
          hintStyle: const TextStyle(color: Color(0xFF7D9ABA)),
          labelStyle: const TextStyle(color: Color(0xFFB4CCE5)),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(11),
            borderSide: const BorderSide(color: Color(0x334DA6E5)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(11),
            borderSide: const BorderSide(color: Color(0xFF5EBCFF), width: 1.3),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(11),
            borderSide: const BorderSide(color: Color(0xFFFF8E8E)),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(11),
            borderSide: const BorderSide(color: Color(0xFFFF9E9E), width: 1.3),
          ),
        ),
        cardTheme: CardThemeData(
          color: const Color(0xCC0F2C4A),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: const BorderSide(color: Color(0x334FAAE9)),
          ),
        ),
        dataTableTheme: DataTableThemeData(
          headingTextStyle: const TextStyle(
            color: Color(0xFFE8F4FF),
            fontWeight: FontWeight.w700,
            fontSize: 13,
          ),
          dataTextStyle: const TextStyle(
            color: Color(0xFFBFD3E8),
          ),
          dividerThickness: 0.5,
        ),
        listTileTheme: const ListTileThemeData(
          textColor: Color(0xFFEAF3FF),
          iconColor: Color(0xFF9AB1CC),
        ),
        snackBarTheme: SnackBarThemeData(
          behavior: SnackBarBehavior.floating,
          backgroundColor: const Color(0xFF0F3558),
          contentTextStyle: const TextStyle(color: Color(0xFFEAF4FF)),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        textTheme: const TextTheme(
          headlineSmall: TextStyle(color: Color(0xFFF2F8FF), fontWeight: FontWeight.w700),
          titleMedium: TextStyle(color: Color(0xFFD6E7FA)),
          bodyMedium: TextStyle(color: Color(0xFFB3C7DC)),
        ),
        useMaterial3: true,
      ),
      initialRoute: AppRoutes.login,
      onGenerateRoute: appRouter.onGenerateRoute,
    );
  }
}
