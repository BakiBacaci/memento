import 'package:url_launcher/url_launcher.dart';

/// Uygulama dışı bağlantılar. Gizlilik politikası ve kullanım koşulları
/// App Store incelemesinde zorunlu; GitHub Pages'te yayınlanıyor.
class AppLinks {
  static const _base = 'https://bakibacaci.github.io/memento';

  static String privacy(String lang) => '$_base/privacy${lang == 'en' ? '-en' : ''}.html';
  static String terms(String lang) => '$_base/terms${lang == 'en' ? '-en' : ''}.html';

  static Future<void> open(String url) =>
      launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
}
