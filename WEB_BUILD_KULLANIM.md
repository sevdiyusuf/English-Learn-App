# Web Build Kullanım Rehberi

## Ne Zaman `fix_web_build.ps1` Kullanılır?

### Senaryo 1: Sadece Web Build (Şu Anki Durum) ✅
**Stub dosyalar kullanılıyor, script'e GEREK YOK:**

```powershell
# Direkt web build yapabilirsiniz
flutter build web --release
```

**Neden?** Çünkü stub dosyalar zaten web-safe ve integer overflow sorunu yok.

---

### Senaryo 2: Mobil Build Sonrası Web Build
**Gerçek Isar dosyaları oluşturulduysa, script GEREKLİ:**

```powershell
# 1. Mobil/Desktop için gerçek Isar dosyalarını oluştur
dart run build_runner build --delete-conflicting-outputs

# 2. Web build için integer overflow'u düzelt (ÖNEMLİ!)
.\fix_web_build.ps1

# 3. Web build yap
flutter build web --release
```

**Neden?** Çünkü `build_runner` gerçek Isar dosyalarını oluşturur ve bunlar büyük integer'lar içerir (JavaScript'te sorun yaratır).

---

## Özet

| Durum | `fix_web_build.ps1` Gerekli mi? | Komut Sırası |
|-------|-------------------------------|--------------|
| **Stub dosyalar kullanılıyor** (şu anki durum) | ❌ **HAYIR** | `flutter build web --release` |
| **Gerçek Isar dosyaları var** (mobil build sonrası) | ✅ **EVET** | `build_runner` → `fix_web_build.ps1` → `flutter build web --release` |

---

## Şu Anki Durumunuz

✅ **Stub dosyalar aktif** → Direkt `flutter build web --release` çalıştırabilirsiniz
❌ `fix_web_build.ps1` script'ine **gerek yok**

---

## Notlar

- **Stub dosyalar**: Web için yeterli, integer overflow sorunu yok
- **Gerçek Isar dosyaları**: Mobil/desktop için gerekli, ama web build öncesi `fix_web_build.ps1` çalıştırılmalı
- **Script amacı**: Sadece gerçek Isar dosyalarındaki büyük integer'ları düzeltmek için
