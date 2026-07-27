import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yunoo/core/tts/resilient_tts_service.dart';
import 'package:yunoo/features/irregular_verbs/logic/irregular_verbs_provider.dart';
import 'package:yunoo/features/irregular_verbs/models/irregular_verb.dart';
import 'package:yunoo/features/irregular_verbs/ui/irregular_verbs_tutorial_page.dart';
import 'package:yunoo/l10n/app_localizations.dart';

void main() {
  testWidgets('speak action succeeds without failure UI', (tester) async {
    final engine = WidgetTtsEngine();
    await _pumpPage(tester, engine: engine);

    await tester.tap(find.byTooltip('Hear pronunciation').first);
    await tester.pumpAndSettle();

    expect(engine.spoken, isNotEmpty);
    expect(
      find.text('Speech could not be played. Please try again.'),
      findsNothing,
    );
  });

  testWidgets('failure is localized, non-blocking, and retry succeeds', (
    tester,
  ) async {
    final engine = WidgetTtsEngine()..speakResult = 0;
    await _pumpPage(tester, engine: engine);

    await tester.tap(find.byTooltip('Hear pronunciation').first);
    await tester.pump();

    expect(
      find.text('Speech could not be played. Please try again.'),
      findsOneWidget,
    );
    expect(find.text('go'), findsWidgets);

    engine.speakResult = 1;
    await tester.tap(find.byTooltip('Hear pronunciation').first);
    await tester.pumpAndSettle();
    expect(engine.spoken.length, 2);
  });

  testWidgets('Turkish semantics and compact large text remain usable', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await _pumpPage(
      tester,
      engine: WidgetTtsEngine(),
      locale: const Locale('tr'),
      textScaler: const TextScaler.linear(2),
    );

    expect(find.byTooltip('Telaffuzu dinle'), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('navigation away during active speech is safe', (tester) async {
    final engine = WidgetTtsEngine()..autoComplete = false;
    final service = ResilientTtsService(engine: engine);
    await _pumpPage(tester, engine: engine, service: service);
    await tester.tap(find.byTooltip('Hear pronunciation').first);
    await tester.pump();

    await tester.pumpWidget(const MaterialApp(home: SizedBox()));
    await tester.pump();

    expect(tester.takeException(), isNull);
    await service.dispose();
  });
}

Future<void> _pumpPage(
  WidgetTester tester, {
  required WidgetTtsEngine engine,
  ResilientTtsService? service,
  Locale locale = const Locale('en'),
  TextScaler textScaler = TextScaler.noScaling,
}) async {
  final tts = service ?? ResilientTtsService(engine: engine);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        irregularVerbsProvider.overrideWith(
          (ref) async => const [
            IrregularVerb(
              v1: 'go',
              v2: 'went',
              v3: 'gone',
              meaningTr: 'gitmek',
            ),
          ],
        ),
      ],
      child: MaterialApp(
        locale: locale,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        builder:
            (context, child) => MediaQuery(
              data: MediaQuery.of(context).copyWith(textScaler: textScaler),
              child: child!,
            ),
        home: IrregularVerbsTutorialPage(ttsService: tts),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

class WidgetTtsEngine implements TtsEngine {
  Object? speakResult = 1;
  bool autoComplete = true;
  final List<String> spoken = [];
  void Function()? _completion;

  @override
  Future<Object?> isLanguageAvailable(String language) async => true;
  @override
  Future<Object?> setLanguage(String language) async => 1;
  @override
  Future<Object?> setPitch(double pitch) async => 1;
  @override
  Future<Object?> setSpeechRate(double rate) async => 1;
  @override
  Future<Object?> stop() async => 1;

  @override
  Future<Object?> speak(String text) async {
    spoken.add(text);
    if (speakResult == 1 && autoComplete) {
      scheduleMicrotask(() => _completion?.call());
    }
    return speakResult;
  }

  @override
  void setCompletionHandler(void Function() handler) {
    _completion = handler;
  }

  @override
  void setErrorHandler(void Function(Object? error) handler) {}
}
