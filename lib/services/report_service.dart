import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

/// Şikâyet ve engelleme.
///
/// Kullanıcıların içerik ürettiği uygulamalarda bu bir tercih değil zorunluluk:
/// hem Play Store hem App Store, şikâyet mekanizması olmayan uygulamaları
/// reddediyor.
class ReportService {
  ReportService._();
  static final instance = ReportService._();

  final _db = FirebaseFirestore.instance;
  String? get _uid => FirebaseAuth.instance.currentUser?.uid;

  static const reasons = [
    'report_spam',
    'report_hate',
    'report_violence',
    'report_sexual',
    'report_other',
  ];

  Future<void> reportQuote({
    required String quoteId,
    required String reasonKey,
    String? ownerId,
  }) async {
    final me = _uid;
    if (me == null) return;
    await _db.collection('reports').add({
      'quote_id': quoteId,
      'owner_id': ownerId,
      'reporter_id': me,
      'reason': reasonKey,
      'created_at': FieldValue.serverTimestamp(),
    });
  }

  // ---------------------------------------------------------------
  // Engelleme — engellenenlerin sözleri akışlardan çıkarılır.
  // ---------------------------------------------------------------

  CollectionReference<Map<String, dynamic>>? get _blockedCol {
    final me = _uid;
    if (me == null) return null;
    return _db.collection('users').doc(me).collection('blocked');
  }

  Future<void> block(String targetUid) async {
    final col = _blockedCol;
    if (col == null) return;
    await col.doc(targetUid).set({'created_at': FieldValue.serverTimestamp()});
  }

  Future<void> unblock(String targetUid) async {
    final col = _blockedCol;
    if (col == null) return;
    await col.doc(targetUid).delete();
  }

  Future<Set<String>> blockedIds() async {
    final col = _blockedCol;
    if (col == null) return {};
    try {
      final s = await col.get();
      return s.docs.map((d) => d.id).toSet();
    } catch (e) {
      debugPrint('Engellenenler okunamadı: $e');
      return {};
    }
  }
}
