import 'package:flutter/material.dart';
import 'package:web_admin_tecnico/core/routing/app_router.dart';
import 'package:web_admin_tecnico/core/routing/app_routes.dart';

void main() {
  runApp(const WebAdminTecnicoApp());
}

class WebAdminTecnicoApp extends StatelessWidget {
  const WebAdminTecnicoApp({super.key});

  static const double _webUiScale = 0.8;

  double _responsiveTextScale(double width) {
    if (width <= 430) {
      return 0.78;
    }
    if (width <= 560) {
      return 0.84;
    }
    if (width <= 900) {
      return 0.9;
    }
    if (width <= 1200) {
      return 0.96;
    }
    return 1.0;
  }

  double _responsiveControlScale(double width) {
    if (width <= 430) {
      return 0.78;
    }
    if (width <= 560) {
      return 0.84;
    }
    if (width <= 900) {
      return 0.9;
    }
    if (width <= 1200) {
      return 0.96;
    }
    return 1.0;
  }

  VisualDensity _responsiveDensity(double width) {
    if (width <= 560) {
      return const VisualDensity(horizontal: -2, vertical: -2);
    }
    if (width <= 900) {
      return const VisualDensity(horizontal: -1.5, vertical: -1.5);
    }
    return VisualDensity.compact;
  }

  TextStyle? _scaleTextStyle(TextStyle? style, double scale) {
    if (style == null) {
      return null;
    }
    final size = style.fontSize;
    if (size == null) {
      return style;
    }
    return style.copyWith(fontSize: size * scale);
  }

  TextTheme _scaleTextTheme(TextTheme theme, double scale) {
    return theme.copyWith(
      displayLarge: _scaleTextStyle(theme.displayLarge, scale),
      displayMedium: _scaleTextStyle(theme.displayMedium, scale),
      displaySmall: _scaleTextStyle(theme.displaySmall, scale),
      headlineLarge: _scaleTextStyle(theme.headlineLarge, scale),
      headlineMedium: _scaleTextStyle(theme.headlineMedium, scale),
      headlineSmall: _scaleTextStyle(theme.headlineSmall, scale),
      titleLarge: _scaleTextStyle(theme.titleLarge, scale),
      titleMedium: _scaleTextStyle(theme.titleMedium, scale),
      titleSmall: _scaleTextStyle(theme.titleSmall, scale),
      bodyLarge: _scaleTextStyle(theme.bodyLarge, scale),
      bodyMedium: _scaleTextStyle(theme.bodyMedium, scale),
      bodySmall: _scaleTextStyle(theme.bodySmall, scale),
      labelLarge: _scaleTextStyle(theme.labelLarge, scale),
      labelMedium: _scaleTextStyle(theme.labelMedium, scale),
      labelSmall: _scaleTextStyle(theme.labelSmall, scale),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appRouter = AppRouter();
    final baseTheme = ThemeData(
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
        headlineSmall: TextStyle(
          color: Color(0xFFF2F8FF),
          fontWeight: FontWeight.w700,
          fontSize: 24,
        ),
        titleLarge: TextStyle(
          color: Color(0xFFE4F0FF),
          fontWeight: FontWeight.w600,
          fontSize: 20,
        ),
        titleMedium: TextStyle(
          color: Color(0xFFD6E7FA),
          fontSize: 16,
        ),
        bodyLarge: TextStyle(
          color: Color(0xFFBFD3E8),
          fontSize: 15,
        ),
        bodyMedium: TextStyle(
          color: Color(0xFFB3C7DC),
          fontSize: 14,
        ),
        bodySmall: TextStyle(
          color: Color(0xFFA6BCD4),
          fontSize: 12,
        ),
        labelLarge: TextStyle(
          color: Color(0xFFD7E9FC),
          fontWeight: FontWeight.w600,
          fontSize: 14,
        ),
        labelMedium: TextStyle(
          color: Color(0xFFC8DCF2),
          fontSize: 12,
        ),
        labelSmall: TextStyle(
          color: Color(0xFFB6CBE2),
          fontSize: 11,
        ),
      ),
      useMaterial3: true,
    );

    final webTheme = baseTheme.copyWith(
      visualDensity: VisualDensity.compact,
      textTheme: _scaleTextTheme(baseTheme.textTheme, _webUiScale),
      primaryTextTheme: _scaleTextTheme(
        baseTheme.primaryTextTheme,
        _webUiScale,
      ),
    );

    return MaterialApp(
      title: 'Web Admin Tecnico',
      debugShowCheckedModeBanner: false,
      theme: webTheme,
      initialRoute: AppRoutes.login,
      onGenerateRoute: appRouter.onGenerateRoute,
      builder: (context, child) {
        final media = MediaQuery.of(context);
        final width = media.size.width;
        final textScale = _responsiveTextScale(width);
        final controlScale = _responsiveControlScale(width);
        final density = _responsiveDensity(width);

        final theme = Theme.of(context);
        final responsiveTheme = theme.copyWith(
          visualDensity: density,
          iconButtonTheme: IconButtonThemeData(
            style: IconButton.styleFrom(
              visualDensity: density,
              padding: EdgeInsets.all(6 * controlScale),
              minimumSize: Size.square(30 * controlScale),
              iconSize: 18 * controlScale,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),
          dataTableTheme: theme.dataTableTheme.copyWith(
            headingTextStyle: _scaleTextStyle(theme.dataTableTheme.headingTextStyle, textScale),
            dataTextStyle: _scaleTextStyle(theme.dataTableTheme.dataTextStyle, textScale),
            headingRowHeight: width < 560 ? 42 : null,
            dataRowMinHeight: width < 560 ? 40 : null,
            dataRowMaxHeight: width < 560 ? 48 : null,
          ),
        );

        return MediaQuery(
          data: media.copyWith(textScaler: TextScaler.linear(textScale)),
          child: Theme(
            data: responsiveTheme,
            child: IconTheme.merge(
              data: IconThemeData(size: 24 * controlScale),
              child: child ?? const SizedBox.shrink(),
            ),
          ),
        );
      },
    );
  }
}
