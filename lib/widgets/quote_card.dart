import 'package:flutter/material.dart';

import '../l10n/strings.dart';
import '../models/quote.dart';
import '../theme.dart';
import 'user_avatar.dart';

/// Keşfet destesindeki kart.
///
/// Kaydırma geri bildirimi bilerek sessiz: yeşil/kırmızı katman yerine sağa
/// kaydırınca kartın kenarı altına dönüyor ve ortada bir kalp beliriyor.
/// Sola kaydırınca kart sadece soluyor. Flört uygulaması gibi değil,
/// sayfa çeviriyormuş gibi hissettiriyor.
class QuoteCard extends StatelessWidget {
  const QuoteCard({
    super.key,
    required this.quote,
    required this.isLiked,
    required this.isSaved,
    required this.onSaveTap,
    required this.onLikeTap,
    this.onAuthorTap,
    this.onShareTap,
    this.onMoreTap,
    this.horizontalOffset = 0,
  });

  final Quote quote;
  final bool isLiked;
  final bool isSaved;
  final VoidCallback onSaveTap;
  final VoidCallback onLikeTap;
  final VoidCallback? onAuthorTap;
  final VoidCallback? onShareTap;
  final VoidCallback? onMoreTap;
  final int horizontalOffset;

  @override
  Widget build(BuildContext context) {
    final lang = context.lang;
    final progress = (horizontalOffset.abs() / 70).clamp(0.0, 1.0);
    final right = horizontalOffset > 0;

    return GestureDetector(
      onDoubleTap: onLikeTap,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 90),
        opacity: right ? 1.0 : 1.0 - progress * 0.35,
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(26),
            border: Border.all(
              color: right
                  ? Color.lerp(AppColors.border, AppColors.gold, progress)!
                  : AppColors.border,
              width: 1 + (right ? progress * 1.4 : 0),
            ),
            boxShadow: right && progress > 0.1
                ? [
                    BoxShadow(
                      color: AppColors.gold.withValues(alpha: 0.18 * progress),
                      blurRadius: 30,
                      spreadRadius: 2,
                    )
                  ]
                : null,
          ),
          clipBehavior: Clip.antiAlias,
          child: Stack(
            fit: StackFit.expand,
            children: [
              _content(context, lang),
              if (right && progress > 0.08)
                IgnorePointer(
                  child: Center(
                    child: Transform.scale(
                      scale: 0.6 + progress * 0.7,
                      child: Icon(
                        Icons.favorite,
                        size: 96,
                        color: AppColors.gold.withValues(alpha: progress * 0.9),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _content(BuildContext context, String lang) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 6, 0),
          child: Row(
            children: [
              UserAvatar(
                photoUrl: quote.ownerPhotoUrl,
                initial: quote.authorFor(lang),
                radius: 18,
                onTap: onAuthorTap,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: GestureDetector(
                  onTap: onAuthorTap,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        quote.authorFor(lang),
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                      ),
                      if (quote.ownerUsername != null)
                        Text('@${quote.ownerUsername}',
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                color: AppColors.textMuted, fontSize: 11)),
                    ],
                  ),
                ),
              ),
              if (onMoreTap != null)
                IconButton(
                  icon: const Icon(Icons.more_horiz,
                      color: AppColors.textMuted),
                  onPressed: onMoreTap,
                ),
            ],
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 10),
            child: Center(
              child: SingleChildScrollView(
                child: Text(
                  '“${quote.textFor(lang)}”',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontFamily: kSerif,
                    color: AppColors.textPrimary,
                    fontSize: 23,
                    fontStyle: FontStyle.italic,
                    height: 1.5,
                  ),
                ),
              ),
            ),
          ),
        ),
        Container(
          decoration: const BoxDecoration(
            border: Border(top: BorderSide(color: AppColors.border)),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          child: Row(
            children: [
              _Action(
                icon: isLiked ? Icons.favorite : Icons.favorite_border,
                color: isLiked ? AppColors.gold : AppColors.textMuted,
                label: quote.likes > 0 ? '${quote.likes}' : null,
                onTap: onLikeTap,
              ),
              _Action(
                icon: isSaved ? Icons.bookmark : Icons.bookmark_border,
                color: isSaved ? AppColors.gold : AppColors.textMuted,
                onTap: onSaveTap,
              ),
              const Spacer(),
              if (onShareTap != null)
                _Action(
                  icon: Icons.ios_share,
                  color: AppColors.textMuted,
                  onTap: onShareTap!,
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Action extends StatelessWidget {
  const _Action({
    required this.icon,
    required this.color,
    required this.onTap,
    this.label,
  });

  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  final String? label;

  @override
  Widget build(BuildContext context) => InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          child: Row(
            children: [
              // Kalp dolduğunda hafif bir zıplama.
              AnimatedScale(
                scale: color == AppColors.gold ? 1.15 : 1.0,
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOutBack,
                child: Icon(icon, color: color, size: 24),
              ),
              if (label != null) ...[
                const SizedBox(width: 6),
                Text(label!,
                    style: TextStyle(
                        color: color,
                        fontSize: 13,
                        fontWeight: FontWeight.w600)),
              ],
            ],
          ),
        ),
      );
}
