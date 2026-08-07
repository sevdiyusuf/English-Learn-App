import 'dart:async';
import 'package:flutter/foundation.dart';
import '../features/dictionary/load_dictionary.dart';

/// Native IO platform implementation for Isar startup initialization.
Future<void> initIsarStoreOnStartup() async {
  try {
    debugPrint('🚀 Isar Başlatılıyor (Force Await)...');
    await openDictionaryStore();
    debugPrint('✅ Isar Başarıyla Başlatıldı!');
  } catch (e) {
    debugPrint('❌ Isar Başlatma Hatası: $e');
  }
}
