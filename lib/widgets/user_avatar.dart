import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../services/storage_service.dart';
import '../theme.dart';

/// Profil fotoğrafı ya da baş harf.
///
/// Fotoğraf iki biçimde gelebilir: `avatar:<uid>:<zaman>` (Firestore'da
/// saklanan küçük JPEG) ya da eski sürümlerden kalan bir web adresi.
/// Fotoğraf yoksa / yüklenemezse kullanıcının renginde baş harf gösterilir.
class UserAvatar extends StatelessWidget {
  const UserAvatar({
    super.key,
    this.photoUrl,
    this.initial,
    this.radius = 20,
    this.onTap,
  });

  final String? photoUrl;
  final String? initial;
  final double radius;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final url = photoUrl;
    final hasPhoto = url != null && url.isNotEmpty;
    final seed = (initial == null || initial!.isEmpty) ? 'M' : initial!;
    final mood = QuoteMood.of(seed.toLowerCase());
    final letter = seed.substring(0, 1).toUpperCase();
    final size = radius * 2;

    final fallback = Container(
      color: mood.top,
      alignment: Alignment.center,
      child: Text(
        letter,
        style: TextStyle(
          color: mood.accent,
          fontSize: radius * 0.9,
          fontWeight: FontWeight.w800,
        ),
      ),
    );

    Widget photo;
    if (!hasPhoto) {
      photo = fallback;
    } else if (StorageService.isAvatarRef(url)) {
      photo = FutureBuilder<Uint8List?>(
        future: StorageService.instance.avatarBytes(url),
        builder: (context, snap) {
          final bytes = snap.data;
          if (bytes == null) {
            return snap.connectionState == ConnectionState.done
                ? fallback
                : Container(color: mood.top);
          }
          return Image.memory(bytes,
              fit: BoxFit.cover,
              width: size,
              height: size,
              gaplessPlayback: true,
              errorBuilder: (_, __, ___) => fallback);
        },
      );
    } else {
      photo = Image.network(
        url,
        fit: BoxFit.cover,
        width: size,
        height: size,
        webHtmlElementStrategy: WebHtmlElementStrategy.fallback,
        errorBuilder: (_, __, ___) => fallback,
        loadingBuilder: (context, child, progress) =>
            progress == null ? child : Container(color: mood.top),
      );
    }

    final avatar = SizedBox(
      width: size,
      height: size,
      child: ClipOval(child: photo),
    );

    if (onTap == null) return avatar;
    return GestureDetector(onTap: onTap, child: avatar);
  }
}
