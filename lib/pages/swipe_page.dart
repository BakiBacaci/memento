import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_card_swiper/flutter_card_swiper.dart';

import '../l10n/strings.dart';
import '../models/quote.dart';
import '../services/like_service.dart';
import '../services/quote_service.dart';
import '../services/report_service.dart';
import '../services/saved_service.dart';
import '../services/user_service.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/quote_actions.dart';
import '../widgets/quote_card.dart';
import '../widgets/share_card.dart';
import 'profile_page.dart';

class SwipePage extends StatefulWidget {
  const SwipePage({super.key, this.onRequireSignIn});

  final VoidCallback? onRequireSignIn;

  @override
  State<SwipePage> createState() => _SwipePageState();
}

class _SwipePageState extends State<SwipePage> {
  final _controller = CardSwiperController();

  List<Quote> _quotes = [];
  Set<String> _savedIds = {};
  Set<String> _likedIds = {};
  Set<String> _blockedIds = {};
  bool _loading = true;
  String? _syncWarningKey;

  StreamSubscription<List<Quote>>? _sub;

  @override
  void initState() {
    super.initState();
    _init();
  }

  @override
  void dispose() {
    _sub?.cancel();
    _controller.dispose();
    super.dispose();
  }

  /// Sıralama kasıtlı: önce yerel sözler ekrana basılır, SONRA Firestore
  /// denenir. İnternet yoksa, kurallar kapalıysa ya da indeks eksikse
  /// uygulama boş ekranda kalmaz.
  Future<void> _init() async {
    final assetQuotes = await QuoteService.instance.loadAssetQuotes();

    if (!mounted) return;
    setState(() {
      _quotes = [...assetQuotes]..shuffle();
      _loading = false;
    });

    if (!UserService.instance.isSignedIn) return;

    for (final step in [
      () async => _savedIds = await SavedService.instance.savedIds(),
      () async => _likedIds = await LikeService.instance.myLikedIds(),
      () async => _blockedIds = await ReportService.instance.blockedIds(),
    ]) {
      try {
        await step();
      } catch (e) {
        debugPrint('Yardımcı veri okunamadı: $e');
      }
    }
    if (mounted) setState(() {});

    _sub = QuoteService.instance.newest().listen(
      (remote) {
        if (!mounted) return;
        setState(() {
          _syncWarningKey = null;
          final existing = _quotes.map((q) => q.id).toSet();
          // Yeni sözler listenin SONUNA eklenir. Başa eklemek indeksleri
          // kaydırır ve CardSwiper yanlış sözü beğenir.
          _quotes.addAll(remote.where((q) =>
              !existing.contains(q.id) && !_blockedIds.contains(q.ownerId)));
        });
      },
      onError: (Object e) {
        debugPrint('Firestore akışı hata verdi: $e');
        if (mounted) setState(() => _syncWarningKey = _explain(e));
      },
    );
  }

  String _explain(Object e) {
    final s = e.toString();
    if (s.contains('failed-precondition') || s.contains('requires an index')) {
      return 'index_missing';
    }
    if (s.contains('permission-denied')) return 'permission_denied';
    if (s.contains('unavailable')) return 'offline_local_only';
    return 'load_failed';
  }

  Future<bool> _ensureSignedIn() async {
    if (UserService.instance.isSignedIn) return true;
    final wants = await requireSignIn(context);
    if (wants) widget.onRequireSignIn?.call();
    return false;
  }

  /// Beğeni. Artık hazır sözler de beğenilebiliyor — eskiden bunlar
  /// Firestore'da bir dökümana karşılık gelmediği için beğeni sessizce
  /// başarısız oluyor, kalp bir an görünüp kayboluyordu.
  Future<void> _onLike(Quote q) async {
    if (!await _ensureSignedIn()) return;

    final wasLiked = _likedIds.contains(q.id);
    HapticFeedback.mediumImpact();

    // İyimser güncelleme: arayüz beklemeden tepki veriyor.
    setState(() {
      if (wasLiked) {
        _likedIds.remove(q.id);
      } else {
        _likedIds.add(q.id);
      }
    });

    try {
      await LikeService.instance.toggle(q);
    } catch (e) {
      debugPrint('Beğeni yazılamadı: $e');
      if (!mounted) return;
      setState(() {
        if (wasLiked) {
          _likedIds.add(q.id);
        } else {
          _likedIds.remove(q.id);
        }
      });
    }
  }

  Future<void> _onSave(Quote q) async {
    if (!await _ensureSignedIn()) return;
    final nowSaved = await SavedService.instance.toggle(q);
    if (!mounted) return;
    setState(() {
      if (nowSaved) {
        _savedIds.add(q.id);
      } else {
        _savedIds.remove(q.id);
      }
    });
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Text(context.t(nowSaved ? 'saved' : 'unsaved')),
        duration: const Duration(milliseconds: 900),
      ));
  }

  void _openAuthor(Quote q) {
    if (q.ownerId == null) return;
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ProfilePage(uid: q.ownerId!)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            if (_syncWarningKey != null) _buildWarningBar(),
            Expanded(child: _buildBody()),
            if (!_loading && _quotes.isNotEmpty) _buildHint(),
          ],
        ),
      ),
    );
  }

  Widget _buildWarningBar() => Container(
        width: double.infinity,
        color: AppColors.surface,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            const Icon(Icons.cloud_off, size: 15, color: Colors.grey),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                context.t(_syncWarningKey!),
                style: const TextStyle(color: Colors.grey, fontSize: 11),
              ),
            ),
          ],
        ),
      );

  Widget _buildHint() => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Text(
          context.t('swipe_hint'),
          style: TextStyle(color: Colors.grey[700], fontSize: 11),
        ),
      );

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_quotes.isEmpty) {
      return EmptyState(message: context.t('no_quotes'));
    }
    return CardSwiper(
      controller: _controller,
      cardsCount: _quotes.length,
      numberOfCardsDisplayed: _quotes.length < 3 ? _quotes.length : 3,
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      backCardOffset: const Offset(0, 28),
      onSwipe: (prev, curr, dir) {
        if (dir == CardSwiperDirection.right &&
            !_likedIds.contains(_quotes[prev].id)) {
          _onLike(_quotes[prev]);
        }
        return true;
      },
      cardBuilder: (ctx, i, hOffset, vOffset) {
        final q = _quotes[i];
        return QuoteCard(
          quote: q,
          horizontalOffset: hOffset,
          isLiked: _likedIds.contains(q.id),
          isSaved: _savedIds.contains(q.id),
          onSaveTap: () => _onSave(q),
          onLikeTap: () => _onLike(q),
          onAuthorTap: q.ownerId == null ? null : () => _openAuthor(q),
          onShareTap: () => QuoteShareSheet.show(context, q),
          onMoreTap: () => QuoteActions.show(
            context,
            q,
            onDeleted: () => setState(() => _quotes.remove(q)),
            onBlocked: () => setState(() {
              _blockedIds.add(q.ownerId ?? '');
              _quotes.removeWhere((e) => e.ownerId == q.ownerId);
            }),
          ),
        );
      },
    );
  }
}
