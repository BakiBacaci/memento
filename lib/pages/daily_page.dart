import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../l10n/strings.dart';
import '../models/app_user.dart';
import '../models/quote.dart';
import '../services/daily_service.dart';
import '../services/journal_service.dart';
import '../widgets/journal_sheet.dart';
import '../services/saved_service.dart';
import '../services/user_service.dart';
import '../theme.dart';
import '../widgets/share_card.dart';

/// Günün sözü — kişiye özel.
///
/// Herkes her gün farklı bir söz görür. Söz önce kapalı bir kart olarak
/// gelir ("Bugün senin için bir söz var"); dokununca kart dönüp açılır.
/// O gün bir kez açıldıktan sonra sayfa doğrudan açık hâliyle gelir.
class DailyPage extends StatefulWidget {
  const DailyPage({super.key});

  static Future<void> open(BuildContext context) => Navigator.push(
        context,
        PageRouteBuilder(
          transitionDuration: const Duration(milliseconds: 380),
          pageBuilder: (_, __, ___) => const DailyPage(),
          transitionsBuilder: (_, a, __, child) => FadeTransition(
            opacity: CurvedAnimation(parent: a, curve: Curves.easeOut),
            child: child,
          ),
        ),
      );

  @override
  State<DailyPage> createState() => _DailyPageState();
}

class _DailyPageState extends State<DailyPage> with TickerProviderStateMixin {
  late final _flip = AnimationController(vsync: this, duration: const Duration(milliseconds: 750));
  late final _float = AnimationController(vsync: this, duration: const Duration(seconds: 3))..repeat(reverse: true);
  Quote? _q;
  AppUser? _me;
  bool _saved = false;

  @override
  void initState() {
    super.initState();
    if (DailyService.instance.seenToday.value) _flip.value = 1;
    _load();
  }

  Future<void> _load() async {
    final q = await DailyService.instance.today();
    final uid = UserService.instance.uid;
    final me = uid == null ? null : await UserService.instance.get(uid);
    if (!mounted) return;
    setState(() {
      _q = q;
      _me = me;
    });
  }

  @override
  void dispose() {
    _flip.dispose();
    _float.dispose();
    super.dispose();
  }

  Future<void> _reveal() async {
    if (_flip.value > 0 || _q == null) return;
    HapticFeedback.mediumImpact();
    await _flip.animateTo(1, curve: Curves.easeInOutCubic);
    HapticFeedback.lightImpact();
    DailyService.instance.markSeen();
  }

  Future<void> _save() async {
    final q = _q;
    if (q == null) return;
    if (!UserService.instance.isSignedIn) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(context.t('sign_in_required'))));
      return;
    }
    final now = await SavedService.instance.toggle(q);
    if (mounted) setState(() => _saved = now);
  }

  @override
  Widget build(BuildContext context) {
    final lang = context.lang;
    final q = _q;
    final mood = q == null ? QuoteMood.all.first : QuoteMood.forQuote(q);
    final name = (_me?.name ?? '').trim();
    final title = name.isEmpty
        ? context.t('daily_for_you')
        : context.tn('daily_for_name', {'name': name.split(' ').first});

    return AnimatedBuilder(
      animation: Listenable.merge([_flip, _float]),
      builder: (context, _) {
        final f = _flip.value;
        final open = f >= .5;
        // Zemin: kapalıyken koyu gece, açılınca sözün rengi.
        final bg = Color.lerp(const Color(0xFF111114), mood.top, Curves.easeIn.transform(((f - .4) / .6).clamp(0, 1)))!;
        final ink = open ? mood.accent : const Color(0xFFF5F3EE);
        final date = _date(DateTime.now(), lang);

        return Scaffold(
          backgroundColor: bg,
          body: SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 8, 8, 0),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(title,
                                style: TextStyle(color: ink, fontSize: 20, fontWeight: FontWeight.w800)),
                            Text(date,
                                style: TextStyle(color: ink.withValues(alpha: .7), fontSize: 14, fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ),
                      IconButton(icon: Icon(Icons.close, color: ink), onPressed: () => Navigator.pop(context)),
                    ],
                  ),
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: _reveal,
                    behavior: HitTestBehavior.opaque,
                    child: Center(child: _card(context, q, mood, f, lang)),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
                  child: AnimatedOpacity(
                    duration: const Duration(milliseconds: 300),
                    opacity: open ? 1 : 0,
                    child: IgnorePointer(
                      ignoring: !open,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: ValueListenableBuilder<bool>(
                                  valueListenable: JournalService.instance.todayDone,
                                  builder: (context, done, _) => FilledButton.icon(
                                    style: FilledButton.styleFrom(
                                      backgroundColor: mood.accent,
                                      foregroundColor: mood.top,
                                      minimumSize: const Size.fromHeight(54),
                                    ),
                                    onPressed: q == null ? null : () => showJournalSheet(context, q),
                                    icon: Icon(done ? Icons.check : Icons.menu_book_rounded, size: 20),
                                    label: Text(context.t(done ? 'journal_written' : 'journal_write_button')),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              SizedBox(
                                width: 54,
                                height: 54,
                                child: OutlinedButton(
                                  style: OutlinedButton.styleFrom(
                                    padding: EdgeInsets.zero,
                                    side: BorderSide(color: mood.accent, width: 2),
                                    shape: const CircleBorder(),
                                  ),
                                  onPressed: q == null ? null : () => QuoteShareSheet.show(context, q),
                                  child: Icon(Icons.ios_share, color: mood.accent, size: 22),
                                ),
                              ),
                              const SizedBox(width: 10),
                              SizedBox(
                                width: 54,
                                height: 54,
                                child: OutlinedButton(
                                  style: OutlinedButton.styleFrom(
                                    padding: EdgeInsets.zero,
                                    side: BorderSide(color: mood.accent, width: 2),
                                    shape: const CircleBorder(),
                                  ),
                                  onPressed: _save,
                                  child: Icon(_saved ? Icons.bookmark : Icons.bookmark_border, color: mood.accent),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(context.t('daily_tomorrow'),
                              style: TextStyle(color: mood.accent, fontSize: 13, height: 1.4, fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Uygulamada Türkçe tarih yerelleştirmesi yüklü değil; elle yazıyoruz.
  static String _date(DateTime d, String lang) {
    const trM = ['Ocak', 'Şubat', 'Mart', 'Nisan', 'Mayıs', 'Haziran', 'Temmuz', 'Ağustos', 'Eylül', 'Ekim', 'Kasım', 'Aralık'];
    const trD = ['Pazartesi', 'Salı', 'Çarşamba', 'Perşembe', 'Cuma', 'Cumartesi', 'Pazar'];
    const enM = ['January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'];
    const enD = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    return lang == 'en'
        ? '${enD[d.weekday - 1]}, ${enM[d.month - 1]} ${d.day}'
        : '${d.day} ${trM[d.month - 1]}, ${trD[d.weekday - 1]}';
  }

  Widget _card(BuildContext context, Quote? q, QuoteMood mood, double f, String lang) {
    final angle = f * pi;
    final front = angle > pi / 2;
    final bob = front ? 0.0 : sin(_float.value * pi) * 8;
    final size = MediaQuery.sizeOf(context);
    final w = min(size.width - 40, 420.0);
    final h = min(size.height * .62, w * 1.35);

    final Widget face;
    if (!front) {
      // Kapalı kart: gece rengi, içinde küçük bir davet.
      face = Container(
        width: w,
        height: h,
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          color: const Color(0xFF1F1F24),
          borderRadius: BorderRadius.circular(36),
          border: Border.all(color: mood.top.withValues(alpha: .55), width: 2),
          boxShadow: [BoxShadow(color: mood.top.withValues(alpha: .25), blurRadius: 60)],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('memento',
                style: TextStyle(color: mood.top, fontWeight: FontWeight.w800, fontSize: 22, letterSpacing: -.6)),
            const Spacer(),
            Text(context.t('daily_sealed'),
                style: const TextStyle(color: Color(0xFFF5F3EE), fontWeight: FontWeight.w800, fontSize: 34, height: 1.05, letterSpacing: -1)),
            const SizedBox(height: 14),
            Row(children: [
              Icon(Icons.touch_app_outlined, color: mood.top, size: 20),
              const SizedBox(width: 8),
              Text(context.t('daily_tap'),
                  style: TextStyle(color: mood.top, fontWeight: FontWeight.w700, fontSize: 16)),
            ]),
          ],
        ),
      );
    } else {
      final text = q?.textFor(lang) ?? '';
      face = Transform(
        alignment: Alignment.center,
        transform: Matrix4.rotationY(pi),
        child: Container(
          width: w,
          height: h,
          padding: const EdgeInsets.fromLTRB(28, 28, 24, 28),
          decoration: BoxDecoration(color: mood.top, borderRadius: BorderRadius.circular(36)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Spacer(),
              Text(text, style: quoteStyle(text, scale: .95, color: mood.accent)),
              const SizedBox(height: 18),
              Text(q?.authorFor(lang) ?? '',
                  style: TextStyle(color: mood.accent, fontWeight: FontWeight.w600, fontSize: 17)),
              const Spacer(),
            ],
          ),
        ),
      );
    }

    return Transform.translate(
      offset: Offset(0, bob),
      child: Transform(
        alignment: Alignment.center,
        transform: Matrix4.identity()
          ..setEntry(3, 2, .0012)
          ..rotateY(angle)
          ..scaleByDouble(1 + .06 * sin(f * pi), 1 + .06 * sin(f * pi), 1, 1),
        child: face,
      ),
    );
  }
}
