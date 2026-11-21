import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_card_swiper/flutter_card_swiper.dart';

import '../l10n/strings.dart';
import '../models/quote.dart';
import '../services/like_service.dart';
import '../services/quote_service.dart';
import '../services/block_service.dart';
import '../services/saved_service.dart';
import '../services/user_service.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/quote_actions.dart';
import '../widgets/quote_card.dart';
import '../widgets/share_card.dart';
import '../services/daily_service.dart';
import 'daily_page.dart';
import 'journal_page.dart';
import '../services/journal_service.dart';
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

  // Kaydırma sonrası tek seferlik geri bildirim (kalp yükselir / çarpı kayar).
  int _burstId = 0;
  bool _burstLike = true;

  StreamSubscription<List<Quote>>? _sub;
  StreamSubscription<Set<String>>? _likedSub;
  StreamSubscription<Set<String>>? _savedSub;
  StreamSubscription<User?>? _authSub;

  @override
  void initState() {
    super.initState();
    _init();
  }

  @override
  void dispose() {
    _sub?.cancel();
    _likedSub?.cancel();
    _savedSub?.cancel();
    _authSub?.cancel();
    BlockService.instance.blocked.removeListener(_onBlockedChanged);
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

    // Beğeni ve kayıt işaretleri canlı: başka cihazdan yapılan değişiklik
    // de anında görünür. Oturum açılıp kapanınca yeniden bağlanır.
    _authSub = FirebaseAuth.instance.authStateChanges().listen((_) => _bindUserStreams());
    _blockedIds = BlockService.instance.blocked.value;
    BlockService.instance.blocked.addListener(_onBlockedChanged);

    // Herkese açık sözler misafirlere de akıyor.
    _sub = QuoteService.instance.newest().listen(
      (remote) {
        if (!mounted) return;
        setState(() {
          _syncWarningKey = null;
          final existing = _quotes.map((q) => q.id).toSet();
          // Yeni sözler listenin SONUNA eklenir. Başa eklemek indeksleri
          // kaydırır ve CardSwiper yanlış sözü beğenir.
          // Kendi sözlerin destede çıkmaz: kendini beğenmek anlamsız, karma da vermiyor.
          final me = UserService.instance.uid;
          _quotes.addAll(remote.where((q) =>
              !existing.contains(q.id) &&
              !_blockedIds.contains(q.ownerId) &&
              (me == null || q.ownerId != me)));
        });
      },
      onError: (Object e) {
        debugPrint('Firestore akışı hata verdi: $e');
        if (mounted) setState(() => _syncWarningKey = _explain(e));
      },
    );
  }

  void _bindUserStreams() {
    _likedSub?.cancel();
    _savedSub?.cancel();
    if (!UserService.instance.isSignedIn) {
      if (mounted) setState(() {
        _likedIds = {};
        _savedIds = {};
      });
      return;
    }
    _likedSub = LikeService.instance.watchLikedIds().listen(
        (ids) { if (mounted) setState(() => _likedIds = ids); },
        onError: (Object e) => debugPrint('Beğeniler dinlenemedi: $e'));
    _savedSub = SavedService.instance.watchIds().listen(
        (ids) { if (mounted) setState(() => _savedIds = ids); },
        onError: (Object e) => debugPrint('Kayıtlar dinlenemedi: $e'));
  }

  void _onBlockedChanged() {
    if (!mounted) return;
    setState(() {
      _blockedIds = BlockService.instance.blocked.value;
      _quotes.removeWhere((q) => _blockedIds.contains(q.ownerId));
    });
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
            _buildHeader(),
            if (_syncWarningKey != null) _buildWarningBar(),
            Expanded(
              child: Stack(
                children: [
                  Positioned.fill(child: _buildBody()),
                  if (_burstId > 0)
                    Positioned.fill(
                      child: IgnorePointer(
                        child: _Burst(key: ValueKey(_burstId), like: _burstLike),
                      ),
                    ),
                ],
              ),
            ),
            if (!_loading && _quotes.isNotEmpty) _buildHint(),
          ],
        ),
      ),
    );
  }

  /// Üst şerit: marka, seri ve günün sözü.
  Widget _buildHeader() => Padding(
        padding: const EdgeInsets.fromLTRB(22, 10, 16, 2),
        child: Row(
          children: [
            Text(
              'memento',
              style: TextStyle(
                fontFamily: kSans,
                fontSize: 24,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.8,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(width: 10),
            const _JournalPill(),
            const Spacer(),
            Material(
              color: AppColors.textPrimary,
              shape: const StadiumBorder(),
              child: InkWell(
                customBorder: const StadiumBorder(),
                onTap: () => DailyPage.open(context),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
                  // Bugünün sözü henüz açılmadıysa yanında küçük bir ışık yanar.
                  child: ValueListenableBuilder<bool>(
                    valueListenable: DailyService.instance.seenToday,
                    builder: (context, seen, _) => Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (!seen) ...[
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(color: Color(0xFFFF7A2F), shape: BoxShape.circle),
                          ),
                          const SizedBox(width: 7),
                        ],
                        Text(context.t(seen ? 'daily_quote' : 'daily_for_you'),
                            style: TextStyle(
                                color: AppColors.bg,
                                fontWeight: FontWeight.w600,
                                fontSize: 14)),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      );

  Widget _buildWarningBar() => Container(
        width: double.infinity,
        color: AppColors.surface,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            Icon(Icons.cloud_off, size: 15, color: AppColors.textMuted),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                context.t(_syncWarningKey!),
                style: TextStyle(color: AppColors.textMuted, fontSize: 11),
              ),
            ),
          ],
        ),
      );

  Widget _buildHint() => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Text(
          context.t('swipe_hint'),
          style: TextStyle(color: AppColors.textMuted, fontSize: 11),
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
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
      backCardOffset: const Offset(0, 22),
      scale: 0.94,
      onSwipe: (prev, curr, dir) {
        if (dir == CardSwiperDirection.right) {
          setState(() {
            _burstLike = true;
            _burstId++;
          });
          if (!_likedIds.contains(_quotes[prev].id)) {
            _onLike(_quotes[prev]);
          } else {
            HapticFeedback.lightImpact();
          }
        } else if (dir == CardSwiperDirection.left) {
          HapticFeedback.selectionClick();
          setState(() {
            _burstLike = false;
            _burstId++;
          });
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

/// Başlıktaki defter göstergesi: bugün deftere bir söz işlendiyse dolu
/// halka ve seri; işlenmediyse boş halka ve "Defter". Dokununca defter açılır.
/// Kaydırmak bu göstergeyi doldurmaz; yalnızca deftere işlenen söz doldurur.
class _JournalPill extends StatelessWidget {
  const _JournalPill();

  @override
  Widget build(BuildContext context) {
    final j = JournalService.instance;
    return GestureDetector(
      onTap: () => JournalPage.open(context),
      behavior: HitTestBehavior.opaque,
      child: ValueListenableBuilder<bool>(
        valueListenable: j.todayDone,
        builder: (context, done, _) => ValueListenableBuilder<int>(
          valueListenable: j.streak,
          builder: (context, streak, _) => TweenAnimationBuilder<double>(
            key: ValueKey(done),
            tween: Tween(begin: done ? 1.25 : 1.0, end: 1.0),
            duration: const Duration(milliseconds: 420),
            curve: Curves.easeOutBack,
            builder: (context, v, child) => Transform.scale(scale: v, child: child),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: done ? const Color(0xFFFF7A2F) : Colors.transparent,
                    border: Border.all(color: done ? const Color(0xFFFF7A2F) : AppColors.border, width: 3),
                  ),
                  child: done ? const Icon(Icons.check, size: 15, color: Colors.white) : null,
                ),
                const SizedBox(width: 6),
                Text(
                  streak > 0 ? '🔥 $streak' : context.t('journal'),
                  style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w800, fontSize: 14),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Kaydırdıktan sonra yarım saniyelik iz.
///
/// Beğeni: kalp ortada küçük bir sıçramayla belirir, yukarı süzülüp söner.
/// Geç: küçük bir çarpı sola kayıp söner. Abartısız, tekrar tekrar
/// görülse de yormasın diye kısa.
class _Burst extends StatelessWidget {
  const _Burst({super.key, required this.like});
  final bool like;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: like ? 720 : 460),
      builder: (context, t, _) {
        if (t >= 1) return const SizedBox.shrink();
        if (like) {
          final pop = Curves.easeOutBack.transform((t / 0.35).clamp(0.0, 1.0));
          final rise = Curves.easeInCubic.transform(((t - 0.35) / 0.65).clamp(0.0, 1.0));
          return Align(
            alignment: const Alignment(0, -0.1),
            child: Transform.translate(
              offset: Offset(0, -90 * rise),
              child: Opacity(
                opacity: 1 - rise,
                child: Transform.scale(
                  scale: 0.4 + 0.6 * pop,
                  child: const Icon(Icons.favorite,
                      size: 84, color: AppColors.danger),
                ),
              ),
            ),
          );
        }
        final e = Curves.easeOutCubic.transform(t);
        return Align(
          alignment: const Alignment(-0.55, -0.1),
          child: Transform.translate(
            offset: Offset(-50 * e, 0),
            child: Opacity(
              opacity: 1 - e,
              child: Icon(Icons.close_rounded,
                  size: 56, color: AppColors.textMuted),
            ),
          ),
        );
      },
    );
  }
}
