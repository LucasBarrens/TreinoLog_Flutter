import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AppColors {
  // Brand
  static const primary = Color(0xFF1741D4);
  static const primaryMuted = Color(0xFFEEF2FF);
  static const primaryDark = Color(0xFF5B8BFF);

  // Semantic
  static const success = Color(0xFF10B981);
  static const successMuted = Color(0xFFECFDF5);
  static const warning = Color(0xFFF59E0B);
  static const warningMuted = Color(0xFFFFFBEB);
  static const danger = Color(0xFFEF4444);
  static const dangerMuted = Color(0xFFFEF2F2);

  // Light neutrals
  static const lightBg = Color(0xFFF1F5F9);
  static const lightSurface = Color(0xFFFFFFFF);
  static const lightBorder = Color(0xFFE2E8F0);
  static const lightText = Color(0xFF0F172A);
  static const lightTextMuted = Color(0xFF64748B);

  // Dark neutrals
  static const darkBg = Color(0xFF0D1117);
  static const darkSurface = Color(0xFF161B27);
  static const darkBorder = Color(0xFF252D40);
  static const darkText = Color(0xFFF1F5FF);
  static const darkTextMuted = Color(0xFF8B9AB7);
}

class AppTheme {
  static ThemeData light() => _build(
        isLight: true,
        colorScheme: const ColorScheme(
          brightness: Brightness.light,
          primary: AppColors.primary,
          onPrimary: Colors.white,
          primaryContainer: AppColors.primaryMuted,
          onPrimaryContainer: AppColors.primary,
          secondary: Color(0xFF475569),
          onSecondary: Colors.white,
          secondaryContainer: Color(0xFFF1F5F9),
          onSecondaryContainer: Color(0xFF0F172A),
          error: AppColors.danger,
          onError: Colors.white,
          errorContainer: AppColors.dangerMuted,
          onErrorContainer: AppColors.danger,
          surface: AppColors.lightSurface,
          onSurface: AppColors.lightText,
          surfaceContainerHighest: AppColors.lightBg,
          onSurfaceVariant: AppColors.lightTextMuted,
          outline: AppColors.lightBorder,
          outlineVariant: Color(0xFFF0F4F8),
          shadow: Colors.black,
          scrim: Colors.black,
          inverseSurface: AppColors.darkText,
          onInverseSurface: AppColors.darkBg,
          inversePrimary: AppColors.primaryDark,
        ),
      );

  static ThemeData dark() => _build(
        isLight: false,
        colorScheme: const ColorScheme(
          brightness: Brightness.dark,
          primary: AppColors.primaryDark,
          onPrimary: Colors.white,
          primaryContainer: Color(0xFF1A2E6E),
          onPrimaryContainer: AppColors.primaryDark,
          secondary: Color(0xFF94A3B8),
          onSecondary: AppColors.darkBg,
          secondaryContainer: Color(0xFF1E2740),
          onSecondaryContainer: Color(0xFFCDD5E8),
          error: Color(0xFFFF6B6B),
          onError: AppColors.darkBg,
          errorContainer: Color(0xFF3D1515),
          onErrorContainer: Color(0xFFFF6B6B),
          surface: AppColors.darkSurface,
          onSurface: AppColors.darkText,
          surfaceContainerHighest: AppColors.darkBg,
          onSurfaceVariant: AppColors.darkTextMuted,
          outline: AppColors.darkBorder,
          outlineVariant: Color(0xFF1E2538),
          shadow: Colors.black,
          scrim: Colors.black,
          inverseSurface: AppColors.lightText,
          onInverseSurface: AppColors.lightBg,
          inversePrimary: AppColors.primary,
        ),
      );

  static ThemeData _build({required bool isLight, required ColorScheme colorScheme}) {
    final border = isLight ? AppColors.lightBorder : AppColors.darkBorder;
    final cardColor = isLight ? AppColors.lightSurface : AppColors.darkSurface;
    final scaffoldBg = isLight ? AppColors.lightBg : AppColors.darkBg;
    final inputFill = isLight ? const Color(0xFFF1F5F9) : const Color(0xFF1E2538);

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: scaffoldBg,
      appBarTheme: AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        backgroundColor: cardColor,
        foregroundColor: colorScheme.onSurface,
        systemOverlayStyle: (isLight
                ? SystemUiOverlayStyle.dark
                : SystemUiOverlayStyle.light)
            .copyWith(statusBarColor: Colors.transparent),
        titleTextStyle: TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.3,
          color: colorScheme.onSurface,
        ),
        shape: Border(bottom: BorderSide(color: border, width: 0.5)),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: cardColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: border, width: 1),
        ),
        margin: const EdgeInsets.symmetric(vertical: 5),
        clipBehavior: Clip.antiAlias,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: inputFill,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: colorScheme.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.danger, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        isDense: true,
        hintStyle: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 14),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
          elevation: 0,
          shadowColor: Colors.transparent,
          minimumSize: const Size(double.infinity, 48),
          padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 20),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            letterSpacing: 0,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(double.infinity, 48),
          padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 20),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          side: BorderSide(color: border, width: 1.5),
          textStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            letterSpacing: 0,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          textStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            letterSpacing: 0,
          ),
        ),
      ),
      listTileTheme: const ListTileThemeData(
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      ),
      dividerTheme: DividerThemeData(
        color: border,
        space: 1,
        thickness: 0.5,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        showDragHandle: true,
      ),
      dialogTheme: DialogThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        titleTextStyle: TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.3,
          color: colorScheme.onSurface,
        ),
      ),
      popupMenuTheme: PopupMenuThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 4,
      ),
    );
  }
}
