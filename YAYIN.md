# Memento — yayın rehberi

Mac gerekmez. iPhone sürümü Codemagic'te (bulutta macOS) derlenir; Android sürümü kendi bilgisayarında ya da yine Codemagic'te.

## 0. Depoda ne var, ne yok

| Var | Yok (gizli, depoya konmaz) |
|---|---|
| Tüm kaynak kod, Firebase kuralları ve indeksleri | Android imza anahtarı `memento-upload.jks` ve şifreleri (`android/key.properties`) |
| `codemagic.yaml` (iOS → TestFlight, Android → AAB) | App Store Connect API anahtarı (`.p8`) |
| Simgeler ve mağaza metinleri: `store/` | Gemini API anahtarı (reklam seslendirmesi için) |
| Gizlilik / koşullar sayfaları: `web/privacy*.html`, `web/terms*.html` | |
| Kural testleri: `test/firestore_rules/` | |
| Reklam videolarının kaynakları: `marketing/` | |

> **İmza anahtarını yedekle.** `C:\dev\keys\memento-upload.jks` ve şifresi kaybolursa Google Play'deki uygulama ancak Google destekle anahtar sıfırlanarak güncellenebilir. Dosyayı ve şifreyi bir parola yöneticisine ya da şifreli bir buluta koy. Herkese açık depoya **koyma**.

## 1. iPhone — TestFlight

### 1.1 Apple Developer → Certificates, Identifiers & Profiles → Identifiers
1. **App Groups** → `group.com.bakibacaci.memento`
2. **App IDs → App** → `com.bakibacaci.memento`
   - Capabilities: **App Groups** (yukarıdaki grup), **Sign in with Apple**, **Push Notifications** (ileride)
3. **App IDs → App** → `com.bakibacaci.memento.MementoWidget`
   - Capabilities: **App Groups** (aynı grup)

### 1.2 App Store Connect
1. **Uygulamalar → + → Yeni Uygulama**: iOS, ad `Memento: Günün Sözü` (alınmışsa benzeri), dil Türkçe, Bundle ID `com.bakibacaci.memento`, SKU `memento`.
2. **Kullanıcılar ve Erişim → Entegrasyonlar → App Store Connect API → +**: ad `codemagic`, erişim **App Manager**. `.p8` dosyasını indir (bir kez indirilebilir), **Issuer ID** ve **Key ID**'yi not et.

### 1.3 Codemagic
1. codemagic.io → GitHub ile giriş → **Add application** → `BakiBacaci/memento` → yapılandırma: `codemagic.yaml`.
2. **Teams → Integrations → App Store Connect → Add key**: adı tam olarak **`memento_asc`**, Issuer ID, Key ID, `.p8` dosyası.
3. Uygulamada **Start new build** → dal `gelistirme` (ya da `main`) → iş akışı **iOS → TestFlight**.
   - İlk derleme ~20 dk. Bitince App Store Connect'te işlenmesi 10–30 dk daha sürer.
   - Ücretsiz plan: ayda 500 dk macOS.

### 1.4 Kendi telefonuna kur
App Store Connect → TestFlight → **İç Test** grubu oluştur → kendini ekle → iPhone'a **TestFlight** uygulamasını kur → Memento'yu yükle. İç testte Apple incelemesi yoktur.

### 1.5 App Store'a göndermeden önce (zorunlu)
- [ ] **Apple ile giriş** ekle (Google ile giriş olduğu için Guideline 4.8). Firebase Console → Authentication → Sign-in method → Apple'ı aç.
- [ ] Gizlilik ve koşullar sayfaları yayında (aşağıda, 3. bölüm).
- [ ] Gerçek iPhone ekran görüntüleri (`store/MAGAZA.md`).
- [ ] Uygulama gizliliği formu (`store/MAGAZA.md` sonunda).
- [ ] Firebase App Check: App Attest'i Firebase Console → App Check'te kaydet (zorunlu kılmadan önce).

## 2. Android — Google Play

### 2.1 İmzalı paket (AAB)
Kendi bilgisayarında (anahtar `C:\dev\keys`'te):
```
flutter build appbundle --release
```
Çıktı: `build/app/outputs/bundle/release/app-release.aab`

Ya da Codemagic'te: **Teams → Code signing identities → Android keystores** → `memento-upload.jks` yükle, referans adı **`memento_upload`** → iş akışı **Android → AAB**.

### 2.2 Play Console
1. **Uygulama oluştur** → ad, Türkçe, Uygulama, Ücretsiz.
2. **Test → Dahili test** → yeni sürüm → AAB'yi yükle → kendini test kullanıcısı olarak ekle.
3. **Play App Signing** açık gelir. **Uygulama bütünlüğü → Uygulama imzalama anahtarı sertifikası**ndaki **SHA-1 ve SHA-256**'yı Firebase'e ekle (yoksa Play'den indirilen sürümde Google ile giriş çalışmaz):
   ```
   firebase apps:android:sha:create 1:906107187459:android:c15e6c94ca18c0e7c23936 <SHA> --project memento-60cce
   ```
   ya da Firebase Console → Proje ayarları → Android uygulaması → Parmak izi ekle.
4. Mağaza girişi, içerik derecelendirmesi, veri güvenliği formu: `store/MAGAZA.md`.

## 3. Gizlilik ve koşullar sayfaları (GitHub Pages)

`gh-pages` dalı web sürümünü ve hukuki sayfaları yayınlar:
- https://bakibacaci.github.io/memento/privacy.html
- https://bakibacaci.github.io/memento/terms.html

GitHub → depo → **Settings → Pages** → Source: **Deploy from a branch** → `gh-pages` / root. Web sürümünü güncellemek için:
```
flutter build web --release --base-href /memento/
```
çıktıyı (`build/web`) `gh-pages` dalına koy.

## 4. Firebase

- Kuralları yayınla: `firebase deploy --only firestore:rules,firestore:indexes,storage --project memento-60cce`
- Kuralları test et (Java 21 + Node gerekir):
  ```
  cd test/firestore_rules && npm install && npm test
  ```
- Konsolda yapılacaklar: Proje ayarları → Herkese açık ad **Memento** ve destek e-postası; Authentication → Şablonlar → dil **Türkçe**; Authentication → Ayarlar → Yetkili alan adları → `bakibacaci.github.io`.

## 5. Sürüm numarası

`pubspec.yaml` → `version: 1.0.0+1`. Her mağaza yüklemesinde `+` sonrası (build numarası) artmalı. Codemagic iOS'ta bunu TestFlight'taki son numaraya bakarak kendisi artırır.

## 6. Mağazaya çıktıktan sonra

`lib/widgets/share_card.dart` → `QuoteShareSheet.storeLink` alanına mağaza bağlantısını yaz; paylaşım görselleri ve metinleri bağlantıyı otomatik taşır.
