# Web Build Çözümü - Isar Generated Dosyalar

## Sorun
Isar generator, web platformu için `.g.dart` dosyalarını oluşturmuyor çünkü Isar web'de desteklenmiyor. Ancak bu dosyalar derleme için gerekli.

## Çözüm
Web build için minimal stub dosyalar oluşturuldu:

- `lib/features/word_match/models/word_pair.g.dart`
- `lib/features/word_match/models/word_set.g.dart`
- `lib/features/dictionary/models/dict_entry.g.dart`

Bu stub dosyalar:
- Schema type alias'larını tanımlar (`WordPairSchema`, `WordSetSchema`, `DictEntrySchema`)
- Web'de Isar kullanılmadığı için gerçek implementasyon içermez
- Sadece derlemenin geçmesi için yeterlidir

## Kullanım

### Development/Debug (Local Test) İçin:
```powershell
# Chrome'da debug modunda çalıştırma (local test)
flutter run -d chrome
```

### Production Web Build İçin:
```powershell
# 1. Production web build oluştur
flutter build web --release

# 2. Build çıktısı: build/web klasöründe
# 3. Firebase Hosting'e deploy için:
firebase deploy --only hosting
```

### Mobil/Desktop Build İçin:
```powershell
# 1. Gerçek Isar dosyalarını oluştur
dart run build_runner build --delete-conflicting-outputs

# 2. Eğer web build yapacaksanız, integer overflow'u düzelt
.\fix_web_build.ps1

# 3. Build yap
flutter build web --release  # Web için
flutter run  # Mobil için (Android/iOS)
```

## Notlar

- **Web'de Isar kullanılmaz**: Uygulama web'de `localStorage` kullanır, Isar sadece mobil/desktop için kullanılır
- **Stub dosyalar**: Web build/run için yeterlidir, gerçek Isar fonksiyonları çağrılmaz
- **Mobil build**: Gerçek Isar dosyaları `build_runner` ile oluşturulmalıdır
- **Terminoloji**: 
  - `flutter run -d chrome` → Development/debug modunda local test
  - `flutter build web --release` → Production web build

## Sorun Giderme

Eğer hala derleme hatası alıyorsanız:

1. Stub dosyaların var olduğunu kontrol edin
2. `flutter clean` çalıştırın
3. `flutter pub get` çalıştırın
4. Tekrar build deneyin
