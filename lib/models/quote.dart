/// Gizlilik seçenekleri.
///
/// Firestore'da saklanan değerler Türkçe metinler — mevcut veriyi bozmamak
/// için böyle kaldı. Ekranda gösterilen etiket `label()` ile diline göre
/// çevriliyor, yani kullanıcı İngilizce'ye geçince "Public" görüyor ama
/// veritabanında yine 'Herkese Açık' yazıyor.
class QuoteVisibility {
  static const public = 'Herkese Açık';
  static const followers = 'Takipçilerim';
  static const private = 'Yalnızca Ben';

  static const all = [public, followers, private];

  static String labelKey(String value) => switch (value) {
        followers => 'vis_followers',
        private => 'vis_private',
        _ => 'vis_public',
      };
}

/// Platformdan bağımsız, deterministik string hash (FNV-1a 32-bit).
/// Dart'ın String.hashCode'u sürümler arası sabit olmadığı için kalıcı
/// kimlik üretiminde kullanılamaz.
String stableHash(String s) {
  var h = 0x811c9dc5;
  for (final c in s.codeUnits) {
    h ^= c;
    h = (h * 0x01000193) & 0xFFFFFFFF;
  }
  return h.toRadixString(16).padLeft(8, '0');
}

class Quote {
  /// Firestore döküman id'si, ya da hazır sözler için 'local_<hash>'.
  final String id;

  /// Sözün asıl dilindeki hali.
  final String text;
  final String author;

  /// Hazır sözlerin İngilizce karşılığı. Makine çevirisi DEĞİL — sözün
  /// bilinen orijinali ya da kabul görmüş İngilizce çevirisi. Yoksa null,
  /// o zaman Türkçesi gösterilir.
  final String? textEn;
  final String? authorEn;

  /// Kullanıcı sözlerinin yazıldığı dil ('tr' / 'en').
  final String lang;

  final String? ownerId;
  final String? ownerUsername;
  final String? ownerPhotoUrl;
  final int likes;
  final String visibility;

  /// Yazarın seçtiği kart rengi (QuoteMood paletinde sıra). Yoksa null.
  final int? color;

  /// Günün sözü havuzunda mı (herkese iyi gelecek, motive eden sözler).
  final bool daily;

  const Quote({
    required this.id,
    required this.text,
    required this.author,
    this.textEn,
    this.authorEn,
    this.lang = 'tr',
    this.ownerId,
    this.ownerUsername,
    this.ownerPhotoUrl,
    this.likes = 0,
    this.visibility = QuoteVisibility.public,
    this.color,
    this.daily = false,
  });

  /// Firestore'dan mı geldi? Beğeni ve karma yalnızca bunlarda çalışır.
  bool get isRemote => !id.startsWith('local_');

  /// Arayüzün diline göre gösterilecek metin.
  String textFor(String uiLang) =>
      (uiLang == 'en' && textEn != null && textEn!.isNotEmpty) ? textEn! : text;

  String authorFor(String uiLang) => (uiLang == 'en' &&
          authorEn != null &&
          authorEn!.isNotEmpty)
      ? authorEn!
      : author;

  factory Quote.fromAsset(Map<String, dynamic> json) {
    final text = (json['text'] as String?) ?? '';
    return Quote(
      id: 'local_${stableHash(text)}',
      text: text,
      author: (json['author'] as String?) ?? 'Anonim',
      textEn: json['text_en'] as String?,
      authorEn: json['author_en'] as String?,
      daily: json['daily'] == true,
    );
  }

  factory Quote.fromFirestore(String docId, Map<String, dynamic> d) {
    return Quote(
      id: docId,
      text: ((d['text'] as String?) ?? '').trim(),
      author: (d['author'] as String?) ?? 'Anonim',
      lang: (d['lang'] as String?) ?? 'tr',
      ownerId: d['user_id'] as String?,
      ownerUsername: d['owner_username'] as String?,
      ownerPhotoUrl: d['owner_photo_url'] as String?,
      likes: (d['likes'] as num?)?.toInt() ?? 0,
      visibility: (d['privacy'] as String?) ?? QuoteVisibility.public,
      color: (d['color'] as num?)?.toInt(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'text': text,
        'author': author,
        if (textEn != null) 'text_en': textEn,
        if (authorEn != null) 'author_en': authorEn,
        'lang': lang,
        'user_id': ownerId,
        'owner_username': ownerUsername,
        'owner_photo_url': ownerPhotoUrl,
        'likes': likes,
        'privacy': visibility,
        if (color != null) 'color': color,
      };

  factory Quote.fromJson(Map<String, dynamic> j) {
    final text = (j['text'] as String?) ?? '';
    return Quote(
      id: (j['id'] as String?) ??
          (j['docId'] as String?) ??
          'local_${stableHash(text)}',
      text: text,
      author: (j['author'] as String?) ?? 'Anonim',
      textEn: j['text_en'] as String?,
      authorEn: j['author_en'] as String?,
      lang: (j['lang'] as String?) ?? 'tr',
      ownerId: j['user_id'] as String?,
      ownerUsername: j['owner_username'] as String?,
      ownerPhotoUrl: j['owner_photo_url'] as String?,
      likes: (j['likes'] as num?)?.toInt() ?? 0,
      visibility: (j['privacy'] as String?) ?? QuoteVisibility.public,
      color: (j['color'] as num?)?.toInt(),
    );
  }

  Quote copyWith({int? likes}) => Quote(
        id: id,
        text: text,
        author: author,
        textEn: textEn,
        authorEn: authorEn,
        lang: lang,
        ownerId: ownerId,
        ownerUsername: ownerUsername,
        ownerPhotoUrl: ownerPhotoUrl,
        likes: likes ?? this.likes,
        visibility: visibility,
        color: color,
      );

  @override
  bool operator ==(Object other) => other is Quote && other.id == id;

  @override
  int get hashCode => id.hashCode;
}
