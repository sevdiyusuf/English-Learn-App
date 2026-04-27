# Firebase Console Uygulama Yapılandırması

## Mevcut Durum

Kodunuzda kullanılan package name: **`com.example.yunoo`**

Firebase Console'da görünen uygulamalar:
- `english.word` (Android) - package name bilinmiyor
- `tamamm (android)` - `com.example.tamamm`
- iOS ve Web uygulamaları da var

## Sorun

SHA-1'i `com.example.tamamm` uygulamasına eklediniz, ama kod `com.example.yunoo` kullanıyor. Bu uyumsuzluk Google Sign-In'in çalışmamasına neden olur.

## Çözüm Seçenekleri

### Seçenek 1: `com.example.yunoo` için SHA-1 ekleyin (ÖNERİLEN)

1. Firebase Console → Your apps bölümüne gidin
2. `com.example.yunoo` package name'li bir Android uygulaması var mı kontrol edin
3. Eğer yoksa:
   - **Add app** → **Android** seçin
   - **Android package name**: `com.example.yunoo` girin
   - **App nickname**: "yunoo" veya istediğiniz bir isim
   - **Register app** butonuna tıklayın
   - Yeni `google-services.json` dosyasını indirin ve `android/app/` klasörüne koyun
4. Bu uygulamanın **SHA certificate fingerprints** bölümüne SHA-1'i ekleyin

### Seçenek 2: ApplicationId'yi `com.example.tamamm` yapın

Eğer `com.example.tamamm` kullanmak istiyorsanız:

1. `android/app/build.gradle.kts` dosyasında:
   ```kotlin
   applicationId = "com.example.tamamm"
   ```

2. `android/app/google-services.json` dosyasını `com.example.tamamm` için yeniden indirin:
   - Firebase Console → Your apps → `tamamm (android)` uygulaması
   - `google-services.json` dosyasını indirin
   - `android/app/google-services.json` dosyasını değiştirin

3. Uygulamayı yeniden build edin:
   ```bash
   flutter clean
   flutter build apk --release
   ```

## Hangi Uygulamayı Kullanmalıyım?

**Öneri**: `com.example.yunoo` kullanın çünkü:
- Kod zaten bu package name'i kullanıyor
- `google-services.json` dosyası da `com.example.yunoo` için yapılandırılmış
- Sadece Firebase Console'da bu uygulama için SHA-1 eklemeniz yeterli

## Kontrol Listesi

- [ ] Firebase Console'da `com.example.yunoo` Android uygulaması var mı?
- [ ] SHA-1 fingerprint `com.example.yunoo` uygulamasına eklendi mi?
- [ ] Google Cloud Console'da `com.example.yunoo` için OAuth Client ID var mı?
- [ ] `google-services.json` dosyası `com.example.yunoo` için mi?
- [ ] `build.gradle.kts`'te `applicationId = "com.example.yunoo"` mi?

## Test

SHA-1 ekledikten sonra:
1. APK'yı yeniden build edin
2. Google Sign-In'i test edin
3. Hata devam ederse, Firebase Console'da doğru uygulamaya SHA-1 eklediğinizden emin olun
