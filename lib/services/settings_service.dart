import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Dil ve oturum tercihleri. `ValueNotifier` olduğu için ayarlar sayfasında
/// dili değiştirdiğinde tüm uygulama anında yeniden çiziliyor — yeniden
/// başlatmaya gerek yok.
class SettingsService {
  SettingsService._();
  static final instance = SettingsService._();

  static const _kLang = 'app_language';
  static const _kGuest = 'guest_mode';

  final language = ValueNotifier<String>('tr');

  /// Kullanıcı "hesapsız devam et" dediyse true. Bir daha giriş duvarı
  /// gösterilmez, ama beğenme/paylaşma gibi işlemlerde giriş istenir.
  final guestMode = ValueNotifier<bool>(false);

  SharedPreferences? _prefs;

  Future<void> load() async {
    _prefs = await SharedPreferences.getInstance();

    final saved = _prefs?.getString(_kLang);
    if (saved != null && (saved == 'tr' || saved == 'en')) {
      language.value = saved;
    } else {
      // İlk açılış: cihazın dili İngilizce ise İngilizce başlat.
      final device = ui.PlatformDispatcher.instance.locale.languageCode;
      language.value = device == 'tr' ? 'tr' : 'en';
    }

    guestMode.value = _prefs?.getBool(_kGuest) ?? false;
  }

  Future<void> setLanguage(String code) async {
    if (code != 'tr' && code != 'en') return;
    language.value = code;
    await _prefs?.setString(_kLang, code);
  }

  Future<void> setGuestMode(bool value) async {
    guestMode.value = value;
    await _prefs?.setBool(_kGuest, value);
  }
}
