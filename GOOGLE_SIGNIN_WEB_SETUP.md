# Google Sign-In Web Yapılandırması

## Genel Bakış

Web'de Google Sign-In için Firebase Auth'un native `signInWithPopup` metodu kullanılmaktadır. Bu yöntem:
- ✅ People API'ye ihtiyaç duymaz
- ✅ Firebase Console yapılandırması yeterlidir
- ✅ Daha güvenilir ve önerilen yöntemdir

## Yapılandırma

### Adım 1: Firebase Console'da Google Sign-In'i Etkinleştirin

1. [Firebase Console](https://console.firebase.google.com/) → Projenizi seçin
2. **Authentication** → **Sign-in method** → **Google**
3. **Enable** butonuna tıklayın
4. **Web SDK configuration** bölümünden **Web client ID**'yi not edin (gerekirse)

### Adım 2: Test

1. Uygulamayı çalıştırın: `flutter run -d chrome`
2. "Google ile giriş yap" butonuna tıklayın
3. Google Sign-In popup'ı açılmalı ve giriş yapabilmelisiniz

## Teknik Detaylar

### Web'de Kullanılan Yöntem

Web platformunda `lib/features/auth/data/auth_repo.dart` dosyasındaki `_signInWithGoogleWeb()` metodu:
- Firebase Auth'un `signInWithPopup()` metodunu kullanır
- `GoogleAuthProvider` ile doğrudan entegre çalışır
- `google_sign_in` paketini web'de kullanmaz (People API gereksinimini önler)

### Mobil/Desktop'ta Kullanılan Yöntem

Mobil ve desktop platformlarında:
- `google_sign_in` paketi kullanılır
- `scopes: ['email', 'profile']` ile yapılandırılır
- Native platform entegrasyonu sağlar

## Sorun Giderme

### Popup Açılmıyor
- Browser'ın popup blocker'ını kontrol edin
- Browser console'u kontrol edin (F12) ve hata mesajlarını inceleyin

### Firebase Auth Hatası
- Firebase Console'da Google Sign-In provider'ının etkin olduğundan emin olun
- Firebase projesinin doğru yapılandırıldığından emin olun

### Giriş İptal Edildi
- Kullanıcı popup'ı kapattıysa bu normal bir durumdur
- "Giriş iptal edildi" mesajı gösterilir

## Notlar

- **People API gerekmez:** Web'de Firebase Auth'un native metodu kullanıldığı için People API'yi etkinleştirmenize gerek yoktur
- **Meta tag gerekmez:** `web/index.html` dosyasında `google-signin-client_id` meta tag'ine gerek yoktur (Firebase Auth otomatik olarak yapılandırmayı kullanır)
- **Daha güvenilir:** Firebase Auth'un native metodu, `google_sign_in` paketinden daha güvenilir ve önerilen yöntemdir
