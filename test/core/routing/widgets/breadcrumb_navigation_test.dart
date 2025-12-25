import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:grex/core/routing/router_delegate.dart';
import 'package:grex/core/routing/widgets/breadcrumb_navigation.dart';

void main() {
  group('BreadcrumbNavigation', () {
    testWidgets('should display custom breadcrumbs when provided', (
      tester,
    ) async {
      const customBreadcrumbs = [
        BreadcrumbItem(title: 'Home', path: '/'),
        BreadcrumbItem(title: 'Groups', path: '/groups'),
        BreadcrumbItem(title: 'Group Details', path: '/group/123'),
      ];

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: BreadcrumbNavigation(
              customBreadcrumbs: customBreadcrumbs,
              showHome: false,
            ),
          ),
        ),
      );

      expect(find.text('Home'), findsOneWidget);
      expect(find.text('Groups'), findsOneWidget);
      expect(find.text('Group Details'), findsOneWidget);
      expect(find.byIcon(Icons.chevron_right), findsNWidgets(2));
    });

    testWidgets('should show home breadcrumb when showHome is true', (
      tester,
    ) async {
      const customBreadcrumbs = [
        BreadcrumbItem(title: 'Groups', path: '/groups'),
      ];

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: BreadcrumbNavigation(
              customBreadcrumbs: customBreadcrumbs,
            ),
          ),
        ),
      );

      expect(find.text('Home'), findsOneWidget);
      expect(find.text('Groups'), findsOneWidget);
      expect(find.byIcon(Icons.chevron_right), findsOneWidget);
    });

    testWidgets('should not show home breadcrumb when showHome is false', (
      tester,
    ) async {
      const customBreadcrumbs = [
        BreadcrumbItem(title: 'Groups', path: '/groups'),
      ];

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: BreadcrumbNavigation(
              customBreadcrumbs: customBreadcrumbs,
              showHome: false,
            ),
          ),
        ),
      );

      expect(find.text('Home'), findsNothing);
      expect(find.text('Groups'), findsOneWidget);
      expect(find.byIcon(Icons.chevron_right), findsNothing);
    });

    testWidgets('should handle empty breadcrumbs', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: BreadcrumbNavigation(
              customBreadcrumbs: [],
            ),
          ),
        ),
      );

      expect(find.byType(BreadcrumbNavigation), findsOneWidget);
      expect(find.text('Home'), findsNothing);
    });

    testWidgets('should apply custom text color', (tester) async {
      const customBreadcrumbs = [
        BreadcrumbItem(title: 'Test', path: '/test'),
      ];

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: BreadcrumbNavigation(
              customBreadcrumbs: customBreadcrumbs,
              textColor: Colors.red,
              showHome: false,
            ),
          ),
        ),
      );

      final textWidget = tester.widget<Text>(find.text('Test'));
      expect(textWidget.style?.color, equals(Colors.red));
    });

    testWidgets('should apply custom separator color', (tester) async {
      const customBreadcrumbs = [
        BreadcrumbItem(title: 'First', path: '/first'),
        BreadcrumbItem(title: 'Second', path: '/second'),
      ];

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: BreadcrumbNavigation(
              customBreadcrumbs: customBreadcrumbs,
              separatorColor: Colors.blue,
              showHome: false,
            ),
          ),
        ),
      );

      final iconWidget = tester.widget<Icon>(find.byIcon(Icons.chevron_right));
      expect(iconWidget.color, equals(Colors.blue));
    });

    testWidgets('should handle tap on non-last breadcrumb items', (
      tester,
    ) async {
      const customBreadcrumbs = [
        BreadcrumbItem(title: 'First', path: '/first'),
        BreadcrumbItem(title: 'Second', path: '/second'),
      ];

      await tester.pumpWidget(
        MaterialApp.router(
          routerConfig: GoRouter(
            initialLocation: '/second',
            routes: [
              GoRoute(
                path: '/first',
                builder: (context, state) => const Scaffold(
                  body: Text('First Page'),
                ),
              ),
              GoRoute(
                path: '/second',
                builder: (context, state) => const Scaffold(
                  body: BreadcrumbNavigation(
                    customBreadcrumbs: customBreadcrumbs,
                    showHome: false,
                  ),
                ),
              ),
            ],
          ),
        ),
      );

      // Tap on first breadcrumb (should be clickable)
      await tester.tap(find.text('First'));
      await tester.pumpAndSettle();

      expect(find.text('First Page'), findsOneWidget);
    });

    testWidgets('should not handle tap on last breadcrumb item', (
      tester,
    ) async {
      const customBreadcrumbs = [
        BreadcrumbItem(title: 'First', path: '/first'),
        BreadcrumbItem(title: 'Second', path: '/second'),
      ];

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: BreadcrumbNavigation(
              customBreadcrumbs: customBreadcrumbs,
              showHome: false,
            ),
          ),
        ),
      );

      // Last item should not be clickable (no InkWell onTap)
      final lastItemFinder = find.text('Second');
      expect(lastItemFinder, findsOneWidget);

      // Verify the last item has different styling
      final lastTextWidget = tester.widget<Text>(lastItemFinder);
      expect(lastTextWidget.style?.fontWeight, equals(FontWeight.w600));
    });
  });

  group('CompactBreadcrumbNavigation', () {
    testWidgets('should display limited number of breadcrumbs', (tester) async {
      const customBreadcrumbs = [
        BreadcrumbItem(title: 'First', path: '/first'),
        BreadcrumbItem(title: 'Second', path: '/second'),
        BreadcrumbItem(title: 'Third', path: '/third'),
        BreadcrumbItem(title: 'Fourth', path: '/fourth'),
      ];

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CompactBreadcrumbNavigation(
              customBreadcrumbs: customBreadcrumbs,
            ),
          ),
        ),
      );

      // Should show only last 2 items
      expect(find.text('First'), findsNothing);
      expect(find.text('Second'), findsNothing);
      expect(find.text('Third'), findsOneWidget);
      expect(find.text('Fourth'), findsOneWidget);

      // Should show more indicator
      expect(find.byIcon(Icons.more_horiz), findsOneWidget);
    });

    testWidgets('should not show more indicator when items fit', (
      tester,
    ) async {
      const customBreadcrumbs = [
        BreadcrumbItem(title: 'First', path: '/first'),
        BreadcrumbItem(title: 'Second', path: '/second'),
      ];

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CompactBreadcrumbNavigation(
              customBreadcrumbs: customBreadcrumbs,
              maxItems: 3,
            ),
          ),
        ),
      );

      expect(find.text('First'), findsOneWidget);
      expect(find.text('Second'), findsOneWidget);
      expect(find.byIcon(Icons.more_horiz), findsNothing);
    });

    testWidgets('should handle empty breadcrumbs', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CompactBreadcrumbNavigation(
              customBreadcrumbs: [],
            ),
          ),
        ),
      );

      expect(find.byType(CompactBreadcrumbNavigation), findsOneWidget);
      expect(find.byIcon(Icons.more_horiz), findsNothing);
    });

    testWidgets('should use smaller text style', (tester) async {
      const customBreadcrumbs = [
        BreadcrumbItem(title: 'Test', path: '/test'),
      ];

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CompactBreadcrumbNavigation(
              customBreadcrumbs: customBreadcrumbs,
            ),
          ),
        ),
      );

      final textWidget = tester.widget<Text>(find.text('Test'));
      // Should use bodySmall style (smaller than regular breadcrumbs)
      expect(textWidget.maxLines, equals(1));
      expect(textWidget.overflow, equals(TextOverflow.ellipsis));
    });

    testWidgets('should handle tap on non-last items', (tester) async {
      const customBreadcrumbs = [
        BreadcrumbItem(title: 'First', path: '/first'),
        BreadcrumbItem(title: 'Second', path: '/second'),
      ];

      await tester.pumpWidget(
        MaterialApp.router(
          routerConfig: GoRouter(
            initialLocation: '/second',
            routes: [
              GoRoute(
                path: '/first',
                builder: (context, state) => const Scaffold(
                  body: Text('First Page'),
                ),
              ),
              GoRoute(
                path: '/second',
                builder: (context, state) => const Scaffold(
                  body: CompactBreadcrumbNavigation(
                    customBreadcrumbs: customBreadcrumbs,
                  ),
                ),
              ),
            ],
          ),
        ),
      );

      // Tap on first breadcrumb
      await tester.tap(find.text('First'));
      await tester.pumpAndSettle();

      expect(find.text('First Page'), findsOneWidget);
    });
  });
}
