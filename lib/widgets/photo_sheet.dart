import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../l10n/strings.dart';
import '../services/storage_service.dart';
import '../services/user_service.dart';
import '../theme.dart';

/// Profil fotoğrafı: galeriden seç, kamerayla çek ya da kaldır.
///
/// Dönen değer: yeni adres, kaldırıldıysa '' , vazgeçildi/başarısızsa null.
/// Hata durumunda kullanıcıya nedenini söyler.
Future<String?> changeProfilePhoto(BuildContext context,
    {required bool hasPhoto, ValueChanged<bool>? onBusy}) async {
  final uid = UserService.instance.uid;
  if (uid == null) return null;
  final messenger = ScaffoldMessenger.of(context);
  final failed = context.t('photo_failed');
  final tooLarge = context.t('photo_too_large');

  final choice = await showModalBottomSheet<String>(
    context: context,
    builder: (ctx) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _Option(
              icon: Icons.photo_library_outlined,
              label: ctx.t('photo_gallery'),
              onTap: () => Navigator.pop(ctx, 'gallery'),
            ),
            if (!kIsWeb)
              _Option(
                icon: Icons.photo_camera_outlined,
                label: ctx.t('photo_camera'),
                onTap: () => Navigator.pop(ctx, 'camera'),
              ),
            if (hasPhoto)
              _Option(
                icon: Icons.delete_outline,
                label: ctx.t('photo_remove'),
                danger: true,
                onTap: () => Navigator.pop(ctx, 'remove'),
              ),
          ],
        ),
      ),
    ),
  );
  if (choice == null) return null;

  onBusy?.call(true);
  try {
    if (choice == 'remove') {
      await UserService.instance.removePhoto(uid);
      return '';
    }
    final file =
        await StorageService.instance.pickImage(fromCamera: choice == 'camera');
    if (file == null) return null;
    final url = await StorageService.instance.uploadProfilePhoto(uid, file);
    await UserService.instance.updatePhotoUrl(uid, url);
    return url;
  } catch (e) {
    debugPrint('Fotoğraf değiştirilemedi: $e');
    // Nedeni de göster: sessiz "yüklenemedi" hatayı bulmayı imkânsız kılıyordu.
    final code = e is StateError && e.message == 'too_large'
        ? tooLarge
        : '$failed ($e)';
    messenger.showSnackBar(SnackBar(content: Text(code)));
    return null;
  } finally {
    onBusy?.call(false);
  }
}

class _Option extends StatelessWidget {
  const _Option({
    required this.icon,
    required this.label,
    required this.onTap,
    this.danger = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final color = danger ? AppColors.danger : AppColors.textPrimary;
    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(label,
          style: TextStyle(color: color, fontWeight: FontWeight.w600)),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      onTap: onTap,
    );
  }
}
