import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

import '../l10n/strings.dart';
import '../models/quote.dart';
import '../theme.dart';
import '../utils/links.dart';
import '../utils/temp_file.dart';

/// Bir platform için görsel biçimi.
///
/// Güvenli alanlar: Instagram ve TikTok hikâye/video ekranında üstte profil
/// satırı, altta yorum kutusu ve sağda düğmeler var. Söz o bölgelere
/// taşmasın diye her biçimin kendi iç boşlukları tanımlı.
enum ShareFormat {
  instagramStory(1080, 1920, top: 250, bottom: 420, right: 96, label: 'Instagram Story'),
  tiktok(1080, 1920, top: 260, bottom: 520, right: 200, label: 'TikTok'),
  instagramPost(1080, 1350, top: 110, bottom: 150, right: 96, label: 'Instagram'),
  xPost(1600, 900, top: 90, bottom: 110, right: 110, label: 'X');

  const ShareFormat(this.w, this.h,
      {required this.top, required this.bottom, required this.right, required this.label});
  final double w, h, top, bottom, right;
  final String label;
}

/// Sözü platforma göre tasarlanmış bir görsele çevirip paylaşır.
///
/// Büyümenin ana kanalı bu: her görsel uygulamanın adını ve adresini taşıyor.
class QuoteShareSheet {
  static const _link = 'bakibacaci.github.io/memento';

  static Future<void> show(BuildContext context, Quote quote) async {
    final messenger = ScaffoldMessenger.of(context);
    final lang = context.lang;
    final text = quote.textFor(lang);
    final author = quote.authorFor(lang);
    final plain = '“$text”\n— $author\n\nMemento · https://$_link';

    Future<void> image(ShareFormat f) async {
      final ok = await _shareAsImage(quote, lang, plain, f);
      if (!ok) {
        messenger.showSnackBar(SnackBar(content: Text(L(lang).t('share_failed'))));
      }
    }

    await showModalBottomSheet<void>(
      context: context,
      builder: (sheetCtx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(sheetCtx.t('share'),
                  style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 24,
                      fontWeight: FontWeight.w800)),
              const SizedBox(height: 14),
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 3,
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                childAspectRatio: 0.95,
                children: [
                  _Target(
                    label: 'Instagram\n${sheetCtx.t('share_story')}',
                    icon: Icons.amp_stories_outlined,
                    color: const Color(0xFFFFB8DE),
                    ink: const Color(0xFF5A0F35),
                    onTap: () { Navigator.pop(sheetCtx); image(ShareFormat.instagramStory); },
                  ),
                  _Target(
                    label: 'TikTok',
                    icon: Icons.music_note_outlined,
                    color: const Color(0xFF9AD1FF),
                    ink: const Color(0xFF0A2A4A),
                    onTap: () { Navigator.pop(sheetCtx); image(ShareFormat.tiktok); },
                  ),
                  _Target(
                    label: 'Instagram\n${sheetCtx.t('share_post')}',
                    icon: Icons.crop_portrait,
                    color: const Color(0xFFFF9F80),
                    ink: const Color(0xFF4A1406),
                    onTap: () { Navigator.pop(sheetCtx); image(ShareFormat.instagramPost); },
                  ),
                  _Target(
                    label: 'X',
                    icon: Icons.alternate_email,
                    color: const Color(0xFF17171A),
                    ink: const Color(0xFFF5F3EE),
                    onTap: () {
                      Navigator.pop(sheetCtx);
                      // Metin + bağlantı doğrudan X'in gönderi ekranına; X 280
                      // karakter sınırı için söz gerekirse kısaltılır.
                      final short = text.length > 200 ? '${text.substring(0, 197)}…' : text;
                      final tweet = '“$short” — $author\n\nhttps://$_link';
                      AppLinks.open('https://x.com/intent/post?text=${Uri.encodeComponent(tweet)}');
                    },
                  ),
                  _Target(
                    label: 'WhatsApp',
                    icon: Icons.chat_outlined,
                    color: const Color(0xFF8FE3C4),
                    ink: const Color(0xFF07402C),
                    onTap: () {
                      Navigator.pop(sheetCtx);
                      AppLinks.open('https://wa.me/?text=${Uri.encodeComponent(plain)}');
                    },
                  ),
                  _Target(
                    label: sheetCtx.t('more'),
                    icon: Icons.ios_share,
                    color: AppColors.surface2,
                    ink: AppColors.textPrimary,
                    onTap: () { Navigator.pop(sheetCtx); image(ShareFormat.xPost); },
                  ),
                ],
              ),
              const SizedBox(height: 6),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(Icons.copy, color: AppColors.textPrimary),
                title: Text(sheetCtx.t('copy')),
                onTap: () {
                  Navigator.pop(sheetCtx);
                  Clipboard.setData(ClipboardData(text: plain));
                  messenger.showSnackBar(SnackBar(content: Text(L(lang).t('copied'))));
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  static Future<bool> _shareAsImage(
      Quote quote, String lang, String plain, ShareFormat f) async {
    try {
      final bytes = await renderCard(quote, lang, format: f);
      if (bytes == null) return false;
      final path = await writeTempPng(bytes, 'memento_${quote.id}_${f.name}.png');
      if (path == null) {
        await Share.share(plain); // Web: dosya sistemi yok.
        return true;
      }
      await Share.shareXFiles([XFile(path, mimeType: 'image/png')], text: plain);
      return true;
    } catch (e) {
      debugPrint('Görsel paylaşılamadı: $e');
      return false;
    }
  }

  /// Kartı ekrana basmadan doğrudan bellekte çizer.
  static Future<Uint8List?> renderCard(Quote quote, String lang,
      {ShareFormat format = ShareFormat.instagramStory}) async {
    final w = format.w, h = format.h;
    final mood = QuoteMood.forQuote(quote);
    final ink = mood.accent;
    final landscape = w > h;

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder, Rect.fromLTWH(0, 0, w, h));
    canvas.drawRect(Rect.fromLTWH(0, 0, w, h), Paint()..color = mood.top);

    TextPainter paint(String s, TextStyle style, {double? maxWidth}) =>
        TextPainter(
          text: TextSpan(text: s, style: style),
          textDirection: TextDirection.ltr,
        )..layout(maxWidth: maxWidth ?? w);

    const side = 96.0;
    final maxText = w - side - format.right;
    final text = quote.textFor(lang);
    final base = quoteStyle(text, color: ink);

    // Yazı boyutu: güvenli alana sığana kadar küçült.
    var scale = landscape ? 2.2 : 2.7;
    late TextPainter quotePainter;
    final authorPainter = paint(
      quote.authorFor(lang),
      TextStyle(fontFamily: kSans, color: ink, fontSize: 44, fontWeight: FontWeight.w600),
      maxWidth: maxText,
    );
    final available = h - format.top - format.bottom - authorPainter.height - 120;
    for (var i = 0; i < 12; i++) {
      quotePainter = paint(
        text,
        base.copyWith(
            fontSize: base.fontSize! * scale,
            letterSpacing: base.letterSpacing! * scale),
        maxWidth: maxText,
      );
      if (quotePainter.height <= available) break;
      scale *= 0.9;
    }

    final ay = h - format.bottom - authorPainter.height;
    final qy = ay - 48 - quotePainter.height;
    quotePainter.paint(canvas, Offset(side, qy));
    authorPainter.paint(canvas, Offset(side, ay));

    // Üstte marka, onun hizasında adres: her paylaşım bir davet.
    final brand = paint('memento', TextStyle(
      fontFamily: kSans, color: ink, fontSize: 48,
      fontWeight: FontWeight.w800, letterSpacing: -1.5,
    ));
    brand.paint(canvas, Offset(side, format.top - brand.height - 20));
    final link = paint(_link, TextStyle(
      fontFamily: kSans, color: ink, fontSize: 28, fontWeight: FontWeight.w600,
    ));
    link.paint(canvas, Offset(w - format.right - link.width,
        format.top - 20 - brand.height + (brand.height - link.height) / 2));

    final image = await recorder.endRecording().toImage(w.toInt(), h.toInt());
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();
    return data?.buffer.asUint8List();
  }
}

class _Target extends StatelessWidget {
  const _Target({
    required this.label,
    required this.icon,
    required this.color,
    required this.ink,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final Color color;
  final Color ink;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
        color: color,
        borderRadius: BorderRadius.circular(22),
        child: InkWell(
          borderRadius: BorderRadius.circular(22),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: ink, size: 28),
                const SizedBox(height: 8),
                Text(label,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        color: ink,
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                        height: 1.15)),
              ],
            ),
          ),
        ),
      );
}
