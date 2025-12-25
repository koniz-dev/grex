import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:grex/features/expenses/domain/entities/split_method.dart';
import 'package:grex/features/expenses/presentation/widgets/split_method_selector.dart';

void main() {
  group('SplitMethodSelector Widget Tests', () {
    testWidgets('should display all split method options', (tester) async {
      var selectedMethod = SplitMethod.equal;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SplitMethodSelector(
              selectedMethod: selectedMethod,
              onMethodChanged: (method) => selectedMethod = method,
            ),
          ),
        ),
      );

      // Check all split method options
      expect(find.text(SplitMethod.equal.displayName), findsOneWidget);
      expect(find.text(SplitMethod.percentage.displayName), findsOneWidget);
      expect(find.text(SplitMethod.exact.displayName), findsOneWidget);
      expect(find.text(SplitMethod.shares.displayName), findsOneWidget);
    });

    testWidgets('should show equal split as selected by default', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SplitMethodSelector(
              selectedMethod: SplitMethod.equal,
              onMethodChanged: (method) {},
            ),
          ),
        ),
      );

      // Equal split should be selected
      final equalOption = find.ancestor(
        of: find.text(SplitMethod.equal.displayName),
        matching: find.byType(RadioListTile<SplitMethod>),
      );

      final radioTile = tester.widget<RadioListTile<SplitMethod>>(equalOption);
      expect(radioTile.value, equals(SplitMethod.equal));
      // Accessing deprecated member for testing purposes
      // ignore: deprecated_member_use
      expect(radioTile.value == radioTile.groupValue, isTrue);
    });

    testWidgets('should call onMethodChanged when selection changes', (
      tester,
    ) async {
      var selectedMethod = SplitMethod.equal;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SplitMethodSelector(
              selectedMethod: selectedMethod,
              onMethodChanged: (method) => selectedMethod = method,
            ),
          ),
        ),
      );

      // Tap on percentage option
      await tester.tap(find.text(SplitMethod.percentage.displayName));

      expect(selectedMethod, equals(SplitMethod.percentage));
    });

    testWidgets('should display descriptions for each method', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SplitMethodSelector(
              selectedMethod: SplitMethod.equal,
              onMethodChanged: (method) {},
            ),
          ),
        ),
      );

      // Check descriptions
      expect(
        find.text(SplitMethod.equal.description),
        findsOneWidget,
      );
      expect(find.text(SplitMethod.percentage.description), findsOneWidget);
      expect(find.text(SplitMethod.exact.description), findsOneWidget);
      expect(find.text(SplitMethod.shares.description), findsOneWidget);
    });

    testWidgets('should display icons for each method', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SplitMethodSelector(
              selectedMethod: SplitMethod.equal,
              onMethodChanged: (method) {},
            ),
          ),
        ),
      );

      // Check icons
      expect(find.byIcon(Icons.balance), findsOneWidget);
      expect(find.byIcon(Icons.pie_chart), findsOneWidget);
      expect(find.byIcon(Icons.percent), findsOneWidget);
      expect(find.byIcon(Icons.calculate), findsOneWidget);
    });

    testWidgets('should update selection when selectedMethod prop changes', (
      tester,
    ) async {
      var selectedMethod = SplitMethod.equal;

      await tester.pumpWidget(
        MaterialApp(
          home: StatefulBuilder(
            builder: (context, setState) {
              return Scaffold(
                body: Column(
                  children: [
                    SplitMethodSelector(
                      selectedMethod: selectedMethod,
                      onMethodChanged: (method) {
                        setState(() {
                          selectedMethod = method;
                        });
                      },
                    ),
                    ElevatedButton(
                      onPressed: () {
                        setState(() {
                          selectedMethod = SplitMethod.exact;
                        });
                      },
                      child: const Text('Change to Exact'),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      );

      // Initially equal should be selected
      final equalOption = find.ancestor(
        of: find.text(SplitMethod.equal.displayName),
        matching: find.byType(RadioListTile<SplitMethod>),
      );

      var radioTile = tester.widget<RadioListTile<SplitMethod>>(equalOption);
      // Accessing deprecated member for testing purposes
      // ignore: deprecated_member_use
      expect(radioTile.value == radioTile.groupValue, isTrue);

      // Change selection programmatically
      await tester.tap(find.text('Change to Exact'));
      await tester.pump();

      // Exact should now be selected
      final exactOption = find.ancestor(
        of: find.text(SplitMethod.exact.displayName),
        matching: find.byType(RadioListTile<SplitMethod>),
      );

      radioTile = tester.widget<RadioListTile<SplitMethod>>(exactOption);
      // Accessing deprecated member for testing purposes
      // ignore: deprecated_member_use
      expect(radioTile.value == radioTile.groupValue, isTrue);
    });

    testWidgets('should have proper styling for radio tiles', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SplitMethodSelector(
              selectedMethod: SplitMethod.equal,
              onMethodChanged: (method) {},
            ),
          ),
        ),
      );

      // Check that all options are RadioListTiles
      expect(find.byType(RadioListTile<SplitMethod>), findsNWidgets(4));

      // Check that tiles have proper content structure
      final radioTiles = tester.widgetList<RadioListTile<SplitMethod>>(
        find.byType(RadioListTile<SplitMethod>),
      );

      for (final tile in radioTiles) {
        expect(tile.title, isNotNull);
        expect(tile.subtitle, isNotNull);
        expect(tile.secondary, isNotNull);
      }
    });

    testWidgets('should handle all split method values', (tester) async {
      final methods = <SplitMethod>[];
      var selectedMethod = SplitMethod.equal;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                return SplitMethodSelector(
                  selectedMethod: selectedMethod,
                  onMethodChanged: (method) {
                    setState(() {
                      selectedMethod = method;
                    });
                    methods.add(method);
                  },
                );
              },
            ),
          ),
        ),
      );

      // Test each method
      await tester.tap(find.text(SplitMethod.percentage.displayName));
      await tester.pump();
      await tester.tap(find.text(SplitMethod.exact.displayName));
      await tester.pump();
      await tester.tap(find.text(SplitMethod.shares.displayName));
      await tester.pump();
      await tester.tap(find.text(SplitMethod.equal.displayName));
      await tester.pump();

      expect(methods, [
        SplitMethod.percentage,
        SplitMethod.exact,
        SplitMethod.shares,
        SplitMethod.equal,
      ]);
    });

    testWidgets('should be scrollable when content overflows', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              height: 200, // Constrain height to force scrolling
              child: SplitMethodSelector(
                selectedMethod: SplitMethod.equal,
                onMethodChanged: (method) {},
              ),
            ),
          ),
        ),
      );

      expect(find.byType(SplitMethodSelector), findsOneWidget);
      expect(find.byType(SingleChildScrollView), findsOneWidget);
    });

    testWidgets('should maintain selection state correctly', (tester) async {
      var selectedMethod = SplitMethod.equal;

      await tester.pumpWidget(
        MaterialApp(
          home: StatefulBuilder(
            builder: (context, setState) {
              return Scaffold(
                body: SplitMethodSelector(
                  selectedMethod: selectedMethod,
                  onMethodChanged: (method) {
                    setState(() {
                      selectedMethod = method;
                    });
                  },
                ),
              );
            },
          ),
        ),
      );

      // Change to percentage
      await tester.tap(find.text(SplitMethod.percentage.displayName));
      await tester.pump();

      // Verify percentage is selected
      final percentageOption = find.ancestor(
        of: find.text(SplitMethod.percentage.displayName),
        matching: find.byType(RadioListTile<SplitMethod>),
      );

      final radioTile = tester.widget<RadioListTile<SplitMethod>>(
        percentageOption,
      );
      // Accessing deprecated member for testing purposes
      // ignore: deprecated_member_use
      expect(radioTile.value == radioTile.groupValue, isTrue);

      // Change to exact
      await tester.tap(find.text(SplitMethod.exact.displayName));
      await tester.pump();

      // Verify exact is selected
      final exactOption = find.ancestor(
        of: find.text(SplitMethod.exact.displayName),
        matching: find.byType(RadioListTile<SplitMethod>),
      );

      final exactRadioTile = tester.widget<RadioListTile<SplitMethod>>(
        exactOption,
      );
      // Accessing deprecated member for testing purposes
      // ignore: deprecated_member_use
      expect(exactRadioTile.value == exactRadioTile.groupValue, isTrue);
    });
  });
}
