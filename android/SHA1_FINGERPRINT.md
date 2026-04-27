# Android Google Sign-In SHA-1 Fingerprint Kurulumu

Android APK'da Google Sign-In hatası (kod 10: DEVELOPER_ERROR) genellikle SHA-1 fingerprint'in Firebase Console'da kayıtlı olmamasından kaynaklanır.

## SHA-1 Fingerprint Alma

### Debug Key için:
```bash
cd android
./gradlew signingReport
```

veya

```bash
keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android
```

### Release Key için:
Eğer release key kullanıyorsanız:
```bash
keytool -list -v -keystore <keystore-path> -alias <alias-name>
```

## Firebase Console'a Ekleme

1. [Firebase Console](https://console.firebase.google.com/) → Projenizi seçin
2. **Project Settings** (⚙️) → **Your apps** bölümüne gidin
3. Android uygulamanızı seçin (com.example.yunoo)
4. **SHA certificate fingerprints** bölümüne gidin
5. **Add fingerprint** butonuna tıklayın
6. SHA-1 fingerprint'i yapıştırın ve kaydedin

## Google Cloud Console'da OAuth Client ID Kontrolü

1. [Google Cloud Console](https://console.cloud.google.com/) → Projenizi seçin
2. **APIs & Services** → **Credentials** bölümüne gidin
3. Android OAuth 2.0 Client ID'nin olduğundan emin olun
4. Eğer yoksa, **Create Credentials** → **OAuth client ID** → **Android** seçin
5. Package name: `com.example.yunoo`
6. SHA-1 fingerprint'i ekleyin

## Önemli Notlar

- **Debug ve Release** için farklı SHA-1 fingerprint'ler olabilir
- Her ikisini de Firebase Console'a eklemeniz gerekebilir
- Değişikliklerin etkili olması birkaç dakika sürebilir
- APK'yı yeniden build etmeniz gerekebilir

## Test

SHA-1 fingerprint'i ekledikten sonra:
1. APK'yı yeniden build edin: `flutter build apk --release`
2. Uygulamayı yükleyin ve Google Sign-In'i test edin
