# Memento — 1. aşama değişikliklerini uygulama

Bu paket `lib/` klasörünün tamamını, Firestore kurallarını ve güncellenmiş
`pubspec.yaml` / `firebase.json` dosyalarını içeriyor.

## 1. Yedek al

```bash
cd memento
git checkout -b refactor/temizlik
```

## 2. Eskiyi sil, yeniyi koy

Bu paketteki dosyalar eski `lib/` klasörünün **yerine** geçiyor —
üstüne kopyalamak yetmez, çünkü silinen 4 dosya kalırsa
`Quote` ve `ProfilePage` sınıfları iki kez tanımlanmış olur ve derleme patlar.

```bash
# Silinecekler
rm -rf lib assets/images assets/sounds

# Sonra bu paketteki lib/ klasörünü, firestore.rules,
# firestore.indexes.json, pubspec.yaml ve firebase.json dosyalarını
# proje köküne kopyala.
```

Windows PowerShell'de:

```powershell
Remove-Item -Recurse -Force lib, assets\images, assets\sounds
# paketi proje köküne çıkar
```

> `lib/firebase_options.dart` pakete dahil — sendeki dosyanın aynısı,
> API anahtarların değişmedi.

## 3. Bağımlılıkları güncelle

```bash
flutter pub get
flutter analyze
```

`flutter analyze` temiz çıkmalı. Burada bir hata görürsen bana yaz —
bu ortamda Flutter SDK'sı indirilemediği için kodu derleyerek test edemedim,
elle doğruladım.

## 4. Çalıştır

```bash
flutter run
```

Keşfet sayfası artık açılmalı. Eskiden sonsuz dönen yükleme çarkında
kalıyordu.

## 5. Firestore kurallarını deploy et — BUNU ATLAMA

Şu an veritabanın büyük ihtimalle test modunda, yani **herkes tüm verini
okuyup silebilir.** Kurallar deploy edilmeden uygulamayı yayınlama.

```bash
npm install -g firebase-tools     # kurulu değilse
firebase login
firebase deploy --only firestore:rules,firestore:indexes
```

İndeksler birkaç dakikada hazır olur. Hazır olmadan Keşfet sayfası
"failed-precondition" hatası verebilir; Firebase konsolunda
Firestore → Indexes sekmesinden durumu görebilirsin.

---

## Bu aşamada ne değişti

**Düzeltilen kritik hata.** `SwipePage._loadQuotes()` içinde, aynı isimde
iç içe bir fonksiyon tanımlanmıştı:

```dart
Future<void> _loadQuotes() async {Future<void> _loadQuotes() async {
  ...
}
}
```

Dıştaki fonksiyonun gövdesi sadece içtekini *tanımlıyor*, hiç *çağırmıyordu*.
Sonuç: `_isLoading` hiçbir zaman `false` olmuyor, Keşfet sayfası sonsuza
kadar yükleniyor. Derleyici bunu hata olarak görmez, sadece "kullanılmayan
fonksiyon" uyarısı verir — o yüzden gözden kaçmış.

**Silinen dosyalar.** `auth_service.dart`, `daily_oracle_page.dart`,
`leaderboard_page.dart`, `profile_page.dart` — dördü de hiçbir yerden
import edilmiyordu. `profile_page.dart` ikinci bir `Quote` sınıfı, ikinci
bir `ProfilePage` tanımlıyordu. Google ile giriş kodu (`auth_service.dart`)
de buradaydı ve hiç bağlanmamıştı; o özelliği yaparken temiz bir şekilde
geri ekleriz.

**Yeni klasör yapısı.**

```
lib/
  main.dart              — başlangıç + oturum kapısı
  theme.dart             — renkler ve tema, tek kaynak
  models/quote.dart      — Quote modeli + gizlilik sabitleri
  services/              — Firestore işleri (sayfalar artık Firestore'u
                           doğrudan çağırmıyor)
  pages/                 — her ekran kendi dosyasında
  widgets/quote_card.dart
```

**Diğer düzeltmeler.**

| Ne | Neden |
|---|---|
| Oturum yönlendirmesi tek bir `_AuthGate`'e taşındı | Eskiden her sayfa kendi `pushReplacement`'ını yapıyordu; çıkış yapınca ekranda kalınabiliyordu |
| Beğeni artık `quotes/{id}/likes/{uid}` alt koleksiyonuna yazılıyor | Aynı kişi aynı sözü sınırsız beğenip karma kasabiliyordu |
| Kendi sözünü beğenmek karma vermiyor | Aynı sebep |
| Sıralama `count()` ile hesaplanıyor | Eskiden karması senden yüksek **tüm** kullanıcı dökümanları çekiliyordu: 1000 kullanıcı = 1000 okuma. Şimdi 1 okuma |
| Firestore dinleyicisi `dispose()`'da iptal ediliyor | Sayfa kapandıktan sonra `setState` çağrılıyordu |
| Yeni sözler listenin **sonuna** ekleniyor | Başa eklemek indeksleri kaydırıyordu; kaydırdığın sözle beğenilen söz farklı olabiliyordu |
| Boş liste kontrolü eklendi | `CardSwiper`, `cardsCount: 0` ile çöküyor |
| Firebase hata kodları Türkçeleştirildi | Kullanıcı `[firebase_auth/invalid-credential]` görüyordu |
| "TEST: Bot Ekle (Gizli)" butonu silindi | Üretimde duruyordu, tıklayan 50 sahte kullanıcı ekliyordu |
| 6.3 MB asset silindi | `zeno.png`, `seneca.png`, `epictetus.png`, `swipe.mp3` — hiçbiri kodda kullanılmıyordu |
| 6 bağımlılık kaldırıldı | `lottie`, `sensors_plus`, `audioplayers`, `google_sign_in`, `image_picker`, `firebase_storage` — hiçbiri çağrılmıyordu. Profil fotoğrafı ve Google girişi yapılırken gerekenleri geri ekleyeceğiz |
| `pubspec.yaml` adı `Memento` → `memento` | Dart paket adları küçük harf olmalı |

---

## Bilinen açık: karma güvenliği

`firestore.rules` içinde bir kullanıcının `karma` alanını başkasının
+1 artırmasına izin verdim — beğeni bunu gerektiriyor. Kötü niyetli
biri bu çağrıyı döngüye alıp karma şişirebilir.

Kalıcı çözüm, karma artışını bir Cloud Function'a taşımak: istemci
sadece `likes/{uid}` dökümanını yazar, sayaçları fonksiyon günceller,
kurallarda `karma` yazımı tamamen kapatılır. Cloud Functions için
Firebase'de **Blaze** planına geçmek gerekiyor — kredi kartı istiyor ama
ücretsiz kota aynı kalıyor, bu ölçekte fatura gelmez.

Bunu yapalım mı, karar senin.

---

## Sırada ne var

1. Kaydedilenleri Firestore'a taşımak (`SavedService`'in gövdesi değişecek,
   sayfalar hiç değişmeyecek — o yüzden ayrı bir servise koydum)
2. Takip sistemi
3. Profil fotoğrafı + bio
4. Kilit ekranı widget'ı (iOS + Android)
5. Web sürümünü yeniden yayınlamak

Ayrıca `ios/Runner/GoogleService-Info.plist` eksik — iOS'ta çalıştırmadan
önce `flutterfire configure` çalıştırman lazım.
