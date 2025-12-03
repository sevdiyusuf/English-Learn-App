# Performans Optimizasyonları

## Chrome'da Yavaş Açılış Sorunu

### Çözüm 1: Release Modda Çalıştırma (Önerilen)

Debug modda çalıştırmak yavaştır çünkü hot reload, debugging ve diğer geliştirme araçları aktif olur.

**Release modda çalıştırmak için:**

```bash
# Web için release build
flutter build web --release

# Build edilen dosyaları çalıştır
cd build/web
python -m http.server 8000
# veya
# npx serve -s build/web
```

Veya PowerShell script'i kullan:
```powershell
.\run_web_release.ps1
```

### Çözüm 2: Debug Modda Hızlandırma

Eğer debug modda çalıştırmak zorundaysanız:

1. Chrome DevTools'u kapatın (F12)
2. Hot reload'u devre dışı bırakın
3. Gereksiz extension'ları kapatın

Debug modda çalıştırırken:
```bash
flutter run -d chrome
```

## Yapılan Optimizasyonlar

1. ✅ Viewport meta tag warning'i düzeltildi
2. ✅ Gereksiz debugPrint çağrıları kaldırıldı/kDebugMode ile sarmalandı
3. ✅ Dictionary loading optimizasyonu
4. ✅ Release modda çalıştırma script'i eklendi

## Performans İpuçları

- **Development**: Debug modda çalıştırın (yavaş ama hot reload var)
- **Testing**: Release modda çalıştırın (hızlı, gerçek kullanıcı deneyimi)
- **Production**: `flutter build web --release` ile build edin ve deploy edin

