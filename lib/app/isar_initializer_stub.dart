import 'dart:async';
import 'package:flutter/foundation.dart';

/// Web platform stub for Isar startup initialization.
Future<void> initIsarStoreOnStartup() async {
  if (kDebugMode) {
    debugPrint('Web platform: Skipping Isar store startup initialization.');
  }
}
