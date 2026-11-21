import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';

/// Profil fotoğrafı.
///
/// Fotoğraf Firebase Storage'a değil, Firestore'da `avatars/{uid}` belgesine
/// küçük bir JPEG (≤ 256 px, ~10–40 KB) olarak yazılır. Storage, faturalandırma
/// hesabı olmayan projelerde kilitleniyor (402); Firestore ücretsiz planda
/// çalışıyor. Profildeki `photo_url` alanı `avatar:<uid>:<zaman>` biçiminde
/// bir işaretçi tutar; zaman değişince önbellek tazelenir.
class StorageService {
  StorageService._();
  static final instance = StorageService._();

  final _picker = ImagePicker();
  final _db = FirebaseFirestore.instance;

  /// Firestore belge sınırı 1 MB; güvenli tavan.
  static const _maxBytes = 150 * 1024;

  static bool isAvatarRef(String? url) => url != null && url.startsWith('avatar:');

  Future<XFile?> pickImage({bool fromCamera = false}) async {
    try {
      return await _picker.pickImage(
        source: fromCamera ? ImageSource.camera : ImageSource.gallery,
        maxWidth: 256,
        maxHeight: 256,
        imageQuality: 72,
        requestFullMetadata: false,
      );
    } catch (e) {
      debugPrint('Fotoğraf seçilemedi: $e');
      return null;
    }
  }

  /// Yükler ve profilde saklanacak işaretçiyi döner. Hata olursa fırlatır,
  /// böylece arayüz nedenini gösterebilir.
  Future<String> uploadProfilePhoto(String uid, XFile file) async {
    var bytes = await file.readAsBytes();
    if (bytes.length > _maxBytes) {
      // Seçici küçültemediyse (bazı web tarayıcıları) daha sert sıkıştırarak tekrar dene.
      final again = await _picker.pickImage(source: ImageSource.gallery, maxWidth: 160, maxHeight: 160, imageQuality: 55);
      if (again == null) throw StateError('too_large');
      bytes = await again.readAsBytes();
      if (bytes.length > _maxBytes) throw StateError('too_large');
    }
    await _db.collection('avatars').doc(uid).set({
      'data': base64Encode(bytes),
      'updated_at': FieldValue.serverTimestamp(),
    });
    final ref = 'avatar:$uid:${DateTime.now().millisecondsSinceEpoch}';
    _cache[ref] = Future.value(bytes);
    return ref;
  }

  Future<void> deleteAvatar(String uid) async {
    try {
      await _db.collection('avatars').doc(uid).delete();
    } catch (e) {
      debugPrint('Avatar silinemedi: $e');
    }
  }

  // ---- okuma: işaretçi başına bir kez indirilir, bellekte tutulur
  final Map<String, Future<Uint8List?>> _cache = {};

  Future<Uint8List?> avatarBytes(String ref) => _cache.putIfAbsent(ref, () async {
        final parts = ref.split(':');
        if (parts.length < 2) return null;
        try {
          final snap = await _db.collection('avatars').doc(parts[1]).get();
          final data = snap.data()?['data'];
          return data is String ? base64Decode(data) : null;
        } catch (e) {
          debugPrint('Avatar okunamadı: $e');
          return null;
        }
      });
}
