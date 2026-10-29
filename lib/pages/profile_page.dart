import 'package:flutter/material.dart';

import '../l10n/strings.dart';
import '../models/app_user.dart';
import '../models/quote.dart';
import '../services/follow_service.dart';
import '../services/like_service.dart';
import '../services/quote_service.dart';
import '../services/saved_service.dart';
import '../services/user_service.dart';
import '../theme.dart';
import '../widgets/chunky_button.dart';
import '../widgets/common.dart';
import '../widgets/quote_actions.dart';
import '../widgets/quote_tile.dart';
import '../widgets/share_card.dart';
import '../widgets/user_avatar.dart';
import 'edit_profile_page.dart';
import 'follow_list_page.dart';
import 'settings_page.dart';

/// Profil — Instagram düzeni.
///
/// Avatar solda, sayaçlar sağda yatay bir sırada. Ad ve bio altta, sola
/// hizalı. Sayaçlara dokunulabiliyor. Eski hâlde her şey ortalanmıştı ve
/// sayılar birer ölü metindi.
class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key, this.uid, this.onRequireSignIn});

  final String? uid;
  final VoidCallback? onRequireSignIn;

  @override
  Widget build(BuildContext context) {
    final myUid = UserService.instance.uid;
    final targetUid = uid ?? myUid;

    if (targetUid == null) {
      return Scaffold(
        appBar: AppBar(title: Text(context.t('profile'))),
        body: EmptyState(
          message: context.t('sign_in_required'),
          icon: Icons.lock_outline,
          action: SizedBox(
            width: 220,
            child: ChunkyButton(
              label: context.t('sign_in_to_continue'),
              onPressed: onRequireSignIn,
            ),
          ),
        ),
      );
    }

    final isMe = targetUid == myUid;

    return StreamBuilder<AppUser>(
      stream: UserService.instance.watch(targetUid),
      builder: (context, snap) {
        final user = snap.data;

        return DefaultTabController(
          length: isMe ? 3 : 1,
          child: Scaffold(
            appBar: AppBar(
              title: Text(user == null ? '' : '@${user.username}'),
              actions: [
                if (isMe)
                  IconButton(
                    icon: const Icon(Icons.menu),
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const SettingsPage()),
                    ),
                  ),
              ],
            ),
            body: NestedScrollView(
              headerSliverBuilder: (context, _) => [
                SliverToBoxAdapter(
                  child: _Header(
                    user: user,
                    isMe: isMe,
                    targetUid: targetUid,
                  ),
                ),
              ],
              body: Column(
                children: [
                  TabBar(
                    tabs: [
                      Tab(icon: const Icon(Icons.format_quote, size: 20),
                          text: context.t('tab_quotes')),
                      if (isMe)
                        Tab(icon: const Icon(Icons.bookmark_border, size: 20),
                            text: context.t('tab_saved')),
                      if (isMe)
                        Tab(icon: const Icon(Icons.favorite_border, size: 20),
                            text: context.t('tab_liked')),
                    ],
                  ),
                  Expanded(
                    child: TabBarView(
                      children: [
                        _QuoteList(
                          stream: QuoteService.instance.byUser(targetUid),
                          emptyKey: isMe ? 'no_quotes_yet' : 'user_no_quotes',
                          emptyIcon: Icons.format_quote,
                        ),
                        if (isMe)
                          _QuoteList(
                            stream: SavedService.instance.watch(),
                            emptyKey: 'no_saved_yet',
                            emptyIcon: Icons.bookmark_border,
                          ),
                        if (isMe)
                          _QuoteList(
                            stream: LikeService.instance.watchLiked(),
                            emptyKey: 'no_liked_yet',
                            emptyIcon: Icons.favorite_border,
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.user,
    required this.isMe,
    required this.targetUid,
  });

  final AppUser? user;
  final bool isMe;
  final String targetUid;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              UserAvatar(
                photoUrl: user?.photoUrl,
                initial: user?.name,
                radius: 40,
              ),
              const SizedBox(width: 24),
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _Stat(
                      value: user?.quoteCount ?? 0,
                      labelKey: 'quotes_count',
                    ),
                    _Stat(
                      value: user?.followerCount ?? 0,
                      labelKey: 'followers',
                      onTap: () => _openList(context, true),
                    ),
                    _Stat(
                      value: user?.followingCount ?? 0,
                      labelKey: 'following',
                      onTap: () => _openList(context, false),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            user?.name ?? '...',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
          if ((user?.bio ?? '').isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              user!.bio,
              style: const TextStyle(
                  color: AppColors.textPrimary, fontSize: 13, height: 1.45),
            ),
          ],
          if ((user?.link ?? '').isNotEmpty) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.link, size: 14, color: AppColors.gold),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    user!.link,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        color: AppColors.gold, fontSize: 13),
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 10),
          _KarmaBadge(karma: user?.karma ?? 0),
          const SizedBox(height: 14),
          if (isMe)
            ChunkyOutlineButton(
              label: context.t('edit_profile'),
              icon: Icons.edit_outlined,
              compact: true,
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => EditProfilePage(user: user)),
              ),
            )
          else
            _FollowButton(targetUid: targetUid),
        ],
      ),
    );
  }

  void _openList(BuildContext context, bool followers) => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) =>
              FollowListPage(uid: targetUid, showFollowers: followers),
        ),
      );
}

/// Karma'yı bir seviye çubuğu gibi gösteriyor — sadece sayı yerine
/// "bir sonraki eşiğe ne kadar kaldı" hissi veriyor.
class _KarmaBadge extends StatelessWidget {
  const _KarmaBadge({required this.karma});
  final int karma;

  static const _levels = [0, 10, 50, 150, 400, 1000, 2500];

  @override
  Widget build(BuildContext context) {
    var level = 0;
    for (var i = 0; i < _levels.length; i++) {
      if (karma >= _levels[i]) level = i;
    }
    final next = level + 1 < _levels.length ? _levels[level + 1] : null;
    final start = _levels[level];
    final progress =
        next == null ? 1.0 : ((karma - start) / (next - start)).clamp(0.0, 1.0);

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.local_fire_department,
                  color: AppColors.gold, size: 16),
              const SizedBox(width: 6),
              Text(
                '${context.t('karma')} $karma',
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w700),
              ),
              const Spacer(),
              Text(
                next == null
                    ? context.t('max_level')
                    : '${next - karma} ${context.t('to_next_level')}',
                style: const TextStyle(
                    color: AppColors.textMuted, fontSize: 11),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: progress),
              duration: const Duration(milliseconds: 700),
              curve: Curves.easeOutCubic,
              builder: (context, v, _) => LinearProgressIndicator(
                value: v,
                minHeight: 6,
                backgroundColor: AppColors.border,
                color: AppColors.gold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.value, required this.labelKey, this.onTap});

  final int value;
  final String labelKey;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Column(
            children: [
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                transitionBuilder: (child, anim) =>
                    ScaleTransition(scale: anim, child: child),
                child: Text(
                  '$value',
                  key: ValueKey('$labelKey$value'),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(height: 2),
              Text(context.t(labelKey),
                  style: const TextStyle(
                      color: AppColors.textMuted, fontSize: 11)),
            ],
          ),
        ),
      );
}

class _FollowButton extends StatefulWidget {
  const _FollowButton({required this.targetUid});
  final String targetUid;

  @override
  State<_FollowButton> createState() => _FollowButtonState();
}

class _FollowButtonState extends State<_FollowButton> {
  bool _busy = false;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<bool>(
      stream: FollowService.instance.isFollowing(widget.targetUid),
      builder: (context, snap) {
        final following = snap.data ?? false;
        return following
            ? ChunkyOutlineButton(
                label: context.t('unfollow'),
                icon: Icons.check,
                compact: true,
                onPressed: _busy ? null : () => _toggle(true),
              )
            : ChunkyButton(
                label: context.t('follow'),
                icon: Icons.person_add_alt_1,
                compact: true,
                loading: _busy,
                onPressed: _busy ? null : () => _toggle(false),
              );
      },
    );
  }

  Future<void> _toggle(bool currentlyFollowing) async {
    if (!UserService.instance.isSignedIn) {
      await requireSignIn(context);
      return;
    }
    setState(() => _busy = true);
    try {
      await FollowService.instance.toggle(widget.targetUid, currentlyFollowing);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }
}

class _QuoteList extends StatelessWidget {
  const _QuoteList({
    required this.stream,
    required this.emptyKey,
    required this.emptyIcon,
  });

  final Stream<List<Quote>> stream;
  final String emptyKey;
  final IconData emptyIcon;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Quote>>(
      stream: stream,
      builder: (context, snap) {
        if (snap.hasError) {
          return EmptyState(
              message: context.t('load_failed'), icon: Icons.cloud_off);
        }
        if (!snap.hasData) return const ShimmerList(count: 3);

        final quotes = snap.data!;
        if (quotes.isEmpty) {
          return EmptyState(message: context.t(emptyKey), icon: emptyIcon);
        }
        return ListView.builder(
          padding: const EdgeInsets.symmetric(vertical: 8),
          itemCount: quotes.length,
          itemBuilder: (context, i) => QuoteTile(
            quote: quotes[i],
            onShareTap: () => QuoteShareSheet.show(context, quotes[i]),
            onMoreTap: () => QuoteActions.show(context, quotes[i]),
          ),
        );
      },
    );
  }
}
