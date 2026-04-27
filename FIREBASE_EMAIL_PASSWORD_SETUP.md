# Firebase Email/Password Authentication Yapılandırması

## Sorun
Email/Password ile giriş yaparken şu hata alınıyor:
```
[firebase_auth/operation-not-allowed] The given sign-in provider is disabled for this Firebase project.
```

## Çözüm: Firebase Console'da Email/Password Provider'ını Etkinleştirin

### Adım 1: Firebase Console'a Gidin

1. [Firebase Console](https://console.firebase.google.com/) → Projenizi seçin (`my-english-project-f25ff`)

### Adım 2: Authentication Ayarlarına Gidin

1. Sol menüden **Authentication** (Kimlik Doğrulama) tıklayın
2. Üst kısımdaki **Sign-in method** (Giriş yöntemi) sekmesine tıklayın

### Adım 3: Email/Password Provider'ını Etkinleştirin

1. **Sign-in providers** listesinde **Email/Password** (E-posta/Şifre) seçeneğini bulun
2. **Email/Password** satırına tıklayın
3. Açılan pencerede:
   - **Enable** (Etkinleştir) toggle'ını **AÇIK** konuma getirin
   - **Email link (passwordless sign-in)** seçeneği isteğe bağlıdır (şu an için gerekli değil)
4. **Save** (Kaydet) butonuna tıklayın

### Adım 4: Test Edin

1. Uygulamayı yeniden başlatın (gerekirse)
2. "E-posta ile kayıt/giriş" butonuna tıklayın
3. Email ve password ile kayıt olmayı veya giriş yapmayı deneyin
4. Artık çalışmalı!

## Ek Notlar

- **Google Sign-In** zaten çalışıyor ✅
- **Email/Password** şimdi etkinleştirildikten sonra çalışacak
- **Apple Sign-In** iOS/macOS için ayrıca etkinleştirilmesi gerekir (web'de desteklenmez)

## Sorun Giderme

### Hala "Bu işlem izin verilmiyor" Hatası Alıyorum
- Firebase Console'da **Email/Password** provider'ının **Enable** durumunun **AÇIK** olduğundan emin olun
- Sayfayı yenileyin (F5) ve tekrar kontrol edin
- Uygulamayı tamamen kapatıp yeniden başlatın

### Email/Password Provider'ı Listede Görünmüyor
- Firebase Console'da doğru projeyi seçtiğinizden emin olun
- **Authentication** → **Sign-in method** sayfasında olduğunuzdan emin olun
- Browser cache'ini temizleyin (Ctrl+Shift+Delete)
