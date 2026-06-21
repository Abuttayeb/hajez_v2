import 'package:flutter/material.dart';

// ═══════════════════════════════════════════════════════
// 🎨 HAJEZ PREMIUM DESIGN SYSTEM v2.0
// ═══════════════════════════════════════════════════════

class AppColors {
  // Primary Palette - Deep Teal
  static const primary = Color(0xFF007C91);
  static const primaryLight = Color(0xFF4DB6AC);
  static const primaryDark = Color(0xFF004D5A);
  static const primarySurface = Color(0xFFE0F7FA);

  // Secondary
  static const secondary = Color(0xFF00695C);
  static const accent = Color(0xFF26C6DA);

  // Gold for premium feel
  static const gold = Color(0xFFFFB300);
  static const goldLight = Color(0xFFFFE082);
  static const goldDark = Color(0xFFFF8F00);

  // Neutrals
  static const background = Color(0xFFF8FAFB);
  static const surface = Color(0xFFFFFFFF);
  static const white = Color(0xFFFFFFFF);
  static const dark = Color(0xFF1A2332);
  static const darkSecondary = Color(0xFF2D3E50);
  static const grey900 = Color(0xFF212121);
  static const grey700 = Color(0xFF616161);
  static const grey600 = Color(0xFF757575);
  static const grey500 = Color(0xFF9E9E9E);
  static const grey400 = Color(0xFFBDBDBD);
  static const grey300 = Color(0xFFE0E0E0);
  static const grey200 = Color(0xFFEEEEEE);
  static const grey100 = Color(0xFFF5F5F5);
  static const grey = Color(0xFF9E9E9E);
  static const greyMedium = Color(0xFFBDBDBD);
  static const greyLight = Color(0xFFF5F5F5);
  static const star = Color(0xFFFFB300);

  // Semantic
  static const error = Color(0xFFE53935);
  static const errorLight = Color(0xFFFFEBEE);
  static const success = Color(0xFF2E7D32);
  static const successLight = Color(0xFFE8F5E9);
  static const warning = Color(0xFFF57F17);
  static const warningLight = Color(0xFFFFF8E1);
  static const info = Color(0xFF1565C0);
  static const infoLight = Color(0xFFE3F2FD);

  // Social
  static const whatsapp = Color(0xFF25D366);
  static const cliq = Color(0xFF0033A0);
  static const efawateer = Color(0xFFE65100);

  // Shadow colors
  static const shadowPrimary = Color(0x15007C91);
  static const shadowDark = Color(0x1A1A2332);
}

class AppDarkColors {
  static const background = Color(0xFF121820);
  static const surface = Color(0xFF1E2736);
  static const cardSurface = Color(0xFF253040);
  static const primary = Color(0xFF4DB6AC);
  static const primaryLight = Color(0xFF80CBC4);
  static const gold = Color(0xFFFFB300);
  static const text = Color(0xFFECEFF1);
  static const textSecondary = Color(0xFF90A4AE);
  static const border = Color(0xFF37474F);
  static const errorLight = Color(0x1AE53935);
  static const successLight = Color(0x1A2E7D32);
  static const warningLight = Color(0x1AF57F17);
  static const greyLight = Color(0xFF2A3A4A);
}

class AppSpacing {
  static const xs = 4.0;
  static const sm = 8.0;
  static const md = 12.0;
  static const lg = 16.0;
  static const xl = 20.0;
  static const xxl = 24.0;
  static const xxxl = 32.0;
}

class AppRadius {
  static const sm = 8.0;
  static const md = 12.0;
  static const lg = 16.0;
  static const xl = 20.0;
  static const xxl = 24.0;
  static const xxxl = 32.0;
  static const full = 100.0;
}

class AppText {
  static const heading1 = TextStyle(fontFamily: 'Cairo', fontSize: 28, fontWeight: FontWeight.w800, color: AppColors.dark, letterSpacing: -0.5);
  static const heading2 = TextStyle(fontFamily: 'Cairo', fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.dark);
  static const heading3 = TextStyle(fontFamily: 'Cairo', fontSize: 17, fontWeight: FontWeight.w700, color: AppColors.dark);
  static const heading4 = TextStyle(fontFamily: 'Cairo', fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.dark);
  static const body = TextStyle(fontFamily: 'Cairo', fontSize: 14, color: AppColors.darkSecondary, height: 1.6);
  static const bodyBold = TextStyle(fontFamily: 'Cairo', fontSize: 14, color: AppColors.dark, fontWeight: FontWeight.w600);
  static const bodyGrey = TextStyle(fontFamily: 'Cairo', fontSize: 14, color: AppColors.grey500, height: 1.5);
  static const small = TextStyle(fontFamily: 'Cairo', fontSize: 12, color: AppColors.grey500);
  static const smallBold = TextStyle(fontFamily: 'Cairo', fontSize: 12, color: AppColors.darkSecondary, fontWeight: FontWeight.w600);
  static const price = TextStyle(fontFamily: 'Cairo', fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.primary);
  static const caption = TextStyle(fontFamily: 'Cairo', fontSize: 11, color: AppColors.grey500);
  static const button = TextStyle(fontFamily: 'Cairo', fontSize: 15, fontWeight: FontWeight.w700);
}

class AppTheme {
  static ThemeData get light => ThemeData(
    useMaterial3: true,
    fontFamily: 'Cairo',
    brightness: Brightness.light,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      primary: AppColors.primary,
      secondary: AppColors.secondary,
      surface: AppColors.surface,
      error: AppColors.error,
    ),
    scaffoldBackgroundColor: AppColors.background,
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.surface,
      foregroundColor: AppColors.dark,
      elevation: 0,
      centerTitle: true,
      scrolledUnderElevation: 2,
      surfaceTintColor: Colors.transparent,
      titleTextStyle: TextStyle(fontFamily: 'Cairo', color: AppColors.dark, fontSize: 18, fontWeight: FontWeight.w700),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.white,
        minimumSize: const Size(double.infinity, 56),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.lg)),
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        textStyle: AppText.button,
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.primary,
        minimumSize: const Size(double.infinity, 56),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.lg)),
        side: const BorderSide(color: AppColors.primary, width: 1.5),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        textStyle: AppText.button,
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: AppColors.primary,
        textStyle: const TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w700),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.grey100,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.lg), borderSide: BorderSide.none),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.lg), borderSide: BorderSide.none),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.lg), borderSide: const BorderSide(color: AppColors.primary, width: 2)),
      errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.lg), borderSide: const BorderSide(color: AppColors.error)),
      focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.lg), borderSide: const BorderSide(color: AppColors.error, width: 2)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      labelStyle: const TextStyle(fontFamily: 'Cairo', color: AppColors.grey500),
      hintStyle: const TextStyle(fontFamily: 'Cairo', color: AppColors.grey500),
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      color: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.xl)),
      margin: EdgeInsets.zero,
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: AppColors.surface,
      selectedItemColor: AppColors.primary,
      unselectedItemColor: AppColors.grey500,
      type: BottomNavigationBarType.fixed,
      elevation: 0,
      selectedLabelStyle: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w700, fontSize: 11),
      unselectedLabelStyle: TextStyle(fontFamily: 'Cairo', fontSize: 11),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.lg)),
      width: 380,
    ),
    dialogTheme: DialogThemeData(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.xxl)),
      titleTextStyle: const TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w700, fontSize: 20),
    ),
    dividerTheme: const DividerThemeData(thickness: 1, color: AppColors.grey200),
    tabBarTheme: const TabBarTheme(
      labelColor: AppColors.primary,
      unselectedLabelColor: AppColors.grey500,
      indicatorColor: AppColors.primary,
      labelStyle: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w700),
      unselectedLabelStyle: TextStyle(fontFamily: 'Cairo'),
    ),
  );

  static ThemeData get dark => ThemeData(
    useMaterial3: true,
    fontFamily: 'Cairo',
    brightness: Brightness.dark,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.primaryLight,
      primary: AppDarkColors.primary,
      secondary: AppDarkColors.primaryLight,
      surface: AppDarkColors.surface,
      error: AppColors.error,
    ),
    scaffoldBackgroundColor: AppDarkColors.background,
    appBarTheme: const AppBarTheme(
      backgroundColor: AppDarkColors.surface,
      foregroundColor: AppDarkColors.text,
      elevation: 0,
      centerTitle: true,
      surfaceTintColor: Colors.transparent,
      titleTextStyle: TextStyle(fontFamily: 'Cairo', color: AppDarkColors.text, fontSize: 18, fontWeight: FontWeight.w700),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppDarkColors.primary,
        foregroundColor: AppDarkColors.background,
        minimumSize: const Size(double.infinity, 56),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.lg)),
        textStyle: AppText.button,
      ),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: AppDarkColors.surface,
      selectedItemColor: AppDarkColors.primary,
      unselectedItemColor: AppDarkColors.textSecondary,
      type: BottomNavigationBarType.fixed,
      elevation: 0,
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      color: AppDarkColors.cardSurface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.xl)),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppDarkColors.greyLight,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.lg), borderSide: BorderSide.none),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.lg), borderSide: BorderSide.none),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.lg), borderSide: const BorderSide(color: AppDarkColors.primary, width: 2)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      labelStyle: const TextStyle(fontFamily: 'Cairo', color: AppDarkColors.textSecondary),
      hintStyle: const TextStyle(fontFamily: 'Cairo', color: AppDarkColors.textSecondary),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.lg)),
      backgroundColor: AppDarkColors.cardSurface,
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: AppDarkColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.xxl)),
    ),
    dividerTheme: const DividerThemeData(thickness: 1, color: AppDarkColors.border),
    tabBarTheme: const TabBarTheme(
      labelColor: AppDarkColors.primary,
      unselectedLabelColor: AppDarkColors.textSecondary,
      indicatorColor: AppDarkColors.primary,
    ),
  );
}