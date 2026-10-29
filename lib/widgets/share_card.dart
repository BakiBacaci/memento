import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

import '../l10n/strings.dart';
import '../models/quote.dart';
import '../theme.dart';
import '../utils/temp_file.dart';

/// Sözü şık bir görsele çevirip paylaşır.
///
/// Bir sözün gerçekten "ünlü" olması uygulamanın dışına çıkmasıyla olur.
/// Kart 1080x1350 (Instagram gönderi oranı) üretiliyor ve altında uygulamanın
/// adı duruyor — her paylaşım aynı zamanda bir davet.
class QuoteShareSheet {
  static Future<void> show(BuildContext context, Quote quote) async {
    final messenger = ScaffoldMessenger.of(context);
    final lang = context.lang;

    final plain =
        '“${quote.textFor(lang)}”\n— ${quote.authorFor(lang)}\n\nMemento';

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetCtx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 10),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 12),
            ListTile(
              leading: const Icon(Icons.image_outlined, color: AppColors.gold),
              title: Text(sheetCtx.t('share_image'),
                  style: const TextStyle(color: Colors.white)),
              subtitle: Text(sheetCtx.t('share_image_sub'),
                  style: const TextStyle(color: Colors.grey, fontSize: 12)),
              onTap: () async {
                Navigator.pop(sheetCtx);
                final ok = await _shareAsImage(quote, lang, plain);
                if (!ok) {
                  messenger.showSnackBar(
                      SnackBar(content: Text(L(lang).t('share_failed'))));
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.text_fields, color: AppColors.gold),
              title: Text(sheetCtx.t('share_text'),
                  style: const TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(sheetCtx);
                Share.share(plain);
              },
            ),
            ListTile(
              leading: const Icon(Icons.copy, color: AppColors.gold),
              title: Text(sheetCtx.t('copy'),
                  style: const TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(sheetCtx);
                Clipboard.setData(ClipboardData(text: plain));
                messenger.showSnackBar(
                    SnackBar(content: Text(L(lang).t('copied'))));
              },
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  static Future<bool> _shareAsImage(
      Quote quote, String lang, String plain) async {
    try {
      final bytes = await renderCard(quote, lang);
      if (bytes == null) return false;

      final path = await writeTempPng(bytes, 'memento_${quote.id}.png');
      if (path == null) {
        // Web: dosya sistemi yok, metne düşüyoruz.
        await Share.share(plain);
        return true;
      }
      await Share.shareXFiles([XFile(path)], text: plain);
      return true;
    } catch (e) {
      debugPrint('Görsel paylaşılamadı: $e');
      return false;
    }
  }

  /// Kartı ekrana hiç basmadan doğrudan bellekte çiziyoruz — kullanıcı
  /// bir önizleme ekranından geçmeden paylaşabiliyor.
  static Future<Uint8List?> renderCard(Quote quote, String lang) async {
    const w = 1080.0;
    const h = 1350.0;

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder, const Rect.fromLTWH(0, 0, w, h));

    canvas.drawRect(
      const Rect.fromLTWH(0, 0, w, h),
      Paint()
        ..shader = ui.Gradient.radial(
          const Offset(w / 2, h / 2),
          w,
          const [Color(0xFF1F1F1F), Color(0xFF000000)],
        ),
    );

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(44, 44, w - 88, h - 88),
        const Radius.circular(28),
      ),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = AppColors.gold.withValues(alpha: 0.45),
    );

    final text = quote.textFor(lang);
    final fontSize = switch (text.length) {
      > 220 => 40.0,
      > 140 => 48.0,
      > 70 => 58.0,
      _ => 68.0,
    };

    final quotePainter = TextPainter(
      text: TextSpan(
        text: '“$text”',
        style: TextStyle(
          color: const Color(0xFFE8E8E8),
          fontSize: fontSize,
          fontFamily: kSerif,
          fontStyle: FontStyle.italic,
          height: 1.45,
        ),
      ),
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: w - 220);

    quotePainter.paint(
      canvas,
      Offset((w - quotePainter.width) / 2, (h - quotePainter.height) / 2 - 60),
    );

    final authorPainter = TextPainter(
      text: TextSpan(
        text: '— ${quote.authorFor(lang)}',
        style: const TextStyle(
          color: AppColors.gold,
          fontSize: 40,
          fontFamily: kSerif,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: w - 220);

    authorPainter.paint(
      canvas,
      Offset((w - authorPainter.width) / 2, (h + quotePainter.height) / 2 + 8),
    );

    final brandPainter = TextPainter(
      text: const TextSpan(
        text: 'M E M E N T O',
        style: TextStyle(
          color: Color(0xFF6A6A6A),
          fontSize: 26,
          fontFamily: kSerif,
          letterSpacing: 8,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    brandPainter.paint(canvas, Offset((w - brandPainter.width) / 2, h - 132));

    final image = await recorder.endRecording().toImage(w.toInt(), h.toInt());
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();
    return data?.buffer.asUint8List();
  }
}
