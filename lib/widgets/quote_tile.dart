import 'package:flutter/material.dart';

import '../l10n/strings.dart';
import '../models/quote.dart';
import '../theme.dart';
import 'user_avatar.dart';

/// Akış ve profil listelerindeki söz satırı.
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

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (rank != null) ...[
                Text(
                  '$rank',
                  style: TextStyle(
                    color: switch (rank!) {
                      1 => AppColors.gold1,
                      2 => AppColors.silver,
                      3 => AppColors.bronze,
                      _ => Colors.grey,
                    },
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(width: 12),
              ],
              UserAvatar(
                photoUrl: quote.ownerPhotoUrl,
                initial: quote.authorFor(lang),
                radius: 15,
                onTap: onAuthorTap,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: GestureDetector(
                  onTap: onAuthorTap,
                  child: Text(
                    quote.authorFor(lang),
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
              if (onMoreTap != null)
                GestureDetector(
                  onTap: onMoreTap,
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 4),
                    child: Icon(Icons.more_horiz,
                        color: Colors.white38, size: 20),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '“${quote.textFor(lang)}”',
            style: const TextStyle(
              fontFamily: kSerif,
              color: AppColors.textPrimary,
              fontSize: 16,
              fontStyle: FontStyle.italic,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.favorite, size: 14, color: Colors.grey),
              const SizedBox(width: 5),
              Text('${quote.likes}',
                  style: const TextStyle(color: Colors.grey, fontSize: 12)),
              const Spacer(),
              if (trailing != null) trailing!,
              if (onShareTap != null)
                GestureDetector(
                  onTap: onShareTap,
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 6),
                    child:
                        Icon(Icons.ios_share, color: Colors.white38, size: 18),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
