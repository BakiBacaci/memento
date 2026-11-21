import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/quote.dart';

/// Kaydedilen sözler — Firestore'da: users/{uid}/saved/{quoteId}
///
/// Önceden cihazda (SharedPreferences) tutuluyordu; telefon değişince ya da
/// uygulama silinince kayıtlar gidiyordu. Eski kayıtlar ilk girişte otomatik
/// buluta taşınıyor.
///
/// Giriş yapılmamışsa yerel depoya düşüyor — misafir kullanıcı da söz
/// kaydedebilsin, giriş yapınca kayıtları taşınsın diye.
class SavedService {
  SavedService._();
  static final instance = SavedService._();

  static const _legacyKey = 'saved_quotes_v2';

  final _db = FirebaseFirestore.instance;

  String? get _uid => FirebaseAuth.instance.currentUser?.uid;

  CollectionReference<Map<String, dynamic>>? get _col {
    final uid = _uid;
    if (uid == null) return null;
    return _db.collection('users').doc(uid).collection('saved');
  }

  // ---------------------------------------------------------------
  // Okuma
  // ---------------------------------------------------------------

  /// Canlı akış — kaydedilenler değişince ekran kendiliğinden güncellenir.
  Stream<List<Quote>> watch() {
    final col = _col;
    if (col == null) return Stream.fromFuture(_legacyAll());
    return col
        .orderBy('saved_at', descending: true)
        .snapshots()
        .map((s) => s.docs.map(_fromDoc).toList());
  }

  /// Kaydedilenlerin kimlikleri — canlı.
  Stream<Set<String>> watchIds() {
    final col = _col;
    if (col == null) {
      return Stream.fromFuture(_legacyAll()).map((l) => l.map((q) => q.id).toSet());
    }
    _migrateIfNeeded();
    return col.snapshots().map((s) => s.docs.map((d) => d.id).toSet());
  }

  Future<List<Quote>> all() async {
    final col = _col;
    if (col == null) return _legacyAll();
    await _migrateIfNeeded();
    try {
      final snap = await col.orderBy('saved_at', descending: true).get();
      return snap.docs.map(_fromDoc).toList();
    } catch (e) {
      debugPrint('Kaydedilenler okunamadı: $e');
      return const [];
    }
  }

  Future<Set<String>> savedIds() async => (await all()).map((q) => q.id).toSet();

  Quote _fromDoc(QueryDocumentSnapshot<Map<String, dynamic>> d) =>
      Quote.fromJson({...d.data(), 'id': d.id});

  // ---------------------------------------------------------------
  // Yazma
  // ---------------------------------------------------------------

  /// Kayıtlıysa kaldırır, değilse ekler. `true` = artık kayıtlı.
  Future<bool> toggle(Quote q) async {
    final col = _col;
    if (col == null) return _legacyToggle(q);

    final ref = col.doc(q.id);
    final snap = await ref.get();

    if (snap.exists) {
      await ref.delete();
      return false;
    }
    // Sözün bir kopyası burada saklanıyor: kaydedilenler listesini açmak için
    // tek tek quotes koleksiyonuna gitmek gerekmesin diye. 50 kayıt = 1 sorgu.
    await ref.set({
      ...q.toJson(),
      'saved_at': FieldValue.serverTimestamp(),
    });
    return true;
  }

  // ---------------------------------------------------------------
  // Eski yerel kayıtların taşınması
  // ---------------------------------------------------------------

  String _migratedKey(String uid) => 'saved_migrated_v3_$uid';

  Future<void> _migrateIfNeeded() async {
    final uid = _uid;
    final col = _col;
    if (uid == null || col == null) return;

    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool(_migratedKey(uid)) ?? false) return;

    final legacy = prefs.getStringList(_legacyKey) ?? const [];
    if (legacy.isNotEmpty) {
      try {
        final batch = _db.batch();
        for (final raw in legacy) {
          try {
            final q = Quote.fromJson(jsonDecode(raw) as Map<String, dynamic>);
            batch.set(col.doc(q.id), {
              ...q.toJson(),
              'saved_at': FieldValue.serverTimestamp(),
            });
          } catch (_) {
            // Bozuk kayıt — atla.
          }
        }
        await batch.commit();
        debugPrint('${legacy.length} kayıtlı söz buluta taşındı.');
      } catch (e) {
        // Taşıma başarısızsa bayrağı YAZMIYORUZ; bir dahaki açılışta yeniden
        // denenir. Yarım kalıp veri kaybetmesin diye.
        debugPrint('Kayıtlar buluta taşınamadı: $e');
        return;
      }
    }
    await prefs.setBool(_migratedKey(uid), true);
  }

  Future<List<Quote>> _legacyAll() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_legacyKey) ?? const [];
    final out = <Quote>[];
    for (final e in raw) {
      try {
        out.add(Quote.fromJson(jsonDecode(e) as Map<String, dynamic>));
      } catch (_) {}
    }
    return out;
  }

  Future<bool> _legacyToggle(Quote q) async {
    final prefs = await SharedPreferences.getInstance();
    final list = await _legacyAll();
    final wasSaved = list.any((e) => e.id == q.id);
    if (wasSaved) {
      list.removeWhere((e) => e.id == q.id);
    } else {
      list.add(q);
    }
    await prefs.setStringList(
      _legacyKey,
      list.map((e) => jsonEncode(e.toJson())).toList(),
    );
    return !wasSaved;
  }
}
