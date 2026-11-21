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
import '../widgets/share_card.dart';
import '../widgets/user_avatar.dart';
import 'edit_profile_page.dart';
import '../widgets/photo_sheet.dart';
import 'follow_list_page.dart';
import 'journal_page.dart';
import 'notifications_page.dart';
import 'settings_page.dart';

/// Profil — Instagram düzeni.
///
/// Avatar solda, sayaçlar sağda yatay bir sırada. Ad ve bio altta, sola
/// hizalı. Sayaçlara dokunulabiliyor. Eski hâlde her şey ortalanmıştı ve
/// sayılar birer ölü metindi.
class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key, this.uid, this.onRequireSignIn});

  final String? uid;
  final VoidCallback? onRequireSignIn;

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  String? get uid => widget.uid;
  VoidCallback? get onRequireSignIn => widget.onRequireSignIn;

  // Profil akışı bir kez açılır; sekme değişip sayfa yeniden çizilince
  // baştan bağlanmaz (titreme ve gereksiz okuma olmaz).
  String? _streamUid;
  Stream<AppUser>? _userStream;
  Stream<AppUser> _watch(String id) {
    if (_streamUid != id || _userStream == null) {
      _streamUid = id;
      _userStream = UserService.instance.watch(id);
    }
    return _userStream!;
  }

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
      stream: _watch(targetUid),
      builder: (context, snap) {
        final user = snap.data;

        return DefaultTabController(
          length: isMe ? 3 : 1,
          child: Scaffold(
            appBar: AppBar(
              title: Text(user == null ? '' : '@${user.username}'),
              actions: [
                if (isMe) const NotificationBell(),
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
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: TabBar(
                      tabs: [
                        Tab(height: 40, text: context.t('tab_quotes')),
                        if (isMe) Tab(height: 40, text: context.t('tab_saved')),
                        if (isMe) Tab(height: 40, text: context.t('tab_liked')),
                      ],
                    ),
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
    final mood = QuoteMood.of(targetUid);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(color: mood.top, shape: BoxShape.circle),
                child: UserAvatar(
                  photoUrl: user?.photoUrl,
                  initial: user?.name,
                  radius: 34,
                  onTap: isMe
                      ? () => changeProfilePhoto(context,
                          hasPhoto: user?.hasPhoto ?? false)
                      : null,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user?.name ?? '…',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 28,
                        height: 1.05,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.8,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 14,
                      children: [
                        _Stat(value: user?.quoteCount ?? 0, labelKey: 'quotes_count'),
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
                  ],
                ),
              ),
            ],
          ),
          if ((user?.bio ?? '').isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              user!.bio,
              style: TextStyle(
                  color: AppColors.textPrimary, fontSize: 15, height: 1.4),
            ),
          ],
          if ((user?.link ?? '').isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              user!.link,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                  color: AppColors.gold, fontSize: 14, fontWeight: FontWeight.w600),
            ),
          ],
          if (user?.pinned != null) ...[
            const SizedBox(height: 14),
            _PinnedCard(quote: user!.pinned!, isMe: isMe),
          ],
          const SizedBox(height: 14),
          _KarmaBadge(karma: user?.karma ?? 0),
          const SizedBox(height: 12),
          if (isMe)
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(46)),
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => EditProfilePage(user: user)),
                    ),
                    child: Text(context.t('edit_profile')),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(46),
                      backgroundColor: AppColors.textPrimary,
                      foregroundColor: AppColors.bg,
                    ),
                    onPressed: () => JournalPage.open(context),
                    icon: const Icon(Icons.menu_book_rounded, size: 18),
                    label: Text(context.t('my_journal')),
                  ),
                ),
              ],
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

    const lime = Color(0xFFD7F75B);
    const ink = Color(0xFF24400A);
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
      decoration: BoxDecoration(
        color: lime,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                '$karma',
                style: const TextStyle(
                    color: ink,
                    fontSize: 26,
                    height: 1,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.8),
              ),
              const SizedBox(width: 6),
              Text(context.t('karma'),
                  style: const TextStyle(
                      color: ink, fontSize: 14, fontWeight: FontWeight.w600)),
              const Spacer(),
              Text(
                next == null
                    ? context.t('max_level')
                    : '${next - karma} ${context.t('to_next_level')}',
                style: const TextStyle(
                    color: ink, fontSize: 12, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: progress),
              duration: const Duration(milliseconds: 700),
              curve: Curves.easeOutCubic,
              builder: (context, v, _) => LinearProgressIndicator(
                value: v,
                minHeight: 8,
                backgroundColor: ink.withValues(alpha: 0.15),
                color: ink,
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
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Text.rich(
          TextSpan(children: [
            TextSpan(
              text: '$value ',
              style: TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w800,
                  fontSize: 15),
            ),
            TextSpan(
              text: context.t(labelKey),
              style: TextStyle(color: AppColors.textMuted, fontSize: 14),
            ),
          ]),
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
  bool? _optimistic;
  late final _stream = FollowService.instance.isFollowing(widget.targetUid);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<bool>(
      stream: _stream,
      builder: (context, snap) {
        final following = _optimistic ?? snap.data ?? false;
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
    final messenger = ScaffoldMessenger.of(context);
    final failed = context.t('follow_failed');
    setState(() {
      _busy = true;
      _optimistic = !currentlyFollowing;
    });
    try {
      await FollowService.instance.toggle(widget.targetUid, currentlyFollowing);
    } catch (e) {
      debugPrint('Takip işlemi başarısız: $e');
      messenger.showSnackBar(SnackBar(content: Text(failed)));
    } finally {
      if (mounted) {
        setState(() {
          _busy = false;
          _optimistic = null;
        });
      }
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
        // Renkli söz duvarı: iki sütun, her söz kendi renginde.
        return GridView.builder(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 0.9,
          ),
          itemCount: quotes.length,
          itemBuilder: (context, i) => _WallTile(quote: quotes[i]),
        );
      },
    );
  }
}

class _WallTile extends StatelessWidget {
  const _WallTile({required this.quote});
  final Quote quote;

  @override
  Widget build(BuildContext context) {
    final mood = QuoteMood.forQuote(quote);
    final text = quote.textFor(context.lang);
    return Material(
      color: mood.top,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: () => QuoteShareSheet.show(context, quote),
        onLongPress: () => QuoteActions.show(context, quote),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  text,
                  overflow: TextOverflow.fade,
                  style: quoteStyle(text, scale: 0.46, color: mood.accent),
                ),
              ),
              const SizedBox(height: 6),
              Row(children: [
                Icon(Icons.favorite, size: 13, color: mood.accent),
                const SizedBox(width: 4),
                Text('${quote.likes}',
                    style: TextStyle(
                        color: mood.accent,
                        fontWeight: FontWeight.w800,
                        fontSize: 12)),
              ]),
            ],
          ),
        ),
      ),
    );
  }
}

/// Profilin en üstündeki sabit söz: kişinin "beni bu anlatır" dediği söz.
class _PinnedCard extends StatelessWidget {
  const _PinnedCard({required this.quote, required this.isMe});
  final Quote quote;
  final bool isMe;

  @override
  Widget build(BuildContext context) {
    final mood = QuoteMood.forQuote(quote);
    final lang = context.lang;
    final text = quote.textFor(lang);
    return Material(
      color: mood.top,
      borderRadius: BorderRadius.circular(26),
      child: InkWell(
        borderRadius: BorderRadius.circular(26),
        onTap: () => QuoteShareSheet.show(context, quote),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 14, 8, 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.push_pin, size: 16, color: mood.accent),
                  const SizedBox(width: 6),
                  Text(context.t('pinned_quote'),
                      style: TextStyle(
                          color: mood.accent,
                          fontWeight: FontWeight.w600,
                          fontSize: 13)),
                  const Spacer(),
                  if (isMe)
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      tooltip: context.t('unpin'),
                      icon: Icon(Icons.close, size: 18, color: mood.accent),
                      onPressed: () => UserService.instance.setPinned(null),
                    ),
                ],
              ),
              const SizedBox(height: 6),
              Padding(
                padding: const EdgeInsets.only(right: 12),
                child: Text(text,
                    style: quoteStyle(text, scale: 0.7, color: mood.accent)),
              ),
              const SizedBox(height: 10),
              Text(quote.authorFor(lang),
                  style: TextStyle(
                      color: mood.accent,
                      fontWeight: FontWeight.w600,
                      fontSize: 14)),
            ],
          ),
        ),
      ),
    );
  }
}
