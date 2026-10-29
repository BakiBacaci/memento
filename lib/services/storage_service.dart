import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';

/// Profil fotoğrafı yükleme.
///
/// Fotoğraf seçilirken 512x512'ye indirgeniyor ve %80 kaliteye sıkıştırılıyor.
/// Ham telefon fotoğrafı 5 MB olabiliyor; profil avatarı için 50 KB yeterli.
/// Bu hem Storage maliyetini hem de profil açılış süresini düşürüyor.
class StorageService {
  StorageService._();
  static final instance = StorageService._();

  final _picker = ImagePicker();

  Future<XFile?> pickImage({bool fromCamera = false}) async {
    try {
      return await _picker.pickImage(
        source: fromCamera ? ImageSource.camera : ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 80,
      );
    } catch (e) {
      debugPrint('Fotoğraf seçilemedi: $e');
      return null;
    }
  }

  /// Yükler ve indirilebilir adresi döner. Hata olursa null.
  Future<String?> uploadProfilePhoto(String uid, XFile file) async {
    try {
      final ref = FirebaseStorage.instance.ref('profile_photos/$uid.jpg');
      final metadata = SettableMetadata(contentType: 'image/jpeg');

      if (kIsWeb) {
        await ref.putData(await file.readAsBytes(), metadata);
      } else {
        await ref.putFile(File(file.path), metadata);
      }
      return await ref.getDownloadURL();
    } catch (e) {
      debugPrint('Fotoğraf yüklenemedi: $e');
      return null;
    }
  }
}
