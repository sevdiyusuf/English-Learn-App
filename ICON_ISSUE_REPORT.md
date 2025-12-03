# Flutter Web HTML Renderer - MaterialIcons Görünmeme Sorunu Raporu

## 🔴 Sorun Özeti
Flutter web uygulamasında MaterialIcons iconları **local ortamda** (dev/debug modunda) düzgün görünüyor, ancak **web build** (production) ortamında görünmüyor. Sorun özellikle **iOS Safari** için kritik.

## 📋 Teknik Detaylar

### Ortam Bilgileri
- **Flutter SDK:** Mevcut sürüm
- **Platform:** Web (HTML renderer)
- **Tarayıcılar:** iOS Safari, Desktop Safari, Chrome (bazı durumlarda)
- **Render Mode:** HTML renderer (CanvasKit iOS Safari'de çalışmıyor)

### Sorunun Belirtileri
1. ✅ Font yükleniyor (`MaterialIcons font loaded from FontManifest.json: assets/fonts/MaterialIcons-Regular.otf` log mesajı görünüyor)
2. ❌ Iconlar DOM'da görünmüyor (boş alanlar)
3. ⚠️ Konsolda "Could not find a set of Noto fonts" uyarısı var
4. ✅ Local dev/debug modunda iconlar düzgün çalışıyor

## 🔧 Denenen Çözümler

### 1. CSS @font-face Tanımı
```css
@font-face {
  font-family: 'MaterialIcons';
  font-style: normal;
  font-weight: 400;
  font-display: block;
  src: url('assets/fonts/MaterialIcons-Regular.otf') format('opentype');
}
```
**Sonuç:** Font tanımı eklendi, font yükleniyor ama iconlar görünmüyor.

### 2. Font Preload Link
```html
<link rel="preload" href="assets/fonts/MaterialIcons-Regular.otf" as="font" type="font/otf" crossorigin="anonymous" />
```
**Sonuç:** Font önceden yükleniyor, iconlar hala görünmüyor.

### 3. JavaScript FontFace API
```javascript
const fontFace = new FontFace('MaterialIcons', `url(${fontPath})`, {
  style: 'normal',
  weight: '400',
  display: 'block'
});
fontFace.load().then(loadedFont => document.fonts.add(loadedFont));
```
**Sonuç:** Font API ile yükleniyor (log mesajı görünüyor), iconlar görünmüyor.

### 4. FontManifest.json'dan Font Yükleme
```javascript
fetch('assets/FontManifest.json')
  .then(response => response.json())
  .then(fontManifest => {
    // Font yükleme kodu
  });
```
**Sonuç:** Font yükleniyor, iconlar görünmüyor.

### 5. Flutter First Frame Event Listener
```javascript
window.addEventListener('flutter-first-frame', function() {
  // Font yükleme denemeleri
});
```
**Sonuç:** Font yükleniyor, iconlar görünmüyor.

### 6. Deprecated Meta Tag Düzeltmesi
```html
<meta name="mobile-web-app-capable" content="yes">
```
**Sonuç:** Uyarı giderildi, icon sorunu devam ediyor.

## 🔍 Sorun Analizi

### Font Yükleniyor Ama Iconlar Görünmüyor - Olası Nedenler:

1. **Flutter'ın Font Yükleme Sistemi ile Uyumsuzluk**
   - Flutter web HTML renderer, kendi font yükleme mekanizmasını kullanıyor
   - Manuel font yükleme Flutter'ın font kayıt sistemini atlıyor olabilir
   - Font yüklü olsa bile, Flutter'ın icon rendering sistemi fontu tanımıyor

2. **Timing Sorunu**
   - Font yükleme Flutter'ın font sistemi başlatılmadan önce tamamlanıyor
   - Flutter font sistemini başlattığında font zaten yüklü olduğu için tekrar kayıt edilmiyor

3. **Font Family İsim Uyumsuzluğu**
   - CSS'te tanımlanan font-family adı (`'MaterialIcons'`)
   - Flutter'ın beklediği font-family adı farklı olabilir
   - FontManifest.json'da `"family": "MaterialIcons"` görünüyor

4. **iOS Safari Özel Durumları**
   - iOS Safari font yükleme mekanizması farklı çalışıyor
   - `font-display: block` iOS Safari'de farklı davranabilir
   - CORS ayarları iOS Safari'de daha katı olabilir

5. **Flutter Web HTML Renderer Limitation**
   - Flutter web HTML renderer'da MaterialIcons için bilinen sorunlar olabilir
   - Flutter'ın font yükleme mekanizması HTML renderer'da tam desteklenmiyor olabilir

## 🎯 Olası Alternatif Çözümler (Test Edilmedi)

### Çözüm 1: Flutter'ın Font Yükleme Sistemini Beklemek
Flutter'ın font yükleme sistemini doğrudan tetiklemek veya beklemek:
```javascript
// Flutter'ın font yükleme sistemini bekle
window.addEventListener('flutter-first-frame', function() {
  // Flutter'ın font yükleme mekanizmasını tetikle
  if (window._flutter && window._flutter.loader) {
    // Flutter loader'ı kullanarak font yükle
  }
});
```

### Çözüm 2: SVG Iconlar Kullanmak
MaterialIcons yerine SVG iconlar kullanmak (flutter_svg paketi ile):
```dart
import 'package:flutter_svg/flutter_svg.dart';

SvgPicture.asset('assets/icons/icon_name.svg')
```

### Çözüm 3: Custom Font Assets
MaterialIcons font dosyasını `pubspec.yaml`'a özel font olarak eklemek:
```yaml
flutter:
  fonts:
    - family: MaterialIcons
      fonts:
        - asset: assets/fonts/MaterialIcons-Regular.otf
```

### Çözüm 4: CanvasKit Renderer (iOS Safari Dışında)
CanvasKit renderer kullanmak (iOS Safari hariç tüm tarayıcılarda):
```bash
flutter build web --web-renderer canvaskit
```
**Not:** iOS Safari CanvasKit'i desteklemiyor (WebAssembly.compileStreaming eksik).

### Çözüm 5: Google Fonts API Kullanmak
MaterialIcons'u Google Fonts üzerinden yüklemek:
```html
<link rel="stylesheet" href="https://fonts.googleapis.com/icon?family=Material+Icons">
```

## 📊 Test Edilen Dosya Yapısı

```
web/
  └── index.html (Font yükleme scriptleri eklendi)
  
build/web/
  └── assets/
      ├── FontManifest.json ({"family":"MaterialIcons","fonts":[{"asset":"fonts/MaterialIcons-Regular.otf"}]})
      └── fonts/
          └── MaterialIcons-Regular.otf (Mevcut)

pubspec.yaml
  └── flutter:
      └── uses-material-design: true ✅
```

## 🐛 Bilinen Sorunlar

1. **Noto Fonts Uyarısı**
   - "Could not find a set of Noto fonts" uyarısı görünüyor
   - Bu uyarı icon sorunuyla ilgili olabilir mi?
   - Flutter, eksik karakterler için Noto fontları arıyor

2. **Flutter Web HTML Renderer Font Yükleme**
   - Flutter web HTML renderer'da font yükleme mekanizması tam belgelenmemiş
   - FontManifest.json'dan font yükleme otomatik mi yoksa manuel mi?

## 💡 Öneriler

1. **Flutter GitHub Issues Kontrol Et**
   - Flutter web HTML renderer MaterialIcons sorunları için GitHub issues
   - Benzer sorunları aramak ve çözümleri incelemek

2. **Flutter Font Yükleme Sistemini İncele**
   - Flutter'ın web'de font yükleme mekanizmasını anlamak
   - Flutter engine kodlarını incelemek (açık kaynak)

3. **Alternatif Icon Çözümleri**
   - SVG iconlar kullanmak (en güvenilir çözüm)
   - Custom icon widget'ları oluşturmak
   - Image asset olarak iconlar kullanmak

4. **CanvasKit Renderer (iOS Safari Dışında)**
   - iOS Safari hariç tüm tarayıcılarda CanvasKit kullanmak
   - iOS Safari için HTML renderer + SVG iconlar kombinasyonu

## 📝 Gemini'ye Sorulacak Soru Önerisi

```
Flutter web uygulamasında MaterialIcons iconları local dev/debug modunda 
düzgün çalışıyor, ancak web build (production) ortamında görünmüyor. 
Özellikle iOS Safari'de sorun var. HTML renderer kullanılıyor (CanvasKit 
iOS Safari'de çalışmıyor).

Font yükleniyor gibi görünüyor (konsol logları: "MaterialIcons font loaded 
from FontManifest.json"), ancak iconlar DOM'da görünmüyor. 

Denenen çözümler:
- CSS @font-face tanımı
- Font preload link
- JavaScript FontFace API
- FontManifest.json'dan font yükleme
- Flutter first-frame event listener

Tüm çözümlerde font yükleniyor ama iconlar görünmüyor. Bu, Flutter'ın 
font yükleme sistemine entegre olmama sorunu mu? Nasıl çözebilirim?

Ayrıca konsolda "Could not find a set of Noto fonts" uyarısı var. Bu 
icon sorunuyla ilgili olabilir mi?
```

## 🔗 İlgili Kaynaklar

- [Flutter Web Font Loading](https://flutter.dev/docs/cookbook/design/fonts)
- [Flutter Web Renderer Options](https://docs.flutter.dev/deployment/web#renderer-options)
- [Material Icons Font](https://fonts.google.com/icons)
- [Flutter GitHub Issues - Web Icons](https://github.com/flutter/flutter/issues?q=is%3Aissue+is%3Aopen+web+icons)

---

**Rapor Tarihi:** 2024
**Hazırlayan:** AI Assistant
**Durum:** Açık Sorun - Çözüm Aranıyor

