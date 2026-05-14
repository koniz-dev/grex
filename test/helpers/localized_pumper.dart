import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:grex/l10n/app_localizations.dart';

/// Pumps [child] wrapped in a minimal [MaterialApp] that exposes
/// [AppLocalizations].
///
/// Locale defaults to Vietnamese because existing widget assertions in this
/// repo are written against Vietnamese copy.
Future<void> pumpLocalized(
  WidgetTester tester,
  Widget child, {
  Locale locale = const Locale('vi'),
  ThemeData? theme,
}) {
  return tester.pumpWidget(
    MaterialApp(
      theme: theme,
      locale: locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: Scaffold(body: child),
    ),
  );
}
