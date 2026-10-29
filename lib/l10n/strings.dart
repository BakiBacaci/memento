import 'package:flutter/widgets.dart';

import '../services/settings_service.dart';

/// Uygulamanın tüm metinleri tek dosyada. Yeni bir dil eklemek,
/// yeni bir harita eklemekten ibaret.
///
/// Kullanım:  context.t('discover')
class L {
  L(this.lang);
  final String lang;

  static L of(BuildContext context) =>
      L(SettingsService.instance.language.value);

  String t(String key) {
    final map = lang == 'en' ? _en : _tr;
    return map[key] ?? _tr[key] ?? key;
  }

  /// Değişkenli metinler:  tn('n_followers', {'n': '12'})
  String tn(String key, Map<String, String> vars) {
    var s = t(key);
    vars.forEach((k, v) => s = s.replaceAll('{$k}', v));
    return s;
  }

  static const supported = ['tr', 'en'];

  static String languageName(String code) =>
      code == 'en' ? 'English' : 'Türkçe';

  // ---------------------------------------------------------------
  static const Map<String, String> _tr = {
    'app_tagline': 'Kendi gerçeğini keşfet.',

    'discover': 'Keşfet',
    'feed': 'Akış',
    'create': 'Oluştur',
    'leaderboard': 'Zirve',
    'profile': 'Profil',

    'sign_in': 'GİRİŞ YAP',
    'sign_up': 'KAYDOL',
    'register': 'Kayıt Ol',
    'email': 'E-posta',
    'password': 'Şifre',
    'username': 'Kullanıcı Adı',
    'no_account': 'Hesabın yok mu? ',
    'continue_as_guest': 'Hesapsız devam et',
    'guest': 'Misafir',
    'sign_in_required': 'Bunun için giriş yapman gerekiyor.',
    'sign_in_to_continue': 'Devam etmek için giriş yap',
    'sign_out': 'Çıkış',

    'err_invalid_email': 'E-posta adresi geçersiz.',
    'err_user_disabled': 'Bu hesap devre dışı bırakılmış.',
    'err_bad_credentials': 'E-posta veya şifre hatalı.',
    'err_too_many': 'Çok fazla deneme yapıldı, biraz bekle.',
    'err_network': 'İnternet bağlantısı yok.',
    'err_email_in_use': 'Bu e-posta zaten kayıtlı.',
    'err_weak_password': 'Şifre çok zayıf (en az 6 karakter).',
    'err_generic': 'Bir şeyler ters gitti.',
    'err_username_taken': 'Bu kullanıcı adı alınmış.',
    'err_username_invalid':
        'Kullanıcı adı 3-20 karakter olmalı; harf, rakam ve alt çizgi.',

    'no_quotes': 'Henüz gösterilecek söz yok.',
    'offline_local_only': 'Bağlantı yok — sadece hazır sözler gösteriliyor.',
    'index_missing': 'Firestore indeksi eksik — sadece hazır sözler.',
    'permission_denied': 'Firestore izni yok — sadece hazır sözler.',
    'load_failed': 'Paylaşılan sözler yüklenemedi.',
    'swipe_hint': 'Beğenmek için sağa kaydır',
    'like': 'BEĞEN',
    'pass': 'GEÇ',

    'tab_popular': 'Popüler',
    'tab_new': 'Yeni',
    'tab_following': 'Takip',
    'following_empty':
        'Kimseyi takip etmiyorsun.\nBeğendiğin sözlerin yazarlarını takip et.',
    'feed_empty': 'Burada henüz bir şey yok.',

    'saved': 'Kaydedildi',
    'unsaved': 'Kaldırıldı',
    'likes': 'beğeni',
    'share': 'Paylaş',
    'share_image': 'Görsel olarak paylaş',
    'share_image_sub': 'Instagram, WhatsApp, her yere',
    'share_text': 'Metin olarak paylaş',
    'share_failed': 'Paylaşılamadı.',
    'report': 'Şikâyet et',
    'delete': 'Sil',
    'delete_confirm': 'Bu sözü silmek istediğine emin misin?',
    'deleted': 'Silindi',
    'copied': 'Kopyalandı',
    'copy': 'Kopyala',

    'share_wisdom': 'BİLGELİĞİNİ PAYLAŞ',
    'quote_hint': 'Sözü buraya yaz...',
    'author_hint': 'Söz kime ait?',
    'publish': 'PAYLAŞ',
    'published': 'Paylaşıldı!',
    'publish_failed': 'Paylaşılamadı',
    'vis_public': 'Herkese Açık',
    'vis_followers': 'Takipçilerim',
    'vis_private': 'Yalnızca Ben',
    'quote_language': 'Sözün dili',

    'edit_profile': 'Profili Düzenle',
    'my_quotes': 'PAYLAŞTIKLARIM',
    'my_saved': 'KAYDETTİKLERİM',
    'no_quotes_yet': 'Henüz paylaşımın yok.',
    'no_saved_yet': 'Henüz kaydettiğin söz yok.',
    'user_no_quotes': 'Henüz paylaşımı yok.',
    'bio': 'Hakkında',
    'bio_default': 'Yeni bir zihin.',
    'karma': 'Karma',
    'quotes_count': 'Söz',
    'followers': 'Takipçi',
    'following': 'Takip',
    'follow': 'Takip Et',
    'unfollow': 'Takibi Bırak',
    'save': 'KAYDET',
    'change_photo': 'Fotoğrafı değiştir',
    'photo_failed': 'Fotoğraf yüklenemedi.',
    'saved_ok': 'Kaydedildi.',
    'block': 'Engelle',
    'unblock': 'Engeli kaldır',
    'blocked': 'Engellendi',
    'profile_load_failed': 'Profil yüklenemedi.',

    'your_rank': 'Senin Sıran:',
    'points': 'Puan',
    'no_one_yet': 'Henüz kimse puan kazanmadı.',
    'rank_failed': 'Sıralama yüklenemedi.',
    'rank_unknown': 'Sıran hesaplanamadı.',

    'settings': 'Ayarlar',
    'language': 'Dil',
    'about': 'Hakkında',
    'version': 'Sürüm',

    'report_title': 'Neden şikâyet ediyorsun?',
    'report_spam': 'Spam veya reklam',
    'report_hate': 'Nefret söylemi',
    'report_violence': 'Şiddet',
    'report_sexual': 'Cinsel içerik',
    'report_other': 'Diğer',
    'report_sent': 'Şikâyetin alındı, teşekkürler.',

    'done': 'Bitti',
    'tab_quotes': 'Sözlerim',
    'tab_saved': 'Kayıtlı',
    'tab_liked': 'Beğendiklerim',
    'no_liked_yet': 'Henüz beğendiğin söz yok.',
    'no_followers': 'Henüz takipçin yok.',
    'no_following': 'Henüz kimseyi takip etmiyorsun.',
    'section_identity': 'Kimlik',
    'section_links': 'Bağlantılar',
    'display_name': 'Ad',
    'display_name_hint': 'Görünen adın',
    'username_helper': 'Harf, rakam ve alt çizgi. 3-20 karakter.',
    'bio_hint': 'Kendinden birkaç kelime...',
    'link': 'Bağlantı',
    'max_level': 'En üst seviye',
    'to_next_level': 'puan sonra seviye atlıyorsun',
    'share_wisdom_sub': 'Yazdığın söz Keşfet akışına düşer. Beğeni aldıkça karman artar.',
    'preview_placeholder': 'Sözün burada görünecek',
    'who_can_see': 'Kimler görebilir',
    'celebrate_title': 'Paylaşıldı!',
    'celebrate_sub': 'Sözün artık Keşfet akışında. Beğeni aldıkça karman artacak.',
    'celebrate_button': 'Devam',

    'cancel': 'Vazgeç',
    'ok': 'Tamam',
    'retry': 'Tekrar dene',
  };

  // ---------------------------------------------------------------
  static const Map<String, String> _en = {
    'app_tagline': 'Discover your own truth.',

    'discover': 'Discover',
    'feed': 'Feed',
    'create': 'Create',
    'leaderboard': 'Top',
    'profile': 'Profile',

    'sign_in': 'SIGN IN',
    'sign_up': 'SIGN UP',
    'register': 'Create account',
    'email': 'Email',
    'password': 'Password',
    'username': 'Username',
    'no_account': "Don't have an account? ",
    'continue_as_guest': 'Continue without an account',
    'guest': 'Guest',
    'sign_in_required': 'You need to sign in for that.',
    'sign_in_to_continue': 'Sign in to continue',
    'sign_out': 'Sign out',

    'err_invalid_email': 'That email address is not valid.',
    'err_user_disabled': 'This account has been disabled.',
    'err_bad_credentials': 'Wrong email or password.',
    'err_too_many': 'Too many attempts. Please wait a moment.',
    'err_network': 'No internet connection.',
    'err_email_in_use': 'That email is already registered.',
    'err_weak_password': 'Password is too weak (6 characters minimum).',
    'err_generic': 'Something went wrong.',
    'err_username_taken': 'That username is taken.',
    'err_username_invalid':
        'Username must be 3-20 characters: letters, numbers, underscore.',

    'no_quotes': 'No quotes to show yet.',
    'offline_local_only': 'Offline — showing built-in quotes only.',
    'index_missing': 'Firestore index missing — built-in quotes only.',
    'permission_denied': 'No Firestore access — built-in quotes only.',
    'load_failed': 'Could not load shared quotes.',
    'swipe_hint': 'Swipe right to like',
    'like': 'LIKE',
    'pass': 'PASS',

    'tab_popular': 'Popular',
    'tab_new': 'New',
    'tab_following': 'Following',
    'following_empty':
        "You're not following anyone yet.\nFollow the authors whose words move you.",
    'feed_empty': 'Nothing here yet.',

    'saved': 'Saved',
    'unsaved': 'Removed',
    'likes': 'likes',
    'share': 'Share',
    'share_image': 'Share as image',
    'share_image_sub': 'Instagram, WhatsApp, anywhere',
    'share_text': 'Share as text',
    'share_failed': 'Could not share.',
    'report': 'Report',
    'delete': 'Delete',
    'delete_confirm': 'Delete this quote?',
    'deleted': 'Deleted',
    'copied': 'Copied',
    'copy': 'Copy',

    'share_wisdom': 'SHARE YOUR WISDOM',
    'quote_hint': 'Write the quote here...',
    'author_hint': 'Who said it?',
    'publish': 'PUBLISH',
    'published': 'Published!',
    'publish_failed': 'Could not publish',
    'vis_public': 'Public',
    'vis_followers': 'Followers only',
    'vis_private': 'Only me',
    'quote_language': 'Language of the quote',

    'edit_profile': 'Edit profile',
    'my_quotes': 'MY QUOTES',
    'my_saved': 'SAVED',
    'no_quotes_yet': "You haven't shared anything yet.",
    'no_saved_yet': "You haven't saved anything yet.",
    'user_no_quotes': 'No quotes yet.',
    'bio': 'About',
    'bio_default': 'A new mind.',
    'karma': 'Karma',
    'quotes_count': 'Quotes',
    'followers': 'Followers',
    'following': 'Following',
    'follow': 'Follow',
    'unfollow': 'Unfollow',
    'save': 'SAVE',
    'change_photo': 'Change photo',
    'photo_failed': 'Could not upload photo.',
    'saved_ok': 'Saved.',
    'block': 'Block',
    'unblock': 'Unblock',
    'blocked': 'Blocked',
    'profile_load_failed': 'Could not load profile.',

    'your_rank': 'Your rank:',
    'points': 'pts',
    'no_one_yet': 'No one has earned points yet.',
    'rank_failed': 'Could not load the leaderboard.',
    'rank_unknown': 'Could not work out your rank.',

    'settings': 'Settings',
    'language': 'Language',
    'about': 'About',
    'version': 'Version',

    'report_title': 'Why are you reporting this?',
    'report_spam': 'Spam or advertising',
    'report_hate': 'Hate speech',
    'report_violence': 'Violence',
    'report_sexual': 'Sexual content',
    'report_other': 'Other',
    'report_sent': 'Thanks — your report has been received.',

    'done': 'Done',
    'tab_quotes': 'Quotes',
    'tab_saved': 'Saved',
    'tab_liked': 'Liked',
    'no_liked_yet': "You haven't liked anything yet.",
    'no_followers': 'No followers yet.',
    'no_following': "You're not following anyone yet.",
    'section_identity': 'Identity',
    'section_links': 'Links',
    'display_name': 'Name',
    'display_name_hint': 'Your display name',
    'username_helper': 'Letters, numbers and underscore. 3-20 characters.',
    'bio_hint': 'A few words about you...',
    'link': 'Link',
    'max_level': 'Max level',
    'to_next_level': 'points to the next level',
    'share_wisdom_sub': 'Your words go into the Discover feed. Every like raises your karma.',
    'preview_placeholder': 'Your quote will appear here',
    'who_can_see': 'Who can see this',
    'celebrate_title': 'Published!',
    'celebrate_sub': "Your words are live. Every like raises your karma.",
    'celebrate_button': 'Continue',

    'cancel': 'Cancel',
    'ok': 'OK',
    'retry': 'Try again',
  };
}

extension L10nContext on BuildContext {
  String t(String key) => L.of(this).t(key);
  String tn(String key, Map<String, String> vars) => L.of(this).tn(key, vars);
  String get lang => SettingsService.instance.language.value;
}
