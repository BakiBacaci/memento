# Memento — iOS yayını: durum ve devam notu

> Bu dosya, işi başka bir bilgisayardaki kişinin ya da AI agent'ın kaldığı yerden sürdürebilmesi için yazıldı.
> Son güncelleme: 21 Kasım 2026.
> **Gizli bilgi yok:** API anahtarları, şifreler ve `.p8` dosyaları bu depoda değil; Codemagic ve App Store Connect'te duruyor.

## Kısa özet

- iOS uygulaması **Codemagic'te derleniyor** ve **App Store Connect / TestFlight'a otomatik yükleniyor.** Son başarılı derleme **2611211409**.
- App Store sayfası büyük ölçüde dolu. **Henüz incelemeye gönderilmedi.** Eksikler aşağıda, "Kalan işler" bölümünde.
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

## Kalan işler (sırayla)

1. **Telefon numarası:** Hem sürüm sayfası → App Review Information → Contact Information, hem TestFlight → Test Information → Beta App Review Information. Ad ve e-posta girilmeye hazır; Apple telefonsuz kaydetmiyor.
2. **Demo hesap:** Uygulamada bir test hesabı aç (e-posta + şifre). İçinde birkaç söz olsun. Bilgileri iki yere yaz:
   - Sürüm sayfası → Sign-In Information ("Sign-in required" işaretli)
   - TestFlight → Test Information → Sign-In Information
3. **Baki'nin test etmesi:** TestFlight → Testciler → Builds → **+** → 2611211409 → test bilgilerini doldur → beta incelemesine gönder. Onaylanınca (genelde 1 gün içinde) iki Baki hesabına davet e-postası gider.
4. **App Store incelemesi:** Sürüm sayfası → **Add for Review** → gönder. Otomatik yayın seçili; onaydan sonra kendiliğinden yayına çıkar.
5. **Mağazaya çıkınca:** `lib/widgets/share_card.dart` → `QuoteShareSheet.storeLink` alanına App Store bağlantısını yaz.
6. İsteğe bağlı: Akış ve Zirve ekranlarındaki test içeriklerini ("deneme", "aaaa" vb.) Firestore'dan temizle. İnceleme sırasında kötü görünür.

## Dikkat edilecekler

- **Derleme ayarlarına sertifika veya profil SİLEN bir adım eklemeyin.** Bir ara eklenen "geçici sertifikayı iptal et" adımı, `--certificate-key` filtresi çalışmadığı için hesaptaki diğer dağıtım sertifikalarını da sildi. Adım kaldırıldı.
- Her derleme Apple'da yeni bir dağıtım sertifikası oluşturuyor. Apple'ın sınırı az (yaklaşık 2–3). Sınıra yaklaşılırsa doğru çözüm şu: tek bir sertifika anahtarı üretip Codemagic'te gizli ortam değişkeni (`CERTIFICATE_PRIVATE_KEY`) olarak saklamak ve `fetch-signing-files`'a `--certificate-key=@env:CERTIFICATE_PRIVATE_KEY` vermek. Böylece hep aynı sertifika kullanılır. Bu değişkeni hesap sahibi eklemeli.
- Apple uyarısı (ITMS-90725): Nisan 2027'den itibaren iOS 27 SDK (Xcode 27) zorunlu olacak. `codemagic.yaml` `xcode: latest` kullandığı için kendiliğinden geçer.
- iPad desteği açık (`TARGETED_DEVICE_FAMILY = 1,2`). Bu yüzden App Store iPad ekran görüntüsü de istiyor; yüklendi.

## Yeni derleme nasıl alınır

1. Kod değişikliğini `main` dalına gönder.
2. Codemagic → memento → **Start new build** → dal `main`, iş akışı **iOS → TestFlight**.
3. 8–10 dakikada TestFlight'a yüklenir. Build numarası tarih ve saatten otomatik üretilir.
