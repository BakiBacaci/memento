import 'package:flutter/material.dart';

import '../l10n/strings.dart';
import '../models/quote.dart';
import '../services/quote_service.dart';
import '../services/user_service.dart';
import '../widgets/common.dart';
import '../widgets/quote_actions.dart';
import '../widgets/quote_tile.dart';
import '../widgets/share_card.dart';
import 'profile_page.dart';

/// Üç sekmeli akış: Popüler / Yeni / Takip.
///
/// "Popüler" uygulamanın fikrinin görünür hali — en çok beğenilen kullanıcı
/// sözleri burada toplanıyor, hedef bu listeye girmek oluyor.
class FeedPage extends StatefulWidget {
  const FeedPage({super.key, this.onRequireSignIn});
  final VoidCallback? onRequireSignIn;

  @override
  State<FeedPage> createState() => _FeedPageState();
}

class _FeedPageState extends State<FeedPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs = TabController(length: 3, vsync: this);

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(context.t('feed')),
        bottom: TabBar(
          controller: _tabs,
          tabs: [
            Tab(text: context.t('tab_popular')),
            Tab(text: context.t('tab_new')),
            Tab(text: context.t('tab_following')),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabs,
        children: [
          _QuoteStreamList(
            stream: QuoteService.instance.popular(),
            showRank: true,
            emptyKey: 'feed_empty',
          ),
          _QuoteStreamList(
            stream: QuoteService.instance.newest(),
            emptyKey: 'feed_empty',
          ),
          UserService.instance.isSignedIn
              ? _QuoteStreamList(
                  stream: QuoteService.instance.followingFeed(),
                  emptyKey: 'following_empty',
                  emptyIcon: Icons.person_add_alt,
                )
              : EmptyState(
                  message: context.t('sign_in_required'),
                  icon: Icons.lock_outline,
                  action: OutlinedButton(
                    onPressed: widget.onRequireSignIn,
                    child: Text(context.t('sign_in_to_continue')),
                  ),
                ),
        ],
      ),
    );
  }
}

class _QuoteStreamList extends StatelessWidget {
  const _QuoteStreamList({
    required this.stream,
    required this.emptyKey,
    this.showRank = false,
    this.emptyIcon = Icons.hourglass_empty,
  });

  final Stream<List<Quote>> stream;
  final String emptyKey;
  final bool showRank;
  final IconData emptyIcon;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Quote>>(
      stream: stream,
      builder: (context, snap) {
        if (snap.hasError) {
          return EmptyState(
            message: context.t('load_failed'),
            icon: Icons.cloud_off,
          );
        }
        if (!snap.hasData) return const ShimmerList();

        final quotes = snap.data!;
        if (quotes.isEmpty) {
          return EmptyState(message: context.t(emptyKey), icon: emptyIcon);
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(vertical: 8),
          itemCount: quotes.length,
          itemBuilder: (context, i) {
            final q = quotes[i];
            return QuoteTile(
              quote: q,
              rank: showRank ? i + 1 : null,
              onAuthorTap: q.ownerId == null
                  ? null
                  : () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => ProfilePage(uid: q.ownerId!)),
                      ),
              onShareTap: () => QuoteShareSheet.show(context, q),
              onMoreTap: () => QuoteActions.show(context, q),
            );
          },
        );
      },
    );
  }
}
