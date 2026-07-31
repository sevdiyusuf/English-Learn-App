# Sprint 12B — Performance Monitoring & Optimization Baseline

This document records the automated verification, post-optimization size baselines, manual profile acceptance results, and operational observations for the application on branch `sprint-12b-performance-clean`.

---

## 1. Automated Verification Results

* **Test Suite Result**: **334/334 tests passed** (`flutter test --reporter=compact`)
* **Static Analyzer Result**: **0 errors, 0 warnings** (`dart analyze lib test` / `flutter analyze --no-fatal-infos`)
* **Dependency Provenance Validation**: **Passed** (`8 content records, 197 resolved packages` verified via `tool/provenance_validator.dart`)
* **Git Diff Check**: Clean (`git diff --check` reported 0 whitespace issues)
* **Debug APK Build**: Success (`build/app/outputs/flutter-apk/app-debug.apk`)
* **Release AAB Build**: Success (`build/app/outputs/bundle/release/app-release.aab`)

---

## 2. Release Android App Bundle (AAB) Size Baseline

* **Build Command**: `flutter build appbundle --release --analyze-size --target-platform android-arm64`
* **Pre-Optimization AAB Baseline**: **40.7 MB**
* **Analysis File**: `build/app-code-size-analysis_01.json`

### Zip Base Archive Breakdown (Historical Baseline)
* **Dart AOT Compiled Code (`libapp.so`)**: 18.2 MB (45.0% of base archive)
* **Bundled Assets (`flutter_assets`)**: 13.9 MB (34.4% of base archive)
* **Flutter Engine (`libflutter.so`)**: 6.6 MB (16.3% of base archive)

### Asset Inventory & Size Optimizations
* Removed unreferenced image `assets/images/example_app.png` (**900 KB**).
* **Authoritative Optimized AAB Size**: **39.8 MB** (net **~900 KB size reduction**).

---

## 3. Custom Performance Trace Dictionary & Privacy Safeguards

| Trace Name | Measured Lifecycle Boundary | Allowed Categorical Attributes |
|---|---|---|
| `app_bootstrap` | Initialization of core services (`bootstrapApp()`) | `stage: 'bootstrap'` |
| `lesson_load` | Grammar lesson load (`lessonDocProvider`) | `content_type: 'grammar_lesson'` |
| `worksheet_load` | Worksheet catalog load (`loadWorksheet`) | `content_type: 'worksheet'` |
| `sync_cycle` | Outbox push, pull, migration (`_runBootstrap`) | `operation: 'sync_bootstrap'` |

* **Controlled Vocabulary Validation**: All attribute values are strictly validated against low-cardinality controlled vocabularies. High-cardinality IDs (`uid`, `room_id`, `lesson_id`, `set_id`), user free text, exception messages, emails, and tokens are strictly rejected.

---

## 4. Physical Android Profile Mode Acceptance Results

Physical device testing was conducted using `flutter run --profile`.

### Visual & Usability Acceptance
- App was fully usable without obvious jank or visual stuttering.
- Lesson navigation transitions were visually smooth.
- Worksheet catalog and Grammar Arena navigation transitions were visually smooth.

### Logcat Metric Verification (`adb logcat -s FirebasePerformance`)
Diagnostic logcat emission was enabled strictly for profile builds (`android/app/src/profile/AndroidManifest.xml`) and verified:
- `app_bootstrap`: **VERIFIED** (emitted and logged)
- `lesson_load`: **VERIFIED** (emitted and logged)
- `worksheet_load`: **VERIFIED** (emitted and logged)
- `sync_cycle`: **VERIFIED** (emitted and logged)

### Firestore Smoke Observation
- **Reads**: 33
- **Writes**: 6
- **Snapshot Listeners (Peak)**: 5

### Firebase Console Dashboard Status
- Asynchronous metrics ingestion into the Firebase Console Performance dashboard remains pending and is non-blocking, as client-side metric emission has been verified directly in profile logcat output.

*(Note: Quantitative benchmarks such as exact cold/warm startup milliseconds, precise jank frame percentages, and peak heap MB were not measured on physical test hardware during this sprint and remain recommendations for future benchmark testing.)*

---

## 5. Discovered Non-12B Operational Issue & Resolution Status

* **Grammar Arena Timestamp Callable Bug**: Resolved on client boundary. `ArenaPlayer` callable payloads now pass only primitive fields (`name`, `photoUrl`), eliminating the `Invalid argument: Instance of 'Timestamp'` exception while preserving global `TimestampConverter` semantics for Firestore document storage.
* **Production Firebase Functions Deployment Drift**: Subsequent physical testing confirmed that client requests reach Cloud Functions, but return `[firebase_functions/not-found] NOT_FOUND` because `createArenaRoom` and the Grammar Arena callable group are not yet deployed to the live production Firebase project.
  * **Cause**: Pre-existing operational deployment gap; `functions/src/index.ts` contains the full implementation but backend has not been deployed.
  * **Resolution Requirement**: Firebase Functions deployment synchronization must be executed post-Sprint 12B integration before the next web/client release acceptance.
