import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../models/quote.dart';
import 'report_service.dart';

/// Engellenen kullanıcıların uygulama genelindeki tek kaynağı.
///
/// Eskiden engelleme yalnızca Keşfet destesine uygulanıyordu; engellenen
/// kişinin sözleri Akış'ta görünmeye devam ediyordu. App Store kullanıcı
/// içeriği kuralı (1.2) engellenen içeriğin her yerden kalkmasını istiyor.
class BlockService {
  BlockService._();
  static final instance = BlockService._();

  final blocked = ValueNotifier<Set<String>>(<String>{});

  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _sub;

  /// Oturum açılınca çağrılır; engellenenler listesini canlı dinler.
  Future<void> load() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    await _sub?.cancel();
    if (uid == null) return clear();
    _sub = FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('blocked')
        .snapshots()
        .listen(
          (s) => blocked.value = s.docs.map((d) => d.id).toSet(),
          onError: (Object e) => debugPrint('Engellenenler dinlenemedi: $e'),
        );
  }

  void clear() {
    _sub?.cancel();
    _sub = null;
    blocked.value = <String>{};
  }

  bool isBlocked(String? uid) => uid != null && blocked.value.contains(uid);

  List<Quote> filter(List<Quote> quotes) =>
      quotes.where((q) => !isBlocked(q.ownerId)).toList();

  Future<void> block(String uid) async {
    await ReportService.instance.block(uid);
    blocked.value = {...blocked.value, uid};
  }

  Future<void> unblock(String uid) async {
    await ReportService.instance.unblock(uid);
    blocked.value = {...blocked.value}..remove(uid);
  }
}
