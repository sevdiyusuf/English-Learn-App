# Web Build ve Deploy Rehberi

## 🚀 Hızlı Deploy (Tek Komut)

En kolay yöntem, hazır script'i kullanmak:

```powershell
.\deploy_firebase.ps1
```

Bu script otomatik olarak:
1. Flutter web build yapar
2. iOS Safari uyumluluğunu düzeltir
3. Firebase Hosting'e deploy eder

---

## 📋 Manuel Adımlar

### 1. Build Temizleme (İsteğe Bağlı)

```powershell
flutter clean
```

### 2. Web Build

```powershell
flutter build web --release
```

**Alternatifler:**
- `flutter build web --release --no-source-maps` (Daha küçük dosya boyutu)
- `flutter build web --release --web-renderer canvaskit` (CanvasKit renderer)

### 3. Firebase'e Deploy

```powershell
firebase deploy --only hosting
```

**Tüm servisleri deploy etmek için:**
```powershell
firebase deploy
```

---

## 🔧 Sorun Giderme

### Firebase CLI Yüklü Değilse

```powershell
npm install -g firebase-tools
firebase login
```

### Build Hatası Alırsanız

1. **Clean build:**
   ```powershell
   flutter clean
   flutter pub get
   flutter build web --release
   ```

2. **Cache temizleme:**
   ```powershell
   Remove-Item -Recurse -Force .dart_tool
   flutter pub get
   ```

### Deploy Hatası Alırsanız

1. **Firebase login kontrolü:**
   ```powershell
   firebase login
   ```

2. **Proje kontrolü:**
   ```powershell
   firebase projects:list
   firebase use my-english-project-f25ff
   ```

---

## 📊 Build Sonrası Kontroller

### Build Dosyalarını Kontrol Et

```powershell
Get-ChildItem build\web -Recurse | Select-Object Name, Length
```

### Local Test (Build Sonrası)

```powershell
cd build\web
python -m http.server 8000
# veya
npx serve -s .
```

Tarayıcıda: `http://localhost:8000`

---

## 🌐 Deploy Sonrası

### URL'leri Görüntüle

```powershell
firebase hosting:channel:list
```

### Production URL

Firebase Console'dan:
- https://console.firebase.google.com/
- Projenizi seçin
- **Hosting** sekmesi
- Production URL'i göreceksiniz

---

## ⚡ Hızlı Komutlar

```powershell
# Sadece build
flutter build web --release

# Build + Deploy (script ile)
.\deploy_firebase.ps1

# Sadece deploy (build zaten yapılmışsa)
firebase deploy --only hosting

# Firestore rules deploy
firebase deploy --only firestore:rules

# Tüm servisleri deploy
firebase deploy
```
