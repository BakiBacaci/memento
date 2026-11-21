import 'package:flutter/material.dart';

import '../l10n/strings.dart';
import '../models/quote.dart';
import '../theme.dart';
import 'user_avatar.dart';

/// Keşfet destesindeki kart: düz renk zemin, kocaman kalın yazı.
///
/// Sağa kaydırınca ortada dolu bir kalp, sola kaydırınca bir çarpı belirir
/// ve kart hafifçe solar. Çift dokunuş beğeniyor.
class QuoteCard extends StatefulWidget {
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
  State<QuoteCard> createState() => _QuoteCardState();
}

class _QuoteCardState extends State<QuoteCard>
    with SingleTickerProviderStateMixin {
  late final _pop = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 520),
  );

  @override
  void dispose() {
    _pop.dispose();
    super.dispose();
  }

  void _doubleTap() {
    _pop.forward(from: 0);
    if (!widget.isLiked) widget.onLikeTap();
  }

  @override
  Widget build(BuildContext context) {
    final q = widget.quote;
    final mood = QuoteMood.forQuote(q);
    final ink = mood.accent;
    final lang = context.lang;
    final drag = (widget.horizontalOffset.abs() / 90).clamp(0.0, 1.0);
    final right = widget.horizontalOffset > 0;
    final text = q.textFor(lang);

    return GestureDetector(
      onDoubleTap: _doubleTap,
      child: Opacity(
        opacity: right ? 1 : 1 - drag * 0.35,
        child: Container(
          decoration: BoxDecoration(
            color: mood.top,
            borderRadius: BorderRadius.circular(34),
          ),
          clipBehavior: Clip.antiAlias,
          child: Stack(
            fit: StackFit.expand,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 16, 12, 18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        if (q.ownerId != null)
                          GestureDetector(
                            onTap: widget.onAuthorTap,
                            child: Row(children: [
                              UserAvatar(
                                photoUrl: q.ownerPhotoUrl,
                                initial: q.ownerUsername ?? q.author,
                                radius: 13,
                              ),
                              const SizedBox(width: 8),
                              Text('@${q.ownerUsername ?? ''}',
                                  style: TextStyle(
                                      color: ink,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14)),
                            ]),
                          ),
                        const Spacer(),
                        if (widget.onMoreTap != null)
                          IconButton(
                            icon: Icon(Icons.more_horiz, color: ink),
                            onPressed: widget.onMoreTap,
                          ),
                      ],
                    ),
                    Expanded(
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.only(right: 12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(text, style: quoteStyle(text, color: ink)),
                              const SizedBox(height: 18),
                              Text(
                                q.authorFor(lang),
                                style: TextStyle(
                                  color: ink,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(right: 12),
                      child: Row(
                        children: [
                          Expanded(
                            child: _Pill(
                              label: widget.isLiked
                                  ? context.t('liked')
                                  : context.t('like'),
                              icon: widget.isLiked
                                  ? Icons.favorite
                                  : Icons.favorite_border,
                              trailing: q.likes > 0 ? _compact(q.likes) : null,
                              filled: true,
                              ink: ink,
                              paper: mood.top,
                              onTap: widget.onLikeTap,
                            ),
                          ),
                          const SizedBox(width: 8),
                          _RoundButton(
                            icon: widget.isSaved
                                ? Icons.bookmark
                                : Icons.bookmark_border,
                            ink: ink,
                            onTap: widget.onSaveTap,
                          ),
                          const SizedBox(width: 8),
                          if (widget.onShareTap != null)
                            Expanded(
                              child: _Pill(
                                label: context.t('share'),
                                ink: ink,
                                paper: mood.top,
                                onTap: widget.onShareTap!,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              // Sürüklerken ortada beliren rozet: sağda dolu kalp, solda
              // ince çizgili çarpı. Sürükledikçe büyür ve netleşir.
              if (drag > 0.08)
                IgnorePointer(
                  child: Center(
                    child: Opacity(
                      opacity: Curves.easeOut.transform(drag),
                      child: Transform.scale(
                        scale: 0.55 + 0.45 * Curves.easeOutBack.transform(drag),
                        child: Container(
                          width: 108,
                          height: 108,
                          decoration: BoxDecoration(
                            color: right ? ink : mood.top,
                            shape: BoxShape.circle,
                            border: Border.all(color: ink, width: 3),
                          ),
                          child: Icon(
                            right ? Icons.favorite : Icons.close_rounded,
                            size: 50,
                            color: right ? mood.top : ink,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              // Çift dokunuşta zıplayan kalp.
              AnimatedBuilder(
                animation: _pop,
                builder: (_, __) {
                  final t = _pop.value;
                  if (t == 0 || t == 1) return const SizedBox.shrink();
                  final s = Curves.elasticOut.transform((t * 1.5).clamp(0, 1));
                  final a = t < 0.65 ? 1.0 : 1 - (t - 0.65) / 0.35;
                  return IgnorePointer(
                    child: Center(
                      child: Transform.scale(
                        scale: 0.3 + s,
                        child: Icon(Icons.favorite,
                            size: 120, color: ink.withValues(alpha: a)),
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

String _compact(int n) => n >= 1000
    ? '${(n / 1000).toStringAsFixed(n >= 10000 ? 0 : 1)}B'
    : '$n';

class _Pill extends StatelessWidget {
  const _Pill({
    required this.label,
    required this.ink,
    required this.paper,
    required this.onTap,
    this.icon,
    this.trailing,
    this.filled = false,
  });

  final String label;
  final Color ink;
  final Color paper;
  final VoidCallback onTap;
  final IconData? icon;
  final String? trailing;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    final fg = filled ? paper : ink;
    return Material(
      color: filled ? ink : Colors.transparent,
      shape: StadiumBorder(side: BorderSide(color: ink, width: 2)),
      child: InkWell(
        customBorder: const StadiumBorder(),
        onTap: onTap,
        child: SizedBox(
          height: 50,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Icon(icon, color: fg, size: 19),
                const SizedBox(width: 6),
              ],
              Flexible(
                child: Text(label,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        color: fg, fontWeight: FontWeight.w600, fontSize: 15)),
              ),
              if (trailing != null) ...[
                const SizedBox(width: 6),
                Text(trailing!,
                    style: TextStyle(
                        color: fg.withValues(alpha: 0.7),
                        fontWeight: FontWeight.w600,
                        fontSize: 13)),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _RoundButton extends StatelessWidget {
  const _RoundButton({required this.icon, required this.ink, required this.onTap});
  final IconData icon;
  final Color ink;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
        color: Colors.transparent,
        shape: CircleBorder(side: BorderSide(color: ink, width: 2)),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: SizedBox(
            width: 50,
            height: 50,
            child: Icon(icon, color: ink, size: 21),
          ),
        ),
      );
}
