import 'dart:convert';

import 'dart:math';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:home_widget/home_widget.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../models/quote.dart';
import '../theme.dart';
import 'quote_service.dart';
import 'settings_service.dart';

/// "Günün sözü" — uygulamayı her gün yeniden açtıran mekanik.
///
/// Üç yerde görünür:
///   1. Ana ekran widget'ı (Android + iOS)
///   2. Kilit ekranı widget'ı (iOS 16+)
///   3. Her gün seçilen saatte bildirim (Android'de kilit ekranında da görünür)
///
/// Widget'lar uygulama açılmasa da her gün değişsin diye önümüzdeki
/// [_horizonDays] günün sözleri tek seferde widget deposuna yazılıyor;
/// yerel (Kotlin / Swift) taraf bugünün tarihine bakıp doğru sözü seçiyor.
class DailyService {
  DailyService._();
  static final instance = DailyService._();

  static const appGroupId = 'group.com.bakibacaci.memento';
  static const androidWidget = 'com.bakibacaci.memento.MementoWidgetProvider';
  static const androidSmallWidget = 'com.bakibacaci.memento.MementoSmallWidgetProvider';
  static const androidJournalWidget = 'com.bakibacaci.memento.MementoJournalWidgetProvider';
  static const iosWidget = 'MementoWidget';

  static const _horizonDays = 45;
  static const _notifDays = 14;
  static const _kEnabled = 'daily_enabled';
  static const _kHour = 'daily_hour';
  static const _kMinute = 'daily_minute';

  final enabled = ValueNotifier<bool>(false);

  /// Art arda kaç gün günlük hedef tamamlandı. Kaçırılan gün seriyi sıfırlar.
  final streak = ValueNotifier<int>(0);

  /// Günlük hedef: bugün kaç söze karar verildi (beğen ya da geç).
  static const dailyGoal = 5;
  final todayCount = ValueNotifier<int>(0);
  SharedPreferences? _prefs;
  final time = ValueNotifier<TimeOfDay>(const TimeOfDay(hour: 9, minute: 0));

  final _notifs = FlutterLocalNotificationsPlugin();
  bool _ready = false;

  Future<void> init() async {
    await _loadSeed();
    if (kIsWeb) return;
    try {
      await HomeWidget.setAppGroupId(appGroupId);

      tzdata.initializeTimeZones();
      final zone = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(zone.identifier));

      await _notifs.initialize(
        settings: const InitializationSettings(
          android: AndroidInitializationSettings('@drawable/ic_stat_memento'),
          iOS: DarwinInitializationSettings(
            requestAlertPermission: false,
            requestBadgePermission: false,
            requestSoundPermission: false,
          ),
        ),
      );

      final p = await SharedPreferences.getInstance();
      enabled.value = p.getBool(_kEnabled) ?? false;
      time.value = TimeOfDay(
        hour: p.getInt(_kHour) ?? 9,
        minute: p.getInt(_kMinute) ?? 0,
      );
      _ready = true;
      _prefs = p;
      _loadProgress(p);
    } catch (e) {
      debugPrint('Günlük söz servisi başlatılamadı: $e');
    }
    await refresh();
  }

  // ---------------------------------------------------------------
  // Söz seçimi — kişiye özel. Herkes her gün FARKLI bir söz görür:
  // kişinin tohumu (giriş yaptıysa uid'den, değilse cihaza özel rastgele
  // sayı) + tarih → motive eden sözler havuzundan bir söz. Aynı kişi aynı
  // gün hep aynı sözü görür (widget, bildirim ve uygulama tutarlı).
  // ---------------------------------------------------------------
  int _seed = 0;

  /// Bugünün sözü açıldı mı? Açılmadıysa başlıktaki düğmede nokta yanar.
  final seenToday = ValueNotifier<bool>(true);

  Future<void> _loadSeed() async {
    final p = _prefs ?? await SharedPreferences.getInstance();
    _prefs = p;
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      _seed = int.parse(stableHash(uid), radix: 16);
    } else {
      var s = p.getInt('daily_seed');
      if (s == null) {
        s = Random().nextInt(1 << 30);
        await p.setInt('daily_seed', s);
      }
      _seed = s;
    }
    seenToday.value = p.getString('daily_seen') == _ymd(DateTime.now());
  }

  Future<void> markSeen() async {
    final p = _prefs ?? await SharedPreferences.getInstance();
    await p.setString('daily_seen', _ymd(DateTime.now()));
    seenToday.value = true;
  }

  /// Oturum değişince (giriş/çıkış) tohum yeniden hesaplanır.
  Future<void> onAuthChanged() async {
    await _loadSeed();
    await refresh();
  }
  static int _dayNumber(DateTime d) =>
      DateTime.utc(d.year, d.month, d.day).millisecondsSinceEpoch ~/ 86400000;

  Quote? quoteFor(List<Quote> all, DateTime day) {
    final pool = all.where((q) => q.daily).toList();
    final list = pool.isEmpty ? all : pool;
    if (list.isEmpty) return null;
    // 7919 asal: ardışık günler havuzda birbirinden uzak sözlere düşüyor;
    // tohum her kişiyi havuzun farklı bir yerinden başlatıyor.
    return list[((_dayNumber(day) * 7919) + _seed) % list.length];
  }

  Future<Quote?> today() async {
    if (_seed == 0) await _loadSeed();
    return quoteFor(await QuoteService.instance.loadAssetQuotes(), DateTime.now());
  }

  static String _hex(Color c) =>
      '#${(c.toARGB32() & 0xFFFFFF).toRadixString(16).padLeft(6, '0').toUpperCase()}';

  static String _ymd(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  /// Widget verisini ve planlanmış bildirimleri yeniler. Uygulama her
  /// açıldığında ve ayar değiştiğinde çağrılır.
  Future<void> refresh() async {
    if (kIsWeb || !_ready) return;
    final all = await QuoteService.instance.loadAssetQuotes();
    if (all.isEmpty) return;
    final lang = SettingsService.instance.language.value;
    final now = DateTime.now();

    final days = <Map<String, String>>[];
    for (var i = 0; i < _horizonDays; i++) {
      final day = now.add(Duration(days: i));
      final q = quoteFor(all, day)!;
      final mood = QuoteMood.forQuote(q);
      days.add({
        'd': _ymd(day),
        't': q.textFor(lang),
        'a': q.authorFor(lang),
        'bg': _hex(mood.top),
        'ink': _hex(mood.accent),
      });
    }

    try {
      await HomeWidget.saveWidgetData<String>('days', jsonEncode(days));
      await HomeWidget.saveWidgetData<String>('text', days.first['t']);
      await HomeWidget.saveWidgetData<String>('author', days.first['a']);
      await HomeWidget.saveWidgetData<String>(
          'label', lang == 'en' ? 'Today, for you' : 'Bugün senin için');
      await HomeWidget.saveWidgetData<String>('lang', lang);
      await HomeWidget.updateWidget(
          qualifiedAndroidName: androidWidget, iOSName: iosWidget);
      await HomeWidget.updateWidget(qualifiedAndroidName: androidSmallWidget);
    } catch (e) {
      debugPrint('Widget güncellenemedi: $e');
    }

    await _schedule(all, lang);
  }

  Future<void> _schedule(List<Quote> all, String lang) async {
    try {
      await _notifs.cancelAll();
      if (!enabled.value) return;

      final t = time.value;
      final now = tz.TZDateTime.now(tz.local);
      var first = tz.TZDateTime(tz.local, now.year, now.month, now.day, t.hour, t.minute);
      if (!first.isAfter(now)) first = first.add(const Duration(days: 1));

      const details = NotificationDetails(
        android: AndroidNotificationDetails(
          'daily_quote',
          'Günün sözü',
          channelDescription: 'Her gün bir söz',
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
          styleInformation: BigTextStyleInformation(''),
          visibility: NotificationVisibility.public, // kilit ekranında tam metin
        ),
        iOS: DarwinNotificationDetails(),
      );

      for (var i = 0; i < _notifDays; i++) {
        final when = first.add(Duration(days: i));
        final q = quoteFor(all, DateTime(when.year, when.month, when.day))!;
        await _notifs.zonedSchedule(
          id: i,
          title: q.authorFor(lang),
          body: '“${q.textFor(lang)}”',
          scheduledDate: when,
          notificationDetails: details,
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        );
      }
    } catch (e) {
      debugPrint('Bildirimler planlanamadı: $e');
    }
  }

  void _loadProgress(SharedPreferences p) {
    final today = _dayNumber(DateTime.now());
    final last = p.getInt('streak_last') ?? -10;
    final n = p.getInt('streak_count') ?? 0;
    // Dün ya da bugün hedef tamamlandıysa seri sürüyor; yoksa sıfır.
    streak.value = (last == today || last == today - 1) ? n : 0;
    todayCount.value =
        p.getInt('goal_day') == today ? (p.getInt('goal_count') ?? 0) : 0;
  }

  /// Bir söze karar verildi (sağa ya da sola kaydırma). Hedef tam bu
  /// kaydırmayla dolduysa `true` döner — kutlama göstermek için.
  Future<bool> recordRead() async {
    final p = _prefs ?? await SharedPreferences.getInstance();
    _prefs = p;
    final today = _dayNumber(DateTime.now());
    if (p.getInt('goal_day') != today) {
      await p.setInt('goal_day', today);
      todayCount.value = 0;
    }
    todayCount.value += 1;
    await p.setInt('goal_count', todayCount.value);
    if (todayCount.value != dailyGoal) return false;

    final last = p.getInt('streak_last') ?? -10;
    var n = p.getInt('streak_count') ?? 0;
    if (last == today) return false;
    n = last == today - 1 ? n + 1 : 1;
    await p.setInt('streak_last', today);
    await p.setInt('streak_count', n);
    streak.value = n;
    return true;
  }

  /// `false` dönerse kullanıcı bildirim iznini vermedi.
  Future<bool> setEnabled(bool on) async {
    if (on) {
      final granted = await _requestPermission();
      if (!granted) return false;
    }
    enabled.value = on;
    final p = await SharedPreferences.getInstance();
    await p.setBool(_kEnabled, on);
    await refresh();
    return true;
  }

  Future<void> setTime(TimeOfDay t) async {
    time.value = t;
    final p = await SharedPreferences.getInstance();
    await p.setInt(_kHour, t.hour);
    await p.setInt(_kMinute, t.minute);
    await refresh();
  }

  Future<bool> _requestPermission() async {
    if (kIsWeb) return false;
    if (defaultTargetPlatform == TargetPlatform.android) {
      final android = _notifs.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      return await android?.requestNotificationsPermission() ?? true;
    }
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      final ios = _notifs.resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin>();
      return await ios?.requestPermissions(alert: true, sound: true) ?? false;
    }
    return false;
  }
}
