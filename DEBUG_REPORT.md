# Hata Analiz Raporu: Tamamm Uygulaması

Bu rapor, "Tamamm" uygulamasında karşılaşılan ve çözülemeyen iki kritik sorunu, bu sorunların teknik kök nedenlerini, uygulanan başarısız çözüm denemelerini ve sonraki adımlar için önerileri içermektedir. Bu belge, başka bir AI asistanından veya geliştiriciden yardım almak amacıyla hazırlanmıştır.

---

## 1. Sorun: "Başka Setle Birleştir" Özelliği Hatası (0 Kelime Görünmesi)

### Sorun Tanımı
Kullanıcı, "Kelime Eşleştirme" modülünde iki farklı kelime setini birleştirmek istediğinde ("Başka setle birleştir" özelliği), yeni bir set oluşturuluyor ancak bu setin içi boş geliyor (0 kelime). Oysa birleşen iki setin kelimelerinin toplamı (tekrarlar hariç) yeni sette yer almalıydı.

### Teknik Arka Plan
*   **Veritabanı:** Proje yerel veritabanı olarak **Isar** kullanıyor. Web tarafında Isar'ın WASM desteği, Mobil tarafta native desteği kullanılıyor.
*   **Mimari:** `WordMatchSetsController` (Riverpod) iş mantığını yönetiyor, `WordMatchRepo` (Repository Pattern) veritabanı işlemlerini yapıyor.
*   **ID Yönetimi:** Isar'da ID'ler `Isar.autoIncrement` ile yönetiliyor.

### Başarısız Çözüm Denemeleri ve Nedenleri

#### 1. Deneme: ID Sıfırlama ve Bağımlılık Temizliği
*   **Yapılan İşlem:** `WordMatchSetsController` içinde birleştirilecek kelimelerin ID'leri `Isar.autoIncrement` yerine manuel olarak `0`'a eşitlendi. Amaç, Repository katmanının bu kelimeleri "yeni kayıt" olarak algılamasını sağlamaktı. Ayrıca Controller'dan Isar bağımlılığı kaldırıldı.
*   **Sonuç:** Sorun devam etti.
*   **Olası Başarısızlık Nedeni:** Repository katmanındaki (`savePairs`) `id=0` kontrolü doğru çalışsa bile, `WordPair` nesnelerinin bellekteki kopyalanma şekli veya Isar'ın `putAll` işlemi sırasında `autoIncrement` atamalarında bir sorun yaşanıyor olabilir. Yeni oluşturulan nesnelerin `setId`'sinin doğru atanıp atanmadığı veya asenkron işlemlerin (`await`) sıralamasında bir yarış durumu (race condition) olabilir.

#### 2. Deneme: Repository Kayıt Mantığını Değiştirme
*   **Yapılan İşlem:** `WordMatchRepo.savePairs` metodu güncellendi. Eğer gelen kelimenin `id`'si `0` ise veya `setId`'si hedef set ile uyuşmuyorsa, bu kelimenin "yeni bir kopya" olarak oluşturulması ve `putIfAbsent` ile listeye eklenmesi sağlandı.
*   **Sonuç:** Sorun devam etti.
*   **Olası Başarısızlık Nedeni:** `Isar.writeTxn` işlemi içinde toplu kayıt (`putAll`) yapılırken, nesnelerin referansları veya ID çakışmaları nedeniyle kayıt işlemi sessizce başarısız oluyor olabilir veya veriler kaydediliyor ancak UI tarafında `watch` (gözlemci) tetiklenmiyor.

### Teknik Analiz için İpuçları (AI'ya Not)
*   `WordMatchSetsController.mergeSets` metodunda `repo.createSet` ile set oluşturuluyor, ID alınıyor. Sonra `repo.savePairs` çağrılıyor.
*   `savePairs` içinde `newPairs` listesi oluşturulurken, `WordPair` nesnelerinin "deep copy" (derin kopya) yapıldığından emin olunmalı.
*   Isar'ın `autoIncrement` özelliği, manuel olarak `id` atanmış nesneler üzerinde beklendiği gibi çalışmayabilir. Nesne `id` özelliği `null` olamaz (int), bu yüzden `Isar.autoIncrement` (çok büyük bir long değeri) kullanılıyor. Bu değerin Web ortamında (JavaScript) güvenli tamsayı sınırlarını aşıp aşmadığı kontrol edilmeli (daha önce `find_safe_hash` ile ilgili bir düzeltme yapılmıştı ama burada da etkili olabilir).

---

## 2. Sorun: Arkadaşlık İsteği Kabul Etme Hatası (Permission Denied)

### Sorun Tanımı
Kullanıcı gelen bir arkadaşlık isteğini "Kabul Et" butonuna basarak onayladığında, buton kısa bir süre (örneğin 1 saniye) "Kabul Edildi" durumuna geçiyor, ancak hemen ardından eski haline dönüyor veya hata veriyor. Konsolda `[cloud_firestore/permission-denied]` hatası alınıyor.

### Teknik Arka Plan
*   **Backend:** Firebase Firestore.
*   **Veri Yapısı:** `/friendships/{userId}/friends/{friendUid}` yolu altında karşılıklı kayıt tutuluyor.
*   **İşlem:** "Kabul Et" işlemi bir `WriteBatch` (toplu yazma) işlemidir. Hem kullanıcının kendi listesine hem de karşı tarafın listesine aynı anda yazma (set merge) işlemi yapılır.

### Başarısız Çözüm Denemeleri ve Nedenleri

#### 1. Deneme: Firestore Kurallarını (Rules) Genişletme
*   **Yapılan İşlem:** `firestore.rules` dosyasında, kullanıcının sadece kendi verisini değil, arkadaş olduğu kişinin verisini de yazabilmesi için kurallar gevşetildi.
    ```javascript
    match /friendships/{userId}/friends/{friendUid} {
      allow read, create, update, delete: if isAuthenticated() && (request.auth.uid == userId || request.auth.uid == friendUid);
    }
    ```
*   **Sonuç:** Sorun devam etti (Kullanıcı "çözemedin" geri bildirimi verdi).
*   **Olası Başarısızlık Nedeni:** Batch işleminde (toplu yazma), Firestore güvenlik kuralları her bir yazma işlemi için ayrı ayrı değerlendirilir.
    1.  `friendships/{me}/friends/{other}` -> `userId=me`, `friendUid=other`. `request.auth.uid == userId` (True). **İzin verilir.**
    2.  `friendships/{other}/friends/{me}` -> `userId=other`, `friendUid=me`. `request.auth.uid == friendUid` (True). **İzin verilir.**
    *   Teoride çalışması gerekirken hata alınıyorsa, sorun **Authentication** durumunda olabilir. Kullanıcı "Anonim" (misafir) giriş yapmışsa ve Firestore kurallarında başka bir yerde (örneğin global bir kısıtlama) anonim kullanıcılara kısıtlama varsa bu hata döner.
    *   Veya `request.auth.uid` beklenen değer değildir.

#### 2. Deneme: Kod Tarafında Hata Yakalama ve Merge
*   **Yapılan İşlem:** `FriendsRepo` içinde `batch.set` işlemlerine `SetOptions(merge: true)` eklendi ve `try-catch` bloğu ile hata loglaması yapıldı.
*   **Sonuç:** Hata loglara düşüyor ama işlem engelleniyor.
*   **Olası Başarısızlık Nedeni:** Sorun kodun çalışmasında değil, yetkilendirmede (Authorization).

### Teknik Analiz için İpuçları (AI'ya Not)
*   Firestore Simülatörü kullanılarak şu senaryo test edilmeli: `Auth UID: A`, Yazma Yolu: `/friendships/B/friends/A`. Kural: `request.auth.uid == friendUid` (Burada `friendUid` path parametresi `A`'dır). Bu kuralın doğru çalışıp çalışmadığı teyit edilmeli.
*   Eğer kullanıcı "Anonim" ise, `isAuthenticated()` fonksiyonunun tanımı kontrol edilmeli. Genelde `request.auth != null` yeterlidir ama proje özelinde `request.auth.token.email_verified` gibi ek şartlar varsa anonim kullanıcılar takılıyor olabilir.
