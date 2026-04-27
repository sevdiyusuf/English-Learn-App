# Grammar Bölümü – Teknik Rapor

Bu dokümanın amacı, projedeki **Grammar** bölümünü bir yapay zekânın tamamen anlayabileceği kadar ayrıntılı şekilde açıklamaktır:

- Veri kaynakları (lessons & worksheets)
- Domain modelleri (Lesson*, Story*, Worksheet*)
- UI akışı (Learn, Story, Training)
- Soru motorları (engine’ler) ve doğrulama mantığı
- Hangi seviye (A1–B2) için hangi worksheet’ler ve hangi derslerle eşleştikleri

Kod referansları:
- Grammar modelleri: [grammar_models.dart](file:///c:/ders/flutter/tamamm/lib/features/grammar/models/grammar_models.dart)
- Grammar repository & provider’lar:  
  - [grammar_repository.dart](file:///c:/ders/flutter/tamamm/lib/features/grammar/data/grammar_repository.dart)  
  - [grammar_providers.dart](file:///c:/ders/flutter/tamamm/lib/features/grammar/logic/grammar_providers.dart)
- Grammar UI sayfaları:  
  - [grammar_home_page.dart](file:///c:/ders/flutter/tamamm/lib/features/grammar/ui/pages/grammar_home_page.dart)  
  - [lesson_viewer_page.dart](file:///c:/ders/flutter/tamamm/lib/features/grammar/ui/pages/lesson_viewer_page.dart)  
  - [story_viewer_page.dart](file:///c:/ders/flutter/tamamm/lib/features/grammar/ui/pages/story_viewer_page.dart)
- Training tarafı:  
  - [training_models.dart](file:///c:/ders/flutter/tamamm/lib/features/training/models/training_models.dart)  
  - [training_repo.dart](file:///c:/ders/flutter/tamamm/lib/features/training/data/training_repo.dart)  
  - [training_home_page.dart](file:///c:/ders/flutter/tamamm/lib/features/training/ui/training_home_page.dart)  
  - [worksheet_page.dart](file:///c:/ders/flutter/tamamm/lib/features/training/ui/worksheet_page.dart)  
  - [training_session_controller.dart](file:///c:/ders/flutter/tamamm/lib/features/training/logic/training_session_controller.dart)  
  - Engine router: [engine_renderer.dart](file:///c:/ders/flutter/tamamm/lib/features/training/ui/engine_renderer.dart)  
  - Tek tek engine’ler: `engine_mcq.dart`, `engine_fill.dart`, `engine_tap.dart`, `engine_order.dart`, `engine_transform.dart`, `engine_error_spot.dart`, `engine_matching.dart`

---

## 1. Genel Mimari

Grammar bölümü tamamen **Training** altyapısının üzerine kuruludur:

- **Veri katmanı**
  - Grammar dersleri JSON: `assets/lessons/index.json` + `assets/lessons/<LEVEL>/<LESSON_ID>-lesson.json`
  - Training worksheet index’i: `assets/worksheets/index.json`
- **Domain modeller**
  - Grammar tarafı: `LessonIndex`, `LessonEntry`, `LessonDoc`, `MicroLesson`, `LessonCard`, `StoryMode`
  - Ortak soru modeli: `Worksheet`, `WorksheetItem`, `EngineType`, `TransformStep`
- **UI / akış**
  - Grammar ana sayfası aslında **TrainingHomePage** UI’sini yeniden kullanır:
    - [GrammarHomePage](file:///c:/ders/flutter/tamamm/lib/features/grammar/ui/pages/grammar_home_page.dart) → `TrainingHomePage(showAppBar: true)`
  - Worksheet kartına tıklayınca açılan bottom sheet’te:
    - **Learn**: o worksheet ile ilişkili grammar dersi varsa `LessonViewerPage`’e gider
    - **Train**: worksheet’i açıp normal training modunu başlatır
- **Engine mimarisi**
  - Tüm sorular, ortak bir router olan [EngineRenderer](file:///c:/ders/flutter/tamamm/lib/features/training/ui/engine_renderer.dart) ile çizilir.
  - Engine tipleri: `mcq`, `fill`, `tap`, `order`, `transform`, `error_spotting`, `matching`.

Özet: Grammar, “mikro ders + story” tarafını ekleyen bir katman; soru motoru ve worksheet mantığı tamamen Training modülünden miras alınıyor.

---

## 2. Veri Kaynakları ve Seviye Yapısı

### 2.1 Grammar Ders İndeksi (assets/lessons/index.json)

Dosya: `assets/lessons/index.json`

Model: [LessonIndex](file:///c:/ders/flutter/tamamm/lib/features/grammar/models/grammar_models.dart#L3-L29)

```json
{
  "levels": ["A1", "A2", "B1", "B2"],
  "lessons": {
    "A1": [ { ... LessonEntry ... }, ... ],
    "A2": [ ... ],
    "B1": [ ... ],
    "B2": []
  }
}
```

Her `LessonEntry`:

- `lesson_id`: `"A1-ART-01-lesson"` gibi benzersiz ID
- `title`: Ders başlığı
- `path`: JSON dosyasının yolu (`A1/A1-ART-01-lesson.json` vb.)
- `topic_tags`: Konu etiketleri
- `train_worksheet_id`: Bu dersle ilişkili worksheet ID’si (örn. `"A1-ART-01"`)

Bu index, `GrammarRepository.loadIndex()` ile yüklenir ve Riverpod üzerinden sunulur:
- `lessonIndexProvider`: tüm ders listesi
- `lessonDocProvider(lessonId)`: belirli bir `LessonDoc`’u yükler

### 2.2 Training Worksheet İndeksi (assets/worksheets/index.json)

Dosya: `assets/worksheets/index.json`

Model: [WorksheetMetadata](file:///c:/ders/flutter/tamamm/lib/features/training/models/training_models.dart#L20-L53)

```json
{
  "schema_version": "1.0",
  "levels": {
    "A1": [ { "worksheet_id": "...", "title": "...", "path": "...", "tags": [...] }, ... ],
    "A2": [ ... ],
    "B1": [ ... ],
    "B2": [ ... ]
  }
}
```

Yükleyen repo: [training_repo.dart](file:///c:/ders/flutter/tamamm/lib/features/training/data/training_repo.dart)

- `loadIndex()`:
  - `assets/worksheets/index.json` dosyasını okur
  - Her seviyedeki listeyi `WorksheetMetadata` listesine çevirir
  - Başlığın sonundaki parantez içlerini (`(mixed practice)` gibi) tag olarak çıkarır ve başlığı temizler.

Bu index, `trainingIndexProvider` ile UI’ya iletilir.

### 2.3 Seviye Bazında Grammar Dersleri ve Worksheet’ler

#### A1 – Dersler ve Worksheet’ler

**Grammar dersleri (A1) – LessonEntry → Worksheet mapping**

- `A1-ART-01-lesson` → "Articles: a/an/the + zero" → `train_worksheet_id = "A1-ART-01"`
- `A1-CAN-01-lesson` → "Can / Can't (Ability & Possibility)" → `"A1-CAN-01"`
- `A1-CU-01-lesson` → "Countable vs Uncountable Nouns" → `"A1-CU-01"`
- `A1-POSS-01-lesson` → "Possessive Adjectives & 's" → `"A1-POSS-01"`
- `A1-PREP-01-lesson` → "Prepositions of Place (In, On, At)" → `"A1-PREP-01"`
- `A1-PS-PC-01-lesson` → "Present Simple vs Continuous" → `"A1-PS-PC-01"`
- `A1-QUEST-01-lesson` → "Question Words (Wh- Questions)" → `"A1-QUEST-01"`
- `A1-THERE-01-lesson` → "There is / There are" → `"A1-THERE-01"`

**A1 worksheet listesi (assets/worksheets/index.json)**

- `A1-PS-PC-01` – Present Simple vs Present Continuous
- `A1-PS-PC-02` – Present Simple vs Present Continuous (new set)
- `A1-QUEST-01` – Questions (5W1H + do/does order)
- `A1-THERE-01` – There is / There are + some/any
- `A1-CU-01` – Countable vs Uncountable (basic)
- `A1-CU-02` – Countable vs Uncountable (basic) — new set
- `A1-ART-01` – Articles: a/an/the + zero (basic)
- `A1-PREP-01` – Prepositions of place (in/on/under/next to/between)
- `A1-POSS-01` – my/your/his/her/our/their + ’s
- `A1-CAN-01` – Can / can’t (ability) + simple requests

**Not:** Grammar dersi olan worksheet’ler: `A1-ART-01`, `A1-CAN-01`, `A1-CU-01`, `A1-POSS-01`, `A1-PREP-01`, `A1-PS-PC-01`, `A1-QUEST-01`, `A1-THERE-01`.  
Ek practice setleri (sadece Training): `A1-PS-PC-02`, `A1-CU-02`.

#### A2 – Dersler ve Worksheet’ler

**Grammar dersleri (A2) – LessonEntry → Worksheet mapping**

- `A2-COMP-01-lesson` → "Comparatives & Superlatives" → `A2-COMP-01`
- `A2-FUTURE-01-lesson` → "Future with Will & Going to" → `A2-FUTURE-01`
- `A2-FUTURE-02-lesson` → "Present Continuous (future) vs Going to" → `A2-FUTURE-02`
- `A2-ING-01-lesson` → "Gerunds vs Infinitives" → `A2-ING-01`
- `A2-PP-01-lesson` → "Present Perfect Simple" → `A2-PP-01`
- `A2-PS-PC-01-lesson` → "Past Simple vs Past Continuous" → `A2-PS-PC-01`
- `A2-PP-PS-01-lesson` → "Present Perfect vs Past Simple" → `A2-PP-PS-01`
- `A2-PPC-01-lesson` → "Present Perfect Continuous" → `A2-PPC-01`
- `A2-QUANT-01-lesson` → "Quantifiers (Much, Many, A lot of)" → `A2-QUANT-01`
- `A2-REL-01-lesson` → "Relative Clauses (Who, Which, That)" → `A2-REL-01`

**A2 worksheet listesi**

- `A2-FUTURE-01` – Will vs Be going to
- `A2-FUTURE-02` – Present Continuous (future) vs Going to
- `A2-PS-PC-01` – Past Simple vs Past Continuous (when/while)
- `A2-PP-PS-01` – Present Perfect vs Past Simple
- `A2-REL-01` – Relative Clauses (who/which/where)
- `A2-COMP-01` – Comparatives & Superlatives
- `A2-COMP-02` – Comparatives & Superlatives (mixed practice)
- `A2-PPC-01` – Present Perfect Continuous
- `A2-PP-01` – Past Perfect vs Past Simple
- `A2-QUANT-01` – Quantifiers
- `A2-ING-01` – Gerunds (-ing)

Grammar dersi olan worksheet’ler: yukarıdaki tüm A2’lerin çoğu (`A2-COMP-01`, `A2-FUTURE-01/02`, `A2-PS-PC-01`, `A2-PP-PS-01`, `A2-PPC-01`, `A2-PP-01`, `A2-QUANT-01`, `A2-ING-01`, `A2-REL-01`).  
Sadece training seti olarak ekstra: `A2-COMP-02`.

#### B1 – Dersler ve Worksheet’ler

**Grammar dersleri (B1)**

- `B1-ART-01-lesson` → "Advanced Articles & Nouns" → `B1-ART-01`
- `B1-COND-01-lesson` → "Conditionals: Zero, 1st & 2nd" → `B1-COND-01`
- `B1-FUT-01-lesson` → "Future Continuous & Future Perfect" → `B1-FUT-01`
- `B1-MODALS-01-lesson` → "Modals of Deduction (Must, Can't, Might)" → `B1-MODALS-01`
- `B1-PASSIVE-01-lesson` → "Passive Voice (Present/Past Simple)" → `B1-PASSIVE-01`
- `B1-PP-PS-02-lesson` → "Present Perfect vs Past Simple - Part 2" → `B1-PP-PS-02`
- `B1-PPC-PS-01-lesson` → "Past Perfect Continuous vs Past Simple" → `B1-PPC-PS-01`
- `B1-REL-01-lesson` → "Defining & Non-Defining Relative Clauses" → `B1-REL-01`
- `B1-REPORTED-01-lesson` → "Reported Speech" → `B1-REPORTED-01`
- `B1-USED-01-lesson` → "Used to vs Would (Past Habits)" → `B1-USED-01`

**B1 worksheet listesi**

- `B1-PASSIVE-01`, `B1-PASSIVE-02` – Passive Voice
- `B1-MODALS-01`, `B1-MODALS-02` – Modals (should/must/have to…)
- `B1-REPORTED-01`, `B1-REPORTED-02`, `B1-REPORTED-03` – Reported Speech farklı alt beceriler
- `B1-COND-01` – Conditionals: Zero & First
- `B1-PP-PS-02` – Present Perfect vs Past Simple (for/since/how long)
- `B1-REL-01` – Relative Clauses
- `B1-PPC-PS-01` – Past Perfect Continuous vs Past Simple
- `B1-USED-01` – Used to vs Past Simple
- `B1-FUT-01` – Future Perfect vs Future Continuous
- `B1-ART-01` – Articles and meaning

Grammar dersi olan worksheet’ler:  
`B1-ART-01`, `B1-COND-01`, `B1-FUT-01`, `B1-MODALS-01`, `B1-PASSIVE-01`, `B1-PP-PS-02`, `B1-PPC-PS-01`, `B1-REL-01`, `B1-REPORTED-01`, `B1-USED-01`.

Sadece training için ek setler: `B1-PASSIVE-02`, `B1-MODALS-02`, `B1-REPORTED-02`, `B1-REPORTED-03`.

#### B2 – Sadece Training Worksheet’leri

`assets/lessons/index.json` içinde `B2` listesi şu an boş → Grammar mikro dersi yok.  
Worksheet’ler (sadece Training modunda):

- `B2-PASSIVE-02` – Passive Advanced (perfect + modals)
- `B2-REPORTED-01` – Reported Speech (questions & commands)
- `B2-COND-01` – Conditionals (Second & Third + mixed)
- `B2-REL-01` – Relative Clauses Advanced (non-defining + reduced)
- `B2-VERB-01` – Verb Patterns (gerund vs infinitive)
- `B2-PMOD-01` – Perfect modals
- `B2-WISH-01` – Wish and If only
- `B2-INV-01` – Inversion
- `B2-LINK-01` – Linking words

---

## 3. Domain Modelleri

### 3.1 Grammar – Ders Modeli

Dosya: [grammar_models.dart](file:///c:/ders/flutter/tamamm/lib/features/grammar/models/grammar_models.dart)

#### LessonIndex

```dart
class LessonIndex {
  final List<String> levels; // ["A1","A2","B1","B2"]
  final Map<String, List<LessonEntry>> lessonsByLevel;
}
```

#### LessonEntry

Her satır `assets/lessons/index.json` içindeki bir ders:

- `lessonId` – `"A2-COMP-01-lesson"`
- `title` – ders adı
- `path` – JSON yolu
- `topicTags` – grammar etiketi
- `trainWorksheetId` – ilişkili worksheet (Training tarafına köprü)

#### LessonDoc

Tek bir ders dosyası (`A1/A1-ART-01-lesson.json`) şu alanlara map edilir:

- `schemaVersion`
- `level` – `"A1"`, `"A2"` vb.
- `lessonId`
- `title`
- `topicTags`
- `microLesson` – kart bazlı mikro ders
- `storyMode` – opsiyonel story temelli practice
- `trainWorksheetId` – tekrar Training ile bağlantı

#### MicroLesson ve LessonCard

- `MicroLesson.cards`: `List<LessonCard>`
- `LessonCard`:
  - `id`
  - `type`: `LessonCardType` enum
    - `goal`, `rule`, `tip`, `common_mistake`, `examples`, `formula`, `checkpoint`, `unknown`
  - `title` (opsiyonel)
  - `bullets` – madde madde açıklamalar
  - `formula` – yapı/formül satırları
  - `examples` – örnek cümleler
  - `checkpoint` – eğer `type == checkpoint` ise, içine gömülü bir **WorksheetItem** (soru)

Checkpoint kartı, Grammar Learn modunda kullanılan mini quiz kartıdır.

#### StoryMode

```dart
class StoryMode {
  final bool enabled;
  final String title;
  final List<String> introBullets;
  final List<WorksheetItem> items; // story içindeki sorular
  final List<String> recapBullets;
}
```

Story, Grammar’da engine tabanlı bir mini senaryo/practice dizisi olarak çalışır.

### 3.2 Training – Worksheet ve Soru Modeli

Dosya: [training_models.dart](file:///c:/ders/flutter/tamamm/lib/features/training/models/training_models.dart)

#### EngineType

```dart
enum EngineType { mcq, fill, tap, order, transform, error_spotting, matching, unknown }
```

JSON’daki `"engine"` string’i `EngineType.fromString` ile enum’a çevrilir.

#### Worksheet

Tek bir worksheet dosyası (`assets/worksheets/A2/A2-COMP-01.json`):

- `schemaVersion`
- `level`
- `worksheetId`
- `title`
- `topicTags`
- `subskills`
- `difficulty`
- `items`: `List<WorksheetItem>`

#### WorksheetItem

Tüm engine’ler için ortak soru modeli:

- `id`
- `engine`: `EngineType`
- `prompt`: soru metni / cümle vb.
- `answer`: `dynamic`
  - `String` veya `List<String>` veya bazı engine’lerde Map/list kombinasyonu; training logic, engine tipine göre yorumlar
- `hint`: opsiyonel ipucu
- `bank`: `List<String>` – özellikle `tap` / `order` için token listesi
- `options`: `List<String>` – `mcq` gibi seçenekler
- `steps`: `List<TransformStep>` – `transform` engine için çok adımlı yapı
- `raw`: JSON’un tamamı (fallback ve özel alanlar için)

#### TransformStep

Her adım:

- `type`
- `label` – adım açıklaması
- `options` – seçimler
- `answer` – doğru seçenek

---

## 4. UI Akışı: Learn, Story, Training

### 4.1 GrammarHome → TrainingHome → Learn/Train Seçimi

**GrammarHomePage**:  
[grammar_home_page.dart](file:///c:/ders/flutter/tamamm/lib/features/grammar/ui/pages/grammar_home_page.dart)

- Sadece `TrainingHomePage(showAppBar: true)` döner.
- Yani Grammar sekmesi, **görsel olarak Training sekmesinin aynısı**, fark Learn/Train sheet’inde ortaya çıkar.

**TrainingHomePage**:  
[training_home_page.dart](file:///c:/ders/flutter/tamamm/lib/features/training/ui/training_home_page.dart)

- Sekmeler: `A1`, `A2`, `B1`, `B2`, `Tense`
- Her sekmede `WorksheetMetadata` kartları listelenir.
- Worksheet karta tıklayınca `_showLearnTrainSelectionSheet(...)` çalışır.

**Learn/Train seçim bottom sheet’i** (_showLearnTrainSelectionSheet):

- Seçilen worksheet için:
  1. `lessonIndexProvider` üzerinden tüm Grammar dersleri alınır.
  2. Bütün `lessonIndex.lessonsByLevel.values` içinde dönülür.
  3. Bir ders şu koşullardan biriyle ilişkilendirilmiş sayılır:
     - `entry.trainWorksheetId == ws.worksheetId`  
     - veya `entry.lessonId == ws.worksheetId` (fallback)
- Eğer bir `lessonId` bulunduysa:
  - **Learn kartı aktif** (Mikro Ders)
  - Learn’e tıklayınca: `context.push('/grammar/learn/$lessonId');`
- Train kartı:
  - Eğer `subjectSummaries[ws.worksheetId]` birden fazla `worksheetIds` içeriyorsa, kullanıcıya bu gruptaki hangi worksheet’i açacağını soran ikinci bir sheet açılır.
  - Aksi halde direkt: `WorksheetPage`’e `path: ws.path` ile gider.

Sonuç: Grammar tarafının “girişi”, Training’in worksheet kartları üzerinden Learn/Train seçimiyle yapılır.

### 4.2 Learn Modu – LessonViewerPage (Mikro Ders)

Dosya: [lesson_viewer_page.dart](file:///c:/ders/flutter/tamamm/lib/features/grammar/ui/pages/lesson_viewer_page.dart)

Akış:

1. `LessonViewerPage(lessonId)` içinde `lessonDocProvider(lessonId)` izlenir:
   - `GrammarRepository.loadLesson(path)` ile ilgili `LessonDoc` yüklenir.
2. `doc.microLesson.cards` bir `PageView` içinde kart kart gösterilir.
3. AppBar:
   - Seviye etiketi (`A1`, `A2`, `B1`, `B2`) – renkleri `_getLevelColor`
   - Ders başlığı
   - Kart ilerlemesi: `currentIndex + 1 / cards.length`
4. İçerik:
   - `LessonCard.type != checkpoint` ise `_buildContentCard`:
     - `bullets`, `formula`, `examples` görsel olarak gösterilir.
   - `type == checkpoint` ise `_buildCheckpoint`:
     - Kart içindeki `WorksheetItem checkpoint` `EngineRenderer` ile çizilir.
     - Kullanıcının cevabı `_checkpointAnswer`’da tutulur.
     - “Check Answer” butonu ile cevap doğrulanır:
       - `item.answer` string ise, trim & lowercase karşılaştırma
       - `item.answer` liste ise, string karşılaştırma (basit eşitlik)
       - Sonuç: `_isCheckpointSolved` ve `_isCheckpointCorrect` güncellenir.
     - Eğer item.raw’de `explain` alanı varsa, çözüm açıklaması olarak gösterilir.
5. Navigasyon butonu:
   - Eğer son kart değilse:
     - `Next` ile bir sonraki karta geçilir, checkpoint state sıfırlanır.
   - Son kartta:
     - Eğer `doc.storyMode.enabled == true` → `Go to Story` ve `StoryViewerPage`’e navigasyon
     - Aksi halde, `doc.trainWorksheetId` tanımlıysa Training worksheet’ine geçer (`/training/worksheet?path=LEVEL/ID.json`)
     - Hiçbiri yoksa lesson sayfası kapanır.

**Özet:** Learn modu, konuyu kart kart anlatır; içte checkpoint kartları ile mini sorular sorar; en sonunda isteğe bağlı Story moduna ve/veya Training moduna kullanıcıyı taşır.

### 4.3 Story Modu – StoryViewerPage

Dosya: [story_viewer_page.dart](file:///c:/ders/flutter/tamamm/lib/features/grammar/ui/pages/story_viewer_page.dart)

Akış:

1. `StoryViewerPage(lessonId)` yine `lessonDocProvider` kullanır.
2. Eğer `_showRecap == true` ise, story bittikten sonraki **Recap** ekranı gösterilir.
3. Normal durumda:
   - `items = doc.storyMode.items` (tamamı `WorksheetItem` tipinde)
   - Progress bar oranı: `(currentIndex + 1) / items.length`
   - İlk item’dayken yukarıda `introBullets` gösterilir.
4. Her item:
   - `EngineRenderer` ile çizilir (herhangi bir engine tipi olabilir).
   - Kullanıcı cevabı `_currentAnswer` içinde tutulur.
   - “Check Answer” butonu:
     - Eğer `item.answer` string ise:
       - trim + lowercase karşılaştırma
     - Eğer `item.answer` liste ise:
       - İlk olarak kullanıcının cevabını normalize ederek liste içindeki herhangi biriyle eşleşip eşleşmediğine bakar (özellikle fill-type story soruları için).
       - Eğer hala yanlışsa ve `item.engine != EngineType.fill` ise, son çare olarak cevap listesiyle birebir karşılaştırma yapılır (`toString()`).
   - Sonuç: `_isSolved`, `_isCorrect` güncellenir, (ve varsa `item.raw['explain']` gösterilir).
5. Story içi navigasyon:
   - Cevap çözülmeden `Next` aktif değildir; önce `Check Answer`.
   - En son item’de `Show Recap` butonu çıkar ve `_showRecap = true` yapılır.
6. Recap ekranı:
   - `doc.storyMode.recapBullets` maddeler halinde gösterilir.
   - “Start Training Now”:
     - Eğer `doc.trainWorksheetId != null` → ilgili Training worksheet’ine `/training/worksheet?path=LEVEL/ID.json`
     - Aksi halde 2 kez `pop()` ile önce story, sonra lesson ekranından çıkılır.
   - “Back to Lessons”:
     - Story ve Lesson sayfalarını kapatır.

**Özet:** Story modu, engine tabanlı soruları bir hikâye/bağlam içinde ardışık olarak uygular, en sonunda Recap ve Training’e geçiş sunar.

### 4.4 Training Modu – WorksheetPage ve TrainingSessionController

Dosyalar:
- [worksheet_page.dart](file:///c:/ders/flutter/tamamm/lib/features/training/ui/worksheet_page.dart)
- [training_session_controller.dart](file:///c:/ders/flutter/tamamm/lib/features/training/logic/training_session_controller.dart)

Akış:

1. `WorksheetPage(path)` başlarken:
   - `initState` içinde `trainingSessionProvider.notifier.loadWorksheet(path)` çağrılır.
   - Bu, `TrainingRepository.loadWorksheet("assets/worksheets/$path")` üzerinden `Worksheet` verisini yükler.
2. `TrainingSessionController.loadWorksheet`:
   - Worksheet’in `items` listesi `shuffle()` ile karıştırılır.
   - Eğer engine `order` ise, `item.bank` içindeki tokenlar ayrıca karıştırılır.
   - Sonuç, `TrainingSessionState` olarak saklanır:
     - `currentIndex = 0`
     - `userAnswers = {}`
     - `results = {}` (her soru için doğru/yanlış)
     - `isLocked = false`
3. Kullanıcı her soru için:
   - `EngineRenderer` ile engine çizilir.
   - Kullanıcının geçici cevabı `_currentDraftAnswer` state’inde tutulur.
   - “KONTROL ET” butonuna basınca:
     - `TrainingSessionController.submitAnswer(_currentDraftAnswer)`:
       - `_validateAnswer(item, answer)` ile doğru/yanlış hesaplanır.
       - `userAnswers[item.id]` ve `results[item.id]` güncellenir.
       - `isLocked = true`
   - Sonra alt barda:
     - Doğru/yanlış renklendirilmiş panel
     - Yanlışsa doğru cevap gösterilir.
     - “DEVAM ET” butonu ile `nextQuestion()`:
       - `currentIndex` artırılır
       - Son soruda ise skor hesaplanır, SharedPreferences’a kaydedilir ve TrainingHome için update trigger atılır.
4. Bütün sorular bittiğinde:
   - `WorksheetPage` state listener’ı `currentIndex >= items.length` olduğunda `ResultPage`’e navigasyon yapar.

**Özet:** Training modu, sadece EngineRenderer + `TrainingSessionController._validateAnswer` mantığına dayalı klasik quiz akışıdır; Grammar sadece bu mode’a yönlendirir.

---

## 5. Engine’ler ve Mantıkları

Tüm engine’ler [EngineRenderer](file:///c:/ders/flutter/tamamm/lib/features/training/ui/engine_renderer.dart) üzerinden seçilir:

```dart
switch (item.engine) {
  case EngineType.mcq:        return EngineMcq(...);
  case EngineType.fill:       return EngineFill(...);
  case EngineType.tap:        return EngineTap(...);
  case EngineType.order:      return EngineOrder(...);
  case EngineType.transform:  return EngineTransform(...);
  case EngineType.error_spotting: return EngineErrorSpot(...);
  case EngineType.matching:   return EngineMatching(...);
  default: // Unknown
}
```

### 5.1 MCQ – Çoktan Seçmeli (EngineType.mcq)

Dosya: [engine_mcq.dart](file:///c:/ders/flutter/tamamm/lib/features/training/ui/engines/engine_mcq.dart)

- Kullanılan alanlar:
  - `item.prompt` – soru metni (çoğunlukla içinde `____` boşluk olan cümle)
  - `item.options` – seçenekler
  - `item.answer` – doğru seçenek (string)
- UI:
  - Prompt üstte kutu içinde gösterilir.
  - Her seçenek, tıklanabilir kart olarak listelenir.
- Durum:
  - `selected` – kullanıcının seçtiği string
  - `isLocked == false` iken:
    - Seçilen seçenek primary renk ile vurgulanır.
  - `isLocked == true` iken:
    - Kullanıcı seçimi doğruysa: yeşil (success)
    - Yanlışsa: kırmızı (error), ayrıca doğru cevap hafif yeşil ile işaretlenir.

**Doğrulama (Training)**  
`TrainingSessionController._validateAnswer`:

```dart
case EngineType.mcq:
case EngineType.tap:
  return answer.toString() == item.answer.toString();
```

Yani basit string eşitliği.

Grammar tarafında (checkpoint/story):
- Learn modunda checkpoint: string vs list olarak manuel kontrol yapar.
- Story modunda benzer string eşitliği ile kontrol yapılır.

### 5.2 Fill – Boşluk Doldurma / Kısa Cevap (EngineType.fill)

Dosya: [engine_fill.dart](file:///c:/ders/flutter/tamamm/lib/features/training/ui/engines/engine_fill.dart)

- Kullanılan alanlar:
  - `item.prompt` – soru metni
  - `item.answer` – string veya string listesi (alternatif kabul edilen cevaplar)
- UI:
  - Prompt kutu içinde.
  - Tek satırlık TextField ile cevap girilir.
- Durum:
  - `currentText` – kullanıcının girdiği cevap
  - `isLocked` olduğunda TextField disable edilir ve arkaplan rengi değişir.

**Doğrulama (Training)**

```dart
case EngineType.fill:
  final normalizedUser = _normalize(answer.toString());
  if (item.answer is List) {
    final accepted = (item.answer as List)
        .map((e) => _normalize(e.toString()))
        .toList();
    return accepted.contains(normalizedUser);
  } else {
    return normalizedUser == _normalize(item.answer.toString());
  }
```

`_normalize`:
- `trim`
- `toLowerCase`
- birden fazla boşluğu tek boşluğa indirger

Grammar Learn & Story modunda:
- Checkpoint ve story’de de string/alternatif listesine göre benzer trim+lowercase mantığıyla kontrol yapılır.

### 5.3 Tap – Bankadan Kelime Seçme (EngineType.tap)

Dosya: [engine_tap.dart](file:///c:/ders/flutter/tamamm/lib/features/training/ui/engines/engine_tap.dart)

- Kullanılan alanlar:
  - `item.prompt` – boşluklu cümle (çoğunlukla `____`)
  - `item.bank` – altta gösterilen seçilebilir kelime/ifadeler
  - `item.answer` – doğru kelime (string)
- UI:
  - Prompt üstte.
  - Altta Wrap içinde token butonları (kelime chip’leri).
- Davranış:
  - `selected` = seçilen token
  - `isLocked == false` iken:
    - Seçilen token primary renkte, diğerleri nötr.
  - `isLocked == true` iken:
    - Doğru seçim yeşil, yanlış seçim kırmızı, doğru kelime hafif yeşil.

**Doğrulama**  
`mcq` ile aynı: seçilen string doğrudan `item.answer` ile karşılaştırılır.

### 5.4 Order – Kelime Sıralama (EngineType.order)

Dosya: [engine_order.dart](file:///c:/ders/flutter/tamamm/lib/features/training/ui/engines/engine_order.dart)

- Kullanılan alanlar:
  - `item.bank` – tüm kelime/token bankası
  - `item.answer` – doğru sıralama (list)
- UI:
  - Üstte prompt + (locked ise) doğru cevap string olarak.
  - Ortada “Sentence line”: kullanıcının oluşturduğu cümle:
    - Seçilen tokenlar burada gösterilir, tıklayarak geri bankaya gönderebilir.
  - Altta token bankası:
    - Henüz seçilmemiş tokenlar listelenir, tıklanarak cümle satırına eklenir.

**Training doğrulaması**:

```dart
case EngineType.order:
  if (answer is List && item.answer is List) {
    // aynı uzunluk ve aynı sıradaki öğeler eşit olmalı
  }
```

Yani tamamen sıralı liste eşitliği.

Story / checkpoint tarafında:
- Eğer story’de order kullanılırsa, StoryViewerPage’de fallback olarak `answer.toString() == item.answer.toString()` ile karşılaştırma var (çok daha kaba ama yeterli).

### 5.5 Transform – Adım Adım Dönüşüm (EngineType.transform)

Dosya: [engine_transform.dart](file:///c:/ders/flutter/tamamm/lib/features/training/ui/engines/engine_transform.dart)

- Kullanılan alanlar:
  - `item.prompt` – ana cümle/görev
  - `item.steps` – `TransformStep` listesi
    - Her step: `label`, `options`, `answer`
  - `item.answer` veya `raw['final_answer']` – final cümle (locked durumda bilgi amaçlı gösterilir)
- UI:
  - Prompt kutusu
  - Her step için:
    - Step başlığı: `1. label`
    - Altında seçenek butonları
    - Locked ise her step için ayrı doğru/yanlış ikonları
- Durum:
  - `currentAnswer`: List<String> – her step için seçilen seçenek

**Training doğrulaması**:

```dart
case EngineType.transform:
  if (answer is List && item.steps.isNotEmpty) {
    // her step için seçilen option == step.answer olmalı
  } else {
    // fallback: normalize(answer) == normalize(item.answer)
  }
```

Story tarafında:
- Transform içeren story item’ları da aslında `WorksheetItem` olduğu için, yine `StoryViewerPage`’de string/list eşitliği mantığıyla değerlendirilir (genelde cevaplar final cümle veya token listesi şeklinde olur).

### 5.6 Error Spotting – Cümleyi Düzeltme (EngineType.error_spotting)

Dosya: [engine_error_spot.dart](file:///c:/ders/flutter/tamamm/lib/features/training/ui/engines/engine_error_spot.dart)

- Kullanılan alanlar:
  - `item.prompt` – başlangıçta gösterilen cümle (hatalı)
  - `item.hint` – ipucu
  - `item.answer` – düzeltilmiş doğru cümle (string)
- UI:
  - Varsa hint üstte italik gösterilir.
  - Ana kutu içinde:
    - Başta, kullanıcı düzenlemeye başlayana kadar prompt gösterilir.
    - Kullanıcı düzenlemek için tıklar → TextField açılır → cümleyi düzeltir.
- Durum:
  - `currentAnswer`: kullanıcının yazdığı cümle
  - `isLocked`: sorunun kilitli olup olmadığı

**Doğrulama:**

- Engine içi:
  - `isCorrect = widget.isLocked && (currentAnswer.trim() == item.answer)`  
    (TrainingController içinde bu engine tipi için ayrı case yok; doğruluk görsel olarak burada hesaplanıyor.)
- Locked ve yanlışsa:
  - Alt tarafta “Correct Answer:” kutusunda doğru cümle gösterilir.

Grammar Learn/Story:
- Bu engine tipi Grammar tarafında da kullanılabilir; story/ checkpoint kontrolü yine string/list eşitliği mantığı ile yapılır.

### 5.7 Matching – Eşleştirme (EngineType.matching)

Dosya: [engine_matching.dart](file:///c:/ders/flutter/tamamm/lib/features/training/ui/engines/engine_matching.dart)

- Kullanılan alanlar:
  - `item.answer` – `Map<String,String>` yapısında beklenir (left → right eşleşmeleri)
- UI:
  - Sol sütun: `leftItems` (map’in key’leri)
  - Sağ sütun: `rightItems` (map’in values listesi, karıştırılmış)
  - Kullanıcı:
    - Önce sol sütundan bir item seçer (`_selectedLeft`)
    - Sonra sağ sütundan bir item’a tıkladığında, o ikili eşleştirilir.

Durum:

- `currentMatches`: `Map<String, String>` – kullanıcının yaptığı eşleştirmeler
  - Eğer bir right item başka bir left ile eşleştirilmişse, yeni eşleştirme yapmadan önce eski eş silinir (tekil eşleştirme).
- `isLocked == true` olduğunda:
  - Sol ve sağ taraf için:
    - `Widget`’lar, `item.answer` map’ine bakarak doğru/yanlış renklendirilir.

**Doğrulama:**

- UI bu engine tipinde doğruluğu kendi içinde renklendiriyor.
- `TrainingSessionController._validateAnswer` şu an `matching` için özel bir case içermiyor; yani:
  - Training modunda bu engine tipe sahip soru varsa, global doğrulama `default` case’e düşer ve `false` döner.
  - Grammar Story veya checkpoint içinde kullanmak istenirse, `StoryViewerPage` ve `LessonViewerPage`’deki string/list kontrolleri matching için yeterli değildir.
- Pratikte:
  - Şu an matching muhtemelen daha çok görsel feedback için kullanılıyor; skor mantığında tam entegre değil (gelecekte `EngineType.matching` için `_validateAnswer` genişletilebilir).

---

## 6. Learn vs Training Modlarının Farkı

**Learn modu (Grammar / Mikro Ders)**

- Giriş:
  - TrainingHome’dan worksheet’e tıklanır → Learn & Train sheet
  - Learn butonu sadece ilgili `LessonEntry` bulunduysa aktiftir.
- İçerik:
  - Teorik anlatım + madde madde açıklamalar (`LessonCard`’lar)
  - Formüller, common mistakes, examples, tipler
  - Aralarda **checkpoint** kartları ile kısa sorular (EngineRenderer + WorksheetItem)
- Değerlendirme:
  - Checkpoint’lerde cevap **hemen** değerlendirilir, `item.answer` ile basit karşılaştırma:
    - string → trim + lowercase equality
    - list → liste string’i karşılaştırma
  - Eğer item.raw’de `explain` varsa, kullanıcıya açıklama gösterilir.
- Flow:
  - Son karttan sonra:
    - Eğer story mode açık → StoryViewerPage
    - Aksi halde direkt Training worksheet’ine yönlendirme

**Story modu (Grammar)**

- Daha bağlamsal/uygulamalı pratik:
  - Tüm sorular `StoryMode.items` listesinden gelen `WorksheetItem`’lar
- Değerlendirme:
  - Her soru için “Check Answer”:
    - string/list eşitliği, fill için alternatifler listesine bakma
    - Fallback olarak `answer.toString()` eşitliği
  - Doğruluk, story state’inde tutulur (`_isSolved`, `_isCorrect`).
- Flow:
  - Bütün sorular bitince recap bullet’ları gösterilir.
  - İstenirse aynı konunun Training worksheet’ine geçilir.

**Training modu**

- Tamamen quiz / practice odaklı:
  - Soru sayısı, skor, best score, seviye etiketleri, konu özeti butonu
- Değerlendirme:
  - Merkezde `TrainingSessionController._validateAnswer` var:
    - Engine tipine göre farklı karşılaştırma kuralları
    - Özellikle `fill` için normalize edilmiş string karşılaştırma
    - `order` ve `transform` için liste tabanlı exact equality
- Sonuç:
  - Best score SharedPreferences üzerinden tutulur.
  - TrainingHome’da worksheet kartları üzerinde % skor ve “Done” etiketi olarak görünür.

---

## 7. Grammar Bölümünün Özeti (AI için Kısa Rehber)

- Grammar alanı **kendi başına ayrı bir engine sistemi barındırmaz**; Training’in `WorksheetItem` + `EngineType` altyapısını kullanır.
- Grammar’ın eklediği ana şeyler:
  - `LessonDoc` ile yapılandırılmış **mikro ders** (MicroLesson + LessonCard)
  - `StoryMode` ile **story tabanlı uygulama soruları**
  - `lessonIndex` ve `trainWorksheetId` alanları ile Grammar ↔ Training mapping’i
- Kullanıcı akışı:
  1. Training/Grammar sekmesinde seviye & worksheet seçer.
  2. Sheet’te:
     - Learn → Grammar mikro dersine (`LessonViewerPage`)
     - Train → Training worksheet’ine (`WorksheetPage`)
  3. Learn içinde:
     - Kart kart konuyu öğrenir, checkpoint soruları çözer.
     - Varsa Story moduna geçer ve engine tabanlı soruları story bağlamında çözer.
     - En sonunda ilgili Training worksheet’ine “Start Training Now” ile geçer.
  4. Training içinde:
     - Sorular, engine’e göre değerlendirilir, skor hesaplanır ve kaydedilir.

