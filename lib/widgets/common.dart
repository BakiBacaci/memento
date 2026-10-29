import 'package:flutter/material.dart';

import '../l10n/strings.dart';
import '../theme.dart';

/// Boş liste / hata durumları için ortak görünüm.
class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.message,
    this.icon = Icons.hourglass_empty,
    this.action,
  });

  final String message;
  final IconData icon;
  final Widget? action;

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: AppColors.gold.withValues(alpha: 0.6), size: 44),
              const SizedBox(height: 16),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.grey, height: 1.5),
              ),
              if (action != null) ...[const SizedBox(height: 20), action!],
            ],
          ),
        ),
      );
}

/// Yükleniyor gösterimi — dönen çark yerine içeriğin şeklini taklit eden
/// gri kutular. Bekleyiş daha kısa hissettiriyor.
class ShimmerList extends StatefulWidget {
  const ShimmerList({super.key, this.count = 4});
  final int count;

  @override
  State<ShimmerList> createState() => _ShimmerListState();
}

class _ShimmerListState extends State<ShimmerList>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      physics: const NeverScrollableScrollPhysics(),
      itemCount: widget.count,
      itemBuilder: (_, __) => AnimatedBuilder(
        animation: _c,
        builder: (context, child) => Opacity(
          opacity: 0.35 + (_c.value * 0.3),
          child: child,
        ),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const CircleAvatar(radius: 15, backgroundColor: AppColors.border),
                  const SizedBox(width: 8),
                  _bar(110, 11),
                ],
              ),
              const SizedBox(height: 14),
              _bar(double.infinity, 13),
              const SizedBox(height: 8),
              _bar(double.infinity, 13),
              const SizedBox(height: 8),
              _bar(160, 13),
            ],
          ),
        ),
      ),
    );
  }

  Widget _bar(double w, double h) => Container(
        width: w,
        height: h,
        decoration: BoxDecoration(
          color: AppColors.border,
          borderRadius: BorderRadius.circular(6),
        ),
      );
}

/// Misafir kullanıcı korunan bir işleme dokunduğunda çıkan sayfa.
///
/// Uygulamayı ilk açan kimse kayıt olmak zorunda değil; kayıt sadece
/// beğenme, paylaşma ve takip gibi gerçekten hesap gerektiren anlarda
/// isteniyor. Kapıda kaybedilen kullanıcı sayısını ciddi biçimde düşürür.
Future<bool> requireSignIn(BuildContext context) async {
  final result = await showModalBottomSheet<bool>(
    context: context,
    backgroundColor: AppColors.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            const Icon(Icons.lock_outline, color: AppColors.gold, size: 40),
            const SizedBox(height: 16),
            Text(
              ctx.t('sign_in_required'),
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white, fontSize: 16),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(ctx.t('sign_in_to_continue')),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(ctx.t('cancel')),
            ),
          ],
        ),
      ),
    ),
  );
  return result ?? false;
}
