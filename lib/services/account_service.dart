import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../firebase_options.dart';

import 'block_service.dart';
import 'storage_service.dart';
import 'settings_service.dart';
import 'user_service.dart';

/// Hesap yaşam döngüsü: şifre sıfırlama ve hesap silme.
///
/// Hesap silme App Store'da zorunlu (Guideline 5.1.1(v)): hesap açılabilen
/// her uygulama, hesabı uygulamanın içinden silmeyi de sunmalı.
class AccountService {
  AccountService._();
  static final instance = AccountService._();

  final _db = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  /// Hesap Google ile mi açılmış (şifresi yok)?
  bool get isGoogleOnly {
    final u = _auth.currentUser;
    if (u == null) return false;
    final ids = u.providerData.map((p) => p.providerId).toSet();
    return ids.contains('google.com') && !ids.contains('password');
  }

  bool _googleReady = false;

  Future<UserCredential> _googleCredential({bool reauth = false}) async {
    if (kIsWeb) {
      final provider = GoogleAuthProvider();
      return reauth
          ? _auth.currentUser!.reauthenticateWithPopup(provider)
          : _auth.signInWithPopup(provider);
    }
    if (!_googleReady) {
      await GoogleSignIn.instance.initialize(
        clientId: defaultTargetPlatform == TargetPlatform.iOS
            ? DefaultFirebaseOptions.ios.iosClientId
            : null,
      );
      _googleReady = true;
    }
    final account = await GoogleSignIn.instance.authenticate();
    final idToken = account.authentication.idToken;
    final cred = GoogleAuthProvider.credential(idToken: idToken);
    return reauth
        ? _auth.currentUser!.reauthenticateWithCredential(cred)
        : _auth.signInWithCredential(cred);
  }

  /// Google ile giriş. İlk kez giren kişiye boşta bir kullanıcı adı verilir
  /// (sonra Profili düzenle'den değiştirebilir). İptal edilirse null döner.
  Future<User?> signInWithGoogle({required String defaultBio}) async {
    final UserCredential result;
    try {
      result = await _googleCredential();
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled) return null;
      rethrow;
    }
    final user = result.user;
    if (user == null) return null;

    final doc = await _db.collection('users').doc(user.uid).get();
    if (!doc.exists) {
      final name = await _freeUsername(user.displayName ?? user.email ?? 'memento');
      await UserService.instance.createProfile(
          uid: user.uid, username: name, defaultBio: defaultBio);
    }
    await SettingsService.instance.setGuestMode(false);
    return user;
  }

  /// "Baki Bacacı" → "baki_bacaci", alınmışsa sonuna sayı ekler.
  Future<String> _freeUsername(String source) async {
    const tr = {'ç': 'c', 'ğ': 'g', 'ı': 'i', 'ö': 'o', 'ş': 's', 'ü': 'u'};
    var base = source.split('@').first.toLowerCase();
    base = base.split('').map((c) => tr[c] ?? c).join();
    base = base.replaceAll(RegExp(r'[^a-z0-9]+'), '_').replaceAll(RegExp(r'^_+|_+$'), '');
    if (base.length < 3) base = 'memento_$base';
    if (base.length > 16) base = base.substring(0, 16);
    for (var i = 0; i < 20; i++) {
      final candidate = i == 0 ? base : '${base}_${100 + (DateTime.now().microsecond + i * 37) % 900}';
      if (await UserService.instance.usernameStatus(candidate) != UsernameStatus.taken) {
        return candidate;
      }
    }
    return 'memento_${DateTime.now().millisecondsSinceEpoch % 1000000}';
  }

  Future<void> sendPasswordReset(String email) =>
      _auth.sendPasswordResetEmail(email: email.trim());

  /// Eski sürüm e-posta adresini herkese açık profile yazıyordu.
  /// Girişte sessizce temizlenir.
  Future<void> scrubLegacyEmail() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;
    try {
      final ref = _db.collection('users').doc(uid);
      final snap = await ref.get();
      if (snap.data()?.containsKey('email') ?? false) {
        await ref.update({'email': FieldValue.delete()});
      }
    } catch (e) {
      debugPrint('E-posta temizlenemedi: $e');
    }
  }

  /// Hesabı ve kullanıcıya ait tüm veriyi siler.
  ///
  /// Firebase, hassas işlemler için yakın zamanda giriş yapılmış olmasını
  /// istiyor; bu yüzden önce şifreyle yeniden doğrulama yapılır.
  /// Hatalı şifrede [FirebaseAuthException] fırlatır.
  Future<void> deleteAccount(String? password) async {
    final user = _auth.currentUser;
    if (user == null) return;
    final uid = user.uid;

    if (isGoogleOnly) {
      await _googleCredential(reauth: true);
    } else {
      await user.reauthenticateWithCredential(
        EmailAuthProvider.credential(email: user.email ?? '', password: password ?? ''),
      );
    }

    final me = _db.collection('users').doc(uid);
    final profile = (await me.get()).data() ?? const {};

    // 1) Takip ettiklerim: karşı tarafın takipçi kaydı ve sayacı.
    final following = await me.collection('following').get();
    for (final d in following.docs) {
      final batch = _db.batch();
      batch.delete(d.reference);
      batch.delete(_db.collection('users').doc(d.id).collection('followers').doc(uid));
      batch.update(_db.collection('users').doc(d.id),
          {'follower_count': FieldValue.increment(-1)});
      await _commitQuietly(batch);
    }

    // 2) Beni takip edenler: onların "takip ettiklerim" kaydı.
    final followers = await me.collection('followers').get();
    for (final d in followers.docs) {
      final batch = _db.batch();
      batch.delete(d.reference);
      batch.delete(_db.collection('users').doc(d.id).collection('following').doc(uid));
      await _commitQuietly(batch);
    }

    // 3) Sözlerim.
    final quotes =
        await _db.collection('quotes').where('user_id', isEqualTo: uid).get();
    await _deleteDocs(quotes.docs.map((d) => d.reference));

    // 4) Kişisel alt koleksiyonlar.
    for (final sub in ['saved', 'liked', 'blocked', 'notifications', 'journal']) {
      final s = await me.collection(sub).get();
      await _deleteDocs(s.docs.map((d) => d.reference));
    }

    // 5) Kullanıcı adı kilidi, profil fotoğrafı, profil.
    final lower = profile['username_lower'] as String?;
    if (lower != null) {
      await _commitQuietly(
          _db.batch()..delete(_db.collection('usernames').doc(lower)));
    }
    await StorageService.instance.deleteAvatar(uid);
    await me.delete();

    // 6) Son olarak oturum hesabı.
    await user.delete();
    if (!kIsWeb && _googleReady) await GoogleSignIn.instance.signOut();
    BlockService.instance.clear();
    await SettingsService.instance.setGuestMode(false);
  }

  Future<void> _deleteDocs(Iterable<DocumentReference> refs) async {
    final list = refs.toList();
    for (var i = 0; i < list.length; i += 400) {
      final batch = _db.batch();
      for (final r in list.skip(i).take(400)) {
        batch.delete(r);
      }
      await batch.commit();
    }
  }

  Future<void> _commitQuietly(WriteBatch b) async {
    try {
      await b.commit();
    } catch (e) {
      debugPrint('Silme adımı atlandı: $e');
    }
  }
}
