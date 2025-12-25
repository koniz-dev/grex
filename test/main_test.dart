import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:grex/features/groups/presentation/pages/group_list_page.dart';
import 'package:grex/main.dart';

void main() {
  group('MyApp', () {
    testWidgets('should create MyApp widget', (tester) async {
      const myApp = MyApp();
      expect(myApp, isA<ConsumerWidget>());
    });

    testWidgets('should build MaterialApp with correct title', (tester) async {
      final container = ProviderContainer();
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MyApp(),
        ),
      );

      // Wait for router to initialize and navigation to complete
      // Use timeout to prevent hanging
      await tester.pumpAndSettle(const Duration(seconds: 5));

      // Check that MaterialApp is built (title is a property, not displayed
      // text)
      final materialApp = tester.widget<MaterialApp>(find.byType(MaterialApp));
      expect(materialApp.title, 'Grex');
    });

    testWidgets('should use light theme by default', (tester) async {
      final container = ProviderContainer();
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MyApp(),
        ),
      );

      final materialApp = tester.widget<MaterialApp>(find.byType(MaterialApp));
      expect(materialApp.theme, isNotNull);
    });

    testWidgets('should have dark theme configured', (tester) async {
      final container = ProviderContainer();
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MyApp(),
        ),
      );

      final materialApp = tester.widget<MaterialApp>(find.byType(MaterialApp));
      expect(materialApp.darkTheme, isNotNull);
    });

    testWidgets('should configure router correctly', (tester) async {
      final container = ProviderContainer();
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MyApp(),
        ),
      );

      await tester.pumpAndSettle(const Duration(seconds: 5));

      final materialApp = tester.widget<MaterialApp>(find.byType(MaterialApp));
      expect(materialApp.routerConfig, isNotNull);
    });

    testWidgets('should configure localization delegates', (tester) async {
      final container = ProviderContainer();
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MyApp(),
        ),
      );

      final materialApp = tester.widget<MaterialApp>(find.byType(MaterialApp));
      expect(materialApp.localizationsDelegates, isNotNull);
      expect(materialApp.localizationsDelegates!.length, 4);
    });

    testWidgets('should configure supported locales', (tester) async {
      final container = ProviderContainer();
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MyApp(),
        ),
      );

      final materialApp = tester.widget<MaterialApp>(find.byType(MaterialApp));
      expect(materialApp.supportedLocales, isNotNull);
      expect(materialApp.supportedLocales.length, greaterThan(0));
    });

    testWidgets('should use locale from provider', (tester) async {
      final container = ProviderContainer();
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MyApp(),
        ),
      );

      await tester.pump();

      final materialApp = tester.widget<MaterialApp>(find.byType(MaterialApp));
      expect(materialApp.locale, isNotNull);
    });

    testWidgets('should configure text direction from provider', (
      tester,
    ) async {
      final container = ProviderContainer();
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MyApp(),
        ),
      );

      await tester.pump();

      // The builder should wrap content in Directionality
      final directionality = find.byType(Directionality);
      expect(directionality, findsWidgets);
    });

    testWidgets('should wrap content in RepaintBoundary', (tester) async {
      final container = ProviderContainer();
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MyApp(),
        ),
      );

      await tester.pump();

      // The builder should wrap content in RepaintBoundary
      final repaintBoundary = find.byType(RepaintBoundary);
      expect(repaintBoundary, findsWidgets);
    });
  });

  group('GroupListPage', () {
    testWidgets('should create GroupListPage widget', (tester) async {
      const groupListPage = GroupListPage();
      expect(groupListPage, isA<StatelessWidget>());
    });
  });
}
