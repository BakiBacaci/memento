import 'package:flutter/material.dart';

import '../l10n/strings.dart';
import '../models/quote.dart';
import '../theme.dart';
import 'user_avatar.dart';

/// Akış ve profil listelerindeki söz: destedeki kartın küçük, düz renkli hali.
class QuoteTile extends StatelessWidget {
  const QuoteTile({
    super.key,
    required this.quote,
    this.rank,
    this.onAuthorTap,
    this.onShareTap,
    this.onMoreTap,
    this.trailing,
  });

  final Quote quote;

  /// Popüler listesinde sıra numarası. null ise gösterilmez.
  final int? rank;

  final VoidCallback? onAuthorTap;
  final VoidCallback? onShareTap;
  final VoidCallback? onMoreTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final lang = context.lang;
    final mood = QuoteMood.forQuote(quote);
    final ink = mood.accent;
    final text = quote.textFor(lang);

    return Container(
      margin: const EdgeInsets.fromLTRB(14, 5, 14, 5),
      padding: const EdgeInsets.fromLTRB(20, 16, 8, 8),
      decoration: BoxDecoration(
        color: mood.top,
        borderRadius: BorderRadius.circular(26),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (rank != null) ...[
                Text('$rank',
                    style: TextStyle(
                        color: ink,
                        fontWeight: FontWeight.w800,
                        fontSize: 28,
                        height: 1,
                        letterSpacing: -1)),
                const SizedBox(width: 12),
              ],
              if (quote.ownerId != null) ...[
                UserAvatar(
                  photoUrl: quote.ownerPhotoUrl,
                  initial: quote.ownerUsername ?? quote.authorFor(lang),
                  radius: 12,
                  onTap: onAuthorTap,
                ),
                const SizedBox(width: 8),
              ],
              Expanded(
                child: GestureDetector(
                  onTap: onAuthorTap,
                  child: Text(
                    quote.ownerUsername != null
                        ? '@${quote.ownerUsername}'
                        : quote.authorFor(lang),
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        color: ink, fontWeight: FontWeight.w600, fontSize: 14),
                  ),
                ),
              ),
              if (onMoreTap != null)
                IconButton(
                  visualDensity: VisualDensity.compact,
                  onPressed: onMoreTap,
                  icon: Icon(Icons.more_horiz, color: ink, size: 20),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Text(text, style: quoteStyle(text, scale: 0.62, color: ink)),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: Text(
                  quote.ownerId != null ? quote.authorFor(lang) : '',
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                      color: ink, fontSize: 13, fontWeight: FontWeight.w600),
                ),
              ),
              Icon(Icons.favorite, size: 16, color: ink),
              const SizedBox(width: 4),
              Text('${quote.likes}',
                  style: TextStyle(
                      color: ink, fontSize: 14, fontWeight: FontWeight.w800)),
              if (trailing != null) trailing!,
              if (onShareTap != null)
                IconButton(
                  visualDensity: VisualDensity.compact,
                  onPressed: onShareTap,
                  icon: Icon(Icons.ios_share, color: ink, size: 19),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
