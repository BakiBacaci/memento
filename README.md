# Memento

Sözlerin evi: her gün kişiye özel bir söz, kaydırarak keşfet, kendi sözünü yaz, Memento defterine işle.

Flutter + Firebase (Authentication, Firestore, App Check). Android, iOS ve web.

## Klasörler

| Yol | Ne |
|---|---|
| `lib/` | Uygulama kodu (sayfalar, servisler, bileşenler) |
| `assets/quotes.json` | Hazır sözler; `daily: true` olanlar kişiye özel günün sözü havuzu |
| `firestore.rules`, `firestore.indexes.json`, `storage.rules` | Firebase güvenlik kuralları |
| `test/firestore_rules/` | Kural testleri (emülatörde, 42 senaryo) |
| `android/` | Android; ana ekran widget'ları `MementoWidgetProvider.kt` |
| `ios/` | iOS; `MementoWidget/` (WidgetKit), `scripts/add_widget_target.rb` |
| `codemagic.yaml` | iOS → TestFlight ve Android → AAB derlemeleri |
| `web/` | Web sürümü + gizlilik / kullanım koşulları sayfaları |
| `store/` | Mağaza simgeleri, metinler, ekran görüntüsü ön izlemeleri |
| `marketing/` | Reklam videolarının kaynakları ve araçları, maskot taslakları |
| `scripts/` | Windows yardımcı betikleri (kural yayınlama, telefona kurulum) |

## Çalıştırma

```
flutter pub get
flutter run
```

## Yayın

Adım adım: [YAYIN.md](YAYIN.md) — TestFlight, Google Play, GitHub Pages, Firebase.
