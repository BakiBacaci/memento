# Memento'yu iPhone'a (TestFlight / App Store) yükleme

Bu rehber Apple Developer hesabı olan kişi içindir. iPhone uygulaması hazır bir dosya olarak gönderilemez: Apple, uygulamanın **yükleyen hesabın kendi sertifikasıyla** imzalanmasını istiyor. Bu yüzden son derleme senin hesabınla yapılmalı. İki yol var; **Mac yoksa 1. yol**.

Kod: https://github.com/BakiBacaci/memento (dal: `main`)

---

## 1. yol — Mac olmadan (Codemagic, ~30 dk)

### a) Apple Developer → Certificates, Identifiers & Profiles → Identifiers
1. **App Groups → +** → `group.com.bakibacaci.memento`
2. **App IDs → App → +** → Bundle ID `com.bakibacaci.memento`
   - **App Groups** işaretle → yukarıdaki grubu seç
   - **Sign in with Apple** işaretle
3. **App IDs → App → +** → Bundle ID `com.bakibacaci.memento.MementoWidget`
   - **App Groups** işaretle → aynı grubu seç

### b) App Store Connect
1. **Uygulamalar → + → Yeni Uygulama**
   - Platform: iOS · Ad: `Memento: Günün Sözü` (alınmışsa benzeri) · Dil: Türkçe
   - Bundle ID: `com.bakibacaci.memento` · SKU: `memento`
2. **Kullanıcılar ve Erişim → Entegrasyonlar → App Store Connect API → +**
   - Ad: `codemagic` · Erişim: **App Manager**
   - `.p8` dosyasını indir (yalnızca bir kez indirilebilir). **Issuer ID** ve **Key ID**'yi not et.

### c) Codemagic (codemagic.io, ücretsiz)
1. GitHub ile giriş yap. Depo başka hesaptaysa: **Add application → Git repository URL** → `https://github.com/BakiBacaci/memento.git` (herkese açık).
2. **Teams → Integrations → App Store Connect → Add key**
   - Adı tam olarak: **`memento_asc`**
   - Issuer ID, Key ID ve `.p8` dosyası
3. Uygulama sayfası → **Start new build** → dal **`main`** → iş akışı **iOS → TestFlight** → Start.
   - ~20 dk sürer. Biter bitmez otomatik olarak TestFlight'a yüklenir.

### d) TestFlight
App Store Connect → uygulama → **TestFlight** → derleme "İşleniyor"dan çıkınca (10–30 dk):
- **İç Test → +** → grup oluştur → test edecek kişileri ekle (e-postaları App Store Connect kullanıcısı olmalı) ya da
- **Dış Test** → herkese açık bağlantı (ilk sürüm kısa bir Apple incelemesinden geçer).

---

## 2. yol — Mac varsa (Xcode)

```
git clone https://github.com/BakiBacaci/memento.git && cd memento
flutter pub get
gem install xcodeproj && (cd ios && ruby scripts/add_widget_target.rb)
cd ios && pod install && open Runner.xcworkspace
```
Xcode'da:
1. **Runner** ve **MementoWidget** hedeflerinde → Signing & Capabilities → **Team**: kendi hesabın, "Automatically manage signing" açık.
2. Üstten cihaz: **Any iOS Device (arm64)** → **Product → Archive** → **Distribute App → App Store Connect → Upload**.

(App Store Connect'te uygulama kaydı 1. yolun b-1 adımındaki gibi önceden açılmış olmalı.)

---

## Sık çıkan sorunlar

| Hata | Çözüm |
|---|---|
| `No profiles for 'com.bakibacaci.memento'` | Identifiers adımı eksik; a) bölümünü tamamla. |
| `App Group ... not found` | App Group oluşturulup iki App ID'ye de bağlanmalı. |
| `Invalid bundle / already exists` | Bundle ID başka bir hesapta kullanılıyorsa farklı bir ID seç ve bize haber ver, koddaki ID'yi değiştirelim. |
| Codemagic `memento_asc not found` | Entegrasyon adı tam olarak `memento_asc` olmalı. |

## App Store'da yayınlamadan önce (TestFlight için gerekmez)
- **Apple ile giriş** eklenecek (Google ile giriş olduğu için Apple zorunlu tutuyor).
- Gizlilik: https://bakibacaci.github.io/memento/privacy.html · Koşullar: https://bakibacaci.github.io/memento/terms.html
- Mağaza metinleri ve simge: depodaki `store/` klasörü.
