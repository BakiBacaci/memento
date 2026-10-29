import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../models/quote.dart';

/// Beğeniler.
///
/// ÖNEMLİ TASARIM KARARI: Beğeni iki yere birden yazılıyor.
///
///   users/{uid}/liked/{quoteId}   -> HER söz için. Kullanıcının beğeni
///                                    geçmişi burada. Hazır sözler de dahil.
///   quotes/{id}/likes/{uid}       -> SADECE kullanıcı sözleri için.
///                                    Sayaç ve karma bunun üzerinden döner.
///
/// Önceden sadece ikincisi vardı. Destedeki 235 hazır sözün hiçbiri
/// Firestore'da bir dökümana karşılık gelmediği için beğeni işlemi sessizce
/// başarısız oluyordu — kullanıcı sağa kaydırıyor, kalp bir an görünüp
/// kayboluyordu.
class LikeService {
  LikeService._();
  static final instance = LikeService._();

  final _db = FirebaseFirestore.instance;
  String? get _uid => FirebaseAuth.instance.currentUser?.uid;

  CollectionReference<Map<String, dynamic>>? get _likedCol {
    final uid = _uid;
    if (uid == null) return null;
    return _db.collection('users').doc(uid).collection('liked');
  }

  /// Kullanıcının beğendiği tüm sözlerin kimlikleri — tek sorgu.
  Future<Set<String>> myLikedIds() async {
    final col = _likedCol;
    if (col == null) return {};
    try {
      final s = await col.get();
      return s.docs.map((d) => d.id).toSet();
    } catch (e) {
      debugPrint('Beğeni geçmişi okunamadı: $e');
      return {};
    }
  }

  /// Beğenilen sözlerin kendisi — profildeki "Beğendiklerim" için.
  Stream<List<Quote>> watchLiked() {
    final col = _likedCol;
    if (col == null) return Stream.value(const []);
    return col
        .orderBy('liked_at', descending: true)
        .snapshots()
        .map((s) => s.docs
            .map((d) => Quote.fromJson({...d.data(), 'id': d.id}))
            .toList());
  }

  /// Beğen / beğeniyi geri al. `true` döner = artık beğenili.
  ///
  /// Kendi sözünü beğenmek karma vermez.
  Future<bool> toggle(Quote q) async {
    final uid = _uid;
    final col = _likedCol;
    if (uid == null || col == null) return false;

    final myRef = col.doc(q.id);
    final already = (await myRef.get()).exists;

    final batch = _db.batch();

    if (already) {
      batch.delete(myRef);
    } else {
      batch.set(myRef, {
        ...q.toJson(),
        'liked_at': FieldValue.serverTimestamp(),
      });
    }

    // Sayaç ve karma yalnızca gerçek (Firestore'daki) sözler için.
    if (q.isRemote) {
      final quoteRef = _db.collection('quotes').doc(q.id);
      final publicLikeRef = quoteRef.collection('likes').doc(uid);
      final delta = already ? -1 : 1;

      if (already) {
        batch.delete(publicLikeRef);
      } else {
        batch.set(publicLikeRef, {
          'user_id': uid,
          'created_at': FieldValue.serverTimestamp(),
        });
      }
      batch.update(quoteRef, {'likes': FieldValue.increment(delta)});

      if (q.ownerId != null && q.ownerId != uid) {
        batch.update(_db.collection('users').doc(q.ownerId),
            {'karma': FieldValue.increment(delta)});
      }
    }

    await batch.commit();
    return !already;
  }
}
