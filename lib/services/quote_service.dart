import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;

import '../models/quote.dart';

class QuoteService {
  QuoteService._();
  static final instance = QuoteService._();

  final _db = FirebaseFirestore.instance;
  String? get _uid => FirebaseAuth.instance.currentUser?.uid;

  CollectionReference<Map<String, dynamic>> get _quotes =>
      _db.collection('quotes');

  // ---------------------------------------------------------------
  // Hazır sözler
  // ---------------------------------------------------------------

  List<Quote>? _assetCache;

  Future<List<Quote>> loadAssetQuotes() async {
    if (_assetCache != null) return _assetCache!;
    try {
      final raw = await rootBundle.loadString('assets/quotes.json');
      final list = jsonDecode(raw) as List<dynamic>;
      _assetCache =
          list.map((e) => Quote.fromAsset(e as Map<String, dynamic>)).toList();
      return _assetCache!;
    } catch (e) {
      debugPrint('Hazır sözler okunamadı: $e');
      return const [];
    }
  }

  // ---------------------------------------------------------------
  // Akışlar
  // ---------------------------------------------------------------

  List<Quote> _map(QuerySnapshot<Map<String, dynamic>> s) =>
      s.docs.map((d) => Quote.fromFirestore(d.id, d.data())).toList();

  /// En yeni herkese açık sözler.
  Stream<List<Quote>> newest({int limit = 40}) => _quotes
      .where('privacy', isEqualTo: QuoteVisibility.public)
      .orderBy('created_at', descending: true)
      .limit(limit)
      .snapshots()
      .map(_map);

  /// En çok beğenilenler — "sözünü ünlü etme" mekaniğinin görünür hali.
  Stream<List<Quote>> popular({int limit = 40}) => _quotes
      .where('privacy', isEqualTo: QuoteVisibility.public)
      .orderBy('likes', descending: true)
      .limit(limit)
      .snapshots()
      .map(_map);

  /// Takip edilenlerin sözleri.
  ///
  /// Firestore'da whereIn en fazla 30 değer alıyor. Daha fazla kişi takip
  /// edilirse ilk 30'u gösteriyoruz — gerçek bir akış motoru gerekirse
  /// sunucu tarafına taşınmalı.
  ///
  /// Canlı: birini takip edince / bırakınca akış kendiliğinden yenilenir.
  /// Sadece herkese açık sözler — "takipçilerim" sözleri sahibinin
  /// profilinde görünüyor (Firestore kuralları karışık sorguya izin vermiyor).
  Stream<List<Quote>> followingFeed({int limit = 40}) {
    final me = _uid;
    if (me == null) return Stream.value(const []);
    late StreamController<List<Quote>> ctrl;
    StreamSubscription? idsSub;
    StreamSubscription? quotesSub;

    ctrl = StreamController<List<Quote>>(
      onListen: () {
        idsSub = _db
            .collection('users')
            .doc(me)
            .collection('following')
            .limit(30)
            .snapshots()
            .listen((s) {
          quotesSub?.cancel();
          final ids = s.docs.map((d) => d.id).toList();
          if (ids.isEmpty) {
            ctrl.add(const []);
            return;
          }
          quotesSub = _quotes
              .where('privacy', isEqualTo: QuoteVisibility.public)
              .where('user_id', whereIn: ids)
              .orderBy('created_at', descending: true)
              .limit(limit)
              .snapshots()
              .map(_map)
              .listen(ctrl.add, onError: ctrl.addError);
        }, onError: ctrl.addError);
      },
      onCancel: () async {
        await quotesSub?.cancel();
        await idsSub?.cancel();
      },
    );
    return ctrl.stream;
  }

  Stream<List<Quote>> byUser(String uid, {int limit = 50}) => _quotes
      .where('user_id', isEqualTo: uid)
      .orderBy('created_at', descending: true)
      .limit(limit)
      .snapshots()
      .map(_map);

  // ---------------------------------------------------------------
  // Yazma
  // ---------------------------------------------------------------

  Future<void> createQuote({
    required String text,
    required String author,
    required String visibility,
    required String lang,
    String? ownerUsername,
    String? ownerPhotoUrl,
    int? color,
  }) async {
    final uid = _uid;
    if (uid == null) throw StateError('Giriş yapılmamış.');

    final batch = _db.batch();
    final ref = _quotes.doc();
    batch.set(ref, {
      'text': text.trim(),
      'author': author.trim().isEmpty ? 'Anonim' : author.trim(),
      'privacy': visibility,
      'lang': lang,
      'user_id': uid,
      // Yazarın adı ve fotoğrafı sözün içinde kopyalanıyor: akışta 40 söz
      // gösterirken 40 ayrı kullanıcı okuması yapmamak için.
      'owner_username': ownerUsername,
      'owner_photo_url': ownerPhotoUrl,
      'likes': 0,
      if (color != null) 'color': color,
      'created_at': FieldValue.serverTimestamp(),
    });
    batch.update(_db.collection('users').doc(uid), {
      'quote_count': FieldValue.increment(1),
      // Kurallar sayacın gerçek bir söze bağlı olduğunu bununla doğruluyor.
      'quote_src': ref.id,
    });
    await batch.commit();
  }

  Future<void> deleteQuote(Quote q) async {
    final uid = _uid;
    if (uid == null || q.ownerId != uid) return;
    final batch = _db.batch();
    batch.delete(_quotes.doc(q.id));
    batch.update(_db.collection('users').doc(uid), {
      'quote_count': FieldValue.increment(-1),
      'quote_src': q.id,
    });
    await batch.commit();
  }

}
