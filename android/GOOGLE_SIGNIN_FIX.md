# Android APK'da Google Sign-In Hatası Çözümü

## Hata
```
Platform Exception(sign_in_failed, com.google.android.gms.common.api.ApiException: 10:, null, null)
```

Kod 10 = `DEVELOPER_ERROR` - Bu genellikle SHA-1 fingerprint'in Firebase Console'da kayıtlı olmamasından kaynaklanır.

## Çözüm Adımları

### 1. SHA-1 Fingerprint Alma

#### Windows (PowerShell):
```powershell
cd android
keytool -list -v -keystore "%USERPROFILE%\.android\debug.keystore" -alias androiddebugkey -storepass android -keypass android
```

#### macOS/Linux:
```bash
cd android
keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android
```

#### Gradle ile (Tüm Platformlar):
```bash
cd android
./gradlew signingReport
```

Çıktıda **SHA1** veya **SHA-1** satırını bulun. Örnek:
```
SHA1: A1:B2:C3:D4:E5:F6:...
```

### 2. Firebase Console'a SHA-1 Ekleme

1. [Firebase Console](https://console.firebase.google.com/) → Projenizi seçin
2. **⚙️ Project Settings** → **Your apps** bölümüne gidin
3. Android uygulamanızı seçin (`com.example.yunoo`)
4. **SHA certificate fingerprints** bölümüne scroll edin
5. **Add fingerprint** butonuna tıklayın
6. SHA-1 fingerprint'i yapıştırın (iki nokta üst üste formatında: `A1:B2:C3:...`)
7. **Save** butonuna tıklayın

### 3. Google Cloud Console'da OAuth Client ID Kontrolü

1. [Google Cloud Console](https://console.cloud.google.com/) → Projenizi seçin
2. **APIs & Services** → **Credentials** bölümüne gidin
3. **OAuth 2.0 Client IDs** listesinde Android client ID olup olmadığını kontrol edin
4. Eğer yoksa:
   - **+ CREATE CREDENTIALS** → **OAuth client ID**
   - **Application type**: **Android**
   - **Package name**: `com.example.yunoo`
   - **SHA-1 certificate fingerprint**: Yukarıda aldığınız SHA-1'i yapıştırın
   - **Create** butonuna tıklayın

### 4. Release Key için (Opsiyonel)

Eğer release APK build ediyorsanız, release keystore için de SHA-1 almanız gerekir:

```bash
keytool -list -v -keystore <release-keystore-path> -alias <alias-name>
```

Bu SHA-1'i de Firebase Console'a ekleyin.

### 5. APK'yı Yeniden Build Etme

SHA-1 ekledikten sonra:

```bash
flutter clean
flutter build apk --release
```

veya debug için:

```bash
flutter build apk --debug
```

### 6. Test

1. APK'yı cihaza yükleyin
2. Google Sign-In'i deneyin
3. Artık çalışmalı!

## Önemli Notlar

- **Değişikliklerin etkili olması 5-10 dakika sürebilir**
- **Debug ve Release** için farklı SHA-1'ler olabilir - her ikisini de ekleyin
- **google-services.json** dosyasının `android/app/` klasöründe olduğundan emin olun
- ProGuard kuralları güncellendi (Google Sign-In için gerekli kurallar eklendi)

## Sorun Devam Ederse

1. Firebase Console'da SHA-1'in doğru eklendiğini kontrol edin
2. Google Cloud Console'da OAuth Client ID'nin olduğunu kontrol edin
3. `google-services.json` dosyasının güncel olduğundan emin olun
4. Uygulamayı tamamen kaldırıp yeniden yükleyin
5. Birkaç dakika bekleyip tekrar deneyin (Firebase değişikliklerinin yayılması zaman alabilir)
