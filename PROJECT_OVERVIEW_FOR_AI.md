# Yunoo / Tamamm - Project Technical Reference

This document provides a comprehensive technical deep-dive into the **Yunoo (Tamamm)** codebase. It is designed to give AI assistants complete context on architecture, game mechanics, data flows, and folder structures.

## 1. Project Identity & Stack
- **Name**: Yunoo (Package: `com.example.yunoo`)
- **Core Framework**: Flutter (Dart)
- **State Management**: **Riverpod** (Notifiers & AsyncNotifiers)
- **Routing**: **GoRouter** (Feature-based routes in `lib/app/routes/`)
- **Data Layer**:
  - **Isar**: High-performance NoSQL local DB (Dictionaries, Word Sets).
  - **Firebase**: Backend (Auth, Firestore for multiplayer, Functions).
  - **Shared Preferences**: Simple key-value storage (Settings).
- **Code Generation**: `build_runner` with `freezed`, `json_serializable`, `isar_generator`.

## 2. Architecture: Feature-First MVVM
The project strictly follows a **Feature-First** directory structure. Each feature is self-contained.

### Standard Feature Structure (`lib/features/<feature_name>/`)
*   **`data/`**: Repositories, Services, Data Sources.
    *   *Example*: `word_match_repo.dart` (Handles Isar DB operations).
*   **`logic/`**: State management (Riverpod Controllers).
    *   *Example*: `word_match_session_controller.dart` (Game logic, score tracking).
*   **`models/`**: Data classes (Freezed/Isar).
    *   *Example*: `word_set.dart` (Isar entity), `game_state.dart` (Freezed union).
*   **`ui/`**: Widgets and Pages.
    *   *Example*: `word_match_home_page.dart`.

### Core Layer (`lib/core/`)
Shared utilities accessible by all features.
*   **`audio/`**: `SoundManager` for playing SFX (correct, wrong, victory).
*   **`network/`**: `NetworkStatusProvider` for connectivity checks.
*   **`widgets/`**: Reusable UI components (`ResponsiveButton`, `GradientBackground`, `LoadingSkeleton`).
*   **`utils/`**: Helpers (`InputValidator`, `ToastUtils`).

## 3. Game Modes & Mechanics

### A. Word Match (`features/word_match`)
A tile-matching game where users pair words (e.g., English <-> Turkish).
*   **Data Model**:
    *   `WordSet` (Isar Collection): Contains metadata (name, visibility, `isBuiltin`).
    *   `WordPair` (Embedded): Contains `term` (L1) and `definition` (L2).
*   **Game Logic (`WordMatchSessionController`)**:
    *   Manages `WordMatchSessionState`.
    *   **Shuffling**: Maintains separate shuffled lists for Left (Terms) and Right (Definitions) columns.
    *   **Matching**: Checks `selectedLeftId` == `selectedRightId`.
    *   **Sync**: Supports Cloud Sync via Firestore (`cloudId` field in `WordSet`).
*   **Key Features**:
    *   **Custom Sets**: Users can create/edit their own word sets.
    *   **Personal Echo**: Sets created here can be used in the *Word Echo* game.

### B. Word Battle (`features/game`, `features/lobby`)
Real-time multiplayer word game.
*   **Architecture**:
    *   **Lobby**: Users create/join rooms stored in Firestore (`rooms` collection).
    *   **Game Loop**:
        1.  `GameController` subscribes to `watchRoom(roomId)` and `watchPlayedWords(roomId)`.
        2.  Players submit words -> Written to Firestore subcollection.
        3.  UI updates in real-time based on stream data.
*   **Normalization**: Inputs are trimmed, lowercased, and regex-cleaned before submission.
*   **States**: `RoomStatus` (waiting, active, finished).

### C. Word Echo (`features/word_echo`)
A memory and recall game.
*   **Mechanic**: A word/sequence is shown briefly, then hidden. The user must recall it or choose the correct match.
*   **Personal Echo Mode**:
    *   Injects data from **Word Match** sets.
    *   *Algorithm*: Selects 1 correct word from the user's set + 3 distractors (wrong answers) from `opposites.json` or other sources.
*   **Grid Mode**: A variant involving spatial memory (implied by `word_echo_grid_page.dart`).

### D. Training & Worksheets (`features/training`)
A structured learning engine driven by JSON content.
*   **Data Source**: JSON files in `assets/worksheets/` (e.g., A1, A2 levels).
*   **Engine System (`EngineRenderer`)**:
    *   The UI dynamically renders a widget based on the `engine` type field in the JSON item.
    *   **Supported Engines**:
        *   `mcq`: Multiple Choice Question.
        *   `fill`: Fill in the blank.
        *   `order`: Reorder words to form a sentence.
        *   `tap`: Tap the correct element.
        *   `transform`: Change word form (e.g., verb conjugation).
*   **State**: `TrainingSessionController` tracks current index, answers, and score.
*   **Metadata**: `WorksheetMetadata` caches progress (best score) locally.

### E. Flashcards (Opposites & Synonyms)
*   **Data**: Loaded from `assets/opposites.json` and `assets/synonym.json`.
*   **Adaptive Difficulty**: `AdaptiveDifficultyHelper` adjusts the pool of words based on user performance.

## 4. Key Configurations & Setup

### Database & Storage
*   **Isar**:
    *   Used for: `Dictionary`, `WordSet`, `UserStats`.
    *   Schema definitions: `*.g.dart` generated files.
*   **Assets**:
    *   Game data (JSON) is stored in `assets/`.
    *   Images/Icons in `assets/images/` or `assets/icons/`.

### Routing (GoRouter)
*   Routes are defined in `lib/app/routes/` and aggregated in `lib/app/router.dart`.
*   **Navigation**: Uses `context.goNamed()` or `context.pushNamed()`.

### Localization
*   **ARB Files**: `lib/l10n/app_en.arb` and `app_tr.arb`.
*   **Usage**: `AppLocalizations.of(context)!.key`.

## 5. Development Workflow Guidelines
*   **Adding a New Game**:
    1.  Create `lib/features/new_game/`.
    2.  Define State (Freezed) and Controller (Riverpod).
    3.  Add Route in `lib/app/routes/`.
    4.  Register in `lib/app/router.dart`.
*   **Modifying Worksheets**:
    *   Edit JSON files in `assets/worksheets/`.
    *   Ensure `schema_version` matches the parser.

## 6. Recent Updates
*   **Android Build**: `compileSdk` set to **35**.
*   **Build System**: Unified subproject build versions in `android/build.gradle.kts`.

---
*This file is optimized for AI context injection. Read this to understand the project's brain.*
