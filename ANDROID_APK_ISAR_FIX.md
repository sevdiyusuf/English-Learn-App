# Android APK Isar Collections Sorunu - Çözüm Kılavuzu

## Sorun
Android APK release build'de Word Match modunda setler yüklenmiyor. Collections hiç initialize olmuyor.

## Hızlı Test - ProGuard'ı Kapat

**1. Geçici olarak ProGuard'ı kapatın (test için):**

`android/app/build.gradle.kts` dosyasında:
```kotlin
buildTypes {
    release {
        isMinifyEnabled = false  // GEÇİCİ - Test için
        isShrinkResources = false
        // ProGuard rules kaldırıldı - test için
    }
}
```

**2. Yeni APK build edin:**
```bash
flutter clean
flutter build apk --release
```

**3. Test edin:**
- Eğer çalışırsa → Sorun ProGuard/R8 optimization'da
- Eğer çalışmazsa → Sorun Isar native libraries'de

## Eğer ProGuard Sorunuysa

ProGuard kurallarını şu şekilde güçlendirin:

```proguard
# Isar için agresif koruma
-keep class dev.isar.** { *; }
-keep class io.isar.** { *; }
-keep class **Get*Collection* { *; }
-keep class **Collection { *; }
-keep class **Schema { *; }

# Extension methods
-keepclassmembers class * {
    *** wordSets;
    *** wordPairs;
    *** dictEntrys;
}

# Native methods
-keepclasseswithmembernames class * {
    native <methods>;
}
```

## Eğer Native Library Sorunuysa

1. **Isar sürümünü kontrol edin:**
   - Mevcut: `isar: ^3.1.0+1`
   - Güncel sürümü kontrol edin: `flutter pub outdated`

2. **Native library yüklemesini kontrol edin:**
   - `xxf_isar_flutter_libs: ^3.1.0+2` yüklü mü?
   - Gradle sync yapın

3. **Alternatif: Native library'leri önceden yükleyin**
   - MainActivity'de early initialization

## Geçici Workaround

Kullanıcıya daha iyi hata mesajı gösterin:

```dart
if (error.toString().contains('collections never initialized')) {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: Text('Veritabanı Hatası'),
      content: Text(
        'Veritabanı başlatılamadı. Lütfen:\n\n'
        '1. Uygulamayı tamamen kapatın\n'
        '2. Uygulamayı yeniden açın\n\n'
        'Sorun devam ederse uygulamayı kaldırıp yeniden yükleyin.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Tamam'),
        ),
      ],
    ),
  );
}
```

## Debug Komutları

```bash
# Logları izle
adb logcat | grep -i isar

# Database dosyalarını kontrol et
adb shell run-as com.example.yunoo ls -la /data/data/com.example.yunoo/app_flutter/

# Native library'leri kontrol et
adb shell run-as com.example.yunoo ls -la /data/app/*/lib/ | grep isar
```

## Son Çare: Database Reset

Eğer hiçbir şey işe yaramazsa, kullanıcıya database'i sıfırlama seçeneği sunun:

```dart
// Settings sayfasına ekleyin
ElevatedButton(
  onPressed: () async {
    final confirm = await showDialog<bool>(...);
    if (confirm == true) {
      // Isar database dosyalarını sil
      final dir = await getApplicationSupportDirectory();
      final dbDir = Directory('${dir.path}/dictionary.isar');
      if (await dbDir.exists()) {
        await dbDir.delete(recursive: true);
      }
      // Uygulamayı yeniden başlat
    }
  },
  child: Text('Veritabanını Sıfırla'),
)
```
