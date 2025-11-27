//lib/theme/app_theme.dart
import 'package:flutter/material.dart';

class _CPColors {
  // Brand — 옵션 C' 루비 체리 Light
  static const Color primary = Color(0xFFE03A54);        // 루비 체리 (C보다 밝은 버전)
  static const Color primaryStrong = Color(0xFFCB2948);  // 루비 딥 레드 라이트
  static const Color primarySoft = Color(0xFFFFE8EC);    // 루비 소프트

  // Grays (기존 유지)
  static const Color g900 = Color(0xFF111111);
  static const Color g800 = Color(0xFF1F1F1F);
  static const Color g700 = Color(0xFF2E2E2E);
  static const Color g600 = Color(0xFF555555);
  static const Color g500 = Color(0xFF777777);
  static const Color g400 = Color(0xFF9E9E9E);
  static const Color g300 = Color(0xFFD6D6D6);
  static const Color g200 = Color(0xFFECECEC);
  static const Color g100 = Color(0xFFF6F6F6);

  // Status (기존 유지)
  static const Color success = Color(0xFF22C55E);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error   = Color(0xFFEF4444);

  // Other
  static const Color shadow10 = Color(0x1A000000);
}

class AppTheme {
  static ThemeData get lightTheme => _baseTheme(Brightness.light);
  static ThemeData get darkTheme  => _baseTheme(Brightness.dark);

  static ThemeData _baseTheme(Brightness brightness) {
    final isDark = brightness == Brightness.dark;

    final colorScheme = ColorScheme.fromSeed(
      seedColor: _CPColors.primary,
      brightness: brightness,
      primary: _CPColors.primary,
      onPrimary: Colors.white,
      secondary: _CPColors.primaryStrong,
      surface: isDark ? const Color(0xFF121212) : Colors.white,
      onSurface: isDark ? Colors.white : _CPColors.g900,
      error: _CPColors.error,
    );

    return ThemeData(
      useMaterial3: true,
      fontFamily: 'Pretendard', // 프로젝트에 이미 추가되어 있다는 전제
      colorScheme: colorScheme,
      scaffoldBackgroundColor: colorScheme.surface,
      // AppBar
      appBarTheme: AppBarTheme(
        backgroundColor: colorScheme.surface,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: TextStyle(
          fontFamily: 'Pretendard',
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: colorScheme.onSurface,
        ),
        iconTheme: IconThemeData(color: colorScheme.onSurface),
      ),
      // TextTheme
      textTheme: TextTheme(
        displayLarge:  TextStyle(fontSize: 34, fontWeight: FontWeight.w700, color: colorScheme.onSurface),
        displayMedium: TextStyle(fontSize: 28, fontWeight: FontWeight.w700, color: colorScheme.onSurface),
        headlineSmall: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: colorScheme.onSurface),
        titleLarge:    TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: colorScheme.onSurface),
        titleMedium:   TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: colorScheme.onSurface),
        bodyLarge:     TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: colorScheme.onSurface),
        bodyMedium:    TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: isDark ? _CPColors.g300 : _CPColors.g700),
        bodySmall:     TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: isDark ? _CPColors.g400 : _CPColors.g600),
        labelLarge:    const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white),
        labelMedium:   TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: isDark ? _CPColors.g300 : _CPColors.g600),
      ),
      // Buttons
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: _CPColors.primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: _CPColors.primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
          elevation: 0,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: colorScheme.onSurface,
          side: BorderSide(color: isDark ? _CPColors.g600 : _CPColors.g300, width: 1),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: _CPColors.primary,
          textStyle: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      // Inputs
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark ? const Color(0xFF1A1A1A) : _CPColors.g100,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: _CPColors.primary, width: 1),
        ),
        hintStyle: TextStyle(color: isDark ? _CPColors.g500 : _CPColors.g500),
      ),
      //Cards
      cardTheme: CardThemeData(
        color: colorScheme.surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shadowColor: _CPColors.shadow10,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      //BottomSheet
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: colorScheme.surface,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        showDragHandle: false,
      ),
      // Dialog
      dialogTheme: DialogThemeData(
        backgroundColor: colorScheme.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      //Divider
      dividerTheme: DividerThemeData(
        thickness: 1,
        color: isDark ? _CPColors.g700 : _CPColors.g200,
        space: 1,
      ),
      // Slider
      sliderTheme: SliderThemeData(
        trackHeight: 6,
        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
        overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
        activeTrackColor: _CPColors.primary,
        inactiveTrackColor: _CPColors.primarySoft,
        thumbColor: _CPColors.primary,
        overlayColor: _CPColors.primary.withOpacity(0.15),
      ),
      //Chip
      chipTheme: ChipThemeData(
        backgroundColor: isDark ? const Color(0xFF1C1C1C) : _CPColors.g100,
        selectedColor: _CPColors.primarySoft,
        labelStyle: TextStyle(color: colorScheme.onSurface, fontWeight: FontWeight.w600),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      ),
      //Icons
      iconTheme: IconThemeData(color: isDark ? _CPColors.g300 : _CPColors.g700),
      //FAB
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: _CPColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      //BottomNavigation
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        type: BottomNavigationBarType.fixed,
        backgroundColor: colorScheme.surface,
        selectedItemColor: _CPColors.primary,
        unselectedItemColor: isDark ? _CPColors.g500 : _CPColors.g500,
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w700),
        unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600),
        elevation: 0,
      ),
      //ListTile
      listTileTheme: ListTileThemeData(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        iconColor: isDark ? _CPColors.g300 : _CPColors.g600,
        titleTextStyle: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: colorScheme.onSurface,
        ),
        subtitleTextStyle: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: isDark ? _CPColors.g400 : _CPColors.g600,
        ),
      ),
      // Tooltip, Popup
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF2A2A2A) : _CPColors.g900,
          borderRadius: BorderRadius.circular(8),
        ),
        textStyle: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
      ),
    );
  }
}
