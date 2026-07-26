import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yunoo/l10n/app_localizations.dart';

Future<void> configureTestView(
  WidgetTester tester, {
  required Size logicalSize,
  EdgeInsets viewInsets = EdgeInsets.zero,
  EdgeInsets padding = EdgeInsets.zero,
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = logicalSize;
  tester.view.viewInsets = FakeViewPadding(
    left: viewInsets.left,
    top: viewInsets.top,
    right: viewInsets.right,
    bottom: viewInsets.bottom,
  );
  tester.view.padding = FakeViewPadding(
    left: padding.left,
    top: padding.top,
    right: padding.right,
    bottom: padding.bottom,
  );
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
    tester.view.resetViewInsets();
    tester.view.resetPadding();
  });
}

Widget sprint9cTestApp({
  required Widget child,
  Locale locale = const Locale('en'),
  ThemeMode themeMode = ThemeMode.light,
  double textScale = 1,
}) {
  return MaterialApp(
    locale: locale,
    themeMode: themeMode,
    theme: ThemeData(useMaterial3: true, brightness: Brightness.light),
    darkTheme: ThemeData(useMaterial3: true, brightness: Brightness.dark),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    builder:
        (context, appChild) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.linear(textScale)),
          child: appChild!,
        ),
    home: child,
  );
}

void expectNoFlutterException(WidgetTester tester) {
  expect(tester.takeException(), isNull);
}
