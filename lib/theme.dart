import 'package:flutter/material.dart';

/// Uygulamanın tek renk kaynağı.
///
/// Kaydırma sırasında yeşil/kırmızı katman kaldırıldı — o renkler flört
/// uygulamalarının dili ve Memento'nun sakin tonuna ters düşüyordu. Yerine
/// sadece altın bir parlama ve kalp kullanılıyor.
class AppColors {
  static const gold = Color(0xFFD4AF37);
  static const goldSoft = Color(0xFFE8CC72);

  static const bg = Color(0xFF0A0A0A);
  static const surface = Color(0xFF161616);
  static const surface2 = Color(0xFF222222);
  static const surfaceAlt = Color(0xFF1C1C1C);
  static const border = Color(0xFF2E2E2E);

  static const textPrimary = Color(0xFFEDEDED);
  static const textMuted = Color(0xFF8A8A8A);

  static const gold1 = Color(0xFFFFD700);
  static const silver = Color(0xFFC7C7C7);
  static const bronze = Color(0xFFCD7F32);
}

const kSerif = 'Georgia';

ThemeData buildAppTheme() {
  final base = ThemeData.dark(useMaterial3: true);
  return base.copyWith(
    scaffoldBackgroundColor: AppColors.bg,
    primaryColor: AppColors.gold,
    colorScheme: const ColorScheme.dark(
      primary: AppColors.gold,
      secondary: AppColors.goldSoft,
      surface: AppColors.surface,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.bg,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      centerTitle: true,
      iconTheme: IconThemeData(color: Colors.white),
      titleTextStyle: TextStyle(
        color: Colors.white,
        fontSize: 16,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.5,
      ),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: AppColors.bg,
      selectedItemColor: AppColors.gold,
      unselectedItemColor: AppColors.textMuted,
      type: BottomNavigationBarType.fixed,
      elevation: 0,
    ),
    tabBarTheme: const TabBarThemeData(
      labelColor: Colors.white,
      unselectedLabelColor: AppColors.textMuted,
      indicatorColor: AppColors.gold,
      dividerColor: AppColors.border,
      labelStyle: TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: AppColors.surface,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: AppColors.surface2,
      contentTextStyle: const TextStyle(
          color: Colors.white, fontWeight: FontWeight.w600),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.surface,
      hintStyle: const TextStyle(color: AppColors.textMuted),
      labelStyle: const TextStyle(color: AppColors.textMuted),
      counterStyle: const TextStyle(color: AppColors.textMuted, fontSize: 11),
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.gold, width: 1.6),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: AppColors.gold,
        textStyle: const TextStyle(fontWeight: FontWeight.w700),
      ),
    ),
    dividerTheme: const DividerThemeData(color: AppColors.border, space: 1),
    progressIndicatorTheme:
        const ProgressIndicatorThemeData(color: AppColors.gold),
    listTileTheme: const ListTileThemeData(
      titleTextStyle: TextStyle(color: Colors.white, fontSize: 15),
      subtitleTextStyle: TextStyle(color: AppColors.textMuted, fontSize: 12),
    ),
  );
}
