import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:yunoo/core/tts/resilient_tts_service.dart';

void main() {
  group('ResilientTtsService', () {
    test('completes successful speech', () async {
      final engine = FakeTtsEngine();
      final service = ResilientTtsService(engine: engine);

      final result = service.speak('go');
      await engine.waitUntilSpoken();
      engine.complete();

      expect(await result, TtsOutcome.completed);
      expect(engine.spoken, ['go']);
    });

    test('reports unavailable language', () async {
      final engine = FakeTtsEngine()..available = false;
      final service = ResilientTtsService(engine: engine);

      expect(await service.speak('go'), TtsOutcome.unavailable);
      expect(engine.spoken, isEmpty);
    });

    test('reports configuration failure', () async {
      final engine = FakeTtsEngine()..configurationResult = 0;
      final service = ResilientTtsService(engine: engine);

      expect(await service.speak('go'), TtsOutcome.failed);
    });

    test('reports speak failure result', () async {
      final engine = FakeTtsEngine()..speakResult = 0;
      final service = ResilientTtsService(engine: engine);

      expect(await service.speak('go'), TtsOutcome.failed);
    });

    test('contains plugin exceptions', () async {
      final engine = FakeTtsEngine()..throwOnSpeak = true;
      final service = ResilientTtsService(engine: engine);

      expect(await service.speak('go'), TtsOutcome.failed);
    });

    test('times out when completion never arrives', () async {
      final engine = FakeTtsEngine();
      final service = ResilientTtsService(
        engine: engine,
        timeout: const Duration(milliseconds: 10),
      );

      expect(await service.speak('go'), TtsOutcome.timeout);
      expect(engine.stopCount, greaterThanOrEqualTo(2));
    });

    test('cancel is non-error outcome', () async {
      final engine = FakeTtsEngine();
      final service = ResilientTtsService(engine: engine);
      final result = service.speak('go');
      await engine.waitUntilSpoken();

      await service.cancel();

      expect(await result, TtsOutcome.cancelled);
    });

    test(
      'new request supersedes prior request and stale callback is ignored',
      () async {
        final engine = FakeTtsEngine();
        final service = ResilientTtsService(engine: engine);
        final first = service.speak('first');
        await engine.waitUntilSpoken();
        final staleCompletion = engine.completionHandlers.single;

        final second = service.speak('second');
        await engine.waitUntilSpoken(count: 2);
        var secondCompleted = false;
        unawaited(second.then((_) => secondCompleted = true));
        staleCompletion();
        await Future<void>.delayed(Duration.zero);
        expect(await first, TtsOutcome.cancelled);
        expect(secondCompleted, isFalse);

        engine.complete();
        expect(await second, TtsOutcome.completed);
      },
    );

    test('retry succeeds after transient failure', () async {
      final engine = FakeTtsEngine()..speakResult = 0;
      final service = ResilientTtsService(engine: engine);
      expect(await service.speak('go'), TtsOutcome.failed);

      engine.speakResult = 1;
      final retry = service.speak('go');
      await engine.waitUntilSpoken(count: 2);
      engine.complete();

      expect(await retry, TtsOutcome.completed);
    });

    test('dispose completes active request and rejects later work', () async {
      final engine = FakeTtsEngine();
      final service = ResilientTtsService(engine: engine);
      final active = service.speak('go');
      await engine.waitUntilSpoken();

      await service.dispose();

      expect(await active, TtsOutcome.disposed);
      expect(await service.speak('again'), TtsOutcome.disposed);
    });

    test('error callback produces failed outcome', () async {
      final engine = FakeTtsEngine();
      final service = ResilientTtsService(engine: engine);
      final result = service.speak('go');
      await engine.waitUntilSpoken();

      engine.fail();

      expect(await result, TtsOutcome.failed);
    });
  });
}

class FakeTtsEngine implements TtsEngine {
  bool available = true;
  Object? configurationResult = 1;
  Object? speakResult = 1;
  bool throwOnSpeak = false;
  int stopCount = 0;
  final List<String> spoken = [];
  final List<void Function()> completionHandlers = [];
  void Function()? completionHandler;
  void Function(Object? error)? errorHandler;

  @override
  Future<Object?> isLanguageAvailable(String language) async => available;

  @override
  Future<Object?> setLanguage(String language) async => configurationResult;

  @override
  Future<Object?> setPitch(double pitch) async => configurationResult;

  @override
  Future<Object?> setSpeechRate(double rate) async => configurationResult;

  @override
  Future<Object?> speak(String text) async {
    spoken.add(text);
    if (throwOnSpeak) throw StateError('platform failure');
    return speakResult;
  }

  @override
  Future<Object?> stop() async {
    stopCount++;
    return 1;
  }

  @override
  void setCompletionHandler(void Function() handler) {
    completionHandler = handler;
    completionHandlers.add(handler);
  }

  @override
  void setErrorHandler(void Function(Object? error) handler) {
    errorHandler = handler;
  }

  Future<void> waitUntilSpoken({int count = 1}) async {
    for (var i = 0; i < 50 && spoken.length < count; i++) {
      await Future<void>.delayed(Duration.zero);
    }
    expect(spoken.length, greaterThanOrEqualTo(count));
  }

  void complete() => completionHandler?.call();
  void fail() => errorHandler?.call('failed');
}
