import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/material.dart';

class AuthService {
  // Değişkenlerimizi tanımlıyoruz (Hata buranın eksik olmasından da kaynaklanabilir)
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  // --- E-POSTA İLE KAYIT OL ---
  Future<User?> signUpWithEmail(String email, String password) async {
    try {
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email, 
        password: password
      );
      return result.user;
    } catch (e) {
      debugPrint("Kayıt Hatası: $e");
      return null;
    }
  }

  // --- E-POSTA İLE GİRİŞ YAP ---
  Future<User?> signInWithEmail(String email, String password) async {
    try {
      UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email, 
        password: password
      );
      return result.user;
    } catch (e) {
      debugPrint("Giriş Hatası: $e");
      return null;
    }
  }

  // --- GOOGLE İLE GİRİŞ (DÜZELTİLDİ: accessToken SİLİNDİ) ---
  Future<User?> signInWithGoogle() async {
    try {
      // 1. Google penceresini aç
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return null; // Kullanıcı vazgeçti

      // 2. Yetki belgesini al
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      // 3. Firebase'e gönder
      // DÜZELTME: accessToken satırını sildik, hata veriyordu. Sadece idToken yeterli.
      final AuthCredential credential = GoogleAuthProvider.credential(
        idToken: googleAuth.idToken,
      );

      // 4. Giriş yap
      UserCredential result = await _auth.signInWithCredential(credential);
      return result.user;
    } catch (e) {
      debugPrint("Google Giriş Hatası: $e");
      return null;
    }
  }

  // --- ÇIKIŞ YAP ---
  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
  }
  
  // --- MEVCUT KULLANICI ---
  User? get currentUser => _auth.currentUser;
}