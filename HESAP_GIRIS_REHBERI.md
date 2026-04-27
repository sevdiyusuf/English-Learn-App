# Hesap Açma ve Giriş Yapma Rehberi

Bu rehber, Flutter uygulamanıza Google ve Email ile giriş yapma özelliği eklemek için gerekli adımları açıklar.

## Ne Yapacağız?

Uygulamanıza 3 giriş yöntemi ekleyeceğiz:
1. **Misafir olarak devam** - Hemen oynamaya başla, kayıt olmadan
2. **Google ile giriş** - Google hesabınla hızlıca giriş yap
3. **Email ile giriş** - Email ve şifre ile kayıt ol veya giriş yap

## Adım 1: Firebase Console Yapılandırması

### 1.1 Firebase Console'a Git

1. [Firebase Console](https://console.firebase.google.com/) → Projenizi seçin
2. Sol menüden **Authentication** (Kimlik Doğrulama) tıklayın
3. **Sign-in method** (Giriş yöntemi) sekmesine tıklayın

### 1.2 Google Girişini Etkinleştir

1. **Sign-in providers** listesinde **Google** satırına tıklayın
2. **Enable** toggle'ını **AÇIK** yapın
3. **Save** butonuna tıklayın

### 1.3 Email/Password Girişini Etkinleştir

1. **Sign-in providers** listesinde **Email/Password** satırına tıklayın
2. **Enable** toggle'ını **AÇIK** yapın
3. **Save** butonuna tıklayın

**Not:** Bu adımlar sadece bir kez yapılır. Sonrasında kod tarafında çalışır.

## Adım 2: Kod Yapısı (Zaten Hazır)

Uygulamanızda şu dosyalar var:

### 2.1 Kullanıcı Modeli
- `lib/features/auth/models/app_user.dart` - Kullanıcı bilgilerini tutar

### 2.2 Giriş İşlemleri
- `lib/features/auth/data/auth_repo.dart` - Giriş yapma kodları
- `lib/features/auth/logic/auth_controller.dart` - Giriş durumunu yönetir

### 2.3 Arayüz
- `lib/features/auth/ui/account_sheet.dart` - Giriş ekranı
- `lib/features/auth/ui/email_auth_dialog.dart` - Email giriş penceresi

## Adım 3: Nasıl Çalışır?

### 3.1 Misafir Modu
- Uygulama açıldığında otomatik olarak misafir hesabı oluşturulur
- Kullanıcı hemen oynamaya başlayabilir
- İstediği zaman Google veya Email ile gerçek hesaba geçebilir

### 3.2 Google ile Giriş
1. Kullanıcı "Google ile giriş yap" butonuna tıklar
2. Google giriş penceresi açılır
3. Google hesabı seçilir ve onaylanır
4. Otomatik olarak giriş yapılır

### 3.3 Email ile Giriş
1. Kullanıcı "E-posta ile kayıt/giriş" butonuna tıklar
2. Email ve şifre girer
3. "Kayıt ol" veya "Giriş yap" butonuna tıklar
4. Eğer hesap yoksa kayıt olur, varsa giriş yapar

## Adım 4: Kullanım Örnekleri

### 4.1 Giriş Durumunu Kontrol Etme

```dart
// Kullanıcının giriş yapıp yapmadığını kontrol et
final authController = ref.read(authControllerProvider.notifier);
final isLoggedIn = authController.isLoggedIn;
final isGuest = authController.isGuest;
```

### 4.2 Giriş Yapma

```dart
// Google ile giriş
await authController.signInWithGoogle();

// Email ile giriş
await authController.signInWithEmail(
  email: 'kullanici@example.com',
  password: 'sifre123',
);

// Email ile kayıt
await authController.registerWithEmail(
  email: 'kullanici@example.com',
  password: 'sifre123',
);
```

### 4.3 Çıkış Yapma

```dart
await authController.signOut();
```

## Adım 5: Önemli Notlar

### 5.1 Web için Özel Durum
- Web'de Google girişi için özel bir yöntem kullanılır (`signInWithPopup`)
- People API'ye ihtiyaç yoktur
- Firebase Console yapılandırması yeterlidir

### 5.2 Mobil için Özel Durum
- Android ve iOS'ta Google girişi için `google_sign_in` paketi kullanılır
- Ekstra yapılandırma gerekebilir (Android: SHA-1, iOS: Bundle ID)

### 5.3 Hesap Bağlama
- Misafir olarak başlayan kullanıcı, sonradan Google veya Email ile gerçek hesaba geçebilir
- Tüm veriler (oyun skorları, ilerleme vb.) korunur

## Sorun Giderme

### "Bu işlem izin verilmiyor" Hatası
- Firebase Console'da ilgili giriş yönteminin etkin olduğundan emin olun
- **Authentication** → **Sign-in method** → İlgili provider'ı kontrol edin

### Google Girişi Çalışmıyor
- Firebase Console'da Google provider'ının etkin olduğundan emin olun
- Web'de popup blocker'ı kontrol edin

### Email Girişi Çalışmıyor
- Firebase Console'da Email/Password provider'ının etkin olduğundan emin olun
- Email formatını kontrol edin (örn: `kullanici@example.com`)
- Şifre en az 6 karakter olmalıdır

## Özet

1. ✅ Firebase Console'da Google ve Email/Password provider'larını etkinleştir
2. ✅ Kod zaten hazır, sadece kullan
3. ✅ Misafir modu otomatik çalışır
4. ✅ Google ve Email girişi hazır

**Hepsi bu kadar!** Artık uygulamanızda hesap açma ve giriş yapma özellikleri çalışıyor.
