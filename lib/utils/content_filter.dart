/// Basit uygunsuz içerik filtresi (App Store Guideline 1.2).
///
/// Kullanıcı içeriği olan uygulamalarda Apple; şikâyet, engelleme ve
/// moderasyonun yanında uygunsuz içeriği filtreleyen bir yöntem de istiyor.
/// Bu liste kaba küfür ve hakaretleri paylaşılmadan önce yakalar; asıl
/// moderasyon şikâyet + yönetim paneliyle yapılır.
class ContentFilter {
  ContentFilter._();

  static const _words = <String>[
    // Türkçe
    'amk', 'aq', 'amına', 'amina', 'amcık', 'amcik', 'orospu', 'oruspu',
    'piç', 'pic', 'sikerim', 'sikeyim', 'siktir', 'sikik', 'yarrak', 'yarak',
    'göt', 'götveren', 'gotveren', 'ibne', 'kahpe', 'pezevenk', 'şerefsiz',
    'serefsiz', 'kaltak', 'yavşak', 'yavsak', 'sürtük', 'surtuk',
    // English
    'fuck', 'fucking', 'motherfucker', 'shit', 'bitch', 'cunt', 'dick',
    'pussy', 'whore', 'slut', 'nigger', 'nigga', 'faggot', 'retard',
  ];

  static final _pattern = RegExp(
    r'(^|[^a-zA-ZçğıöşüÇĞİÖŞÜ])(' + _words.map(RegExp.escape).join('|') +
        r')(?=$|[^a-zA-ZçğıöşüÇĞİÖŞÜ])',
    caseSensitive: false,
    unicode: true,
  );

  /// Metinde uygunsuz kelime var mı?
  static bool isObjectionable(String text) =>
      _pattern.hasMatch(text.toLowerCase());
}
