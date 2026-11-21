import 'quote.dart';

/// Bir kullanıcı profili.
///
/// Instagram modelini takip ediyor: `username` benzersiz kullanıcı adı
/// (@baki), `displayName` ise ekranda gösterilen serbest isim (Baki Bacacı).
/// Eskiden ikisi tek alandı; bu yüzden kullanıcı adını değiştirmek görünen
/// ismi de değiştiriyordu ve tam tersi.
class AppUser {
  final String uid;
  final String username;
  final String displayName;
  final String bio;
  final String link;
  final String? photoUrl;
  final int karma;
  final int quoteCount;
  final int followerCount;
  final int followingCount;

  /// Profile sabitlenen söz (yoksa null).
  final Quote? pinned;

  const AppUser({
    required this.uid,
    required this.username,
    this.displayName = '',
    this.bio = '',
    this.link = '',
    this.photoUrl,
    this.karma = 0,
    this.quoteCount = 0,
    this.followerCount = 0,
    this.followingCount = 0,
    this.pinned,
  });

  /// Ekranda gösterilecek ad — displayName yoksa kullanıcı adına düşer.
  String get name => displayName.isNotEmpty ? displayName : username;

  bool get hasPhoto => photoUrl != null && photoUrl!.isNotEmpty;

  String get initial =>
      name.isNotEmpty ? name.substring(0, 1).toUpperCase() : 'M';

  factory AppUser.fromMap(String uid, Map<String, dynamic>? d) {
    d ??= const {};
    return AppUser(
      uid: uid,
      username: (d['username'] as String?) ?? '',
      displayName: (d['display_name'] as String?) ?? '',
      bio: (d['bio'] as String?) ?? '',
      link: (d['link'] as String?) ?? '',
      photoUrl: d['photo_url'] as String?,
      karma: (d['karma'] as num?)?.toInt() ?? 0,
      quoteCount: (d['quote_count'] as num?)?.toInt() ?? 0,
      followerCount: (d['follower_count'] as num?)?.toInt() ?? 0,
      followingCount: (d['following_count'] as num?)?.toInt() ?? 0,
      pinned: d['pinned'] is Map
          ? Quote.fromJson(Map<String, dynamic>.from(d['pinned'] as Map))
          : null,
    );
  }
}
