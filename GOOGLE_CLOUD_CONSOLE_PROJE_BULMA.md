# Google Cloud Console'da Firebase Projesini Bulma

## Sorun
Firebase Console'da projeniz (`my-english-project-f25ff`) görünüyor ama Google Cloud Console'da görünmüyor.

## Açıklama
Firebase projeleri aslında Google Cloud projeleridir, ancak:
- Firebase Console'dan oluşturulan projeler bazen Google Cloud Console'da görünmeyebilir
- Farklı bir Google hesabıyla giriş yapmış olabilirsiniz
- Proje henüz Google Cloud Console'da "aktif" olmamış olabilir

## Çözüm Yöntemleri

### Yöntem 1: Firebase Console'dan Google Cloud Console'a Geçiş

1. [Firebase Console](https://console.firebase.google.com/) → Projenizi seçin (`my-english-project-f25ff`)
2. Sol menüden **⚙️ Project Settings** (Proje Ayarları) tıklayın
3. **Project Settings** sayfasında, **General** sekmesinde:
   - **Project ID** veya **Project Number**'ı not edin
   - **Google Cloud Platform** bölümünde **Open in Google Cloud Console** linkine tıklayın
   - Bu link sizi doğru projeye yönlendirecektir

### Yöntem 2: Proje Numarası ile Arama

1. Firebase Console'da projenizin **Project Number**'ını bulun (örnek: `55568769953`)
2. [Google Cloud Console](https://console.cloud.google.com/) → Üst kısımdaki proje seçiciye tıklayın
3. **Project Number** ile arama yapın: `55568769953`
4. Projeyi seçin

### Yöntem 3: Direkt Link ile Erişim

Firebase Console'dan aldığınız **Project Number** ile direkt link:
```
https://console.cloud.google.com/home/dashboard?project=55568769953
```

veya Project ID ile:
```
https://console.cloud.google.com/home/dashboard?project=my-english-project-f25ff
```

### Yöntem 4: Aynı Google Hesabı ile Giriş

1. Firebase Console'da hangi Google hesabıyla giriş yaptığınızı kontrol edin
2. Google Cloud Console'da **aynı Google hesabı** ile giriş yapın
3. Üst kısımdaki proje seçiciye tıklayın ve projenizi arayın

## People API'yi Etkinleştirme (Artık Gerekli Değil)

**ÖNEMLİ:** Yeni kodda (`signInWithPopup` kullanımı) People API'ye ihtiyaç yoktur. Ancak eski kod hala çalışıyorsa:

1. Google Cloud Console'da projenizi bulun (yukarıdaki yöntemlerden biriyle)
2. **APIs & Services** → **Library** bölümüne gidin
3. **People API** arayın ve tıklayın
4. **Enable** butonuna tıklayın

**Ancak:** Yeni kodda bu gerekli değildir çünkü `google_sign_in` paketi web'de kullanılmıyor.

## Sorun Giderme

### Proje Hala Görünmüyor
- Firebase Console'da **Project Settings** → **General** → **Project Number**'ı kontrol edin
- Google Cloud Console'da **farklı bir hesap** ile giriş yapmış olabilirsiniz
- Proje sahibi değilseniz, projeye erişim izniniz olmayabilir


hatam şuydu"""
### People API Hatası Devam Ediyor
- Uygulamayı **tamamen kapatıp yeniden başlatın** (`flutter run -d chrome`)
- Hot reload yeterli olmayabilir, tam restart gerekebilir
- Browser cache'ini temizleyin (Ctrl+Shift+Delete)
1. Google Cloud Console'a gidin: https://console.cloud.google.com/
2. Projenizi seçin (my-english-project-f25ff)
3. APIs & Services > Library bölümüne gidin
4. "People API" arayın ve tıklayın
5. "Enable" butonuna tıklayın
6. Birkaç dakika bekleyin (API'nin aktif olması için)
7. Uygulamayı yeniden deneyin"""