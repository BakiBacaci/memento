import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import 'notification_service.dart';

/// Takip ilişkisi iki yerde birden tutuluyor:
///   users/{ben}/following/{o}
///   users/{o}/followers/{ben}
///
/// "Kimleri takip ediyorum" ve "beni kimler takip ediyor" sorularının ikisi
/// de tek sorguyla cevaplanabilsin diye. Sayaçlar aynı batch'te güncelleniyor.
///
/// Her işlem önce iki kaydın gerçek durumuna bakar ve yalnızca eksik/fazla
/// olan tarafı düzeltir. Eski sürümlerden kalma yarım kayıtlar (bir taraf
/// var, öbürü yok) yüzünden takip düğmesinin kilitlenmesi böyle önleniyor:
/// kurallar sayacı ancak kayıt gerçekten oluşuyor/siliniyorsa değiştirtiyor.
class FollowService {
  FollowService._();
  static final instance = FollowService._();

  final _db = FirebaseFirestore.instance;
  String? get _uid => FirebaseAuth.instance.currentUser?.uid;

  DocumentReference<Map<String, dynamic>> _user(String uid) =>
      _db.collection('users').doc(uid);

  /// Bu kişiyi takip ediyor muyum? Canlı — buton anında güncellenir.
  Stream<bool> isFollowing(String targetUid) {
    final me = _uid;
    if (me == null) return Stream.value(false);
    return _user(me)
        .collection('following')
        .doc(targetUid)
        .snapshots()
        .map((s) => s.exists)
        .handleError((_) => false);
  }

  Future<void> follow(String targetUid) async {
    final me = _uid;
    if (me == null || me == targetUid) return;

    final followingRef = _user(me).collection('following').doc(targetUid);
    final followerRef = _user(targetUid).collection('followers').doc(me);
    final hasFollowing = (await followingRef.get()).exists;
    final hasFollower = (await followerRef.get()).exists;
    if (hasFollowing && hasFollower) return;

    final batch = _db.batch();
    final now = FieldValue.serverTimestamp();
    if (!hasFollowing) {
      batch.set(followingRef, {'uid': targetUid, 'created_at': now});
      batch.update(_user(me),
          {'following_count': FieldValue.increment(1), 'following_src': targetUid});
    }
    if (!hasFollower) {
      batch.set(followerRef, {'uid': me, 'created_at': now});
      batch.update(_user(targetUid), {'follower_count': FieldValue.increment(1)});
    }
    await batch.commit();

    if (!hasFollower) NotificationService.instance.notifyFollow(targetUid);
  }

  Future<void> unfollow(String targetUid) async {
    final me = _uid;
    if (me == null || me == targetUid) return;

    final followingRef = _user(me).collection('following').doc(targetUid);
    final followerRef = _user(targetUid).collection('followers').doc(me);
    final hasFollowing = (await followingRef.get()).exists;
    final hasFollower = (await followerRef.get()).exists;
    if (!hasFollowing && !hasFollower) return;

    final batch = _db.batch();
    if (hasFollowing) {
      batch.delete(followingRef);
      batch.update(_user(me),
          {'following_count': FieldValue.increment(-1), 'following_src': targetUid});
    }
    if (hasFollower) {
      batch.delete(followerRef);
      batch.update(_user(targetUid), {'follower_count': FieldValue.increment(-1)});
    }
    await batch.commit();
  }

  /// Takipçiyi çıkar: o kişi artık beni takip etmez (engellemeden).
  Future<void> removeFollower(String followerUid) async {
    final me = _uid;
    if (me == null || me == followerUid) return;

    final followerRef = _user(me).collection('followers').doc(followerUid);
    final followingRef = _user(followerUid).collection('following').doc(me);
    final hasFollower = (await followerRef.get()).exists;
    final hasFollowing = (await followingRef.get()).exists;
    if (!hasFollower && !hasFollowing) return;

    final batch = _db.batch();
    if (hasFollower) {
      batch.delete(followerRef);
      batch.update(_user(me),
          {'follower_count': FieldValue.increment(-1), 'follower_src': followerUid});
    }
    if (hasFollowing) {
      batch.delete(followingRef);
      batch.update(_user(followerUid),
          {'following_count': FieldValue.increment(-1), 'following_src': me});
    }
    await batch.commit();
  }

  Future<void> toggle(String targetUid, bool currentlyFollowing) =>
      currentlyFollowing ? unfollow(targetUid) : follow(targetUid);

  /// Takip edilenlerin uid listesi. Akış sorgusu için.
  ///
  /// Firestore'un whereIn sınırı 30, o yüzden burada da 30 ile kesiyoruz.
  Future<List<String>> followingIds({int limit = 30}) async {
    final me = _uid;
    if (me == null) return const [];
    return followingIdsOf(me, limit: limit);
  }

  Future<List<String>> followingIdsOf(String uid, {int limit = 200}) =>
      _idsFrom(uid, 'following', limit);

  Future<List<String>> followerIds(String uid, {int limit = 200}) =>
      _idsFrom(uid, 'followers', limit);

  /// Liste canlı: takipçi çıkarınca satır anında kaybolur.
  Stream<List<String>> watchIds(String uid, {required bool followers}) => _user(uid)
      .collection(followers ? 'followers' : 'following')
      // orderBy yok: eski kayıtlarda created_at olmayabilir, sıralı sorgu
      // onları listeden düşürürdü.
      .limit(300)
      .snapshots()
      .map((s) => s.docs.map((d) => d.id).toList());

  Future<List<String>> _idsFrom(String uid, String sub, int limit) async {
    try {
      final s = await _user(uid).collection(sub).limit(limit).get();
      return s.docs.map((d) => d.id).toList();
    } catch (e) {
      debugPrint('$sub listesi okunamadı: $e');
      return const [];
    }
  }
}
