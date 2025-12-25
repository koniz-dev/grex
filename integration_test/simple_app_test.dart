import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:grex/main.dart' as app;
import 'package:integration_test/integration_test.dart';

/// Simple integration test to verify the app can start
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Simple App Tests', () {
    testWidgets('app starts without crashing', (tester) async {
      // Start the app
      app.main();
      await tester.pumpAndSettle();

      // Verify the app has started by looking for a MaterialApp
      expect(find.byType(MaterialApp), findsOneWidget);
    });
  });
}
