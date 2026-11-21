import 'package:flutter/material.dart';

import 'models/quote.dart';

/// Uygulamanın tek renk ve tipografi kaynağı.
///
/// Dil: "renk patlaması". Açık, sıcak-gri bir zemin; her söz kendi düz
/// renginde, kalın ve sıkı bir grotesk ile (Bricolage Grotesque). Degrade,
/// parlama, gölge yok — renk ve yazı işi taşıyor.
class _Palette {
  const _Palette({
    required this.gold,
    required this.goldSoft,
    required this.goldDeep,
    required this.onAccent,
    required this.bg,
    required this.surface,
    required this.surface2,
    required this.surfaceAlt,
    required this.border,
    required this.textPrimary,
    required this.textMuted,
  });
  final Color gold, goldSoft, goldDeep, onAccent;
  final Color bg, surface, surface2, surfaceAlt, border;
  final Color textPrimary, textMuted;
}

const _light = _Palette(
  gold: Color(0xFF5B2EE6),
  goldSoft: Color(0xFFC9B6FF),
  goldDeep: Color(0xFF2A1460),
  onAccent: Color(0xFFFFFFFF),
  bg: Color(0xFFF5F3EE),
  surface: Color(0xFFFFFFFF),
  surface2: Color(0xFFECE9E2),
  surfaceAlt: Color(0xFFEFECE6),
  border: Color(0xFFDEDAD2),
  textPrimary: Color(0xFF17171A),
  textMuted: Color(0xFF6B6B70),
);

const _dark = _Palette(
  gold: Color(0xFFC9B6FF),
  goldSoft: Color(0xFF3B2C78),
  goldDeep: Color(0xFFE6DDFF),
  onAccent: Color(0xFF2A1460),
  bg: Color(0xFF151517),
  surface: Color(0xFF1F1F22),
  surface2: Color(0xFF2A2A2E),
  surfaceAlt: Color(0xFF242427),
  border: Color(0xFF34343A),
  textPrimary: Color(0xFFF5F3EE),
  textMuted: Color(0xFFA3A3A9),
);

/// Renkler seçili temaya göre değişir (açık / koyu). Tema değişince uygulama
/// ağacı baştan kurulduğu için her ekran yeni renkleri okur.
class AppColors {
  static _Palette _p = _light;
  static bool get isDark => identical(_p, _dark);
  static void apply(Brightness b) => _p = b == Brightness.dark ? _dark : _light;

  // Marka vurgusu. Adı tarihsel olarak "gold".
  static Color get gold => _p.gold;
  static Color get goldSoft => _p.goldSoft;
  static Color get goldDeep => _p.goldDeep;
  static Color get onAccent => _p.onAccent;

  static Color get bg => _p.bg;
  static Color get surface => _p.surface;
  static Color get surface2 => _p.surface2;
  static Color get surfaceAlt => _p.surfaceAlt;
  static Color get border => _p.border;

  static Color get textPrimary => _p.textPrimary;
  static Color get textMuted => _p.textMuted;

  // Silme gibi geri alınamaz işlemler ve bildirim rozeti.
  static const danger = Color(0xFFE5484D);

  // Zirve kürsüsü (iki temada aynı).
  static const gold1 = Color(0xFFF2B705);
  static const silver = Color(0xFFA9B1BC);
  static const bronze = Color(0xFFC9773B);

  static LinearGradient get goldGradient => LinearGradient(colors: [gold, gold]);
}

const kSerif = 'Bricolage';
const kSans = 'Bricolage';

/// Her sözün rengi: kimliğinden türetilir, hep aynı kalır.
/// [top] zemin, [accent] o zemin üstündeki yazı rengi (aynı aileden koyu ton).
class QuoteMood {
  const QuoteMood(this.top, this.accent, this.name);
  final Color top;
  final Color accent;
  final String name;

  Color get bottom => top;

  static const _base = [
    QuoteMood(Color(0xFFC9B6FF), Color(0xFF2A1460), 'lila'),
    QuoteMood(Color(0xFFD7F75B), Color(0xFF24400A), 'limon'),
    QuoteMood(Color(0xFF9AD1FF), Color(0xFF0A2A4A), 'gök'),
    QuoteMood(Color(0xFFFF9F80), Color(0xFF4A1406), 'mercan'),
    QuoteMood(Color(0xFFFFB8DE), Color(0xFF5A0F35), 'pembe'),
    QuoteMood(Color(0xFFFFE27A), Color(0xFF4A3600), 'tereyağı'),
    QuoteMood(Color(0xFF8FE3C4), Color(0xFF07402C), 'nane'),
    QuoteMood(Color(0xFF17171A), Color(0xFFF5F3EE), 'gece'),
  ];

  static List<QuoteMood> get all => AppColors.isDark
      ? [..._base.take(_base.length - 1), const QuoteMood(Color(0xFFF5F3EE), Color(0xFF17171A), 'kağıt')]
      : _base;

  /// Sözün rengi: yazarı seçtiyse o, yoksa kimliğinden türetilen.
  static QuoteMood forQuote(Quote q) {
    final c = q.color;
    if (c != null && c >= 0 && c < _base.length) return all[c];
    return of(q.id);
  }

  static QuoteMood of(String id) {
    var h = 0;
    for (final c in id.codeUnits) {
      h = (h * 31 + c) & 0x7fffffff;
    }
    return all[h % all.length];
  }

  /// Geriye uyumluluk: eskiden degrade dönüyordu, artık düz renk.
  LinearGradient get gradient => LinearGradient(colors: [top, top]);
}

/// Söz metni: uzunluğa göre küçülen, sıkı ve kalın grotesk.
TextStyle quoteStyle(String text, {double scale = 1, Color? color}) {
  final byLength = switch (text.length) {
    > 220 => 22.0,
    > 150 => 26.0,
    > 90 => 31.0,
    > 45 => 37.0,
    _ => 44.0,
  };
  // En uzun kelime satıra sığmalı: yoksa "Sorgulanmamış" gibi kelimeler
  // ortadan bölünüyor. Kart yazı alanı ~300 birim, harf başına ~0.6 em.
  var longest = 0;
  for (final w in text.split(RegExp(r'\s+'))) {
    if (w.length > longest) longest = w.length;
  }
  final byWord = longest == 0 ? byLength : 300 / (longest * 0.6);
  final size = (byWord < byLength ? byWord : byLength).clamp(20.0, 44.0);
  return TextStyle(
    fontFamily: kSans,
    fontWeight: FontWeight.w800,
    fontSize: size * scale,
    height: 1.0,
    letterSpacing: -0.035 * size * scale,
    color: color ?? AppColors.textPrimary,
  );
}

ThemeData buildAppTheme() {
  final dark = AppColors.isDark;
  final base = dark ? ThemeData.dark(useMaterial3: true) : ThemeData.light(useMaterial3: true);
  final text = base.textTheme.apply(
    fontFamily: kSans,
    bodyColor: AppColors.textPrimary,
    displayColor: AppColors.textPrimary,
  );

  return base.copyWith(
    scaffoldBackgroundColor: AppColors.bg,
    primaryColor: AppColors.gold,
    textTheme: text,
    primaryTextTheme: text,
    colorScheme: (dark ? const ColorScheme.dark() : const ColorScheme.light()).copyWith(
      primary: AppColors.gold,
      onPrimary: AppColors.onAccent,
      secondary: AppColors.goldSoft,
      onSecondary: AppColors.goldDeep,
      surface: AppColors.surface,
      onSurface: AppColors.textPrimary,
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: AppColors.bg,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      centerTitle: false,
      iconTheme: IconThemeData(color: AppColors.textPrimary),
      titleTextStyle: TextStyle(
        fontFamily: kSans,
        color: AppColors.textPrimary,
        fontSize: 26,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.8,
      ),
    ),
    tabBarTheme: TabBarThemeData(
      labelColor: AppColors.onAccent,
      unselectedLabelColor: AppColors.textPrimary,
      indicator: ShapeDecoration(
        color: AppColors.textPrimary,
        shape: StadiumBorder(),
      ),
      indicatorSize: TabBarIndicatorSize.tab,
      dividerColor: Colors.transparent,
      labelPadding: EdgeInsets.symmetric(horizontal: 4),
      labelStyle: TextStyle(fontFamily: kSans, fontWeight: FontWeight.w600, fontSize: 14),
      unselectedLabelStyle: TextStyle(fontFamily: kSans, fontWeight: FontWeight.w600, fontSize: 14),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      titleTextStyle: TextStyle(
          fontFamily: kSans, fontSize: 22, fontWeight: FontWeight.w800,
          color: AppColors.textPrimary),
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: AppColors.surface,
      surfaceTintColor: Colors.transparent,
      showDragHandle: true,
      dragHandleColor: AppColors.border,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: AppColors.textPrimary,
      contentTextStyle: TextStyle(
          fontFamily: kSans, color: AppColors.bg, fontWeight: FontWeight.w600),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(40)),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.textPrimary,
        foregroundColor: AppColors.bg,
        disabledBackgroundColor: AppColors.border,
        minimumSize: const Size.fromHeight(56),
        elevation: 0,
        shape: const StadiumBorder(),
        textStyle: const TextStyle(
            fontFamily: kSans, fontWeight: FontWeight.w800, fontSize: 16),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.textPrimary,
        side: BorderSide(color: AppColors.textPrimary, width: 2),
        shape: const StadiumBorder(),
        textStyle: const TextStyle(fontFamily: kSans, fontWeight: FontWeight.w600),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.surface,
      hintStyle: TextStyle(color: AppColors.textMuted),
      labelStyle: TextStyle(color: AppColors.textMuted),
      counterStyle: TextStyle(color: AppColors.textMuted, fontSize: 11),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide(color: AppColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide(color: AppColors.textPrimary, width: 2),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: AppColors.gold,
        textStyle: const TextStyle(fontFamily: kSans, fontWeight: FontWeight.w600),
      ),
    ),
    switchTheme: SwitchThemeData(
      trackColor: WidgetStateProperty.resolveWith((s) =>
          s.contains(WidgetState.selected) ? AppColors.textPrimary : AppColors.surface2),
      thumbColor: WidgetStateProperty.resolveWith((s) =>
          s.contains(WidgetState.selected) ? AppColors.bg : AppColors.textMuted),
      trackOutlineColor: const WidgetStatePropertyAll(Colors.transparent),
    ),
    dividerTheme: DividerThemeData(color: AppColors.border, space: 1),
    progressIndicatorTheme:
        ProgressIndicatorThemeData(color: AppColors.textPrimary),
    listTileTheme: ListTileThemeData(
      titleTextStyle: TextStyle(fontFamily: kSans, color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.w600),
      subtitleTextStyle: TextStyle(fontFamily: kSans, color: AppColors.textMuted, fontSize: 13),
    ),
  );
}
