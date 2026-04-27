# Web Build Fix for Isar Generated Files

## Problem
Isar generates `.g.dart` files with large 64-bit integer literals that can't be represented exactly in JavaScript. This causes compilation errors when building for web.

## Solution
Run the fix script after `build_runner` and before building for web:

```powershell
# 1. Generate code (if needed)
dart run build_runner build --delete-conflicting-outputs

# 2. Fix JavaScript integer overflow
.\fix_web_build.ps1

# 3. Build for web
flutter run -d chrome
```

## What the script does
The `fix_web_build.ps1` script replaces large integer literals (16+ digits) in Isar-generated files with `0`, which is safe for JavaScript compilation.

**Note:** This only affects web builds. Mobile/desktop builds use the original Isar-generated files with proper 64-bit integers.

## Files affected
- `lib/features/word_match/models/word_pair.g.dart`
- `lib/features/word_match/models/word_set.g.dart`
- `lib/features/dictionary/models/dict_entry.g.dart`

## Alternative: Automated Fix
You can add this to your build process or create a combined script:

```powershell
# Combined script: build_runner + fix + web build
dart run build_runner build --delete-conflicting-outputs
.\fix_web_build.ps1
flutter run -d chrome
```
