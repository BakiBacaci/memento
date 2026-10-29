import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../models/app_user.dart';

class UsernameTakenException implements Exception {}

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
  /// Döküman kimliği kullanıcı adının kendisi olduğu için, iki kişi aynı anda
  /// aynı adı almaya çalışırsa ikincisi başarısız olur.
  Future<bool> isUsernameAvailable(String username) async {
    try {
      final s = await _db.collection('usernames').doc(username.toLowerCase()).get();
      return !s.exists;
    } catch (e) {
      debugPrint('Kullanıcı adı kontrol edilemedi: $e');
      return true; // Kontrol edilemiyorsa yazma anında zaten reddedilir.
    }
  }

  // ---------------------------------------------------------------
  // Yazma
  // ---------------------------------------------------------------

  Future<void> createProfile({
    required String uid,
    required String username,
    required String email,
    required String defaultBio,
  }) async {
    final lower = username.toLowerCase();
    final batch = _db.batch();

    batch.set(_db.collection('usernames').doc(lower), {'uid': uid});
    batch.set(_doc(uid), {
      'uid': uid,
      'username': username,
      'username_lower': lower,
      'display_name': username,
      'link': '',
      'email': email,
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
      if (e.code == 'permission-denied') throw UsernameTakenException();
      rethrow;
    }
  }

  /// Profil güncelleme. Kullanıcı adı değiştiyse eski kilit bırakılır,
  /// yenisi alınır — ikisi tek batch içinde, yarım kalmasın diye.
  Future<void> updateProfile({
    required String uid,
    required String username,
    required String displayName,
    required String bio,
    String link = '',
    String? previousUsername,
  }) async {
    final batch = _db.batch();
    final lower = username.toLowerCase();

    if (previousUsername != null &&
        previousUsername.toLowerCase() != lower) {
      batch.delete(_db.collection('usernames').doc(previousUsername.toLowerCase()));
      batch.set(_db.collection('usernames').doc(lower), {'uid': uid});
    }

    batch.update(_doc(uid), {
      'username': username,
      'username_lower': lower,
      'display_name': displayName,
      'bio': bio,
      'link': link,
      'updated_at': FieldValue.serverTimestamp(),
    });

    try {
      await batch.commit();
    } on FirebaseException catch (e) {
      if (e.code == 'permission-denied') throw UsernameTakenException();
      rethrow;
    }
  }

  Future<void> updatePhotoUrl(String uid, String url) =>
      _doc(uid).update({'photo_url': url});

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
