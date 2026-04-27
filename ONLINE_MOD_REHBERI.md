# Online Mod (Word Battle) Rehberi

Bu rehber, Flutter uygulamanıza **Word Battle** benzeri bir online multiplayer modu nasıl ekleyeceğinizi adım adım açıklar. Yazılıma yeni başlayanlar için tasarlanmıştır.

## 📋 İçindekiler

1. [Genel Bakış](#genel-bakış)
2. [Gereksinimler](#gereksinimler)
3. [Mimari Yapı](#mimari-yapı)
4. [Adım Adım Implementasyon](#adım-adım-implementasyon)
5. [Firebase Kurulumu](#firebase-kurulumu)
6. [Kod Örnekleri](#kod-örnekleri)
7. [Test ve Debug](#test-ve-debug)

---

## 🎯 Genel Bakış

**Word Battle** benzeri bir online mod, kullanıcıların gerçek zamanlı olarak birbirleriyle yarışabileceği bir oyun modudur. Bu modda:

- Kullanıcılar **oda oluşturabilir** veya **mevcut odalara katılabilir**
- Her oda **5 haneli bir kod** ile tanımlanır (örn: `12345`)
- Oyuncular **sırayla** kelime girer (fiil → sıfat)
- Oyun **gerçek zamanlı** olarak Firestore üzerinden senkronize edilir
- Oyun mantığı **Cloud Functions** ile sunucu tarafında kontrol edilir

### Oyun Akışı

1. **Oda Oluşturma**: Bir oyuncu oda oluşturur, 5 haneli kod alır
2. **Odaya Katılma**: Diğer oyuncular kodu girerek odaya katılır
3. **Lobby**: Oyuncular hazır olana kadar bekler
4. **Oyun Başlatma**: Host oyunu başlatır
5. **Oyun**: Oyuncular sırayla kelime girer, süre sınırı vardır
6. **Kazanan**: En çok geçerli kelime giren oyuncu kazanır

---

## 🔧 Gereksinimler

### Teknolojiler

- **Flutter** (Dart 3.7+)
- **Firebase**:
  - **Firestore** (veritabanı)
  - **Cloud Functions** (sunucu mantığı)
  - **Firebase Auth** (kimlik doğrulama)
- **Riverpod** (state management)
- **go_router** (navigasyon)
- **Freezed** (data models)

### Paketler

```yaml
dependencies:
  cloud_firestore: ^5.0.0
  cloud_functions: ^5.0.0
  firebase_auth: ^5.0.0
  flutter_riverpod: ^2.5.0
  go_router: ^14.0.0
  freezed_annotation: ^2.4.0

dev_dependencies:
  build_runner: ^2.4.0
  freezed: ^2.4.0
  json_serializable: ^6.7.0
```

---

## 🏗️ Mimari Yapı

### Klasör Yapısı

```
lib/features/
├── lobby/              # Oda oluşturma/katılma
│   ├── data/
│   │   └── room_repo.dart      # Firestore işlemleri
│   ├── logic/
│   │   └── room_controller.dart # State management
│   └── ui/
│       ├── create_room_page.dart
│       ├── join_room_page.dart
│       └── room_lobby_page.dart
│
├── game/               # Oyun mantığı
│   ├── data/
│   │   └── game_repo.dart      # Oyun verileri
│   ├── logic/
│   │   └── game_controller.dart # Oyun state
│   ├── models/
│   │   ├── room.dart           # Oda modeli
│   │   ├── game_state.dart     # Oyun durumu
│   │   └── played_word.dart    # Girilen kelimeler
│   └── ui/
│       └── game_page.dart      # Oyun ekranı
│
└── auth/               # Kimlik doğrulama (mevcut)
```

### Veri Akışı

```
UI (Flutter)
    ↓
Controller (Riverpod)
    ↓
Repository (Firestore)
    ↓
Firestore Database
    ↓
Cloud Functions (Sunucu Mantığı)
```

---

## 📝 Adım Adım Implementasyon

### 1. Data Model Oluşturma

#### `lib/features/game/models/room.dart`

```dart
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

enum RoomStatus { waiting, active, finished }

@freezed
class Room with _$Room {
  const factory Room({
    String? id,
    String? roomCode,              // 5 haneli oda kodu
    @Default(RoomStatus.waiting) RoomStatus status,
    @Default(<String>[]) List<String> players,  // Oyuncu UID'leri
    @Default(<String, String>{}) Map<String, String> playerNames,
    @Default(0) int currentTurnIndex,
    String? currentTurnUid,         // Sıradaki oyuncu
    DateTime? turnDeadlineAt,      // Süre bitiş zamanı
    @Default(12) int turnDurationSeconds,
    String? winnerUid,
    required String hostUid,       // Oda sahibi
    required DateTime createdAt,
  }) = _Room;

  factory Room.fromJson(Map<String, dynamic> json) => _$RoomFromJson(json);
  
  // Firestore'dan okuma için özel factory
  factory Room.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Room.fromJson(data).copyWith(id: doc.id);
  }
}
```

**Önemli Noktalar:**
- `roomCode`: 5 haneli benzersiz kod (10000-99999)
- `status`: Oda durumu (beklemede, aktif, bitti)
- `players`: Oyuncu listesi (Firebase UID'leri)
- `playerNames`: UID → kullanıcı adı mapping

#### `lib/features/game/models/played_word.dart`

```dart
@freezed
class PlayedWord with _$PlayedWord {
  const factory PlayedWord({
    required String word,          // Girilen kelime
    required String type,          // 'verb' veya 'adjective'
    required String playerUid,      // Kim girdi
    required DateTime at,           // Ne zaman girildi
  }) = _PlayedWord;

  factory PlayedWord.fromJson(Map<String, dynamic> json) =>
      _$PlayedWordFromJson(json);
}
```

---

### 2. Repository Oluşturma

#### `lib/features/lobby/data/room_repo.dart`

Repository, Firestore ile iletişimi yönetir:

```dart
class RoomRepository {
  final FirebaseFirestore _firestore;
  
  CollectionReference<Map<String, dynamic>> get _roomsRef =>
      _firestore.collection('rooms');

  // Oda oluşturma
  Future<String> createRoom({
    required String hostUid,
    required String hostUsername,
    required int turnDurationSeconds,
  }) async {
    // 1. Benzersiz 5 haneli kod oluştur
    String roomCode = _generateUniqueRoomCode();
    
    // 2. Firestore'a oda ekle
    final doc = _roomsRef.doc();
    await doc.set({
      'roomCode': roomCode,
      'status': 'waiting',
      'players': [hostUid],
      'playerNames': {hostUid: hostUsername},
      'hostUid': hostUid,
      'createdAt': FieldValue.serverTimestamp(),
      // ... diğer alanlar
    });
    
    return doc.id; // Document ID döndür
  }

  // Odaya katılma
  Future<void> joinRoom({
    required String roomCode,
    required String uid,
    required String username,
  }) async {
    // 1. Odayı kod ile bul
    final rooms = await _roomsRef
        .where('roomCode', isEqualTo: roomCode)
        .where('status', isNotEqualTo: 'finished')
        .limit(1)
        .get();
    
    if (rooms.docs.isEmpty) {
      throw StateError('Oda bulunamadı');
    }
    
    // 2. Oyuncuyu ekle
    await rooms.docs.first.reference.update({
      'players': FieldValue.arrayUnion([uid]),
      'playerNames.$uid': username,
    });
  }

  // Odayı dinle (real-time)
  Stream<Room?> watchRoom(String roomId) {
    return _roomsRef.doc(roomId).snapshots().map((snapshot) {
      if (!snapshot.exists) return null;
      return Room.fromFirestore(snapshot);
    });
  }
}
```

**Önemli Noktalar:**
- `createRoom`: Yeni oda oluşturur, benzersiz kod üretir
- `joinRoom`: Odaya katılır (kod ile bulur)
- `watchRoom`: Real-time dinleme (Stream)

---

### 3. Controller Oluşturma

#### `lib/features/lobby/logic/room_controller.dart`

Controller, UI ile Repository arasında köprü görevi görür:

```dart
class RoomController extends StateNotifier<AsyncValue<void>> {
  final Ref _ref;
  RoomRepository get _repo => _ref.read(roomRepositoryProvider);

  // Oda oluştur
  Future<String> createRoom({
    required String username,
    required int turnDurationSeconds,
  }) async {
    state = const AsyncValue.loading();
    try {
      // 1. Kullanıcıyı al (Auth)
      final user = await _ref
          .read(authControllerProvider.notifier)
          .ensureAnonymousGuestSignedIn();
      
      // 2. Oda oluştur
      final roomId = await _repo.createRoom(
        hostUid: user.uid,
        hostUsername: username.trim(),
        turnDurationSeconds: turnDurationSeconds,
      );
      
      state = const AsyncValue.data(null);
      return roomId;
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      rethrow;
    }
  }

  // Odaya katıl
  Future<void> joinRoom({
    required String roomCode,
    required String username,
  }) async {
    state = const AsyncValue.loading();
    try {
      final user = await _ref
          .read(authControllerProvider.notifier)
          .ensureAnonymousGuestSignedIn();
      
      await _repo.joinRoom(
        roomCode: roomCode.trim(),
        uid: user.uid,
        username: username.trim(),
      );
      
      state = const AsyncValue.data(null);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      rethrow;
    }
  }
}
```

---

### 4. UI Sayfaları

#### `lib/features/lobby/ui/create_room_page.dart`

```dart
class CreateRoomPage extends ConsumerStatefulWidget {
  @override
  ConsumerState<CreateRoomPage> createState() => _CreateRoomPageState();
}

class _CreateRoomPageState extends ConsumerState<CreateRoomPage> {
  final _usernameController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  Future<void> _createRoom() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      final controller = ref.read(roomControllerProvider.notifier);
      final roomId = await controller.createRoom(
        username: _usernameController.text,
        turnDurationSeconds: 12,
      );

      // Oda oluşturuldu, lobby sayfasına git
      if (mounted) {
        context.go('/lobby/$roomId');
      }
    } catch (e) {
      // Hata göster
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Hata: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Oda Oluştur')),
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            TextFormField(
              controller: _usernameController,
              decoration: const InputDecoration(labelText: 'Kullanıcı Adı'),
              validator: (value) => value?.isEmpty ?? true 
                  ? 'Kullanıcı adı gerekli' 
                  : null,
            ),
            ElevatedButton(
              onPressed: _createRoom,
              child: const Text('Oda Oluştur'),
            ),
          ],
        ),
      ),
    );
  }
}
```

#### `lib/features/lobby/ui/join_room_page.dart`

```dart
class JoinRoomPage extends ConsumerStatefulWidget {
  @override
  ConsumerState<JoinRoomPage> createState() => _JoinRoomPageState();
}

class _JoinRoomPageState extends ConsumerState<JoinRoomPage> {
  final _roomCodeController = TextEditingController();
  final _usernameController = TextEditingController();

  Future<void> _joinRoom() async {
    try {
      final controller = ref.read(roomControllerProvider.notifier);
      await controller.joinRoom(
        roomCode: _roomCodeController.text,
        username: _usernameController.text,
      );

      // Odaya katıldı, room ID'yi bul ve lobby'ye git
      final repo = ref.read(roomRepositoryProvider);
      final roomId = await repo.getRoomIdByCode(_roomCodeController.text);
      
      if (roomId != null && mounted) {
        context.go('/lobby/$roomId');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Hata: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Odaya Katıl')),
      body: Column(
        children: [
          TextField(
            controller: _roomCodeController,
            decoration: const InputDecoration(labelText: 'Oda Kodu'),
            keyboardType: TextInputType.number,
            maxLength: 5,
          ),
          TextField(
            controller: _usernameController,
            decoration: const InputDecoration(labelText: 'Kullanıcı Adı'),
          ),
          ElevatedButton(
            onPressed: _joinRoom,
            child: const Text('Katıl'),
          ),
        ],
      ),
    );
  }
}
```

#### `lib/features/lobby/ui/room_lobby_page.dart`

Lobby sayfası, oyuncuların hazır olmasını bekler:

```dart
class RoomLobbyPage extends ConsumerWidget {
  final String roomId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Odayı real-time dinle
    final roomAsync = ref.watch(roomStreamProvider(roomId));

    return roomAsync.when(
      data: (room) {
        if (room == null) {
          return const Center(child: Text('Oda bulunamadı'));
        }

        // Oyun başladıysa oyun sayfasına git
        if (room.status == RoomStatus.active) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            context.go('/game/$roomId');
          });
        }

        return Scaffold(
          appBar: AppBar(title: Text('Oda: ${room.roomCode}')),
          body: Column(
            children: [
              // Oyuncu listesi
              ...room.players.map((uid) => ListTile(
                title: Text(room.playerNames[uid] ?? 'Bilinmeyen'),
                trailing: room.hostUid == uid 
                    ? const Text('👑 Host') 
                    : null,
              )),
              
              // Host ise "Oyunu Başlat" butonu
              if (room.hostUid == ref.read(authControllerProvider).value?.uid)
                ElevatedButton(
                  onPressed: () => _startGame(ref, roomId),
                  child: const Text('Oyunu Başlat'),
                ),
            ],
          ),
        );
      },
      loading: () => const CircularProgressIndicator(),
      error: (e, _) => Text('Hata: $e'),
    );
  }

  Future<void> _startGame(WidgetRef ref, String roomId) async {
    // Cloud Function'ı çağır
    final functions = FirebaseFunctions.instance;
    final callable = functions.httpsCallable('startGame');
    
    try {
      await callable.call({'roomId': roomId});
    } catch (e) {
      // Hata yönetimi
    }
  }
}
```

---

### 5. Oyun Sayfası

#### `lib/features/game/ui/game_page.dart`

```dart
class GamePage extends ConsumerWidget {
  final String roomId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Oyun durumunu dinle
    final gameStateAsync = ref.watch(gameControllerProvider(roomId));

    return gameStateAsync.when(
      data: (gameState) {
        final room = gameState.room;
        final currentUser = ref.read(authControllerProvider).value;
        final isMyTurn = room.currentTurnUid == currentUser?.uid;

        return Scaffold(
          appBar: AppBar(title: Text('Oda: ${room.roomCode}')),
          body: Column(
            children: [
              // Sıra göstergesi
              Text('Sıra: ${room.playerNames[room.currentTurnUid]}'),
              
              // Süre sayacı
              if (room.turnDeadlineAt != null)
                CountdownTimer(deadline: room.turnDeadlineAt!),
              
              // Kelime girişi (sıra bende ise)
              if (isMyTurn)
                WordInput(
                  onSubmitted: (word) => _submitWord(ref, roomId, word),
                ),
              
              // Girilen kelimeler listesi
              Expanded(
                child: WordPool(words: gameState.playedWords),
              ),
            ],
          ),
        );
      },
      loading: () => const CircularProgressIndicator(),
      error: (e, _) => Text('Hata: $e'),
    );
  }

  Future<void> _submitWord(
    WidgetRef ref,
    String roomId,
    String word,
  ) async {
    final controller = ref.read(gameControllerProvider(roomId).notifier);
    await controller.submitVerb(verb: word);
  }
}
```

---

## 🔥 Firebase Kurulumu

### 1. Firestore Kuralları

`firestore.rules` dosyası:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Kimlik doğrulama kontrolü
    function isAuthenticated() {
      return request.auth != null;
    }
    
    // Host kontrolü
    function isHost(roomData) {
      return isAuthenticated() && 
             request.auth.uid == roomData.hostUid;
    }
    
    // Rooms collection
    match /rooms/{roomId} {
      // Herkes okuyabilir (authenticated)
      allow read: if isAuthenticated();
      
      // Oda oluşturma: hostUid kendi UID'si olmalı
      allow create: if isAuthenticated() && 
                       request.resource.data.hostUid == request.auth.uid;
      
      // Oda güncelleme: host veya oyuncu olmalı
      allow update: if isAuthenticated() && (
        isHost(resource.data) ||
        request.auth.uid in resource.data.get('players', [])
      );
      
      // Oda silme: sadece host
      allow delete: if isHost(resource.data);
      
      // Played words subcollection
      match /playedWords/{wordId} {
        allow read: if isAuthenticated();
        // Sadece Cloud Functions yazabilir
        allow write: if false;
      }
    }
  }
}
```

### 2. Cloud Functions

`functions/src/index.ts`:

```typescript
import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';

admin.initializeApp();

// Oyunu başlat
export const startGame = functions.https.onCall(async (data, context) => {
  const { roomId } = data;
  if (!roomId) {
    throw new functions.https.HttpsError('invalid-argument', 'roomId gerekli');
  }

  const db = admin.firestore();
  const roomRef = db.collection('rooms').doc(roomId);
  
  return db.runTransaction(async (tx) => {
    const roomDoc = await tx.get(roomRef);
    if (!roomDoc.exists) {
      throw new functions.https.HttpsError('not-found', 'Oda bulunamadı');
    }

    const room = roomDoc.data()!;
    const players = room.players || [];
    
    if (players.length < 2) {
      throw new functions.https.HttpsError(
        'failed-precondition',
        'En az 2 oyuncu gerekli'
      );
    }

    // Rastgele ilk oyuncuyu seç
    const randomIndex = Math.floor(Math.random() * players.length);
    const firstPlayer = players[randomIndex];
    
    const now = admin.firestore.Timestamp.now();
    const deadline = new admin.firestore.Timestamp(
      now.seconds + 12, // 12 saniye süre
      now.nanoseconds
    );

    // Odayı aktif yap
    tx.update(roomRef, {
      status: 'active',
      currentTurnIndex: randomIndex,
      currentTurnUid: firstPlayer,
      turnDeadlineAt: deadline,
      currentWordType: 'verb', // İlk kelime fiil
    });

    // Kullanılan kelimeleri temizle
    const usedWordsRef = roomRef.collection('meta').doc('usedWords');
    tx.set(usedWordsRef, { used: {} }, { merge: true });

    return { success: true };
  });
});

// Kelime gönderme (fiil)
export const submitVerb = functions.https.onCall(async (data, context) => {
  const { roomId, verb } = data;
  const uid = context.auth?.uid;
  
  if (!uid || !roomId || !verb) {
    throw new functions.https.HttpsError('invalid-argument', 'Eksik parametre');
  }

  const db = admin.firestore();
  const roomRef = db.collection('rooms').doc(roomId);
  
  return db.runTransaction(async (tx) => {
    const roomDoc = await tx.get(roomRef);
    if (!roomDoc.exists) {
      throw new functions.https.HttpsError('not-found', 'Oda bulunamadı');
    }

    const room = roomDoc.data()!;
    
    // Sıra kontrolü
    if (room.currentTurnUid !== uid) {
      throw new functions.https.HttpsError(
        'permission-denied',
        'Sıra sizde değil'
      );
    }

    // Kelimeyi kaydet
    const playedWordsRef = roomRef.collection('playedWords');
    await playedWordsRef.add({
      word: verb.toLowerCase(),
      type: 'verb',
      playerUid: uid,
      at: admin.firestore.FieldValue.serverTimestamp(),
    });

    // Sırayı değiştir (sıfat bekleniyor)
    tx.update(roomRef, {
      currentWordType: 'adjective',
      currentVerb: verb.toLowerCase(),
    });

    return { success: true };
  });
});
```

---

## 🧪 Test ve Debug

### 1. Local Test

```bash
# Firestore emulator
firebase emulators:start --only firestore

# Cloud Functions emulator
firebase emulators:start --only functions
```

### 2. Debug İpuçları

- **Real-time dinleme**: `watchRoom` Stream'i düzgün çalışıyor mu?
- **Cloud Functions**: Firebase Console'da logları kontrol edin
- **Firestore Rules**: Test modunda kuralları gevşetin
- **Network**: İnternet bağlantısını kontrol edin

### 3. Yaygın Hatalar

1. **"Oda bulunamadı"**: Room code yanlış veya oda silinmiş
2. **"Sıra sizde değil"**: Turn management hatası
3. **"Permission denied"**: Firestore rules yanlış
4. **Real-time güncelleme yok**: Stream subscription çalışmıyor

---

## 📚 Özet

Online mod eklemek için:

1. ✅ **Data Models**: Room, PlayedWord, GameState
2. ✅ **Repository**: Firestore işlemleri
3. ✅ **Controller**: State management
4. ✅ **UI**: Create, Join, Lobby, Game sayfaları
5. ✅ **Firebase**: Firestore rules + Cloud Functions
6. ✅ **Routing**: go_router ile sayfa geçişleri

**Önemli Noktalar:**
- Real-time senkronizasyon için Stream kullanın
- Oyun mantığını Cloud Functions'da tutun (güvenlik)
- Firestore rules'u dikkatli yazın
- Error handling ekleyin
- Loading states gösterin

---

## 🎮 Sonuç

Bu rehberi takip ederek, Word Battle benzeri bir online multiplayer modu uygulamanıza ekleyebilirsiniz. Her adımı sırayla uygulayın ve test edin. Sorun yaşarsanız, Firebase Console loglarını kontrol edin.

**İyi kodlamalar! 🚀**
