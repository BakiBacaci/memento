import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

/// Takip ilişkisi iki yerde birden tutuluyor:
///   users/{ben}/following/{o}
///   users/{o}/followers/{ben}
///
/// Çift kayıt gereksiz görünebilir ama "kimleri takip ediyorum" ve
/// "beni kimler takip ediyor" sorularının ikisi de tek sorguyla
/// cevaplanabilsin diye böyle. Sayaçlar da aynı batch'te güncelleniyor.
class FollowService {
  FollowService._();
  static final instance = FollowService._();

  final _db = FirebaseFirestore.instance;
  String? get _uid => FirebaseAuth.instance.currentUser?.uid;

  /// Bu kişiyi takip ediyor muyum? Canlı — buton anında güncellenir.
  Stream<bool> isFollowing(String targetUid) {
    final me = _uid;
    if (me == null) return Stream.value(false);
    return _db
        .collection('users')
        .doc(me)
        .collection('following')
        .doc(targetUid)
        .snapshots()
        .map((s) => s.exists)
        .handleError((_) => false);
  }

  Future<void> follow(String targetUid) async {
    final me = _uid;
    if (me == null || me == targetUid) return;

    final batch = _db.batch();
    final now = FieldValue.serverTimestamp();

    batch.set(
      _db.collection('users').doc(me).collection('following').doc(targetUid),
      {'uid': targetUid, 'created_at': now},
    );
    batch.set(
      _db.collection('users').doc(targetUid).collection('followers').doc(me),
      {'uid': me, 'created_at': now},
    );
    batch.update(_db.collection('users').doc(me),
        {'following_count': FieldValue.increment(1)});
    batch.update(_db.collection('users').doc(targetUid),
        {'follower_count': FieldValue.increment(1)});

    await batch.commit();
  }

  Future<void> unfollow(String targetUid) async {
    final me = _uid;
    if (me == null || me == targetUid) return;

    final batch = _db.batch();
    batch.delete(
        _db.collection('users').doc(me).collection('following').doc(targetUid));
    batch.delete(
        _db.collection('users').doc(targetUid).collection('followers').doc(me));
    batch.update(_db.collection('users').doc(me),
        {'following_count': FieldValue.increment(-1)});
    batch.update(_db.collection('users').doc(targetUid),
        {'follower_count': FieldValue.increment(-1)});

    await batch.commit();
  }

  Future<void> toggle(String targetUid, bool currentlyFollowing) =>
      currentlyFollowing ? unfollow(targetUid) : follow(targetUid);

  /// Takip edilenlerin uid listesi. Akış sorgusu için.
  ///
  /// Firestore'un whereIn sınırı 30, o yüzden burada da 30 ile kesiyoruz.
  /// Daha fazlası gerekirse akışı sunucu tarafında kurmak gerekir.
  Future<List<String>> followingIds({int limit = 30}) async {
    final me = _uid;
    if (me == null) return const [];
    return followingIdsOf(me, limit: limit);
  }

  Future<List<String>> followingIdsOf(String uid, {int limit = 200}) =>
      _idsFrom(uid, 'following', limit);

  Future<List<String>> followerIds(String uid, {int limit = 200}) =>
      _idsFrom(uid, 'followers', limit);

  Future<List<String>> _idsFrom(String uid, String sub, int limit) async {
    try {
      final s = await _db
          .collection('users')
          .doc(uid)
          .collection(sub)
          .limit(limit)
          .get();
      return s.docs.map((d) => d.id).toList();
    } catch (e) {
      debugPrint('$sub listesi okunamadı: $e');
      return const [];
    }
  }
}
