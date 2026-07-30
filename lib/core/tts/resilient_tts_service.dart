import 'dart:async';

import 'package:flutter_tts/flutter_tts.dart';

enum TtsOutcome { completed, unavailable, timeout, failed, cancelled, disposed }

abstract interface class TtsEngine {
  Future<Object?> isLanguageAvailable(String language);
  Future<Object?> setLanguage(String language);
  Future<Object?> setPitch(double pitch);
  Future<Object?> setSpeechRate(double rate);
  Future<Object?> speak(String text);
  Future<Object?> stop();
  void setCompletionHandler(void Function() handler);
  void setErrorHandler(void Function(Object? error) handler);
}

class FlutterTtsEngine implements TtsEngine {
  FlutterTtsEngine([FlutterTts? flutterTts])
    : _flutterTts = flutterTts ?? FlutterTts();

  final FlutterTts _flutterTts;

  @override
  Future<Object?> isLanguageAvailable(String language) async =>
      _flutterTts.isLanguageAvailable(language);

  @override
  Future<Object?> setLanguage(String language) async =>
      _flutterTts.setLanguage(language);

  @override
  Future<Object?> setPitch(double pitch) async => _flutterTts.setPitch(pitch);

  @override
  Future<Object?> setSpeechRate(double rate) async =>
      _flutterTts.setSpeechRate(rate);

  @override
  Future<Object?> speak(String text) async => _flutterTts.speak(text);

  @override
  Future<Object?> stop() async => _flutterTts.stop();

  @override
  void setCompletionHandler(void Function() handler) {
    _flutterTts.setCompletionHandler(handler);
  }

  @override
  void setErrorHandler(void Function(Object? error) handler) {
    _flutterTts.setErrorHandler(handler);
  }
}

class ResilientTtsService {
  ResilientTtsService({
    TtsEngine? engine,
    this.language = 'en-US',
    this.pitch = 1,
    this.speechRate = 0.5,
    this.timeout = const Duration(seconds: 8),
  }) : _engine = engine ?? FlutterTtsEngine();

  final TtsEngine _engine;
  final String language;
  final double pitch;
  final double speechRate;
  final Duration timeout;

  Completer<TtsOutcome>? _active;
  int _generation = 0;
  bool _disposed = false;

  Future<TtsOutcome> speak(String text) async {
    if (_disposed) return TtsOutcome.disposed;
    if (text.trim().isEmpty) return TtsOutcome.failed;

    await cancel();
    if (_disposed) return TtsOutcome.disposed;
    final generation = ++_generation;

    try {
      final available = await _engine.isLanguageAvailable(language);
      if (!_isSuccessfulAvailability(available)) {
        return TtsOutcome.unavailable;
      }
      if (!_isSuccessfulResult(await _engine.setLanguage(language)) ||
          !_isSuccessfulResult(await _engine.setPitch(pitch)) ||
          !_isSuccessfulResult(await _engine.setSpeechRate(speechRate))) {
        return TtsOutcome.failed;
      }
    } on Object {
      return TtsOutcome.failed;
    }
    if (_disposed || generation != _generation) {
      return _disposed ? TtsOutcome.disposed : TtsOutcome.cancelled;
    }

    final completer = Completer<TtsOutcome>();
    _active = completer;
    _engine.setCompletionHandler(() {
      if (!_disposed &&
          generation == _generation &&
          identical(_active, completer) &&
          !completer.isCompleted) {
        completer.complete(TtsOutcome.completed);
      }
    });
    _engine.setErrorHandler((_) {
      if (!_disposed &&
          generation == _generation &&
          identical(_active, completer) &&
          !completer.isCompleted) {
        completer.complete(TtsOutcome.failed);
      }
    });

    try {
      final result = await _engine.speak(text);
      if (!_isSuccessfulResult(result) && !completer.isCompleted) {
        completer.complete(TtsOutcome.failed);
      }
    } on Object {
      if (!completer.isCompleted) completer.complete(TtsOutcome.failed);
    }

    TtsOutcome outcome;
    try {
      outcome = await completer.future.timeout(timeout);
    } on TimeoutException {
      outcome = TtsOutcome.timeout;
      await _stopSafely();
    }
    if (identical(_active, completer)) _active = null;
    return outcome;
  }

  Future<void> cancel() async {
    _generation++;
    final active = _active;
    _active = null;
    if (active != null && !active.isCompleted) {
      active.complete(TtsOutcome.cancelled);
    }
    await _stopSafely();
  }

  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    _generation++;
    final active = _active;
    _active = null;
    if (active != null && !active.isCompleted) {
      active.complete(TtsOutcome.disposed);
    }
    await _stopSafely();
  }

  Future<void> _stopSafely() async {
    try {
      await _engine.stop();
    } on Object {
      // Stopping is best effort and is never a user-visible failure.
    }
  }

  bool _isSuccessfulAvailability(Object? value) =>
      value == true || value == 1 || value == '1';

  bool _isSuccessfulResult(Object? value) =>
      value == null || value == true || value == 1 || value == '1';
}
