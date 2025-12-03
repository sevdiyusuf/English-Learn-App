# Yunoo - İngilizce Kelime Öğrenme Uygulaması
## Kapsamlı Proje Raporu

---

## 📋 İçindekiler
1. [Proje Genel Bakış](#proje-genel-bakış)
2. [Teknoloji Stack](#teknoloji-stack)
3. [Mimari Yapı](#mimari-yapı)
4. [Özellikler ve Modüller](#özellikler-ve-modüller)
5. [Veri Yönetimi](#veri-yönetimi)
6. [UI/UX Tasarım](#uiux-tasarım)
7. [Uygulama İşleyişi](#uygulama-işleyişi)
8. [Güvenlik ve Hata Yönetimi](#güvenlik-ve-hata-yönetimi)
9. [Platform Desteği](#platform-desteği)
10. [Geliştirme Araçları](#geliştirme-araçları)

---

## 🎯 Proje Genel Bakış

**Yunoo**, İngilizce kelime öğrenmeyi eğlenceli ve etkileşimli hale getiren kapsamlı bir Flutter uygulamasıdır. Uygulama, kullanıcılara çeşitli mini oyunlar ve alıştırmalar sunarak kelime öğrenme sürecini destekler.

### Proje Bilgileri
- **Proje Adı**: yunoo
- **Versiyon**: 1.0.0+1
- **Dart SDK**: ^3.7.0
- **Flutter Framework**: Latest stable
- **Platform**: Web (Primary), Mobile (Android/iOS), Desktop (Windows/Linux/macOS)

---

## 🛠 Teknoloji Stack

### Core Framework
- **Flutter**: Cross-platform UI framework
- **Dart**: 3.7.0+ (Null safety enabled)

### State Management
- **flutter_riverpod**: ^2.6.1
  - Reactive state management
  - Dependency injection
  - Provider-based architecture

### Routing & Navigation
- **go_router**: ^14.6.1
  - Declarative routing
  - Deep linking support
  - Code splitting için route modülleri

### Veritabanı & Storage
- **Isar**: ^3.1.0+1
  - NoSQL embedded database
  - Fast local storage
  - Cross-platform support
- **xxf_isar_flutter_libs**: ^3.1.0+2
  - Isar native libraries

### Backend & Cloud Services
- **Firebase Core**: ^3.7.0
- **Firebase Auth**: ^5.3.0
  - Kullanıcı kimlik doğrulama
- **Cloud Firestore**: ^5.4.4
  - Real-time database
  - Multiplayer oyun desteği
- **Cloud Functions**: ^5.2.1
  - Serverless backend logic
  - Region: us-central1

### UI & Assets
- **flutter_svg**: ^2.2.3
  - SVG icon desteği
- **Material Design 3**: Modern UI components

### Utilities
- **path_provider**: ^2.1.5
  - Platform-specific path access
- **connectivity_plus**: ^6.1.0
  - Network status monitoring

### Code Generation
- **freezed**: ^2.5.2
  - Immutable data classes
  - Union types
- **json_serializable**: ^6.8.0
  - JSON serialization
- **isar_generator**: ^3.1.0+1
  - Isar model generation
- **build_runner**: ^2.4.13
  - Code generation runner

### Development Tools
- **flutter_lints**: ^5.0.0
  - Linting rules
- **flutter_launcher_icons**: ^0.14.1
  - App icon generation

---

## 🏗 Mimari Yapı

### Clean Architecture Prensibi

Proje **Feature-Based Clean Architecture** prensibine göre organize edilmiştir:

```
lib/
├── app/                    # Uygulama seviyesi konfigürasyon
│   ├── app.dart            # Ana uygulama widget'ı
│   ├── di.dart             # Dependency Injection
│   ├── router.dart         # Routing konfigürasyonu
│   ├── theme.dart          # Tema tanımlamaları
│   └── routes/             # Route modülleri (code splitting)
│
├── core/                   # Paylaşılan core modüller
│   ├── animations/         # Animasyon utilities
│   ├── errors/             # Hata yönetimi
│   ├── network/            # Network utilities
│   ├── notifications/      # Bildirim servisleri
│   ├── repositories/       # Global repositories
│   ├── responsive/         # Responsive utilities
│   ├── theme/              # Tema renkleri
│   ├── utils/              # Utility fonksiyonlar
│   └── widgets/            # Paylaşılan widget'lar
│
└── features/               # Feature modülleri
    ├── auth/               # Kimlik doğrulama
    ├── cargo_categories/   # Cargo Categories oyunu
    ├── dictionary/         # Sözlük servisi
    ├── flash_opposites/    # Flash Opposites oyunu
    ├── flash_synonym/      # Flash Synonym oyunu
    ├── game/               # Multiplayer oyun
    ├── lobby/              # Oda yönetimi
    ├── mode_select/        # Mod seçim ekranı
    ├── word_echo/          # Word Echo oyunu
    └── word_match/         # Word Match modülü
```

### Her Feature Modülü Yapısı

Her feature modülü aşağıdaki yapıyı takip eder:

```
feature_name/
├── data/           # Data layer (repositories, services)
├── logic/           # Business logic (controllers)
├── models/          # Data models
└── ui/              # UI layer (pages, widgets)
```

### Design Patterns

1. **Repository Pattern**
   - Data access abstraction
   - Interface-based implementation
   - Platform-specific implementations (Isar/Web)

2. **Provider Pattern (Riverpod)**
   - State management
   - Dependency injection
   - Reactive programming

3. **Controller Pattern**
   - Business logic encapsulation
   - State management
   - AsyncNotifier/NotifierProvider kullanımı

4. **Service Pattern**
   - Stateless business logic
   - Singleton services
   - Utility functions

---

## 🎮 Özellikler ve Modüller

### 1. Word Match (Kelime Eşleştirme)
**Amaç**: Kullanıcıların kendi kelime setlerini oluşturup pratik yapması

**Özellikler**:
- Kelime seti oluşturma/düzenleme/silme
- Kelime çiftleri ekleme (İngilizce-Türkçe)
- Eşleştirme oyunu (matching game)
- Öğrenme durumu takibi (learned/unlearned)
- Pratik geçmişi
- "Words from Games" global seti (otomatik oluşturulur, silinemez)

**Teknik Detaylar**:
- Isar database (mobil) / localStorage (web)
- Real-time set listesi güncellemeleri
- Session-based oyun akışı
- Round-based gameplay (8 kelime/round)

### 2. Flash Opposites (Zıt Anlamlı Kelimeler)
**Amaç**: Zıt anlamlı kelimeleri hızlı şekilde eşleştirme

**Özellikler**:
- 3 zorluk seviyesi (Easy, Medium, Hard)
- Düşen kelimeler animasyonu
- Timer-based gameplay
- Skor sistemi
- Pas hakkı (1 kez)
- Kelime kaydetme (Words from Games'e)

**Teknik Detaylar**:
- JSON-based word data
- Animasyonlu falling words
- State machine (loading → active → finished)
- Color-coded options

### 3. Flash Synonym (Eş Anlamlı Kelimeler)
**Amaç**: Eş anlamlı kelimeleri eşleştirme

**Özellikler**:
- Flash Opposites ile benzer yapı
- 3 zorluk seviyesi
- Timer-based gameplay
- Kelime kaydetme özelliği

### 4. Word Echo (Kelime Yansıması)
**Amaç**: Görsel hafıza ile kelime eşleştirme

**Özellikler**:
- 4 slot kart sistemi
- Sıralı kelime gösterimi
- Türkçe ipucu ile eşleştirme
- 2 hız modu (Normal, Fast)
- Timer-based gameplay
- Her kart için kelime kaydetme

**Teknik Detaylar**:
- Sequence-based gameplay
- Visual memory challenge
- Slot-based state management

### 5. Cargo Categories (Kategori Kargo)
**Amaç**: Kelimeleri kategorilere göre ayırma

**Özellikler**:
- Drag & drop mekanizması
- Konveyör bant animasyonu
- Kategori bazlı sınıflandırma
- Zorluk seviyeleri
- "Bilmediğim kelimeler" kaydetme barı
- Timer ve skor sistemi

**Teknik Detaylar**:
- Draggable/DragTarget widgets
- Conveyor belt simulation
- Category-based scoring

### 6. Multiplayer Game (Çok Oyunculu Oyun)
**Amaç**: Gerçek zamanlı çok oyunculu kelime oyunu

**Özellikler**:
- Oda oluşturma/katılma
- Real-time senkronizasyon (Firestore)
- Sıra bazlı oyun akışı
- Kelime doğrulama (Firebase Functions)
- Skor takibi
- Gerçek zamanlı bildirimler

**Teknik Detaylar**:
- Firestore real-time listeners
- Cloud Functions ile kelime doğrulama
- Room-based state management
- Timer service

### 7. Lobby System (Oda Sistemi)
**Özellikler**:
- Oda oluşturma
- Oda listesi görüntüleme
- Odaya katılma
- Oda hazırlık ekranı
- Oyuncu durumu takibi

### 8. Dictionary Service (Sözlük Servisi)
**Amaç**: Kelime doğrulama ve anlam arama

**Özellikler**:
- Lazy loading (non-blocking startup)
- Isar-based storage
- In-memory caching
- JSON-based dictionary data
- Kelime doğrulama API'si

**Teknik Detaylar**:
- Service interface pattern
- Multiple implementations (Isar/InMemory/Lazy)
- Background loading

---

## 💾 Veri Yönetimi

### Local Storage

#### Isar Database (Mobil/Desktop)
- **WordSet**: Kelime setleri
- **WordPair**: Kelime çiftleri
- **DictEntry**: Sözlük girişleri

**Özellikler**:
- Fast queries
- Indexing support
- Transaction support
- Stream-based reactive queries

#### Web Storage (localStorage)
- **WordMatchRepoWeb**: Web platform için localStorage implementation
- JSON-based serialization
- Set/Pair management

### Cloud Storage (Firebase)

#### Firestore Collections
- **rooms**: Oda bilgileri
- **games**: Oyun durumları
- **users**: Kullanıcı profilleri (opsiyonel)

#### Firebase Functions
- Kelime doğrulama
- Oyun logic validation
- Server-side business rules

### Data Models

#### Word Match Models
```dart
WordSet {
  int id
  String name
  DateTime createdAt
  DateTime updatedAt
  DateTime? lastPracticedAt
  bool isBuiltin
}

WordPair {
  int id
  int setId
  String english
  String turkish
  bool learned
}
```

#### Game Models
```dart
Room {
  String id
  String hostId
  List<String> playerIds
  RoomStatus status
  GameSettings settings
}

GameState {
  Room room
  List<PlayedWord> playedWords
  Map<String, bool> usedWords
}
```

---

## 🎨 UI/UX Tasarım

### Tema Sistemi

#### Light Theme
- Material Design 3
- ColorScheme.fromSeed
- Touch-friendly button sizes (min 48x48)
- Rounded corners (12px)

#### Dark Theme
- Custom dark color scheme
- Gradient background support
- Transparent AppBar
- High contrast text

### Renk Paleti (AppColors)
```dart
primary: Ana renk
accent: Vurgu rengi
success: Başarı durumu
error: Hata durumu
surfaceDark: Koyu yüzey
surfaceMedium: Orta yüzey
surfaceLight: Açık yüzey
textPrimary: Ana metin
textSecondary: İkincil metin
textTertiary: Üçüncül metin
```

### Responsive Design
- **ResponsiveUtils**: Ekran boyutu utilities
- **KeyboardShortcuts**: Klavye kısayolları
- Adaptive layouts
- Touch-friendly UI elements

### Animasyonlar
- **Falling words**: Flash Opposites/Synonym
- **Conveyor belt**: Cargo Categories
- **Card animations**: Word Echo
- **Gradient background**: Global background

### Widget Library
- **GradientBackground**: Gradient arka plan
- **LoadingWidget**: Loading states
- **LoadingSkeleton**: Skeleton loading
- **NetworkStatusIndicator**: Network durumu
- **NotificationBanner**: Bildirimler
- **ResponsiveButton**: Responsive butonlar
- **SvgIcon**: SVG icon wrapper

---

## 🔄 Uygulama İşleyişi

### Başlatma Süreci (Bootstrap)

1. **WidgetsFlutterBinding.ensureInitialized()**
   - Flutter engine initialization

2. **Bootstrap Process** (`bootstrapApp()`)
   - Firebase initialization
   - Firestore configuration
   - Dictionary service creation (lazy loading)
   - Error handling

3. **BootstrapWrapper Widget**
   - Loading state gösterimi
   - Error state handling
   - Success state → Ana uygulama

4. **ProviderScope Setup**
   - Dictionary service override
   - Global providers initialization

### Routing Akışı

```
/mode-select (Initial)
  ├── /word-match/* (Word Match routes)
  ├── /lobby/* (Lobby routes)
  ├── /game/* (Game routes)
  ├── /flash-opposites/* (Flash Opposites routes)
  ├── /flash-synonym/* (Flash Synonym routes)
  ├── /cargo-categories/* (Cargo Categories routes)
  └── /word-echo/* (Word Echo routes)
```

### State Management Akışı

1. **Provider Definition**
   ```dart
   final featureControllerProvider = 
     StateNotifierProvider<FeatureController, FeatureState>((ref) {
     return FeatureController(ref);
   });
   ```

2. **State Updates**
   - Controller içinde state değişiklikleri
   - Riverpod otomatik rebuild
   - UI reactive updates

3. **Dependency Injection**
   - Repository providers
   - Service providers
   - Cross-feature dependencies

### Veri Akışı

```
UI Layer (Widgets)
    ↓
Logic Layer (Controllers)
    ↓
Data Layer (Repositories/Services)
    ↓
Storage (Isar/Firestore/localStorage)
```

### Oyun Akışı Örneği (Flash Opposites)

1. **Setup Phase**
   - Level seçimi
   - Controller initialization
   - Word data loading

2. **Game Start**
   - Timer başlatma
   - İlk soru yükleme
   - Falling words animasyonu

3. **Gameplay Loop**
   - Soru gösterimi
   - Kullanıcı seçimi
   - Doğru/Yanlış feedback
   - Skor güncelleme
   - Sonraki soru

4. **Game End**
   - Skor hesaplama
   - Sonuç dialog
   - Tekrar oyna / Geri dön

---

## 🔒 Güvenlik ve Hata Yönetimi

### Hata Yönetimi

1. **AppException**
   - Custom exception types
   - User-friendly error messages
   - Error logging

2. **Try-Catch Blocks**
   - Critical operations
   - Network calls
   - Database operations

3. **Error UI**
   - Error screens
   - SnackBar notifications
   - Retry mechanisms

### Güvenlik

1. **Firebase Auth**
   - User authentication
   - Secure token management

2. **Firestore Security Rules**
   - Data access control
   - User-based permissions

3. **Input Validation**
   - Client-side validation
   - Server-side validation (Cloud Functions)

### Network Handling

1. **Connectivity Monitoring**
   - Network status provider
   - Offline mode detection
   - Connection retry logic

2. **Error Recovery**
   - Retry helper utilities
   - Timeout handling
   - Graceful degradation

---

## 📱 Platform Desteği

### Web (Primary)
- **Build**: `flutter build web --release`
- **Deployment**: Firebase Hosting
- **Storage**: localStorage
- **Features**: Full feature set

### Mobile
- **Android**: Full support
- **iOS**: Full support
- **Storage**: Isar database
- **Features**: Full feature set

### Desktop
- **Windows**: Supported
- **Linux**: Supported
- **macOS**: Supported
- **Storage**: Isar database

### Platform-Specific Implementations

1. **WordMatchRepo**
   - Isar implementation (mobile/desktop)
   - Web implementation (localStorage)

2. **Dictionary Service**
   - Isar implementation (mobile/desktop)
   - In-memory implementation (web)

3. **Storage Service**
   - Platform-specific paths
   - Browser storage (web)

---

## 🛠 Geliştirme Araçları

### Code Generation

1. **Freezed**
   ```bash
   flutter pub run build_runner build --delete-conflicting-outputs
   ```
   - Immutable models
   - Union types
   - CopyWith methods

2. **JSON Serializable**
   - JSON serialization
   - fromJson/toJson methods

3. **Isar Generator**
   - Database model generation
   - Index generation

### Linting
- **flutter_lints**: ^5.0.0
- **analysis_options.yaml**: Lint rules
- IDE integration

### Build Scripts

1. **Web Build**
   ```powershell
   flutter build web --release
   ```

2. **Firebase Deployment**
   ```powershell
   .\deploy_firebase.ps1
   ```

3. **Local Server**
   ```powershell
   .\start_server.ps1
   ```

### Development Workflow

1. **Feature Development**
   - Feature branch oluşturma
   - Clean architecture prensiplerine uyum
   - Test yazma (opsiyonel)

2. **Code Generation**
   - Model değişikliklerinden sonra
   - build_runner çalıştırma

3. **Testing**
   - Local testing
   - Web testing
   - Mobile testing

---

## 📊 Proje İstatistikleri

### Kod Yapısı
- **Toplam Feature**: 10 modül
- **Toplam Route**: 6 route grubu
- **Core Utilities**: 8 kategori
- **Widget Library**: 8 paylaşılan widget

### Veri Yapısı
- **JSON Assets**: 5 dosya (dictionary, opposites, synonym, cargo, word_echo)
- **Database Models**: 3 ana model (WordSet, WordPair, DictEntry)
- **Game Models**: 4 model (Room, GameState, PlayedWord, Category)

### Teknoloji Kullanımı
- **State Management**: Riverpod (100% coverage)
- **Routing**: GoRouter (100% coverage)
- **Database**: Isar (mobile/desktop), localStorage (web)
- **Backend**: Firebase (Auth, Firestore, Functions)
- **UI Framework**: Material Design 3

---

## 🚀 Gelecek Geliştirmeler (Öneriler)

1. **Offline Mode**
   - Tam offline desteği
   - Sync mekanizması

2. **Analytics**
   - Firebase Analytics
   - Kullanıcı davranış analizi

3. **Social Features**
   - Arkadaş sistemi
   - Leaderboard
   - Başarı rozetleri

4. **Content Management**
   - Admin panel
   - Kelime seti paylaşımı
   - Community sets

5. **Performance**
   - Code splitting optimization
   - Lazy loading improvements
   - Image optimization

---

## 📝 Sonuç

**Yunoo**, modern Flutter teknolojileri kullanılarak geliştirilmiş, kapsamlı bir kelime öğrenme uygulamasıdır. Clean architecture prensipleri, reactive state management, ve cross-platform desteği ile güçlü bir temel üzerine inşa edilmiştir.

Uygulama, kullanıcılara çeşitli eğlenceli oyunlar ve alıştırmalar sunarak İngilizce kelime öğrenme sürecini desteklemektedir. Multiplayer özellikleri, real-time senkronizasyon, ve kapsamlı veri yönetimi ile profesyonel bir kullanıcı deneyimi sunmaktadır.

---

**Rapor Tarihi**: 2024
**Versiyon**: 1.0.0
**Hazırlayan**: AI Assistant

