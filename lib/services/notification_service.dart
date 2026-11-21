import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../models/quote.dart';
import 'user_service.dart';

/// Uygulama içi bildirimler: "X sözünü beğendi", "X seni takip etti".
///
///   users/{alıcı}/notifications/{like_<söz>_<kişi> | follow_<kişi>}
///
/// Bildirimi, işlemi yapan kişinin uygulaması yazar; kurallar işlemin
/// gerçekten olduğunu (beğeni / takip kaydının var olduğunu) ve kimliğin
/// taklit edilmediğini doğrular. Kimlikler sabit olduğu için aynı kişi aynı
/// söz için tekrar tekrar bildirim üretemez (beğen-geri al-beğen spam'i yok).
/// Bu yüzden beğeni geri alınınca bildirim de kalır; tekrar beğenmek yenisini üretmez.
///
/// Uygulama kapalıyken telefona gelen bildirim (push) sunucu kodu ister;
/// o Firebase'in ücretli planında. Bu yapı ileride ona da kaynak olur.
class AppNotification {
  AppNotification({
    required this.id,
    required this.type,
    required this.actorUid,
    required this.actorUsername,
    this.actorPhotoUrl,
    this.quoteId,
    this.quoteText,
    this.createdAt,
    this.read = false,
  });

  final String id;
  final String type; // 'like' | 'follow'
  final String actorUid;
  final String actorUsername;
  final String? actorPhotoUrl;
  final String? quoteId;
  final String? quoteText;
  final DateTime? createdAt;
  final bool read;

  factory AppNotification.fromDoc(DocumentSnapshot<Map<String, dynamic>> d) {
    final m = d.data() ?? const {};
    return AppNotification(
      id: d.id,
      type: m['type'] as String? ?? 'like',
      actorUid: m['actor_uid'] as String? ?? '',
      actorUsername: m['actor_username'] as String? ?? '',
      actorPhotoUrl: m['actor_photo_url'] as String?,
      quoteId: m['quote_id'] as String?,
      quoteText: m['quote_text'] as String?,
      createdAt: (m['created_at'] as Timestamp?)?.toDate(),
      read: m['read'] as bool? ?? false,
    );
  }
}

class NotificationService {
  NotificationService._();
  static final instance = NotificationService._();

  final _db = FirebaseFirestore.instance;
  String? get _uid => FirebaseAuth.instance.currentUser?.uid;

  CollectionReference<Map<String, dynamic>> _col(String uid) =>
      _db.collection('users').doc(uid).collection('notifications');

  /// Benim bildirimlerim, en yeni üstte. Canlı.
  Stream<List<AppNotification>> watch() {
    final me = _uid;
    if (me == null) return Stream.value(const []);
    return _col(me)
        .orderBy('created_at', descending: true)
        .limit(100)
        .snapshots()
        .map((s) => s.docs.map(AppNotification.fromDoc).toList());
  }

  /// Okunmamış bildirim sayısı (en fazla 20 sayılır, rozet "20+" der).
  Stream<int> unreadCount() {
    final me = _uid;
    if (me == null) return Stream.value(0);
    return _col(me)
        .where('read', isEqualTo: false)
        .limit(21)
        .snapshots()
        .map((s) => s.size)
        .handleError((Object e) => debugPrint('Bildirim sayısı okunamadı: $e'));
  }

  Future<void> markAllRead() async {
    final me = _uid;
    if (me == null) return;
    try {
      final s = await _col(me).where('read', isEqualTo: false).limit(400).get();
      if (s.docs.isEmpty) return;
      final batch = _db.batch();
      for (final d in s.docs) {
        batch.update(d.reference, {'read': true});
      }
      await batch.commit();
    } catch (e) {
      debugPrint('Bildirimler okundu yapılamadı: $e');
    }
  }

  Future<void> delete(String id) async {
    final me = _uid;
    if (me == null) return;
    await _col(me).doc(id).delete();
  }

  Future<Map<String, Object?>?> _actor() async {
    final me = _uid;
    if (me == null) return null;
    final u = await UserService.instance.get(me);
    if (u == null || u.username.isEmpty) return null;
    return {
      'actor_uid': me,
      'actor_username': u.username,
      'actor_photo_url': u.photoUrl,
      'created_at': FieldValue.serverTimestamp(),
      'read': false,
    };
  }

  /// Bildirim yazmak "en iyi çaba": başarısız olsa da asıl işlem (beğeni,
  /// takip) bozulmaz.
  Future<void> notifyLike(Quote q) async {
    final me = _uid;
    final owner = q.ownerId;
    if (me == null || owner == null || owner == me || !q.isRemote) return;
    try {
      final actor = await _actor();
      if (actor == null) return;
      final text = q.text.length > 140 ? '${q.text.substring(0, 139)}…' : q.text;
      await _col(owner).doc('like_${q.id}_$me').set({
        ...actor,
        'type': 'like',
        'quote_id': q.id,
        'quote_text': text,
      });
    } catch (e) {
      // Zaten varsa (daha önce beğenmiş) kural güncellemeye izin vermez.
      debugPrint('Beğeni bildirimi yazılmadı: $e');
    }
  }


  Future<void> notifyFollow(String target) async {
    final me = _uid;
    if (me == null || target == me) return;
    try {
      final actor = await _actor();
      if (actor == null) return;
      await _col(target).doc('follow_$me').set({...actor, 'type': 'follow'});
    } catch (e) {
      debugPrint('Takip bildirimi yazılmadı: $e');
    }
  }

}
