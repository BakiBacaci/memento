import 'package:flutter/material.dart';

import '../l10n/strings.dart';
import '../models/app_user.dart';
import '../models/quote.dart';
import '../services/quote_service.dart';
import '../services/settings_service.dart';
import '../services/user_service.dart';
import '../theme.dart';
import '../utils/content_filter.dart';
import '../widgets/celebration.dart';
import '../widgets/chunky_button.dart';
import '../widgets/common.dart';
import 'edit_profile_page.dart';

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

  /// true: kendi sözüm (yazar = ben). false: alıntı (yazar adı zorunlu).
  bool _own = true;

  /// Seçilen kart rengi (palette sıra). Ekran her açıldığında rastgele
  /// bir renkle başlar; kullanıcı değiştirebilir.
  int _color = DateTime.now().millisecond % QuoteMood.all.length;

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

    // Kullanıcı adı olmayan (eski) hesap: önce ad seçtir; yoksa sunucu
    // sözü reddediyor ve kullanıcı nedenini anlamıyordu.
    if ((_me?.username ?? '').isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.t('pick_username_first'))));
      await Navigator.push(context,
          MaterialPageRoute(builder: (_) => EditProfilePage(user: _me)));
      await _loadMe();
      return;
    }

    final author = _own ? _me!.name : _author.text.trim();
    if (ContentFilter.isObjectionable(text) ||
        ContentFilter.isObjectionable(author)) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.t('content_blocked'))));
      return;
    }
    if (author.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.t('author_required'))));
      return;
    }

    setState(() => _sending = true);
    try {
      await QuoteService.instance.createQuote(
        text: text,
        author: author,
        visibility: _visibility,
        lang: _quoteLang,
        ownerUsername: _me?.username,
        ownerPhotoUrl: _me?.photoUrl,
        color: _color,
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
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 32,
                      height: 1,
                      letterSpacing: -1,
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
                style: TextStyle(
                    color: AppColors.textMuted, fontSize: 13, height: 1.4),
              ),
              const SizedBox(height: 20),

              // --- Canlı önizleme: yazdığın şey nasıl görünecek ---
              _LivePreview(
                text: _text.text.trim(),
                author: _own ? (_me?.name ?? '') : _author.text.trim(),
                placeholder: context.t('preview_placeholder'),
                mood: QuoteMood.all[_color],
              ),
              const SizedBox(height: 14),
              _ColorPicker(
                selected: _color,
                onSelect: (i) => setState(() => _color = i),
              ),
              const SizedBox(height: 18),

              TextField(
                controller: _text,
                maxLines: 4,
                maxLength: _maxLength,
                autofocus: false,
                style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w600),
                decoration: InputDecoration(
                  hintText: context.t('quote_hint'),
                  counterText: '',
                ),
              ),
              const SizedBox(height: 12),
              _Chips(
                options: const ['own', 'quote'],
                selected: _own ? 'own' : 'quote',
                labelOf: (v) => context.t(v == 'own' ? 'my_own_words' : 'a_quote'),
                iconOf: (v) => v == 'own' ? Icons.edit_outlined : Icons.format_quote,
                onSelect: (v) => setState(() => _own = v == 'own'),
              ),
              if (!_own) ...[
                const SizedBox(height: 12),
                TextField(
                  controller: _author,
                  maxLength: 60,
                  style: TextStyle(color: AppColors.textPrimary),
                  decoration: InputDecoration(
                    hintText: context.t('author_hint'),
                    prefixIcon: Icon(Icons.person_outline,
                        color: AppColors.textMuted, size: 20),
                    counterText: '',
                  ),
                ),
              ],

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

/// Yazarken sözün renkli kart görünümü.
class _LivePreview extends StatelessWidget {
  const _LivePreview({
    required this.text,
    required this.author,
    required this.placeholder,
    required this.mood,
  });

  final String text;
  final String author;
  final String placeholder;
  final QuoteMood mood;

  @override
  Widget build(BuildContext context) {
    final empty = text.isEmpty;
    final shown = empty ? placeholder : text;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 280),
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 190),
      padding: const EdgeInsets.fromLTRB(22, 22, 22, 20),
      decoration: BoxDecoration(
        color: mood.top,
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Text(
            shown,
            style: quoteStyle(shown,
                scale: 0.72,
                color: empty ? mood.accent.withValues(alpha: 0.45) : mood.accent),
          ),
          const SizedBox(height: 12),
          Text(
            author.isEmpty ? '—' : author,
            style: TextStyle(
              color: mood.accent,
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
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
            color: near ? const Color(0xFFE5482F) : AppColors.textPrimary,
          ),
          if (near)
            Text('${max - current}',
                style: const TextStyle(
                    color: Color(0xFFE5482F),
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
                decoration: ShapeDecoration(
                  color: o == selected ? AppColors.textPrimary : Colors.transparent,
                  shape: StadiumBorder(
                    side: BorderSide(color: AppColors.textPrimary, width: 1.5),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (iconOf != null) ...[
                      Icon(iconOf!(o),
                          size: 15,
                          color: o == selected
                              ? AppColors.bg
                              : AppColors.textPrimary),
                      const SizedBox(width: 6),
                    ],
                    Text(
                      labelOf(o),
                      style: TextStyle(
                        color: o == selected ? AppColors.bg : AppColors.textPrimary,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
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
        text,
        style: TextStyle(
          color: AppColors.textPrimary,
          fontSize: 16,
          fontWeight: FontWeight.w800,
        ),
      );
}

/// Kart rengi seçici: paletteki her renk bir daire. Seçili olanın etrafında
/// halka ve içinde tik var. Dokununca önizleme o renge yumuşakça geçer.
class _ColorPicker extends StatelessWidget {
  const _ColorPicker({required this.selected, required this.onSelect});
  final int selected;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    final moods = QuoteMood.all;
    return SizedBox(
      height: 48,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: moods.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, i) {
          final m = moods[i];
          final on = i == selected;
          return Semantics(
            button: true,
            selected: on,
            label: '${context.t('card_color')} ${i + 1}',
            child: GestureDetector(
              onTap: () => onSelect(i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                width: 48,
                height: 48,
                padding: EdgeInsets.all(on ? 4 : 0),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: on ? AppColors.textPrimary : AppColors.border,
                    width: on ? 2.5 : 1,
                  ),
                ),
                child: Container(
                  decoration: BoxDecoration(color: m.top, shape: BoxShape.circle),
                  child: on ? Icon(Icons.check, size: 20, color: m.accent) : null,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
