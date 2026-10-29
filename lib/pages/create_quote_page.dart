import 'package:flutter/material.dart';

import '../l10n/strings.dart';
import '../models/app_user.dart';
import '../models/quote.dart';
import '../services/quote_service.dart';
import '../services/settings_service.dart';
import '../services/user_service.dart';
import '../theme.dart';
import '../widgets/celebration.dart';
import '../widgets/chunky_button.dart';
import '../widgets/common.dart';

/// Söz paylaşma.
///
/// Eski hâli bir formdan ibaretti: iki kutu, bir açılır liste, gri bir buton.
/// Şimdi yazarken sözün gerçek kartını canlı görüyorsun, karakter halkası
/// doluyor ve paylaşınca kutlama ekranı çıkıyor. Aynı işlem, tamamen farklı
/// bir his.
class CreateQuotePage extends StatefulWidget {
  const CreateQuotePage({super.key, this.onRequireSignIn});
  final VoidCallback? onRequireSignIn;

  @override
  State<CreateQuotePage> createState() => _CreateQuotePageState();
}

class _CreateQuotePageState extends State<CreateQuotePage> {
  static const _maxLength = 280;

  final _text = TextEditingController();
  final _author = TextEditingController();

  String _visibility = QuoteVisibility.public;
  String _quoteLang = 'tr';
  bool _sending = false;
  AppUser? _me;

  @override
  void initState() {
    super.initState();
    _quoteLang = SettingsService.instance.language.value;
    _text.addListener(() => setState(() {}));
    _author.addListener(() => setState(() {}));
    _loadMe();
  }

  @override
  void dispose() {
    _text.dispose();
    _author.dispose();
    super.dispose();
  }

  Future<void> _loadMe() async {
    final uid = UserService.instance.uid;
    if (uid == null) return;
    final me = await UserService.instance.get(uid);
    if (!mounted || me == null) return;
    setState(() {
      _me = me;
      if (_author.text.isEmpty) _author.text = me.name;
    });
  }

  Future<void> _submit() async {
    if (!UserService.instance.isSignedIn) {
      final wants = await requireSignIn(context);
      if (wants) widget.onRequireSignIn?.call();
      return;
    }

    final text = _text.text.trim();
    if (text.isEmpty) return;

    setState(() => _sending = true);
    try {
      await QuoteService.instance.createQuote(
        text: text,
        author: _author.text,
        visibility: _visibility,
        lang: _quoteLang,
        ownerUsername: _me?.username,
        ownerPhotoUrl: _me?.photoUrl,
      );
      if (!mounted) return;

      _text.clear();
      FocusScope.of(context).unfocus();

      await CelebrationSheet.show(
        context,
        title: context.t('celebrate_title'),
        subtitle: context.t('celebrate_sub'),
        buttonLabel: context.t('celebrate_button'),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('${context.t('publish_failed')}: $e'),
        backgroundColor: Colors.red,
      ));
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final len = _text.text.characters.length;
    final ready = _text.text.trim().isNotEmpty;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    context.t('share_wisdom'),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const Spacer(),
                  _CharRing(current: len, max: _maxLength),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                context.t('share_wisdom_sub'),
                style: const TextStyle(
                    color: AppColors.textMuted, fontSize: 13, height: 1.4),
              ),
              const SizedBox(height: 20),

              // --- Canlı önizleme: yazdığın şey nasıl görünecek ---
              _LivePreview(
                text: _text.text.trim(),
                author: _author.text.trim(),
                placeholder: context.t('preview_placeholder'),
              ),
              const SizedBox(height: 20),

              TextField(
                controller: _text,
                maxLines: 4,
                maxLength: _maxLength,
                autofocus: false,
                style: const TextStyle(
                    color: Colors.white, fontFamily: kSerif, fontSize: 16),
                decoration: InputDecoration(
                  hintText: context.t('quote_hint'),
                  counterText: '',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _author,
                maxLength: 60,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: context.t('author_hint'),
                  prefixIcon: const Icon(Icons.person_outline,
                      color: AppColors.textMuted, size: 20),
                  counterText: '',
                ),
              ),

              const SizedBox(height: 22),
              _Label(context.t('quote_language')),
              const SizedBox(height: 8),
              _Chips(
                options: L.supported,
                selected: _quoteLang,
                labelOf: L.languageName,
                onSelect: (v) => setState(() => _quoteLang = v),
              ),

              const SizedBox(height: 22),
              _Label(context.t('who_can_see')),
              const SizedBox(height: 8),
              _Chips(
                options: QuoteVisibility.all,
                selected: _visibility,
                labelOf: (v) => context.t(QuoteVisibility.labelKey(v)),
                iconOf: (v) => switch (v) {
                  QuoteVisibility.followers => Icons.people_outline,
                  QuoteVisibility.private => Icons.lock_outline,
                  _ => Icons.public,
                },
                onSelect: (v) => setState(() => _visibility = v),
              ),

              const SizedBox(height: 30),
              ChunkyButton(
                label: context.t('publish'),
                icon: Icons.auto_awesome,
                loading: _sending,
                onPressed: ready && !_sending ? _submit : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Yazarken sözün gerçek kart görünümü.
class _LivePreview extends StatelessWidget {
  const _LivePreview({
    required this.text,
    required this.author,
    required this.placeholder,
  });

  final String text;
  final String author;
  final String placeholder;

  @override
  Widget build(BuildContext context) {
    final empty = text.isEmpty;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 150),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
      decoration: BoxDecoration(
        gradient: const RadialGradient(
          radius: 1.2,
          colors: [AppColors.surfaceAlt, AppColors.bg],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: empty ? AppColors.border : AppColors.gold.withValues(alpha: 0.55),
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            empty ? placeholder : '“$text”',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: kSerif,
              fontSize: text.length > 120 ? 16 : 19,
              fontStyle: FontStyle.italic,
              height: 1.5,
              color: empty ? AppColors.textMuted : AppColors.textPrimary,
            ),
          ),
          if (author.isNotEmpty) ...[
            const SizedBox(height: 14),
            Text(
              '— $author',
              style: const TextStyle(
                color: AppColors.gold,
                fontFamily: kSerif,
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Karakter sayacı — sayı yerine dolan bir halka.
class _CharRing extends StatelessWidget {
  const _CharRing({required this.current, required this.max});
  final int current;
  final int max;

  @override
  Widget build(BuildContext context) {
    final p = (current / max).clamp(0.0, 1.0);
    final near = current > max * 0.85;
    return SizedBox(
      width: 34,
      height: 34,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CircularProgressIndicator(
            value: p,
            strokeWidth: 3,
            backgroundColor: AppColors.border,
            color: near ? Colors.orangeAccent : AppColors.gold,
          ),
          if (near)
            Text('${max - current}',
                style: const TextStyle(
                    color: Colors.orangeAccent,
                    fontSize: 10,
                    fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

/// Açılır liste yerine dokunmatik etiketler — daha hızlı, daha görünür.
class _Chips extends StatelessWidget {
  const _Chips({
    required this.options,
    required this.selected,
    required this.labelOf,
    required this.onSelect,
    this.iconOf,
  });

  final List<String> options;
  final String selected;
  final String Function(String) labelOf;
  final IconData Function(String)? iconOf;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) => Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (final o in options)
            GestureDetector(
              onTap: () => onSelect(o),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 160),
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: o == selected ? AppColors.gold : AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: o == selected ? AppColors.gold : AppColors.border,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (iconOf != null) ...[
                      Icon(iconOf!(o),
                          size: 15,
                          color: o == selected
                              ? Colors.black
                              : AppColors.textMuted),
                      const SizedBox(width: 6),
                    ],
                    Text(
                      labelOf(o),
                      style: TextStyle(
                        color: o == selected ? Colors.black : Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      );
}

class _Label extends StatelessWidget {
  const _Label(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Text(
        text.toUpperCase(),
        style: const TextStyle(
          color: AppColors.textMuted,
          fontSize: 11,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.2,
        ),
      );
}
