import 'package:flutter/material.dart';

/// Paleta exata do projeto de referência (portal-mz.vercel.app).
/// Fonte: variáveis CSS `:root` (dark) e `[data-theme=light]`.
class AppColors {
  // Cores de marca (comuns aos dois temas).
  static const accent = Color(0xFF7C5CFC);
  static const accentSoft = Color(0xFF9B7FFF);
  static const mentionLink = Color(0xFF5CB7FF);
  static const mentionLinkLight = Color(0xFF1677D2);
  static const danger = Color(0xFFFC5C7D);
  static const success = Color(0xFF5CFCB4);
  static const warning = Color(0xFFFCB45C);
  static const pink = Color(0xFFE879F9);

  // Tema escuro.
  static const darkBg = Color(0xFF0A090F);
  static const darkBg2 = Color(0xFF111018);
  static const darkBg3 = Color(0xFF18161F);
  static const darkBg4 = Color(0xFF1F1D28);
  static const darkSurface = Color(0xFF1C1A24);
  static const darkSurface2 = Color(0xFF23202E);
  static const darkText = Color(0xFFF0EEFF);
  static const darkText2 = Color(0xFF9D9AB5);
  static const darkText3 = Color(0xFF5E5B72);
  static const darkBorder = Color(0x12FFFFFF);
  static const darkBorder2 = Color(0x1FFFFFFF);
  static const darkAccentGlow = Color(0x2E7C5CFC);

  // Tema claro.
  static const lightBg = Color(0xFFF5F4FA);
  static const lightBg2 = Color(0xFFEEEDF5);
  static const lightBg3 = Color(0xFFE7E5F0);
  static const lightBg4 = Color(0xFFDDDBE8);
  static const lightSurface = Color(0xFFFFFFFF);
  static const lightSurface2 = Color(0xFFF0EEFF);
  static const lightText = Color(0xFF1A1730);
  static const lightText2 = Color(0xFF5A5575);
  static const lightText3 = Color(0xFF9D9AB5);
  static const lightBorder = Color(0x12000000);
  static const lightBorder2 = Color(0x21000000);
  static const lightAccentGlow = Color(0x1A7C5CFC);

  // Cor de fundo da página de login (a web usa sempre escuro).
  static const loginBg = Color(0xFF0F0F1A);
}

ThemeData buildAppTheme(Brightness brightness) {
  final isDark = brightness == Brightness.dark;
  final scheme = ColorScheme.fromSeed(
    seedColor: AppColors.accent,
    brightness: brightness,
  );

  final bg = isDark ? AppColors.darkBg : AppColors.lightBg;
  final surface = isDark ? AppColors.darkSurface : AppColors.lightSurface;
  final text = isDark ? AppColors.darkText : AppColors.lightText;
  final border = isDark ? AppColors.darkBorder : AppColors.lightBorder;
  final inputFill = isDark ? AppColors.darkBg3 : AppColors.lightBg3;

  final base = ThemeData(
    useMaterial3: true,
    brightness: brightness,
    colorScheme: scheme.copyWith(
      primary: AppColors.accent,
      secondary: AppColors.pink,
      surface: surface,
    ),
    scaffoldBackgroundColor: bg,
  );

  return base.copyWith(
    textTheme: base.textTheme.apply(
      bodyColor: text,
      displayColor: text,
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: surface,
      foregroundColor: text,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      titleTextStyle: TextStyle(
        color: text,
        fontSize: 20,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.3,
      ),
    ),
    cardTheme: CardThemeData(
      color: surface,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: border),
      ),
    ),
    dividerTheme: DividerThemeData(color: border, thickness: 1, space: 1),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: inputFill,
      hintStyle: TextStyle(color: text.withValues(alpha: 0.4)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.accent, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.danger),
      ),
    ),
    chipTheme: base.chipTheme.copyWith(
      backgroundColor: inputFill,
      side: BorderSide(color: border),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      labelStyle: TextStyle(color: text),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: isDark ? AppColors.darkSurface2 : AppColors.lightSurface2,
      contentTextStyle: TextStyle(
        color: isDark ? Colors.white : AppColors.lightText,
      ),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: surface,
      indicatorColor: isDark ? AppColors.darkAccentGlow : AppColors.lightAccentGlow,
      labelTextStyle: WidgetStatePropertyAll(
        TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: text),
      ),
      iconTheme: WidgetStateProperty.resolveWith((states) {
        return IconThemeData(
          color: states.contains(WidgetState.selected)
              ? AppColors.accentSoft
              : text.withValues(alpha: 0.55),
        );
      }),
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: AppColors.accent,
      foregroundColor: Colors.white,
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
    tabBarTheme: TabBarThemeData(
      labelColor: text,
      unselectedLabelColor: text.withValues(alpha: 0.5),
      indicatorColor: AppColors.accent,
      indicatorSize: TabBarIndicatorSize.label,
      labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
      dividerColor: border,
    ),
    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: AppColors.accent,
    ),
    listTileTheme: ListTileThemeData(
      iconColor: text.withValues(alpha: 0.7),
      textColor: text,
    ),
    popupMenuTheme: PopupMenuThemeData(
      color: surface,
      textStyle: TextStyle(color: text),
    ),
  );
}
