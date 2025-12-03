# Flutter Uygulama Yapısı - Gemini için Özet

## 📱 Uygulama Genel Bakış

**Platform:** Flutter (Dart)  
**State Management:** Riverpod (StateNotifier, Provider)  
**Routing:** GoRouter  
**Firebase:** Authentication, Firestore, Cloud Functions  
**Platform:** Web (Chrome), Mobil (Android/iOS)

---

## 🏗️ Mimari Yapı

### Ana Klasör Yapısı
```
lib/
├── app/                    # Uygulama başlatma ve routing
│   ├── router.dart        # Ana router yapılandırması
│   ├── routes/            # Route tanımları (code splitting)
│   └── di.dart            # Dependency injection (Firebase, services)
├── core/                   # Paylaşılan core bileşenler
│   ├── theme/             # Tema ve renkler
│   ├── widgets/           # Genel widget'lar
│   ├── animations/        # Animasyon yardımcıları
│   └── responsive/        # Responsive design utilities
└── features/              # Feature bazlı modüller
    ├── auth/              # Kimlik doğrulama
    ├── lobby/             # Oda lobisi
    ├── game/              # Ana oyun mantığı
    ├── cargo_categories/  # Cargo Categories mini oyunu ⭐ (SORUNLU MODÜL)
    └── ...
```

---

## 🎮 Cargo Categories Oyunu - Modül Yapısı

### Dosya Hiyerarşisi
```
lib/features/cargo_categories/
├── data/
│   └── cargo_service.dart              # JSON veri yükleme servisi (singleton)
├── logic/
│   └── cargo_categories_controller.dart # Riverpod StateNotifier - Oyun mantığı
├── models/
│   ├── cargo_categories_state.dart     # Oyun state modeli
│   ├── cargo_word.dart                 # Kelime modeli (word, translate, category)
│   └── category.dart                   # Kategori modeli (id, name, color)
└── ui/
    ├── cargo_categories_setup_page.dart # Oyun ayarları (zorluk + 3 kategori seçimi)
    ├── cargo_categories_game_page.dart  # Ana oyun sayfası
    └── widgets/
        ├── conveyor_area.dart           # ⚠️ SORUNLU: Bant animasyon widget'ı
        ├── word_box.dart                # Hareket eden kelime kutusu
        ├── category_dock.dart           # Kategori dokları (3 adet)
        └── score_dialog.dart            # Oyun bitiş diyaloğu
```

---

## 🔄 State Management (Riverpod)

### Provider Yapısı
```dart
// Controller Provider
final cargoCategoriesControllerProvider = 
    StateNotifierProvider<CargoCategoriesController, CargoCategoriesState>(
  (ref) => CargoCategoriesController(),
);

// Controller extends StateNotifier<CargoCategoriesState>
class CargoCategoriesController extends StateNotifier<CargoCategoriesState> {
  Timer? _gameTimer;  // Oyun timer'ı (1 saniye aralıkla)
  // ...
}
```

### State Modeli (Immutable)
```dart
class CargoCategoriesState {
  final List<String> selectedCategories;      // Seçilen 3 kategori ID'si
  final Difficulty? selectedDifficulty;       // slow/normal/fast
  final CargoWord? currentWord;               // Şu anki kelime
  final List<CargoWord> remainingWords;       // Kalan kelimeler
  final int score;
  final int correctCount;
  final int wrongCount;
  final int missedCount;
  final Duration remainingTime;               // Kalan süre (60 saniye)
  final bool isRunning;
  final bool isFinished;
  final DateTime? currentWordStartTime;       // Kelime başlangıç zamanı
  final String? highlightedCategoryId;        // Doğru kategori highlight
  final String? wrongCategoryId;              // Yanlış kategori highlight
}
```

---

## 🎯 Oyun Mekaniği

### Oyun Akışı
1. **Setup Sayfası:**
   - Kullanıcı zorluk seviyesi seçer (slow: 4s, normal: 2.5s, fast: 1.5s)
   - Kullanıcı tam 3 kategori seçer
   - "Oyunu Başlat" butonu aktif olur

2. **Oyun Başlatma:**
   ```dart
   void startGame() {
     // 3 kategoriden kelimeler yüklenir ve shuffle edilir
     final words = CargoService.instance.getWordsByCategories(selectedCategories);
     // State güncellenir: remainingWords, isRunning = true
     _startGameTimer();  // 60 saniyelik timer başlar
     _loadNextWord();    // İlk kelime yüklenir
   }
   ```

3. **Oyun Döngüsü:**
   - Kelime sağdan sola bant üzerinde hareket eder
   - Kullanıcı 3 kategoriden birine tıklar
   - `handleAnswer(categoryId)` çağrılır
   - Doğru/yanlış kontrolü yapılır, skor güncellenir
   - 800ms bekleme sonrası `_loadNextWord()` çağrılır

4. **Timeout Senaryosu:**
   - Kelime banttan çıkarsa (animasyon tamamlanırsa)
   - `handleTimeout()` çağrılır
   - -3 puan, missedCount artar
   - `_loadNextWord()` çağrılır

---

## 🐛 Sorunlu Kod: ConveyorArea Widget

### Mevcut Yapı
```dart
class ConveyorArea extends StatefulWidget {
  final CargoWord? currentWord;      // Controller'dan gelen kelime
  final Duration travelDuration;     // Animasyon süresi (zorluk seviyesine göre)
  final VoidCallback onTimeout;      // Animasyon bitince çağrılacak callback
}

class _ConveyorAreaState extends State<ConveyorArea> {
  double? _screenWidth;               // Ekran genişliği
  double _currentX = 0;               // Kelime kutusunun X pozisyonu
  Timer? _animationTimer;             // Animasyon timer'ı (16ms aralıkla)
  String? _animatingWordId;           // Animasyonu çalışan kelime ID'si
  
  void _startAnimation() {
    // Timer.periodic ile manuel animasyon kontrolü
    // Her frame'de _currentX güncellenir
    // setState() ile widget rebuild edilir
  }
}
```

### Sorun Noktaları
1. **Widget Lifecycle:**
   - `build()` metodu her state değişikliğinde çağrılır
   - `didUpdateWidget()` kelime değiştiğinde çağrılır
   - Timer widget lifecycle'dan bağımsız çalışmaya çalışıyor ama senkronizasyon sorunu var

2. **State Değişiklikleri:**
   - Controller'da score update olduğunda state değişir
   - State değişince widget rebuild olur
   - Widget rebuild olduğunda animasyon etkilenebilir

3. **Timer Kontrolü:**
   - Timer içinde `widget.currentWord?.word != startWordId` kontrolü var
   - Bu kontrol widget rebuild sırasında yanlış pozitif verebiliyor
   - Timer erken duruyor (%19 civarında)

4. **Widget Görünürlük:**
   - `Positioned` widget'ı için koşul: `_animatingWordId == widget.currentWord!.word`
   - Bu eşleşme bozulursa widget görünmez ama timer çalışmaya devam eder

---

## 🔧 Teknik Detaylar

### Animasyon Yaklaşımı (Şu Anki)
- **Timer.periodic** ile manuel frame-by-frame animasyon
- 16ms aralıkla (~60 FPS) timer çalışır
- Her tick'te `_currentX` pozisyonu güncellenir
- `setState()` ile widget rebuild edilir
- `Positioned(left: _currentX)` ile widget konumlandırılır

### Alternatif Denenen Yaklaşımlar (Başarısız)
1. ❌ **AnimationController + AnimatedBuilder** - Widget rebuild sorunu
2. ❌ **TweenAnimationBuilder** - Animasyon erken duruyor
3. ❌ **Ayrı Widget Yaklaşımı** - Lifecycle senkronizasyon sorunu

### Veri Yapısı
```json
// assets/cargo_categories.json
{
  "categories": [
    {
      "id": "food",
      "name": "Yiyecek",
      "color": "#F4A261",
      "words": [
        {
          "english": "apple",
          "turkish": "elma"
        },
        // ... 10 kelime
      ]
    },
    // ... 7 kategori
  ]
}
```

---

## 🎨 UI Bileşenleri

### Game Page Yapısı
```
CargoCategoriesGamePage (ConsumerStatefulWidget)
└── Stack
    ├── Background (Gradient)
    ├── TopStatusBar (Timer + Score)
    ├── Center Row (3 CategoryDock)
    └── Positioned Bottom (ConveyorArea)
```

### ConveyorArea İç Yapısı
```
ConveyorArea
└── Stack (clipBehavior: Clip.none)
    ├── Conveyor Belt (Container + CustomPaint)
    └── Positioned WordBox (conditional render)
        └── Transform.translate
            └── WordBox (Container with text)
```

---

## 🔄 Veri Akışı

### Kelime Yükleme Akışı
```
Controller._loadNextWord()
  ↓
state.copyWith(currentWord: newWord)  // State güncellenir
  ↓
Riverpod state değişikliği
  ↓
Widget rebuild (ref.watch ile state dinleniyor)
  ↓
ConveyorArea widget'ına yeni currentWord prop'u gelir
  ↓
didUpdateWidget() çağrılır
  ↓
_startAnimation() çağrılır
  ↓
Timer başlar, animasyon başlar
```

### Timeout Akışı (Beklenen)
```
Timer tamamlanır
  ↓
onTimeout() callback çağrılır
  ↓
Controller.handleTimeout()
  ↓
State güncellenir (score, missedCount)
  ↓
_loadNextWord() çağrılır
  ↓
Yeni kelime yüklenir (yukarıdaki akış tekrarlanır)
```

### Timeout Akışı (Gerçek - Sorunlu)
```
Timer başlar
  ↓
%19'a kadar çalışır
  ↓
❌ Timer duruyor (neden bilinmiyor)
  ↓
onTimeout() çağrılmıyor
  ↓
Yeni kelime gelmiyor
```

---

## 🛠️ Kullanılan Teknolojiler

- **Flutter SDK:** Latest stable
- **Riverpod:** State management
- **GoRouter:** Navigation
- **Timer (dart:async):** Animasyon kontrolü
- **JSON:** Veri depolama (assets)

---

## 📊 Sorun Özeti

**Ana Sorun:** `ConveyorArea` widget'ında bant animasyonu çalışmıyor. Kelime %19 civarında kayboluyor ve yeni kelimeler gelmiyor.

**Teknik Detay:**
- Timer.periodic kullanılıyor
- Widget rebuild + Timer senkronizasyon sorunu var
- State değişiklikleri animasyonu etkiliyor
- Widget görünürlük kontrolü sorunlu

**Beklenen Davranış:**
- Kelime sağdan sola tamamen ekrandan çıkana kadar görünür olmalı
- Animasyon tamamlanınca `onTimeout()` çağrılmalı
- Yeni kelime yüklenmeli ve animasyon tekrarlanmalı

**Gerçek Davranış:**
- Kelime bantın ortasına gelince kayboluyor
- Timer duruyor (%19 civarında)
- `onTimeout()` çağrılmıyor
- Yeni kelime gelmiyor

---

**Not:** Bu özet, Gemini'nin sorunu anlayıp çözüm önermesi için hazırlanmıştır. Tüm ilgili dosyalar `lib/features/cargo_categories/` klasöründe bulunmaktadır.

