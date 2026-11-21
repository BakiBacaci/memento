import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../models/app_user.dart';
import 'storage_service.dart';

class UsernameTakenException implements Exception {}

enum UsernameStatus { free, mine, taken, unknown }

class UserService {
  UserService._();
  static final instance = UserService._();

  final _db = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  User? get currentUser => _auth.currentUser;
  String? get uid => _auth.currentUser?.uid;
  bool get isSignedIn => _auth.currentUser != null;

  DocumentReference<Map<String, dynamic>> _doc(String uid) =>
      _db.collection('users').doc(uid);

  // ---------------------------------------------------------------
  // Okuma
  // ---------------------------------------------------------------

  Stream<AppUser> watch(String uid) =>
      _doc(uid).snapshots().map((s) => AppUser.fromMap(uid, s.data()));

  Future<AppUser?> get(String uid) async {
    try {
      final s = await _doc(uid).get();
      return AppUser.fromMap(uid, s.data());
    } catch (e) {
      debugPrint('Profil okunamadı: $e');
      return null;
    }
  }

  // ---------------------------------------------------------------
  // Kullanıcı adı benzersizliği
  // ---------------------------------------------------------------

  static final _usernameRe = RegExp(r'^[a-zA-Z0-9_]{3,20}$');

  static bool isValidUsername(String s) => _usernameRe.hasMatch(s);

  /// Kullanıcı adları `usernames/{kucukHarfli}` koleksiyonunda kilitleniyor.
  /// Döküman kimliği adın kendisi: iki kişi aynı anda aynı adı alamaz.
  ///
  /// Bir kilit "sahipsiz" olabilir: sahibinin hesabı silinmiş ya da sahibi
  /// başka bir ada geçmiş ama eski sürüm kilidi bırakmamış. Böyle kilitler
  /// boş sayılır ve yeni sahibine devredilir (kurallar da bunu doğrular).
  Future<UsernameStatus> usernameStatus(String username) async {
    final lower = username.toLowerCase();
    try {
      final lock = await _db.collection('usernames').doc(lower).get();
      if (!lock.exists) return UsernameStatus.free;
      final owner = lock.data()?['uid'] as String?;
      if (owner != null && owner == uid) return UsernameStatus.mine;
      if (owner == null) return UsernameStatus.free;
      final ownerDoc = await _doc(owner).get();
      final stillUsed = ownerDoc.exists &&
          (ownerDoc.data()?['username_lower'] as String?) == lower;
      return stillUsed ? UsernameStatus.taken : UsernameStatus.free;
    } catch (e) {
      debugPrint('Kullanıcı adı kontrol edilemedi: $e');
      return UsernameStatus.unknown;
    }
  }

  Future<bool> isUsernameAvailable(String username) async =>
      (await usernameStatus(username)) != UsernameStatus.taken;

  // ---------------------------------------------------------------
  // Yazma
  // ---------------------------------------------------------------

  Future<void> createProfile({
    required String uid,
    required String username,
    required String defaultBio,
  }) async {
    final lower = username.toLowerCase();
    final batch = _db.batch();

    // set: kilit yoksa oluşturur, sahipsizse devralır.
    batch.set(_db.collection('usernames').doc(lower), {'uid': uid});
    batch.set(_doc(uid), {
      'uid': uid,
      'username': username,
      'username_lower': lower,
      'display_name': username,
      'link': '',
      'bio': defaultBio,
      'photo_url': null,
      'karma': 0,
      'quote_count': 0,
      'follower_count': 0,
      'following_count': 0,
      'created_at': FieldValue.serverTimestamp(),
    });

    try {
      await batch.commit();
    } on FirebaseException catch (e) {
      // Ret sebebi gerçekten ad mı? Yeniden kontrol et; değilse asıl hatayı göster.
      if (e.code == 'permission-denied' &&
          await usernameStatus(username) == UsernameStatus.taken) {
        throw UsernameTakenException();
      }
      rethrow;
    }
  }

  /// Profil güncelleme. Ad değiştiyse eski kilit bırakılır, yenisi alınır;
  /// hepsi tek batch içinde, yarım kalmasın diye.
  ///
  /// "Değişti mi?" sorusu ekrandaki eski değere değil, SUNUCUDAKİ kayda göre
  /// cevaplanır: eski sürümden kalan hesaplarda ad alanı ya da ad kilidi hiç
  /// olmayabiliyor; o durumda ad bu kayıtta ilk kez sahipleniliyor.
  Future<void> updateProfile({
    required String uid,
    required String username,
    required String displayName,
    required String bio,
    String link = '',
    String? previousUsername,
  }) async {
    final lower = username.toLowerCase();
    final snap = await _doc(uid).get();

    // Profil kaydı hiç yoksa (yarım kalmış eski kayıt) önce oluştur.
    if (!snap.exists) {
      await createProfile(uid: uid, username: username, defaultBio: bio);
      await _doc(uid).update({
        'display_name': displayName,
        'bio': bio,
        'link': link,
        'updated_at': FieldValue.serverTimestamp(),
      });
      return;
    }

    final data = snap.data() ?? const {};
    final serverLower = data['username_lower'] as String?;
    final serverName = data['username'] as String?;
    final lockSnap = await _db.collection('usernames').doc(lower).get();
    final ownsLock = lockSnap.exists && lockSnap.data()?['uid'] == uid;
    final claim = serverLower != lower || !ownsLock;

    final batch = _db.batch();
    if (claim) {
      if (serverLower != null && serverLower != lower) {
        final old = await _db.collection('usernames').doc(serverLower).get();
        if (old.exists && old.data()?['uid'] == uid) batch.delete(old.reference);
      }
      batch.set(_db.collection('usernames').doc(lower), {'uid': uid});
    }

    batch.update(_doc(uid), {
      'username': username,
      'username_lower': lower,
      'display_name': displayName,
      'bio': bio,
      'link': link,
      // Eski sürüm e-postayı herkese açık profile yazıyordu: temizle.
      if (data.containsKey('email')) 'email': FieldValue.delete(),
      'updated_at': FieldValue.serverTimestamp(),
    });

    try {
      await batch.commit();
    } on FirebaseException catch (e) {
      if (e.code == 'permission-denied' &&
          claim &&
          await usernameStatus(username) == UsernameStatus.taken) {
        throw UsernameTakenException();
      }
      rethrow;
    }

    if (serverName != username) {
      await _syncOwnerFields(uid, {'owner_username': username});
    }
  }

  Future<void> updatePhotoUrl(String uid, String url) async {
    await _doc(uid).update({'photo_url': url});
    await _syncOwnerFields(uid, {'owner_photo_url': url});
  }

  /// Profil fotoğrafını kaldırır: önce profil, sonra dosya.
  Future<void> removePhoto(String uid) async {
    await _doc(uid).update({'photo_url': null});
    await _syncOwnerFields(uid, {'owner_photo_url': null});
    await StorageService.instance.deleteAvatar(uid);
  }

  /// Sözlerin içindeki yazar kopyasını (ad, foto) günceller; akışta eski
  /// foto/ad görünmesin diye.
  Future<void> _syncOwnerFields(String uid, Map<String, Object?> fields) async {
    try {
      final mine =
          await _db.collection('quotes').where('user_id', isEqualTo: uid).get();
      for (var i = 0; i < mine.docs.length; i += 400) {
        final batch = _db.batch();
        for (final d in mine.docs.skip(i).take(400)) {
          batch.update(d.reference, {...fields, 'updated_at': FieldValue.serverTimestamp()});
        }
        await batch.commit();
      }
    } catch (e) {
      debugPrint('Sözlerdeki yazar bilgisi güncellenemedi: $e');
    }
  }

  /// En sevilen sözü profile sabitler (null = kaldır).
  Future<void> setPinned(Map<String, Object?>? quote) =>
      _doc(uid!).update({'pinned': quote});

  // ---------------------------------------------------------------
  // Liderlik tablosu
  // ---------------------------------------------------------------

  Stream<List<AppUser>> topUsers({int limit = 50}) {
    return _db
        .collection('users')
        .orderBy('karma', descending: true)
        .limit(limit)
        .snapshots()
        .map((s) => s.docs.map((d) => AppUser.fromMap(d.id, d.data())).toList());
  }

  /// Kullanıcının sırası.
  ///
  /// Sunucu tarafı count() kullanılıyor: 1000 kullanıcı = 1 okuma.
  /// (Eskiden karması yüksek olan tüm dökümanlar çekiliyordu.)
  Future<({int rank, int karma})> myRank() async {
    final u = uid;
    if (u == null) return (rank: 0, karma: 0);
    try {
      final me = await _doc(u).get();
      final karma = (me.data()?['karma'] as num?)?.toInt() ?? 0;
      final agg = await _db
          .collection('users')
          .where('karma', isGreaterThan: karma)
          .count()
          .get();
      return (rank: (agg.count ?? 0) + 1, karma: karma);
    } catch (e) {
      debugPrint('Sıra hesaplanamadı: $e');
      return (rank: 0, karma: 0);
    }
  }
}
