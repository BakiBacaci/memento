import 'dart:async';

import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import 'package:home_widget/home_widget.dart';

import '../models/quote.dart';
import '../theme.dart';
import 'daily_service.dart';

/// Memento defteri: her gün bir söz, istersen yanında kısa bir not.
///
///   users/{uid}/journal/{yyyy-mm-dd}  →  { quote, note, created_at }
///
/// Yalnızca sahibi okur ve yazar. Seri = bugünden (bugün henüz yazılmadıysa
/// dünden) geriye doğru kesintisiz yazılan gün sayısı. Kaydırmak, beğenmek
/// tek başına seriyi büyütmez; seri, kişinin gerçekten bir söz seçtiği
/// günlerden oluşur.
class JournalEntry {
  JournalEntry({required this.day, required this.quote, this.note = ''});
  final String day; // yyyy-mm-dd
  final Quote quote;
  final String note;
}

class JournalService {
  JournalService._();
  static final instance = JournalService._();

  final _db = FirebaseFirestore.instance;

  /// Gün anahtarı → kayıt. Canlı.
  final entries = ValueNotifier<Map<String, JournalEntry>>({});
  final streak = ValueNotifier<int>(0);
  final todayDone = ValueNotifier<bool>(false);

  StreamSubscription? _sub;

  static String key(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  CollectionReference<Map<String, dynamic>> _col(String uid) =>
      _db.collection('users').doc(uid).collection('journal');

  /// Oturum değişince çağrılır.
  void bind() {
    _sub?.cancel();
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      entries.value = {};
      _recompute();
      return;
    }
    _sub = _col(uid)
        .orderBy(FieldPath.documentId, descending: true)
        .limit(400)
        .snapshots()
        .listen((s) {
      final map = <String, JournalEntry>{};
      for (final d in s.docs) {
        final m = d.data();
        final q = m['quote'];
        if (q is! Map) continue;
        map[d.id] = JournalEntry(
          day: d.id,
          quote: Quote.fromJson(Map<String, dynamic>.from(q)),
          note: (m['note'] as String?) ?? '',
        );
      }
      entries.value = map;
      _recompute();
      _pushWidget(map);
    }, onError: (Object e) => debugPrint('Defter okunamadı: $e'));
  }

  void _recompute() {
    final map = entries.value;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    todayDone.value = map.containsKey(key(today));
    var day = todayDone.value ? today : today.subtract(const Duration(days: 1));
    var n = 0;
    while (map.containsKey(key(day))) {
      n++;
      day = day.subtract(const Duration(days: 1));
    }
    streak.value = n;
  }

  /// Defter widget'ına son 40 günün renklerini yazar; seri Android
  /// tarafında her çizimde yeniden hesaplanır.
  Future<void> _pushWidget(Map<String, JournalEntry> map) async {
    if (kIsWeb) return;
    try {
      final days = map.keys.toList()..sort();
      final recent = days.reversed.take(40).map((d) {
        final c = QuoteMood.forQuote(map[d]!.quote).top.toARGB32() & 0xFFFFFF;
        return {'d': d, 'c': '#${c.toRadixString(16).padLeft(6, '0')}'};
      }).toList();
      await HomeWidget.saveWidgetData<String>('journal', jsonEncode(recent));
      await HomeWidget.updateWidget(qualifiedAndroidName: DailyService.androidJournalWidget);
    } catch (e) {
      debugPrint('Defter widget güncellenemedi: $e');
    }
  }

  JournalEntry? get today => entries.value[key(DateTime.now())];

  /// Bugünün sözünü deftere işler (varsa değiştirir). Yeni bir gün
  /// eklendiyse `true` döner — kutlama için.
  Future<bool> writeToday(Quote q, String note) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) throw StateError('sign_in');
    final k = key(DateTime.now());
    final wasNew = !entries.value.containsKey(k);
    final json = q.toJson()..removeWhere((_, v) => v == null);
    await _col(uid).doc(k).set({
      'quote': json,
      'note': note.trim(),
      'created_at': FieldValue.serverTimestamp(),
    });
    return wasNew;
  }

  Future<void> remove(String day) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    await _col(uid).doc(day).delete();
  }
}
