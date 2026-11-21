# Memento — iOS yayını: durum ve devam notu

> Bu dosya, işi başka bir bilgisayardaki kişinin ya da AI agent'ın kaldığı yerden sürdürebilmesi için yazıldı.
> Son güncelleme: 21 Kasım 2026.
> **Gizli bilgi yok:** API anahtarları, şifreler ve `.p8` dosyaları bu depoda değil; Codemagic ve App Store Connect'te duruyor.

## Kısa özet

- iOS uygulaması **Codemagic'te derleniyor** ve **App Store Connect / TestFlight'a otomatik yükleniyor.** Son başarılı derleme **2611211409**.
- **21 Kasım 2026, 18:12: sürüm 1.0 (derleme 2611211409) App Store incelemesine gönderildi.** Durum: *Waiting for Review*. Onaylanınca otomatik yayınlanacak.
- **TestFlight beta incelemesine de gönderildi** (dış grup *Testciler*, Baki'nin iki hesabı). Apple onaylayınca davet e-postası gidecek.
- Apple Developer hesabı Esad'ın (Team ID `2PLFDNRQMR`). Uygulama orada **"Memento: Günün Sözü"** adıyla kayıtlı (Apple ID `6837676805`).

## Hesaplar ve nerede ne var

| Ne | Nerede |
|---|---|
| Kaynak kod | GitHub `BakiBacaci/memento`, dal `main` |
| iOS derleme | Codemagic (BakiBacaci hesabı) → uygulama `memento` → iş akışı **iOS → TestFlight**. Depo herkese açık HTTPS adresiyle eklendi, bu yüzden derleme **elle** başlatılıyor ("Start new build", dal `main`). |
| App Store Connect API anahtarı | Codemagic → Settings → Integrations → Developer Portal → adı **`memento_asc`** (Admin yetkili anahtar). `codemagic.yaml` bu adı kullanıyor. |
| Bundle ID'ler | `com.bakibacaci.memento` (App Groups + Sign in with Apple), `com.bakibacaci.memento.MementoWidget` (App Groups). App Group: `group.com.bakibacaci.memento` |
| Firebase | Proje `memento-60cce`. Authentication'da **Apple ile giriş açık**. |
| Gizlilik / Koşullar | https://bakibacaci.github.io/memento/privacy.html · https://bakibacaci.github.io/memento/terms.html |

## Bu oturumda yapılanlar

### Kod (hepsi `main` dalında)
- **Apple ile giriş** eklendi (`lib/services/account_service.dart`, `lib/pages/login_page.dart`). Apple hesabı silinirken Apple belirteci de iptal ediliyor (Apple'ın kuralı).
- **Kural 1.2 (kullanıcı içeriği):**
  - `lib/utils/content_filter.dart`: söz paylaşılmadan önce temel bir küfür filtresi. Testi: `test/content_filter_test.dart`.
  - Giriş ekranında Google/Apple düğmelerinin altında "Devam ederek Kullanım Koşulları ve Gizlilik Politikası'nı kabul edersin" yazısı.
- **iOS derleme düzeltmeleri** (`codemagic.yaml`, `ios/scripts/add_widget_target.rb`, `ios/MementoWidget/Info.plist`):
  - Yeni Flutter Swift Package Manager kullanıyor; `Podfile` yoksa CocoaPods adımı atlanıyor.
  - Widget'ın `Widget.xcconfig` yolu düzeltildi (`Flutter/Widget.xcconfig`).
  - Widget gömme fazı "Thin Binary"den önceye alındı (Xcode döngü hatası).
  - Widget Info.plist'e `CFBundleIdentifier` ve zorunlu anahtarlar eklendi.
  - İmzalama: her derlemede yeni bir anahtarla `app-store-connect fetch-signing-files --create` çalışıyor, ardından `xcode-project use-profiles` ve `flutter build ipa`.

### App Store Connect
- Mağaza metinleri (TR): açıklama, tanıtım metni, anahtar kelimeler, alt başlık, destek adresi, telif.
- Ekran görüntüleri yüklendi: iPhone (1206×2622, kaynakları `store/app-store-6.9/`) ve iPad 13" (`store/app-store-ipad-13/`). Web sürümünden çekildi.
- Kategori: Yaşam Tarzı / Kitaplar. İçerik hakları: "gerekli haklara sahibim".
- Yaş derecelendirmesi: **13+**.
- Uygulama gizliliği yayınlandı: ad, e-posta, fotoğraf, kullanıcı içeriği ve kullanıcı kimliği toplanıyor; hepsi uygulama işlevi için, kimlikle ilişkili, izleme yok.
- Fiyat: ücretsiz. 174 ülke; Çin anakarası hariç, çünkü orada ICP kaydı gerekiyor.
- İnceleme notları (İngilizce) yazıldı. Sürüm sayfasında derleme **2611211409** seçili.
- TestFlight:
  - İç grup **Ekip** (hesap sahibi).
  - Dış grup **Testciler**: Baki'nin iki hesabı ekli. Gruba **henüz derleme eklenmedi**; Apple'ın beta incelemesi telefon ve demo hesap istiyor.

## Kalan işler

1. **Apple'ın cevabını bekle** (genelde 24–48 saat). Ret gelirse e-postada sebep yazar; App Store Connect → App Review'da yanıtla ya da düzeltip yeni derleme gönder.
2. **Mağazaya çıkınca:** `lib/widgets/share_card.dart` → `QuoteShareSheet.storeLink` alanına App Store bağlantısını yaz (sonraki güncellemeyle çıkar).
3. Akış ve Zirve ekranlarındaki test içeriklerini ("deneme", "aaaa" vb.) Firestore'dan temizle; mağazadaki kullanıcılar da görecek.
4. Baki'nin bilgisayarındaki yeni özellikler ve yeni ikon henüz GitHub'da değil. Aşağıdaki "Güncelleme nasıl yayınlanır" adımlarıyla 1.0.1 olarak çıkarılacak.

## Dikkat edilecekler

- **Derleme ayarlarına sertifika veya profil SİLEN bir adım eklemeyin.** Bir ara eklenen "geçici sertifikayı iptal et" adımı, `--certificate-key` filtresi çalışmadığı için hesaptaki diğer dağıtım sertifikalarını da sildi. Adım kaldırıldı.
- Her derleme Apple'da yeni bir dağıtım sertifikası oluşturuyor. Apple'ın sınırı az (yaklaşık 2–3). Sınıra yaklaşılırsa doğru çözüm şu: tek bir sertifika anahtarı üretip Codemagic'te gizli ortam değişkeni (`CERTIFICATE_PRIVATE_KEY`) olarak saklamak ve `fetch-signing-files`'a `--certificate-key=@env:CERTIFICATE_PRIVATE_KEY` vermek. Böylece hep aynı sertifika kullanılır. Bu değişkeni hesap sahibi eklemeli.
- Apple uyarısı (ITMS-90725): Nisan 2027'den itibaren iOS 27 SDK (Xcode 27) zorunlu olacak. `codemagic.yaml` `xcode: latest` kullandığı için kendiliğinden geçer.
- iPad desteği açık (`TARGETED_DEVICE_FAMILY = 1,2`). Bu yüzden App Store iPad ekran görüntüsü de istiyor; yüklendi.

## Yeni derleme nasıl alınır

1. Kod değişikliğini `main` dalına gönder.
2. Codemagic → memento → **Start new build** → dal `main`, iş akışı **iOS → TestFlight**.
3. 8–10 dakikada TestFlight'a yüklenir. Build numarası tarih ve saatten otomatik üretilir.

## Güncelleme nasıl yayınlanır (yeni özellik, yeni ikon)

1. **Kodu `main` dalına gönder.** Yeni özellikler ve ikon GitHub'a gelmeden hiçbir şey derlenemez.
2. **İkon değiştiyse:**
   - iOS ikonları `ios/Runner/Assets.xcassets/AppIcon.appiconset/` içinde. Hepsi yeni ikonla yeniden üretilmeli (ör. `flutter_launcher_icons` paketiyle).
   - 1024×1024 App Store ikonu **şeffaflık (alfa kanalı) içermemeli**, yoksa Apple yüklemeyi reddeder.
   - `store/app-store-1024.png` de güncellenmeli.
   - Widget kendi ikonunu kullanmaz, ana uygulamanınkini kullanır.
3. **Sürüm numarasını artır:** `pubspec.yaml` → `version: 1.0.1+1`. Nokta öncesi kısım App Store'daki sürüm adı; `+` sonrasını Codemagic zaten tarih ve saatten üretiyor.
4. **Derle:** Codemagic → memento → Start new build → `main` → iOS → TestFlight. Yaklaşık 10 dakika sonra TestFlight'a düşer. İç gruptaki (Ekip) testçiler hemen görür; dış gruba (Testciler) eklemek için grupta Builds → + ile ekleyip beta incelemesine gönder.
5. **App Store'da yeni sürüm:** 1.0 onaylandıktan sonra App Store Connect → uygulama → sol üstte **+ (Add Version)** → `1.0.1`.
   - "What's New" metnini yaz, yeni derlemeyi seç.
   - Ekran görüntüleri değiştiyse yenilerini yükle.
   - **Add for Review**.
6. Not: 1.0 hâlâ incelemedeyken acil bir değişiklik gerekirse, sürüm sayfasında incelemeden geri çekip (*Remove from Review* / *Cancel Submission*) yeni derlemeyi seçip tekrar gönderebilirsin.
